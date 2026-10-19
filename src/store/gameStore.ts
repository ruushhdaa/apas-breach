import { create } from 'zustand';
import type {
  SimInputs,
  SimOutputs,
} from '../engine/simulation';
import {
  DEFAULT_SIM_INPUTS,
  runSimulation,
} from '../engine/simulation';
import type {
  HHITierConfig,
  HHIComponents,
} from '../engine/hhi';
import {
  calculateHHI,
  getHHITier,
} from '../engine/hhi';
import { audioEngine } from '../game/audio/audioEngine';

export type GameState =
  | 'MENU'
  | 'DISPATCH'
  | 'PLAYING'
  | 'PAUSED'
  | 'DEBRIEF'
  | 'GAMEOVER'
  | 'ENDINGS';

export type SpecialistType = 'VOLT' | 'ANANYA' | 'TARA';

export interface PersistentStats {
  sla: number;        // Starts 100
  trust: number;      // Starts 30
  evidence: number;   // 0 to 6
  budget: number;     // 100 + (evidence * 5), max 130
  pressure: number;   // 0 to 100 (Rohan audit pressure)
}

export interface RadioMessage {
  id: string;
  speaker: 'MEERA' | 'ROHAN' | 'SYSTEM' | 'SUNITA';
  title: string;
  text: string;
  durationSeconds?: number;
}

export interface DecisionOption {
  key: 'A' | 'B' | 'C';
  title: string;
  description: string;
  tags?: string[];
  effects: {
    w?: string;
    p?: string;
    h?: string;
    c?: string;
    t?: string;
    s?: string;
  };
  costBudget?: number;
  minEvidence?: number;
  maxPressure?: number;
}

export interface DecisionCardData {
  title: string;
  subtitle: string;
  options: DecisionOption[];
  onSelect: (optionKey: 'A' | 'B' | 'C') => void;
}

export interface DebriefData {
  title: string;
  levelNumber: number;
  summary: string;
  deltas: {
    potableMLD: string;
    junctionTemp: string;
    pue: string;
    creekEffluent: string;
    trustDelta: string;
    slaDelta: string;
  };
  fieldNoteId?: string;
  onContinue: () => void;
}

export interface GameStoreState {
  // Engine
  simInputs: SimInputs;
  simOutput: SimOutputs;
  hhi: number;
  hhiRaw: number;
  hhiComponents: HHIComponents;
  hhiTier: HHITierConfig;

  // Game Flow
  gameState: GameState;
  currentLevel: number;
  specialist: SpecialistType | null;
  persistent: PersistentStats;
  clock: {
    levelClockStr: string;
    totalSeconds: number;
  };

  // Timers
  activeTimers: {
    scramble: null | { remaining: number; active: boolean };
    sump: null | { remaining: number; active: boolean };
    heat: null | { remaining: number; active: boolean };
  };

  // Level Progression & Objectives
  currentObjective: string;
  currentBeat: number;
  evidenceItems: string[];
  interactPrompt: string | null;
  radioMessage: RadioMessage | null;
  decisionCard: DecisionCardData | null;
  debriefCard: DebriefData | null;
  gameOverReason: string | null;
  finalScore: number | null;
  finalEnding: 'RESTORED' | 'STRAINED' | 'BREACH' | 'COLLAPSE' | null;

  // Tools & HUD states
  qToolActive: boolean;
  mapOpen: boolean;
  devPanel: {
    open: boolean;
    hhiOverride: null | number;
  };
  settings: {
    muted: boolean;
    volume: number;
  };

