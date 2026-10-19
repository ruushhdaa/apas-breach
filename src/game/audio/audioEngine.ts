// APAS : BREACH — Audio Engine
// 100% Web Audio API procedural synthesis. Zero external audio files or samples.

class AudioEngine {
  private ctx: AudioContext | null = null;
  private isMuted: boolean = true;
  private isInitialized: boolean = false;
  private masterGain: GainNode | null = null;

  // Ambient Layer Nodes
  private droneGain: GainNode | null = null;
  private osc60: OscillatorNode | null = null;
  private osc120: OscillatorNode | null = null;
  private droneFilter: BiquadFilterNode | null = null;

  private waterGain: GainNode | null = null;
  private waterNoise: AudioBufferSourceNode | null = null;
  private waterFilter: BiquadFilterNode | null = null;

  private fanGain: GainNode | null = null;
  private fanNoise: AudioBufferSourceNode | null = null;
  private fanFilter: BiquadFilterNode | null = null;

  private hum180Gain: GainNode | null = null;
  private osc180: OscillatorNode | null = null;

  private alarmGain: GainNode | null = null;
  private alarmTimer: number | null = null;

  // Level generative pad
  private padGain: GainNode | null = null;
  private currentLevel: number = 1;
  private currentHHI: number = 38;

  private listeners: Set<(muted: boolean) => void> = new Set();

  public subscribe(listener: (muted: boolean) => void): () => void {
    this.listeners.add(listener);
    listener(this.isMuted);
    return () => this.listeners.delete(listener);
  }

  private notify() {
    this.listeners.forEach((fn) => fn(this.isMuted));
  }

  public init() {
    if (this.isInitialized && this.ctx) return;

    const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    this.ctx = new AudioCtx();

    // Master Gain
    this.masterGain = this.ctx.createGain();
    this.masterGain.gain.setValueAtTime(0, this.ctx.currentTime);
    this.masterGain.connect(this.ctx.destination);

    // 1. 60Hz + 120Hz Low Drone with LFO Filter
    this.droneGain = this.ctx.createGain();
    this.droneGain.gain.setValueAtTime(0.18, this.ctx.currentTime);

    this.droneFilter = this.ctx.createBiquadFilter();
    this.droneFilter.type = 'lowpass';
    this.droneFilter.frequency.setValueAtTime(140, this.ctx.currentTime);

    const droneLfo = this.ctx.createOscillator();
    droneLfo.frequency.setValueAtTime(0.08, this.ctx.currentTime);
    const lfoGain = this.ctx.createGain();
    lfoGain.gain.setValueAtTime(40, this.ctx.currentTime);
    droneLfo.connect(lfoGain);
    lfoGain.connect(this.droneFilter.frequency);
    droneLfo.start();

    this.osc60 = this.ctx.createOscillator();
    this.osc60.type = 'sine';
    this.osc60.frequency.setValueAtTime(60, this.ctx.currentTime);

    this.osc120 = this.ctx.createOscillator();
    this.osc120.type = 'sine';
    this.osc120.frequency.setValueAtTime(120, this.ctx.currentTime);
    const subGain = this.ctx.createGain();
    subGain.gain.setValueAtTime(0.4, this.ctx.currentTime);
    this.osc120.connect(subGain);

    this.osc60.connect(this.droneFilter);
    subGain.connect(this.droneFilter);
    this.droneFilter.connect(this.droneGain);
    this.droneGain.connect(this.masterGain);

    this.osc60.start();
    this.osc120.start();

    // 2. Distant Water Flow (White noise bandpassed 400-800Hz)
    const noiseBuffer = this.createNoiseBuffer(2);
    this.waterNoise = this.ctx.createBufferSource();
    this.waterNoise.buffer = noiseBuffer;
    this.waterNoise.loop = true;

    this.waterFilter = this.ctx.createBiquadFilter();
    this.waterFilter.type = 'bandpass';
    this.waterFilter.frequency.setValueAtTime(600, this.ctx.currentTime);
    this.waterFilter.Q.setValueAtTime(1.5, this.ctx.currentTime);

    this.waterGain = this.ctx.createGain();
    this.waterGain.gain.setValueAtTime(0.12, this.ctx.currentTime);

    this.waterNoise.connect(this.waterFilter);
    this.waterFilter.connect(this.waterGain);
    this.waterGain.connect(this.masterGain);
    this.waterNoise.start();

    // 3. 180Hz Harmonic Hum
    this.osc180 = this.ctx.createOscillator();
    this.osc180.type = 'sawtooth';
    this.osc180.frequency.setValueAtTime(180, this.ctx.currentTime);
    const humFilter = this.ctx.createBiquadFilter();
    humFilter.type = 'lowpass';
    humFilter.frequency.setValueAtTime(320, this.ctx.currentTime);

    this.hum180Gain = this.ctx.createGain();
    this.hum180Gain.gain.setValueAtTime(0.0, this.ctx.currentTime);

    this.osc180.connect(humFilter);
    humFilter.connect(this.hum180Gain);
    this.hum180Gain.connect(this.masterGain);
    this.osc180.start();

    // 4. Industrial Fan Roar (Filtered pinkish noise)
    this.fanNoise = this.ctx.createBufferSource();
    this.fanNoise.buffer = noiseBuffer;
    this.fanNoise.loop = true;

    this.fanFilter = this.ctx.createBiquadFilter();
    this.fanFilter.type = 'lowpass';
    this.fanFilter.frequency.setValueAtTime(800, this.ctx.currentTime);

    this.fanGain = this.ctx.createGain();
    this.fanGain.gain.setValueAtTime(0.04, this.ctx.currentTime);

    this.fanNoise.connect(this.fanFilter);
    this.fanFilter.connect(this.fanGain);
    this.fanGain.connect(this.masterGain);
    this.fanNoise.start();

    // 5. Alarm Gain
    this.alarmGain = this.ctx.createGain();
    this.alarmGain.gain.setValueAtTime(0.0, this.ctx.currentTime);
    this.alarmGain.connect(this.masterGain);

    // 6. Generative level pad gain
    this.padGain = this.ctx.createGain();
    this.padGain.gain.setValueAtTime(0.08, this.ctx.currentTime);
    this.padGain.connect(this.masterGain);

    this.isInitialized = true;
    this.startAlarmLoop();
    this.updateAmbientMix(this.currentHHI, this.currentLevel);
  }

