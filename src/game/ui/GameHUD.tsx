import React, { useEffect, useRef } from 'react';
import * as THREE from 'three';
import { useGameStore } from '../../store/gameStore';
import { audioEngine } from '../audio/audioEngine';

interface GameHUDProps {
  playerPos: THREE.Vector3;
}

export const GameHUD: React.FC<GameHUDProps> = ({ playerPos }) => {
  const hhi = useGameStore((state) => state.hhi);
  const hhiTier = useGameStore((state) => state.hhiTier);
  const clock = useGameStore((state) => state.clock);
  const currentLevel = useGameStore((state) => state.currentLevel);
  const persistent = useGameStore((state) => state.persistent);
  const simOutput = useGameStore((state) => state.simOutput);
  const activeTimers = useGameStore((state) => state.activeTimers);
  const currentObjective = useGameStore((state) => state.currentObjective);
  const interactPrompt = useGameStore((state) => state.interactPrompt);
  const radioMessage = useGameStore((state) => state.radioMessage);
  const decisionCard = useGameStore((state) => state.decisionCard);
  const debriefCard = useGameStore((state) => state.debriefCard);
  const specialist = useGameStore((state) => state.specialist);
  const devPanel = useGameStore((state) => state.devPanel);
  const gameOverReason = useGameStore((state) => state.gameOverReason);
  const finalEnding = useGameStore((state) => state.finalEnding);
  const finalScore = useGameStore((state) => state.finalScore);

  const setSimInputs = useGameStore((state) => state.setSimInputs);
  const setHHIOverride = useGameStore((state) => state.setHHIOverride);
  const jumpToLevel = useGameStore((state) => state.jumpToLevel);
  const toggleMap = useGameStore((state) => state.toggleMap);
  const toggleDevPanel = useGameStore((state) => state.toggleDevPanel);
  const triggerGameOver = useGameStore((state) => state.triggerGameOver);
  const closeDebrief = useGameStore((state) => state.closeDebrief);
  const startNewGame = useGameStore((state) => state.startNewGame);
  const setGameState = useGameStore((state) => state.setGameState);

  const minimapCanvasRef = useRef<HTMLCanvasElement>(null);

  // Minimap rendering (150x150 top-down radar)
  useEffect(() => {
    const canvas = minimapCanvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    ctx.fillStyle = '#16120E';
    ctx.fillRect(0, 0, 150, 150);

    // Grid lines
    ctx.strokeStyle = '#2A2218';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(75, 0); ctx.lineTo(75, 150);
    ctx.moveTo(0, 75); ctx.lineTo(150, 75);
    ctx.stroke();

    // Map coordinate scale (world -60..120 to canvas 0..150)
    const scale = 150 / 180;
    const toCanvasX = (wx: number) => 75 + wx * scale;
    const toCanvasY = (wz: number) => 75 + (wz - 30) * scale;

    // Compound Wall boundary (x -50..50, z -50..50)
    ctx.strokeStyle = '#4D3A28';
    ctx.lineWidth = 1.5;
    ctx.strokeRect(toCanvasX(-50), toCanvasY(-50), 100 * scale, 100 * scale);

    // Gate 4 opening
    ctx.fillStyle = '#F0A500';
    ctx.fillRect(toCanvasX(-6), toCanvasY(50), 12 * scale, 2);

    // Creek zone (x 60..110)
    ctx.fillStyle = '#2A3644';
    ctx.fillRect(toCanvasX(60), toCanvasY(-50), 50 * scale, 100 * scale);

    // Key interactables as white dots
    const interactables = [
      { x: -15, z: 80, label: 'Tanker' },
      { x: -28, z: 44, label: 'Substation' },
      { x: -15, z: -25, label: 'Server Hall' },
      { x: 40, z: -20, label: 'Outfall' },
      { x: 20, z: 10, label: 'SCADA' },
      { x: 0, z: 58, label: 'Audit' },
    ];

    interactables.forEach((item) => {
      ctx.fillStyle = '#FFFFFF';
      ctx.beginPath();
      ctx.arc(toCanvasX(item.x), toCanvasY(item.z), 2.5, 0, Math.PI * 2);
      ctx.fill();
    });

    // Player dot (amber blinking)
    ctx.fillStyle = '#F0A500';
    ctx.beginPath();
    ctx.arc(toCanvasX(playerPos.x), toCanvasY(playerPos.z), 4, 0, Math.PI * 2);
    ctx.fill();

    // Player position coordinates
    ctx.font = '9px "Space Mono", monospace';
    ctx.fillStyle = '#A89880';
    ctx.fillText(`X:${Math.round(playerPos.x)} Z:${Math.round(playerPos.z)}`, 6, 142);
  }, [playerPos]);

  return (
    <div className="absolute inset-0 pointer-events-none select-none z-30 font-mono">
      {/* 1. TOP BAR */}
      <div className="absolute top-0 left-0 right-0 h-12 bg-[#16120E]/90 border-b-2 border-[#4D3A28] px-6 flex justify-between items-center text-xs pointer-events-auto">
        <div className="flex items-center gap-3">
          <span className="w-2.5 h-2.5 rounded-full bg-[#CC2200] animate-pulse" />
          <span className="font-bold text-[#F0A500] tracking-wider">
            HHI: {hhi.toFixed(1)} &mdash; {hhiTier.label}
          </span>
        </div>

        <div className="flex items-center gap-4">
          <span className="font-heading text-lg text-[#E8E0D0] tracking-wider">
            {clock.levelClockStr}
          </span>
          <span className="text-[#A89880] tracking-widest text-[11px] uppercase">
            SHIFT 1 &middot; 42°C
          </span>
        </div>

        <div className="flex items-center gap-4">
          <span className="text-[#A89880] uppercase tracking-wider">
            LEVEL {currentLevel}: METER 4
          </span>
          <button
            type="button"
            onClick={toggleMap}
            className="text-[10px] text-[#F0A500] hover:text-[#E8E0D0] border border-[#4D3A28] px-2 py-1 bg-[#201A14]"
          >
            [M] MAP
          </button>
        </div>
      </div>

      {/* 2. OBJECTIVE BANNER (BELOW TOP BAR) */}
      <div className="absolute top-14 left-6 z-20 bg-[#1C1713]/90 border-l-4 border-l-[#F0A500] border-y border-r border-[#4D3A28] px-4 py-2 shadow-[4px_4px_0px_#0A0806] max-w-xl pointer-events-auto">
        <span className="font-mono text-[9px] text-[#F0A500] uppercase font-bold tracking-widest block mb-0.5">
          CURRENT OBJECTIVE
        </span>
        <p className="font-mono text-xs text-[#E8E0D0] leading-snug">
          {currentObjective}
        </p>
      </div>

      {/* 3. RIGHT PANEL: 6 TELEMETRY METERS */}
      <div className="absolute right-6 top-16 w-64 bg-[#1C1713]/95 border-l-2 border-l-[#F0A500] border-y border-r border-[#4D3A28] p-3.5 shadow-[6px_6px_0px_#0A0806] pointer-events-auto">
        <div className="flex justify-between items-center mb-2 pb-1 border-b border-[#3A2E20]">
          <span className="text-[10px] text-[#F0A500] font-bold tracking-widest uppercase">
            SCADA TELEMETRY
          </span>
          <span className="text-[9px] text-[#A89880]">NODE MAH-04</span>
        </div>

        <div className="space-y-2 text-[11px]">
          {/* W — Water Use */}
          <div className="flex justify-between items-center">
            <span className="text-[#A89880]">W &middot; Water Draw</span>
            <span className="font-bold text-[#E8E0D0]">{simOutput.potableMLD.toFixed(2)} MLD</span>
          </div>

          {/* P — Power Draw / PUE */}
          <div className="flex justify-between items-center">
            <span className="text-[#A89880]">P &middot; Grid PUE</span>
            <span className="font-bold text-[#E8E0D0]">{simOutput.pue.toFixed(3)}</span>
          </div>

          {/* H — Junction Heat */}
          <div className="flex justify-between items-center">
            <span className="text-[#A89880]">H &middot; Silicon Tj</span>
            <span className={`font-bold ${simOutput.junctionTempC >= 85 ? 'text-[#CC2200]' : 'text-[#E8E0D0]'}`}>
              {simOutput.junctionTempC.toFixed(1)} &deg;C
            </span>
          </div>

          {/* C — Creek Health */}
          <div className="flex justify-between items-center">
            <span className="text-[#A89880]">C &middot; Creek Effluent</span>
            <span className="font-bold text-[#E8E0D0]">{simOutput.effluentMLD.toFixed(2)} MLD</span>
          </div>

          {/* T — Community Trust */}
          <div className="flex justify-between items-center">
            <span className="text-[#A89880]">T &middot; Public Trust</span>
            <span className="font-bold text-[#F0A500]">{persistent.trust} / 100</span>
          </div>

          {/* S — Uptime & SLA */}
          <div className="flex justify-between items-center">
            <span className="text-[#A89880]">S &middot; Uptime SLA</span>
            <span className="font-bold text-[#E8E0D0]">{persistent.sla}%</span>
          </div>
        </div>

        {/* Persistent Pressure & Budget */}
        <div className="mt-3 pt-2 border-t border-[#3A2E20] flex justify-between text-[10px] text-[#A89880]">
          <span>BUDGET: ₹{persistent.budget} L</span>
          <span>PRESSURE: {persistent.pressure}/100</span>
        </div>
      </div>

      {/* 4. TOP RIGHT CORNER: SCRAMBLE / SUMP TIMERS & EVIDENCE */}
      <div className="absolute right-6 top-80 flex flex-col items-end gap-2 pointer-events-auto">
        {/* Scramble Timer */}
        {activeTimers.scramble && activeTimers.scramble.active && (
          <div className="bg-[#CC2200] text-white px-3 py-1 font-heading text-xs animate-pulse shadow-[3px_3px_0px_#0A0806]">
            SCRAMBLE: {Math.ceil(activeTimers.scramble.remaining)}s REMAINING
          </div>
        )}

        {/* Evidence Counter */}
        <div className="bg-[#1C1713]/90 border border-[#4D3A28] px-3 py-1.5 flex items-center gap-1.5 shadow-[3px_3px_0px_#0A0806]">
          <span className="text-[10px] text-[#A89880] uppercase tracking-wider">EVIDENCE:</span>
          {Array.from({ length: 6 }).map((_, idx) => (
            <span
              key={idx}
              className={`w-2.5 h-2.5 border ${
                idx < persistent.evidence
                  ? 'bg-[#F0A500] border-[#FFD166]'
                  : 'bg-transparent border-[#4D3A28]'
              }`}
            />
          ))}
        </div>
      </div>

      {/* 5. BOTTOM LEFT: RADIO DIALOGUE & INTERACT PROMPT */}
      <div className="absolute bottom-6 left-6 max-w-lg space-y-2 pointer-events-auto">
        {/* Interaction Key Prompt */}
        {interactPrompt && (
          <div className="bg-[#F0A500] text-[#1C1713] font-bold px-4 py-2 font-mono text-xs shadow-[4px_4px_0px_#0A0806] flex items-center gap-2 animate-bounce">
            <span className="w-2 h-2 rounded-full bg-[#1C1713]" />
            <span>{interactPrompt}</span>
          </div>
        )}

        {/* Radio Box */}
        {radioMessage && (
          <div className="bg-[#1C1713]/95 border-2 border-[#4D3A28] p-4 shadow-[6px_6px_0px_#0A0806] tactical-corners animate-game-panel">
            <div className="flex items-center gap-2 mb-1">
              <span className="w-2 h-2 rounded-full bg-[#F0A500] animate-pulse" />
              <span className="text-[10px] text-[#F0A500] font-bold tracking-wider uppercase">
                {radioMessage.title}
              </span>
            </div>
            <p className="font-mono text-xs text-[#E8E0D0] leading-relaxed">
              "{radioMessage.text}"
            </p>
          </div>
        )}
      </div>

      {/* 6. BOTTOM RIGHT: 2D MINIMAP */}
      <div className="absolute bottom-6 right-6 pointer-events-auto">
        <div className="bg-[#1C1713] border-2 border-[#4D3A28] p-1.5 shadow-[6px_6px_0px_#0A0806] tactical-corners">
          <canvas
            ref={minimapCanvasRef}
            width={150}
            height={150}
            className="block"
          />
        </div>
      </div>

      {/* --- DECISION CARD OVERLAY MODAL --- */}
      {decisionCard && (
        <div className="absolute inset-0 bg-[#120F0C]/85 backdrop-blur-md flex items-center justify-center p-4 z-50 pointer-events-auto">
          <div className="w-full max-w-3xl bg-[#1C1713] border-2 border-[#F0A500] shadow-[10px_10px_0px_#0A0806] tactical-corners animate-game-panel overflow-hidden">
            <div className="hazard-stripe h-2.5 w-full" />
            <div className="p-6 border-b border-[#4D3A28] bg-[#16120E] text-center">
              <span className="text-[10px] text-[#F0A500] font-bold uppercase tracking-[0.25em] block mb-1">
                OPERATIONAL DECISION &middot; NO RETURN
              </span>
              <h2 className="font-heading text-2xl text-[#E8E0D0]">{decisionCard.title}</h2>
              <p className="text-xs text-[#A89880] mt-1">{decisionCard.subtitle}</p>
            </div>

            <div className="p-6 grid grid-cols-1 md:grid-cols-3 gap-4">
              {decisionCard.options.map((opt) => (
                <button
                  key={opt.key}
                  type="button"
                  onMouseEnter={() => audioEngine.playHover()}
                  onClick={() => {
                    audioEngine.playSelect();
                    decisionCard.onSelect(opt.key);
                  }}
                  className="bg-[#241E18] border-2 border-[#4D3A28] hover:border-[#F0A500] p-4 text-left transition-all shadow-[4px_4px_0px_#0A0806] flex flex-col justify-between group cursor-crosshair"
                >
                  <div>
                    <span className="font-mono text-xs font-bold text-[#F0A500] block mb-1">
                      OPTION {opt.key}
                    </span>
                    <h4 className="font-heading text-sm text-[#E8E0D0] group-hover:text-[#F0A500] mb-2">
                      {opt.title}
                    </h4>
                    <p className="font-mono text-xs text-[#A89880] leading-relaxed mb-3">
                      {opt.description}
                    </p>
                  </div>

                  <div className="pt-2 border-t border-[#3A2E20] text-[10px] text-[#F0A500] font-bold flex justify-between">
                    <span>SELECT [{opt.key}]</span>
                    <span>&rarr;</span>
                  </div>
                </button>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* --- DEBRIEF CARD OVERLAY MODAL --- */}
      {debriefCard && (
        <div className="absolute inset-0 bg-[#120F0C]/85 backdrop-blur-md flex items-center justify-center p-4 z-50 pointer-events-auto">
          <div className="w-full max-w-2xl bg-[#1C1713] border-2 border-[#4D3A28] shadow-[10px_10px_0px_#0A0806] tactical-corners animate-game-panel p-6">
            <span className="text-[10px] text-[#F0A500] font-bold uppercase tracking-widest block mb-1">
              LEVEL {debriefCard.levelNumber} &middot; INCIDENT DEBRIEF
            </span>
            <h2 className="font-heading text-2xl text-[#E8E0D0] mb-3">{debriefCard.title}</h2>
            <p className="font-mono text-xs text-[#A89880] leading-relaxed mb-6">
              {debriefCard.summary}
            </p>

            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 bg-[#18130F] p-4 border border-[#3A2E20] mb-6 text-xs">
              <div>
                <span className="text-[10px] text-[#A89880] block">POTABLE DRAW</span>
                <span className="font-bold text-[#E8E0D0]">{debriefCard.deltas.potableMLD}</span>
              </div>
              <div>
                <span className="text-[10px] text-[#A89880] block">JUNCTION TEMP</span>
                <span className="font-bold text-[#E8E0D0]">{debriefCard.deltas.junctionTemp}</span>
              </div>
              <div>
                <span className="text-[10px] text-[#A89880] block">GRID PUE</span>
                <span className="font-bold text-[#E8E0D0]">{debriefCard.deltas.pue}</span>
              </div>
              <div>
                <span className="text-[10px] text-[#A89880] block">CREEK DISCHARGE</span>
                <span className="font-bold text-[#E8E0D0]">{debriefCard.deltas.creekEffluent}</span>
              </div>
              <div>
                <span className="text-[10px] text-[#A89880] block">COMMUNITY TRUST</span>
                <span className="font-bold text-[#F0A500]">{debriefCard.deltas.trustDelta}</span>
              </div>
              <div>
                <span className="text-[10px] text-[#A89880] block">UPTIME SLA</span>
                <span className="font-bold text-[#E8E0D0]">{debriefCard.deltas.slaDelta}</span>
              </div>
            </div>

            <button
              type="button"
              onClick={closeDebrief}
              className="w-full bg-[#F0A500] hover:bg-[#FFD166] text-[#1C1713] font-bold py-3 text-xs tracking-wider uppercase cursor-crosshair shadow-[3px_3px_0px_#0A0806]"
            >
              PROCEED TO NEXT LEVEL &rarr;
            </button>
          </div>
        </div>
      )}

      {/* --- GAME OVER OVERLAY MODAL --- */}
      {gameOverReason && (
        <div className="absolute inset-0 bg-[#0A0806]/95 backdrop-blur-md flex items-center justify-center p-6 z-50 pointer-events-auto">
          <div className="max-w-xl text-center bg-[#1C1713] border-2 border-[#CC2200] p-8 shadow-[10px_10px_0px_#000]">
            <span className="w-3 h-3 rounded-full bg-[#CC2200] inline-block mb-3 animate-ping" />
            <h2 className="font-heading text-3xl text-[#CC2200] mb-3">CRITICAL FAILURE</h2>
            <p className="font-mono text-sm text-[#E8E0D0] mb-6 leading-relaxed">
              {gameOverReason}
            </p>
            <button
              type="button"
              onClick={() => startNewGame(specialist || 'VOLT')}
              className="bg-[#CC2200] hover:bg-[#EE3311] text-white font-bold py-3 px-8 text-xs font-mono uppercase tracking-wider cursor-crosshair"
            >
              RETRY FROM SHIFT START
            </button>
          </div>
        </div>
      )}

      {/* --- ENDINGS OVERLAY MODAL --- */}
      {finalEnding && (
        <div className="absolute inset-0 bg-[#0E0B08]/90 backdrop-blur-md flex items-center justify-center p-6 z-50 pointer-events-auto">
          <div className="max-w-2xl bg-[#1C1713] border-2 border-[#F0A500] p-8 text-center shadow-[10px_10px_0px_#0A0806]">
            <span className="text-xs text-[#F0A500] tracking-widest font-bold uppercase block mb-1">
              DAWN AUDIT CONCLUDED &middot; SCORE: {finalScore} / 100
            </span>
            <h2 className="font-heading text-4xl text-[#E8E0D0] mb-4">
              {finalEnding === 'RESTORED' && 'BASIN RESTORED'}
              {finalEnding === 'STRAINED' && 'STRAINED PASS'}
              {finalEnding === 'BREACH' && 'WATER BREACH'}
              {finalEnding === 'COLLAPSE' && 'SYSTEM COLLAPSE'}
            </h2>
            <p className="font-mono text-sm text-[#A89880] leading-relaxed mb-6">
              {finalEnding === 'RESTORED' &&
                'The creek is blue. The colony has water. The facility is running clean. You did something real tonight.'}
              {finalEnding === 'STRAINED' &&
                'The numbers are better. Not good. The creek will recover eventually. Rohan got his audit, and you got your evidence.'}
              {finalEnding === 'BREACH' &&
                'The facility passed the audit. The creek did not. The tankers are still queuing in Rabale.'}
              {finalEnding === 'COLLAPSE' &&
                'The facility is offline. The creek is black. The colony is still waiting.'}
            </p>
            <div className="flex justify-center gap-4">
              <button
                type="button"
                onClick={() => setGameState('MENU')}
                className="bg-[#F0A500] hover:bg-[#FFD166] text-[#1C1713] font-bold py-3 px-6 text-xs uppercase tracking-wider cursor-crosshair"
              >
                RETURN TO ATTRACT MODE
              </button>
            </div>
          </div>
        </div>
      )}

      {/* --- DEV PANEL (F1 KEY) --- */}
      {devPanel.open && (
        <div className="absolute top-14 right-6 w-84 bg-[#16120E] border-2 border-[#F0A500] p-4 shadow-[0_0_40px_rgba(0,0,0,0.95)] z-[9999] pointer-events-auto text-[11px] text-[#A89880] max-h-[85vh] overflow-y-auto game-scrollbar">
          <div className="flex justify-between items-center mb-3 pb-1 border-b border-[#4D3A28]">
            <span className="font-bold text-[#F0A500] font-mono">[F1] DEV PANEL</span>
            <button
              type="button"
              onClick={toggleDevPanel}
              className="text-xs text-[#F0A500] hover:text-white"
            >
              [X]
            </button>
          </div>

          {/* Jump to Level */}
          <div className="mb-4">
            <span className="text-[10px] text-[#F0A500] uppercase font-bold block mb-1">JUMP TO LEVEL</span>
            <div className="flex gap-1">
              {[1, 2, 3, 4, 5].map((lvl) => (
                <button
                  key={lvl}
                  type="button"
                  onClick={() => jumpToLevel(lvl)}
                  className={`flex-1 py-1 text-center font-bold ${
                    currentLevel === lvl
                      ? 'bg-[#F0A500] text-[#1C1713]'
                      : 'bg-[#241E18] text-[#E8E0D0] hover:bg-[#362B20]'
                  }`}
                >
                  L{lvl}
                </button>
              ))}
            </div>
          </div>

          {/* HHI Manual Override Slider */}
          <div className="mb-4">
            <div className="flex justify-between text-[10px] mb-1">
              <span className="text-[#F0A500] font-bold uppercase">HHI OVERRIDE</span>
              <span>{devPanel.hhiOverride !== null ? devPanel.hhiOverride : 'LIVE (AUTO)'}</span>
            </div>
            <input
              type="range"
              min="0"
              max="100"
              value={devPanel.hhiOverride !== null ? devPanel.hhiOverride : Math.round(hhi)}
              onChange={(e) => setHHIOverride(Number(e.target.value))}
              className="w-full accent-[#F0A500]"
            />
            <div className="flex justify-between mt-1">
              <button
                type="button"
                onClick={() => setHHIOverride(10)}
                className="text-[9px] px-1 bg-[#241E18] text-[#CC2200]"
              >
                10 (COLLAPSE)
              </button>
              <button
                type="button"
                onClick={() => setHHIOverride(38)}
                className="text-[9px] px-1 bg-[#241E18] text-[#F0A500]"
              >
                38 (CRITICAL)
              </button>
              <button
                type="button"
                onClick={() => setHHIOverride(95)}
                className="text-[9px] px-1 bg-[#241E18] text-[#4A7C59]"
              >
                95 (RESTORED)
              </button>
              <button
                type="button"
                onClick={() => setHHIOverride(null)}
                className="text-[9px] px-1 bg-[#241E18] text-[#A89880]"
              >
                RESET
              </button>
            </div>
          </div>

          {/* Simulation Inputs */}
          <div className="mb-4 space-y-2">
            <span className="text-[10px] text-[#F0A500] uppercase font-bold block">SIMULATION ENGINE INPUTS</span>
            <div>
              <span className="block text-[10px]">Cooling Topology</span>
              <select
                value={useGameStore.getState().simInputs.topology}
                onChange={(e) => setSimInputs({ topology: e.target.value as any })}
                className="w-full bg-[#241E18] border border-[#4D3A28] text-xs text-[#E8E0D0] p-1"
              >
                <option value="HYBRID_EVAP">HYBRID_EVAP</option>
                <option value="DRY">DRY</option>
                <option value="DTC">DTC (DIRECT-TO-CHIP)</option>
              </select>
            </div>
            <div>
              <span className="block text-[10px]">Water Source</span>
              <select
                value={useGameStore.getState().simInputs.waterSource}
                onChange={(e) => setSimInputs({ waterSource: e.target.value as any })}
                className="w-full bg-[#241E18] border border-[#4D3A28] text-xs text-[#E8E0D0] p-1"
              >
                <option value="POTABLE">POTABLE (DRINKING)</option>
                <option value="STP">STP (TREATED SEWAGE)</option>
              </select>
            </div>
            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id="zldCheck"
                checked={useGameStore.getState().simInputs.zld}
                onChange={(e) => setSimInputs({ zld: e.target.checked })}
                className="accent-[#F0A500]"
              />
              <label htmlFor="zldCheck" className="text-[10px]">Zero Liquid Discharge (ZLD)</label>
            </div>
          </div>

          {/* Fail State Toggles */}
          <div className="mb-2">
            <span className="text-[10px] text-[#F0A500] uppercase font-bold block mb-1">FAIL STATE TRIGGERS</span>
            <div className="flex flex-col gap-1">
              <button
                type="button"
                onClick={() => triggerGameOver('SILICON MELTDOWN — JUNCTION TEMP EXCEEDED 90°C')}
                className="py-1 bg-[#241E18] hover:bg-[#CC2200] text-white text-[10px] text-left px-2"
              >
                &bull; TRIGGER THERMAL BLACKOUT
              </button>
              <button
                type="button"
                onClick={() => triggerGameOver('SUMP OVERFLOW — EFFLUENT EMBANKMENT FAILURE')}
                className="py-1 bg-[#241E18] hover:bg-[#CC2200] text-white text-[10px] text-left px-2"
              >
                &bull; TRIGGER SUMP OVERFLOW
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