  // Actions
  setSimInputs: (inputs: Partial<SimInputs>) => void;
  setHHIOverride: (override: number | null) => void;
  updateTick: (deltaSeconds: number) => void;
  setGameState: (state: GameState) => void;
  selectSpecialist: (specialist: SpecialistType) => void;
  startNewGame: (specialist: SpecialistType) => void;
  jumpToLevel: (level: number) => void;
  setObjective: (obj: string) => void;
  setBeat: (beat: number) => void;
  collectEvidence: (id: string, description: string) => void;
  modifyPersistent: (delta: Partial<PersistentStats>) => void;
  showRadio: (msg: RadioMessage) => void;
  clearRadio: () => void;
  setInteractPrompt: (prompt: string | null) => void;
  openDecisionCard: (data: DecisionCardData) => void;
  closeDecisionCard: () => void;
  showDebrief: (data: DebriefData) => void;
  closeDebrief: () => void;
  triggerGameOver: (reason: string) => void;
  triggerGameComplete: () => void;
  toggleQTool: () => void;
  toggleMap: () => void;
  toggleDevPanel: () => void;
  toggleMute: () => void;
}

const initialOutputs = runSimulation(DEFAULT_SIM_INPUTS);
const initialHHI = calculateHHI(initialOutputs, 30);