  private createNoiseBuffer(seconds: number): AudioBuffer {
    if (!this.ctx) throw new Error('No audio context');
    const bufferSize = seconds * this.ctx.sampleRate;
    const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      data[i] = Math.random() * 2 - 1;
    }
    return buffer;
  }

  private startAlarmLoop() {
    if (this.alarmTimer) clearInterval(this.alarmTimer);
    this.alarmTimer = window.setInterval(() => {
      if (!this.ctx || this.isMuted || !this.alarmGain) return;
      if (this.currentHHI <= 44) {
        const now = this.ctx.currentTime;
        const freq = this.currentHHI <= 24 ? 880 : 440;
        const dur = this.currentHHI <= 24 ? 0.35 : 0.15;
        const osc = this.ctx.createOscillator();
        const g = this.ctx.createGain();
        osc.type = this.currentHHI <= 24 ? 'sawtooth' : 'square';
        osc.frequency.setValueAtTime(freq, now);
        g.gain.setValueAtTime(0.12, now);
        g.gain.exponentialRampToValueAtTime(0.001, now + dur);
        osc.connect(g);
        g.connect(this.alarmGain);
        osc.start(now);
        osc.stop(now + dur);
      }
    }, 2800);
  }

  // Crossfade ambient layers according to HHI and Level
  public updateAmbientMix(hhi: number, level: number = 1) {
    this.currentHHI = hhi;
    this.currentLevel = level;
    if (!this.ctx || !this.isInitialized) return;

    const now = this.ctx.currentTime;
    const ramp = 3.0; // 3-second smooth transition

    // Drone pitch shifts slightly with load
    if (this.osc60) {
      this.osc60.frequency.linearRampToValueAtTime(56 + (100 - hhi) * 0.08, now + ramp);
    }

    // Water layer: louder in clean/restored state, fades in collapse
    if (this.waterGain) {
      const waterVol = hhi >= 65 ? 0.16 : hhi >= 45 ? 0.08 : 0.02;
      this.waterGain.gain.linearRampToValueAtTime(waterVol, now + ramp);
    }

    // 180Hz hum: louder in strained/critical
    if (this.hum180Gain) {
      const humVol = hhi < 65 && hhi >= 25 ? 0.14 : hhi < 25 ? 0.22 : 0.02;
      this.hum180Gain.gain.linearRampToValueAtTime(humVol, now + ramp);
    }

    // Fan roar: loud in collapse/critical
    if (this.fanGain) {
      const fanVol = hhi <= 24 ? 0.22 : hhi <= 44 ? 0.15 : hhi <= 64 ? 0.08 : 0.02;
      this.fanGain.gain.linearRampToValueAtTime(fanVol, now + ramp);
    }
  }

  public toggleMute(): boolean {
    if (!this.isInitialized) {
      this.init();
    }

    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume();
    }

    this.isMuted = !this.isMuted;

    if (this.masterGain && this.ctx) {
      const now = this.ctx.currentTime;
      if (this.isMuted) {
        this.masterGain.gain.cancelScheduledValues(now);
        this.masterGain.gain.setValueAtTime(this.masterGain.gain.value, now);
        this.masterGain.gain.linearRampToValueAtTime(0, now + 0.15);
      } else {
        this.masterGain.gain.cancelScheduledValues(now);
        this.masterGain.gain.setValueAtTime(this.masterGain.gain.value, now);
        this.masterGain.gain.linearRampToValueAtTime(0.35, now + 0.25);
      }
    }

    this.notify();
    return this.isMuted;
  }

  public getIsMuted(): boolean {
    return this.isMuted;
  }

  // --- UI & GAME PROCEDURAL SOUND EFFECTS ---
  public playHover() {
    if (this.isMuted || !this.ctx) return;
    try {
      const now = this.ctx.currentTime;
      const osc = this.ctx.createOscillator();
      const g = this.ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(1200, now);
      g.gain.setValueAtTime(0.04, now);
      g.gain.exponentialRampToValueAtTime(0.001, now + 0.02);
      osc.connect(g);
      g.connect(this.masterGain || this.ctx.destination);
      osc.start(now);
      osc.stop(now + 0.02);
    } catch {}
  }

  public playSelect() {
    if (this.isMuted || !this.ctx) return;
    try {
      const now = this.ctx.currentTime;
      const osc = this.ctx.createOscillator();
      const g = this.ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(660, now);
      osc.frequency.linearRampToValueAtTime(880, now + 0.18);
      g.gain.setValueAtTime(0.12, now);
      g.gain.exponentialRampToValueAtTime(0.001, now + 0.2);
      osc.connect(g);
      g.connect(this.masterGain || this.ctx.destination);
      osc.start(now);
      osc.stop(now + 0.2);
    } catch {}
  }

  public playDecisionCardOpen() {
    if (this.isMuted || !this.ctx) return;
    try {
      const now = this.ctx.currentTime;
      const freqs = [880, 660, 440];
      freqs.forEach((f, idx) => {
        const time = now + idx * 0.08;
        const osc = this.ctx!.createOscillator();
        const g = this.ctx!.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(f, time);
        g.gain.setValueAtTime(0.1, time);
        g.gain.exponentialRampToValueAtTime(0.001, time + 0.075);
        osc.connect(g);
        g.connect(this.masterGain || this.ctx!.destination);
        osc.start(time);
        osc.stop(time + 0.075);
      });
    } catch {}
  }

  public playWrongValve() {
    if (this.isMuted || !this.ctx) return;
    try {
      const now = this.ctx.currentTime;
      const osc = this.ctx.createOscillator();
      const g = this.ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(200, now);
      osc.frequency.linearRampToValueAtTime(80, now + 0.4);
      g.gain.setValueAtTime(0.18, now);
      g.gain.exponentialRampToValueAtTime(0.001, now + 0.4);
      osc.connect(g);
      g.connect(this.masterGain || this.ctx.destination);
      osc.start(now);
      osc.stop(now + 0.4);
    } catch {}
  }

  public playEvidenceChirp() {
    if (this.isMuted || !this.ctx) return;
    try {
      const now = this.ctx.currentTime;
      const osc = this.ctx.createOscillator();
      const g = this.ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(300, now);
      osc.frequency.exponentialRampToValueAtTime(600, now + 0.12);
      g.gain.setValueAtTime(0.14, now);
      g.gain.exponentialRampToValueAtTime(0.001, now + 0.14);
      osc.connect(g);
      g.connect(this.masterGain || this.ctx.destination);
      osc.start(now);
      osc.stop(now + 0.14);
    } catch {}
  }

  public playLevelComplete() {
    if (this.isMuted || !this.ctx) return;
    try {
      const now = this.ctx.currentTime;
      // Major triad arpeggio (C - E - G)
      const freqs = [523.25, 659.25, 783.99];
      freqs.forEach((f, idx) => {
        const time = now + idx * 0.15;
        const osc = this.ctx!.createOscillator();
        const g = this.ctx!.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(f, time);
        g.gain.setValueAtTime(0.15, time);
        g.gain.exponentialRampToValueAtTime(0.001, time + 0.3);
        osc.connect(g);
        g.connect(this.masterGain || this.ctx!.destination);
        osc.start(time);
        osc.stop(time + 0.3);
      });
    } catch {}
  }

  public playGameOver() {
    if (this.isMuted || !this.ctx) return;
    try {
      const now = this.ctx.currentTime;
      const osc = this.ctx.createOscillator();
      const g = this.ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(320, now);
      osc.frequency.exponentialRampToValueAtTime(45, now + 0.8);
      g.gain.setValueAtTime(0.2, now);
      g.gain.exponentialRampToValueAtTime(0.001, now + 0.8);
      osc.connect(g);
      g.connect(this.masterGain || this.ctx.destination);
      osc.start(now);
      osc.stop(now + 0.8);
    } catch {}
  }

  public playRadioSquelch(speaker: 'MEERA' | 'ROHAN' | 'SYSTEM' = 'MEERA') {
    if (this.isMuted || !this.ctx) return;
    try {
      const now = this.ctx.currentTime;
      // White noise burst bandpassed 300-3400Hz (VHF radio filter)
      const buffer = this.createNoiseBuffer(0.12);
      const src = this.ctx.createBufferSource();
      src.buffer = buffer;

      const bp = this.ctx.createBiquadFilter();
      bp.type = 'bandpass';
      bp.frequency.setValueAtTime(1800, now);
      bp.Q.setValueAtTime(1.2, now);

      const g = this.ctx.createGain();
      g.gain.setValueAtTime(0.08, now);
      g.gain.exponentialRampToValueAtTime(0.001, now + 0.12);

      src.connect(bp);
      bp.connect(g);
      g.connect(this.masterGain || this.ctx.destination);
      src.start(now);

      // Character tone
      const osc = this.ctx.createOscillator();
      const og = this.ctx.createGain();
      if (speaker === 'ROHAN') {
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(160, now + 0.05);
        og.gain.setValueAtTime(0.08, now + 0.05);
        og.gain.exponentialRampToValueAtTime(0.001, now + 0.2);
      } else {
        osc.type = 'sine';
        osc.frequency.setValueAtTime(480, now + 0.05);
        og.gain.setValueAtTime(0.08, now + 0.05);
        og.gain.exponentialRampToValueAtTime(0.001, now + 0.2);
      }
      osc.connect(og);
      og.connect(this.masterGain || this.ctx.destination);
      osc.start(now + 0.05);
      osc.stop(now + 0.2);
    } catch {}
  }

  public playInteract() {
    if (this.isMuted || !this.ctx) return;
    try {
      const now = this.ctx.currentTime;
      const osc = this.ctx.createOscillator();
      const g = this.ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(540, now);
      g.gain.setValueAtTime(0.1, now);
      g.gain.exponentialRampToValueAtTime(0.001, now + 0.08);
      osc.connect(g);
      g.connect(this.masterGain || this.ctx.destination);
      osc.start(now);
      osc.stop(now + 0.08);
    } catch {}
  }
}

export const audioEngine = new AudioEngine();