export const useGameStore = create<GameStoreState>((set, get) => ({
  simInputs: { ...DEFAULT_SIM_INPUTS },
  simOutput: initialOutputs,
  hhi: initialHHI.hhi,
  hhiRaw: initialHHI.hhi,
  hhiComponents: initialHHI.components,
  hhiTier: initialHHI.tier,

  gameState: 'MENU',
  currentLevel: 1,
  specialist: null,
  persistent: {
    sla: 100,
    trust: 30,
    evidence: 0,
    budget: 100,
    pressure: 0,
  },
  clock: {
    levelClockStr: '16:30',
    totalSeconds: 0,
  },

  activeTimers: {
    scramble: null,
    sump: null,
    heat: null,
  },

  currentObjective: 'Report to Gate 4 staging area. Check reservoir levels.',
  currentBeat: 1,
  evidenceItems: [],
  interactPrompt: null,
  radioMessage: null,
  decisionCard: null,
  debriefCard: null,
  gameOverReason: null,
  finalScore: null,
  finalEnding: null,

  qToolActive: false,
  mapOpen: false,
  devPanel: {
    open: false,
    hhiOverride: null,
  },
  settings: {
    muted: true,
    volume: 0.5,
  },

  setSimInputs: (newInputs) => {
    const updatedInputs = { ...get().simInputs, ...newInputs };
    const outputs = runSimulation(updatedInputs);
    const { persistent, devPanel } = get();
    const hhiCalc = calculateHHI(outputs, persistent.trust, updatedInputs.toxicityIndex);
    const hhiEffective = devPanel.hhiOverride !== null ? devPanel.hhiOverride : hhiCalc.hhi;
    const tier = getHHITier(hhiEffective);

    set({
      simInputs: updatedInputs,
      simOutput: outputs,
      hhiRaw: hhiCalc.hhi,
      hhi: hhiEffective,
      hhiComponents: hhiCalc.components,
      hhiTier: tier,
    });

    audioEngine.updateAmbientMix(hhiEffective, get().currentLevel);
  },

  setHHIOverride: (override) => {
    set((state) => {
      const hhiVal = override !== null ? override : state.hhiRaw;
      const tier = getHHITier(hhiVal);
      audioEngine.updateAmbientMix(hhiVal, state.currentLevel);
      return {
        devPanel: { ...state.devPanel, hhiOverride: override },
        hhi: hhiVal,
        hhiTier: tier,
      };
    });
  },

  updateTick: (deltaSeconds) => {
    const state = get();
    if (state.gameState !== 'PLAYING') return;

    // Advance clock
    const newTotalSeconds = state.clock.totalSeconds + deltaSeconds;
    const baseMinutes = (state.currentLevel - 1) * 150 + Math.floor(newTotalSeconds / 60);
    const hour = Math.floor((16.5 * 60 + baseMinutes) / 60) % 24;
    const min = Math.floor((16.5 * 60 + baseMinutes) % 60);
    const timeStr = `${hour.toString().padStart(2, '0')}:${min.toString().padStart(2, '0')}`;

    // Smooth HHI lerp towards target
    const targetHHI = state.devPanel.hhiOverride !== null ? state.devPanel.hhiOverride : state.hhiRaw;
    const lerpedHHI = state.hhi + (targetHHI - state.hhi) * Math.min(1, deltaSeconds * 0.8);
    const tier = getHHITier(lerpedHHI);

    // Active timers tick
    let scramble = state.activeTimers.scramble;
    if (scramble && scramble.active) {
      const rem = scramble.remaining - deltaSeconds;
      if (rem <= 0) {
        state.triggerGameOver('SCRAMBLE FAILED — TOWER BASINS STARVED & SILICON OVERHEATED');
        return;
      }
      scramble = { ...scramble, remaining: rem };
    }

    let sump = state.activeTimers.sump;
    if (sump && sump.active) {
      const rem = sump.remaining - deltaSeconds;
      if (rem <= 0) {
        state.triggerGameOver('SUMP OVERFLOW — UNTREATED EFFLUENT BREACHED CREEK EMBANKMENT');
        return;
      }
      sump = { ...sump, remaining: rem };
    }

    let heat = state.activeTimers.heat;
    if (heat && heat.active) {
      const rem = heat.remaining - deltaSeconds;
      if (rem <= 0) {
        state.triggerGameOver('SILICON MELTDOWN — JUNCTION TEMP EXCEEDED 90°C FOR 20 SECONDS');
        return;
      }
      heat = { ...heat, remaining: rem };
    }

    set({
      hhi: Math.round(lerpedHHI * 10) / 10,
      hhiTier: tier,
      clock: {
        totalSeconds: newTotalSeconds,
        levelClockStr: timeStr,
      },
      activeTimers: { scramble, sump, heat },
    });
  },

  setGameState: (gameState) => {
    set({ gameState });
  },

  selectSpecialist: (specialist) => {
    set({ specialist });
  },

  startNewGame: (specialist) => {
    const outputs = runSimulation(DEFAULT_SIM_INPUTS);
    const initialHhi = calculateHHI(outputs, 30).hhi;
    set({
      gameState: 'PLAYING',
      currentLevel: 1,
      specialist,
      simInputs: { ...DEFAULT_SIM_INPUTS },
      simOutput: outputs,
      hhi: initialHhi,
      hhiRaw: initialHhi,
      hhiTier: getHHITier(initialHhi),
      persistent: {
        sla: 100,
        trust: 30,
        evidence: 0,
        budget: 100,
        pressure: 0,
      },
      evidenceItems: [],
      currentObjective: "Find Sunita tai at Rabale tanker queue (z: 80). Learn community status.",
      currentBeat: 1,
      clock: { levelClockStr: '16:30', totalSeconds: 0 },
      activeTimers: { scramble: null, sump: null, heat: null },
      radioMessage: {
        id: 'L1-START',
        speaker: 'MEERA',
        title: 'MEERA JOSHI // MPCB COORDINATOR',
        text: "You're on site under an emergency inspection warrant. Reservoir's at 14 percent. Find Sunita tai at the colony tanker queue, then locate the municipal meter at the substation.",
      },
      decisionCard: null,
      debriefCard: null,
      gameOverReason: null,
      finalScore: null,
      finalEnding: null,
    });
    audioEngine.updateAmbientMix(38, 1);
    audioEngine.playRadioSquelch('MEERA');
  },

  jumpToLevel: (level) => {
    const clocks = ['16:30', '19:00', '23:00', '03:00', '06:05'];
    const clockStr = clocks[Math.min(clocks.length - 1, level - 1)];
    set({
      currentLevel: level,
      currentBeat: 1,
      clock: { levelClockStr: clockStr, totalSeconds: 0 },
      decisionCard: null,
      debriefCard: null,
      interactPrompt: null,
    });
    audioEngine.updateAmbientMix(get().hhi, level);
  },

  setObjective: (currentObjective) => set({ currentObjective }),
  setBeat: (currentBeat) => set({ currentBeat }),

  collectEvidence: (id, description) => {
    const state = get();
    if (state.evidenceItems.includes(id)) return;
    const newCount = Math.min(6, state.persistent.evidence + 1);
    const newBudget = Math.min(130, 100 + newCount * 5);
    audioEngine.playEvidenceChirp();
    set({
      evidenceItems: [...state.evidenceItems, id],
      persistent: {
        ...state.persistent,
        evidence: newCount,
        budget: newBudget,
      },
      radioMessage: {
        id: `EVID-${Date.now()}`,
        speaker: 'SYSTEM',
        title: 'EVIDENCE RECORDED',
        text: `LOGGED: ${description} (TOTAL EVIDENCE: ${newCount}/6 · BUDGET BONUS: ₹${newBudget} L)`,
      },
    });
  },

  modifyPersistent: (delta) => {
    set((state) => ({
      persistent: {
        sla: Math.max(0, Math.min(100, state.persistent.sla + (delta.sla || 0))),
        trust: Math.max(0, Math.min(100, state.persistent.trust + (delta.trust || 0))),
        evidence: Math.max(0, Math.min(6, state.persistent.evidence + (delta.evidence || 0))),
        budget: Math.max(0, Math.min(130, state.persistent.budget + (delta.budget || 0))),
        pressure: Math.max(0, Math.min(100, state.persistent.pressure + (delta.pressure || 0))),
      },
    }));
  },

  showRadio: (msg) => {
    audioEngine.playRadioSquelch(msg.speaker === 'ROHAN' ? 'ROHAN' : 'MEERA');
    set({ radioMessage: msg });
  },

  clearRadio: () => set({ radioMessage: null }),
  setInteractPrompt: (prompt) => set({ interactPrompt: prompt }),

  openDecisionCard: (data) => {
    audioEngine.playDecisionCardOpen();
    set({ decisionCard: data });
  },

  closeDecisionCard: () => set({ decisionCard: null }),

  showDebrief: (data) => {
    set({ debriefCard: data, decisionCard: null, gameState: 'DEBRIEF' });
  },

  closeDebrief: () => {
    audioEngine.playSelect();
    const nextLevel = get().currentLevel + 1;
    if (nextLevel <= 5) {
      get().jumpToLevel(nextLevel);
      set({ gameState: 'PLAYING', debriefCard: null });
    } else {
      get().triggerGameComplete();
    }
  },

  triggerGameOver: (reason) => {
    audioEngine.playGameOver();
    set({
      gameState: 'GAMEOVER',
      gameOverReason: reason,
      decisionCard: null,
      debriefCard: null,
    });
  },

  triggerGameComplete: () => {
    const { hhi, persistent } = get();
    // Score = HHI * 0.5 + Trust * 0.3 + Evidence * 5 + (100 - Pressure) * 0.2
    const score = Math.round(
      hhi * 0.5 +
      persistent.trust * 0.3 +
      persistent.evidence * 5 +
      (100 - persistent.pressure) * 0.2
    );

    let ending: 'RESTORED' | 'STRAINED' | 'BREACH' | 'COLLAPSE' = 'COLLAPSE';
    if (score >= 80) ending = 'RESTORED';
    else if (score >= 55) ending = 'STRAINED';
    else if (score >= 30) ending = 'BREACH';
    else ending = 'COLLAPSE';

    set({
      gameState: 'ENDINGS',
      finalScore: score,
      finalEnding: ending,
    });
  },

  toggleQTool: () => {
    const next = !get().qToolActive;
    audioEngine.playInteract();
    set({ qToolActive: next });
  },

  toggleMap: () => {
    audioEngine.playHover();
    set((state) => ({ mapOpen: !state.mapOpen }));
  },

  toggleDevPanel: () => {
    audioEngine.playHover();
    set((state) => ({
      devPanel: { ...state.devPanel, open: !state.devPanel.open },
    }));
  },

  toggleMute: () => {
    const isMuted = audioEngine.toggleMute();
    set((state) => ({
      settings: { ...state.settings, muted: isMuted },
    }));
  },
}));
