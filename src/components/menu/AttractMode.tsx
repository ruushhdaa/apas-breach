import React, { useEffect, useRef, useState } from 'react';
import * as THREE from 'three';
import { useGameStore } from '../../store/gameStore';
import { audioEngine } from '../../game/audio/audioEngine';
import { WorldScene } from '../../game/world/WorldScene';
import { PlayerController } from '../../game/player/PlayerController';
import { LevelController } from '../../game/levels/LevelController';
import { GameHUD } from '../../game/ui/GameHUD';
import { FIELD_NOTES } from '../../data/fieldNotes';

import voltImg from '../../assets/characters/volt.png';
import ananyaImg from '../../assets/characters/ananya.png';
import taraImg from '../../assets/characters/tara.png';

type MenuOverlay = 'NONE' | 'DISPATCH' | 'SPECIALISTS' | 'FIELD_NOTES' | 'CREDITS';

export const AttractMode: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const sceneRef = useRef<THREE.Scene | null>(null);
  const cameraRef = useRef<THREE.PerspectiveCamera | null>(null);

  const gameState = useGameStore((state) => state.gameState);
  const specialist = useGameStore((state) => state.specialist);
  const hhi = useGameStore((state) => state.hhi);
  const hhiTier = useGameStore((state) => state.hhiTier);
  const qToolActive = useGameStore((state) => state.qToolActive);
  const settings = useGameStore((state) => state.settings);

  const startNewGame = useGameStore((state) => state.startNewGame);
  const updateTick = useGameStore((state) => state.updateTick);
  const setInteractPrompt = useGameStore((state) => state.setInteractPrompt);
  const toggleMute = useGameStore((state) => state.toggleMute);

  const [activeOverlay, setActiveOverlay] = useState<MenuOverlay>('NONE');
  const [playerPos, setPlayerPos] = useState<THREE.Vector3>(new THREE.Vector3(0, 0, 45));
  const mouseRef = useRef<{ x: number; y: number }>({ x: 0, y: 0 });

  // Mouse tracking for attract mode camera tilt (±5 degrees)
  useEffect(() => {
    const onMouseMove = (e: MouseEvent) => {
      mouseRef.current = {
        x: (e.clientX / window.innerWidth - 0.5) * 2,
        y: (e.clientY / window.innerHeight - 0.5) * 2,
      };
    };
    window.addEventListener('mousemove', onMouseMove);
    return () => window.removeEventListener('mousemove', onMouseMove);
  }, []);

  // --- THREE.JS INITIALIZATION & ATTRACT CAMERA LOOP ---
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    // 1. Scene & Exponential Fog (Dusk smog at HHI 38 baseline)
    const scene = new THREE.Scene();
    sceneRef.current = scene;
    const initialFogColor = new THREE.Color(hhiTier.skyColor);
    scene.background = initialFogColor;
    scene.fog = new THREE.FogExp2(initialFogColor.getHex(), hhiTier.fogDensity);

    // 2. Camera: FOV 55 (matching gameplay)
    const camera = new THREE.PerspectiveCamera(55, window.innerWidth / window.innerHeight, 0.5, 300);
    camera.position.set(0, 14, 68);
    cameraRef.current = camera;

    // 3. Renderer: 540p internal resolution with nearest-neighbour upscale
    const renderer = new THREE.WebGLRenderer({
      canvas,
      antialias: false,
      powerPreference: 'high-performance',
    });
    renderer.setPixelRatio(1);

    const updateSize = () => {
      const aspect = window.innerWidth / window.innerHeight;
      const height = 540;
      const width = Math.round(height * aspect);
      renderer.setSize(width, height, false);
      camera.aspect = aspect;
      camera.updateProjectionMatrix();
    };
    updateSize();
    window.addEventListener('resize', updateSize);

    // 4. Lighting: Flat-shaded PS2-era directional + ambient
    const ambientLight = new THREE.AmbientLight(0x2a3142, 0.95);
    scene.add(ambientLight);

    const dirLight = new THREE.DirectionalLight(0xf0a500, 1.4);
    dirLight.position.set(-60, 32, 45);
    scene.add(dirLight);

    const hemiLight = new THREE.HemisphereLight(0x3a5a8a, 0x2c1b0e, 0.4);
    scene.add(hemiLight);

    // 5. Attract Mode 45-Second Looping Flyover Path
    const camSpline = new THREE.CatmullRomCurve3([
      new THREE.Vector3(0, 14, 68),     // Above Gate 4 looking across compound
      new THREE.Vector3(-15, 15, 15),   // Drifting past Server Hall toward cooling towers
      new THREE.Vector3(12, 13, -15),   // Near cooling towers looking at steam
      new THREE.Vector3(60, 15, 10),    // Creek and outfall canal view
      new THREE.Vector3(30, 18, 70),    // Colony background view looking back at compound
    ], true);

    const lookSpline = new THREE.CatmullRomCurve3([
      new THREE.Vector3(0, 4, 10),      // Compound center
      new THREE.Vector3(10, 8, -35),    // Cooling towers base
      new THREE.Vector3(14, 11, -35),   // Cooling towers steam
      new THREE.Vector3(80, 0, 0),      // Creek and outfall
      new THREE.Vector3(0, 4, 30),      // Compound entrance
    ], true);

    // Billboard Sprites at Gate 4 during attract mode
    const texLoader = new THREE.TextureLoader();
    const voltTexture = texLoader.load(voltImg);
    const ananyaTexture = texLoader.load(ananyaImg);
    const taraTexture = texLoader.load(taraImg);
    [voltTexture, ananyaTexture, taraTexture].forEach((t) => {
      t.magFilter = THREE.NearestFilter;
      t.minFilter = THREE.NearestFilter;
    });

    const createHeroSprite = (tex: THREE.Texture, x: number) => {
      const sp = new THREE.Sprite(new THREE.SpriteMaterial({ map: tex, transparent: true, depthWrite: false }));
      sp.scale.set(3.2, 4.8, 1);
      sp.position.set(x, 2.4, 48);
      scene.add(sp);
      return sp;
    };

    const voltSprite = createHeroSprite(voltTexture, -3.5);
    const ananyaSprite = createHeroSprite(ananyaTexture, 0);
    const taraSprite = createHeroSprite(taraTexture, 3.5);

    // --- MAIN RENDER & ANIMATION LOOP ---
    let frameId: number;
    const clock = new THREE.Clock();
    const currentCamPos = new THREE.Vector3();
    const currentLookTarget = new THREE.Vector3();

    const animate = () => {
      frameId = requestAnimationFrame(animate);
      const dt = clock.getDelta();
      const elapsed = clock.getElapsedTime();

      // Tick store simulation & timers during active play
      updateTick(dt);

      const currentGameState = useGameStore.getState().gameState;

      if (currentGameState === 'MENU') {
        voltSprite.visible = true;
        ananyaSprite.visible = true;
        taraSprite.visible = true;

        // 45-second normalized loop (0 to 1)
        const t = (elapsed % 45) / 45;
        const splinePos = camSpline.getPointAt(t);
        const splineLook = lookSpline.getPointAt(t);

        // Subtle mouse responsiveness (±5 degrees)
        const mouseOffsetX = mouseRef.current.x * 3.0;
        const mouseOffsetY = -mouseRef.current.y * 2.0;

        currentCamPos.set(splinePos.x + mouseOffsetX, splinePos.y + mouseOffsetY, splinePos.z);
        currentLookTarget.set(splineLook.x + mouseOffsetX * 0.4, splineLook.y + mouseOffsetY * 0.4, splineLook.z);

        camera.position.copy(currentCamPos);
        camera.lookAt(currentLookTarget);

        // Idle sprite sway (0.3px / 2s loop)
        const sway = (elapsed / 2) * Math.PI * 2;
        voltSprite.position.x = -3.5 + Math.sin(sway) * 0.04;
        voltSprite.position.y = 2.4 + Math.cos(sway) * 0.02;

        ananyaSprite.position.x = 0 + Math.sin(sway + 1.2) * 0.04;
        ananyaSprite.position.y = 2.4 + Math.cos(sway + 1.2) * 0.02;

        taraSprite.position.x = 3.5 + Math.sin(sway + 2.4) * 0.04;
        taraSprite.position.y = 2.4 + Math.cos(sway + 2.4) * 0.02;
      } else {
        // In-game: hide attract billboard sprites (player controller renders own sprite)
        voltSprite.visible = false;
        ananyaSprite.visible = false;
        taraSprite.visible = false;
      }

      renderer.render(scene, camera);
    };

    animate();

    return () => {
      cancelAnimationFrame(frameId);
      window.removeEventListener('resize', updateSize);
      renderer.dispose();
    };
  }, [updateTick, hhiTier]);

  return (
    <div className="relative w-screen h-screen overflow-hidden bg-[#18130F] font-mono select-none">
      {/* 540p Internal WebGL Canvas: pixelated nearest-neighbour */}
      <canvas
        ref={canvasRef}
        className="w-full h-full block cursor-crosshair"
        style={{ imageRendering: 'pixelated' }}
        onClick={() => {
          if (settings.muted) toggleMute();
        }}
      />

      {/* Retro CRT Scanlines & Film Grain Overlay */}
      <div className="scanlines absolute inset-0 pointer-events-none opacity-25" />
      <div className="film-grain" />

      {/* Dark Warm Vignette */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background: 'radial-gradient(circle at center, transparent 35%, rgba(18, 12, 6, 0.55) 100%)',
        }}
      />

      {/* 3D World Geometry Blockout */}
      {sceneRef.current && (
        <WorldScene
          scene={sceneRef.current}
          qToolActive={qToolActive}
          specialistId={specialist}
        />
      )}

      {/* In-Game Player Controller & Levels */}
      {gameState === 'PLAYING' && sceneRef.current && cameraRef.current && canvasRef.current && (
        <>
          <PlayerController
            scene={sceneRef.current}
            camera={cameraRef.current}
            domElement={canvasRef.current}
            onInteract={() => {}}
            onNearInteractable={(prompt: string | null) => setInteractPrompt(prompt)}
            onPlayerPosUpdate={(pos: THREE.Vector3) => setPlayerPos(pos.clone())}
          />
          <LevelController playerPos={playerPos} />
          <GameHUD playerPos={playerPos} />
        </>
      )}

      {/* --- ATTRACT MODE TITLE SCREEN OVERLAY (WHEN IN MENU) --- */}
      {gameState === 'MENU' && activeOverlay === 'NONE' && (
        <div className="absolute top-10 sm:top-14 left-1/2 -translate-x-1/2 flex flex-col items-center z-30 select-none pointer-events-auto">
          {/* Top Center: Game Title with flicker */}
          <h1
            className="font-heading text-4xl sm:text-6xl md:text-7xl text-[#F0A500] tracking-wider text-center drop-shadow-[0_4px_14px_rgba(0,0,0,0.95)] animate-title-flicker"
            style={{ letterSpacing: '0.08em' }}
          >
            APAS <span className="text-[#E8E0D0]">:</span> BREACH
          </h1>

          {/* Below title: Four menu items stacked vertically in Space Mono */}
          <div className="mt-8 sm:mt-10 flex flex-col items-center space-y-4 sm:space-y-5">
            <button
              type="button"
              onMouseEnter={() => audioEngine.playHover()}
              onClick={() => {
                audioEngine.playDecisionCardOpen();
                setActiveOverlay('DISPATCH');
              }}
              className="font-mono text-xl sm:text-2xl text-[#E8E0D0] hover:text-[#F0A500] hover:drop-shadow-[0_0_12px_rgba(240,165,0,0.9)] cursor-crosshair transition-all duration-150 tracking-wider flex items-center gap-2 group"
            >
              <span className="text-[#F0A500] group-hover:translate-x-1 transition-transform">&gt;</span>
              <span>NEW GAME</span>
            </button>

            <button
              type="button"
              onMouseEnter={() => audioEngine.playHover()}
              onClick={() => {
                audioEngine.playDecisionCardOpen();
                setActiveOverlay('SPECIALISTS');
              }}
              className="font-mono text-xl sm:text-2xl text-[#E8E0D0] hover:text-[#F0A500] hover:drop-shadow-[0_0_12px_rgba(240,165,0,0.9)] cursor-crosshair transition-all duration-150 tracking-wider flex items-center gap-2 group"
            >
              <span className="text-[#F0A500] group-hover:translate-x-1 transition-transform">&gt;</span>
              <span>SPECIALISTS</span>
            </button>

            <button
              type="button"
              onMouseEnter={() => audioEngine.playHover()}
              onClick={() => {
                audioEngine.playDecisionCardOpen();
                setActiveOverlay('FIELD_NOTES');
              }}
              className="font-mono text-xl sm:text-2xl text-[#E8E0D0] hover:text-[#F0A500] hover:drop-shadow-[0_0_12px_rgba(240,165,0,0.9)] cursor-crosshair transition-all duration-150 tracking-wider flex items-center gap-2 group"
            >
              <span className="text-[#F0A500] group-hover:translate-x-1 transition-transform">&gt;</span>
              <span>FIELD NOTES</span>
            </button>

            <button
              type="button"
              onMouseEnter={() => audioEngine.playHover()}
              onClick={() => {
                audioEngine.playDecisionCardOpen();
                setActiveOverlay('CREDITS');
              }}
              className="font-mono text-xl sm:text-2xl text-[#E8E0D0] hover:text-[#F0A500] hover:drop-shadow-[0_0_12px_rgba(240,165,0,0.9)] cursor-crosshair transition-all duration-150 tracking-wider flex items-center gap-2 group"
            >
              <span className="text-[#F0A500] group-hover:translate-x-1 transition-transform">&gt;</span>
              <span>CREDITS</span>
            </button>
          </div>
        </div>
      )}

      {/* Bottom Left: Live ticking HHI readout in Space Mono 11px #F0A500 */}
      <div className="absolute bottom-6 left-6 sm:left-10 z-30 font-mono text-[11px] text-[#F0A500] tracking-wider select-none flex items-center gap-2 bg-[#1C1713]/90 border border-[#4D3A28] px-3.5 py-1.5 shadow-[3px_3px_0px_#0A0806]">
        <span className="inline-block w-2 h-2 rounded-full bg-[#CC2200] animate-pulse" />
        <span>HHI: {hhi.toFixed(1)} &mdash; {hhiTier.name}</span>
      </div>

      {/* Bottom Right: Audio Unmute Toggle */}
      <div className="absolute bottom-6 right-6 sm:right-10 z-30 select-none">
        <button
          type="button"
          onMouseEnter={() => audioEngine.playHover()}
          onClick={toggleMute}
          className="font-mono text-[11px] text-[#E8E0D0] hover:text-[#F0A500] cursor-crosshair flex items-center gap-2 tracking-wider transition-colors bg-[#1C1713]/90 border border-[#4D3A28] hover:border-[#F0A500] px-3.5 py-1.5 shadow-[3px_3px_0px_#0A0806] focus:outline-none"
        >
          {settings.muted ? (
            <span className="text-[#F0A500] animate-pulse flex items-center gap-1.5">
              <span>&bull;</span> CLICK TO UNMUTE
            </span>
          ) : (
            <span className="flex items-center gap-2 text-[#F0A500] hover:text-[#FFD166]">
              <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24">
                <path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z" />
              </svg>
              <span className="text-[10px] text-[#A89880]">AUDIO ACTIVE</span>
            </span>
          )}
        </button>
      </div>

      {/* --- DISPATCH SCREEN (CHOOSE YOUR SPECIALIST) --- */}
      {activeOverlay === 'DISPATCH' && (
        <div className="absolute inset-0 z-40 bg-[#120F0C]/90 backdrop-blur-md flex flex-col items-center justify-center p-4 sm:p-6">
          <div className="relative w-full max-w-5xl bg-[#1C1713] border-2 border-[#F0A500] shadow-[12px_12px_0px_#0A0806] tactical-corners animate-game-panel overflow-hidden flex flex-col max-h-[92vh]">
            <div className="crt-beam" />
            <div className="hazard-stripe h-2.5 w-full" />

            <div className="p-4 sm:p-6 border-b border-[#4D3A28] bg-[#16120E] text-center">
              <span className="font-mono text-xs text-[#F0A500] font-bold tracking-[0.25em] uppercase block mb-1">
                DISPATCH // SELECT OPERATIONAL SPECIALIST
              </span>
              <h2 className="font-heading text-2xl sm:text-4xl text-[#E8E0D0] tracking-wide mb-1">
                CHOOSE YOUR SPECIALIST
              </h2>
              <p className="font-mono text-xs text-[#A89880] tracking-widest uppercase">
                TARGET: GATE 4 STAGING AREA &middot; SHIFT 16:30 &rarr; SUNRISE
              </p>
            </div>

            <div className="p-4 sm:p-6 overflow-y-auto game-scrollbar grid grid-cols-1 md:grid-cols-3 gap-6">
              {/* Kabir Volt Rao */}
              <div
                onMouseEnter={() => audioEngine.playHover()}
                className="bg-[#241E18] border-2 border-[#4D3A28] hover:border-[#F0A500] p-5 shadow-[6px_6px_0px_#0A0806] flex flex-col justify-between group hover:scale-[1.015] transition-all"
              >
                <div>
                  <div className="w-full h-44 bg-[#18130F] mb-3 border border-[#4D3A28] flex items-center justify-center overflow-hidden relative">
                    <img src={voltImg} alt="Volt" className="h-full object-contain pointer-events-none group-hover:scale-105 transition-transform" />
                  </div>
                  <h4 className="font-heading text-xl text-[#F0A500] mb-1">KABIR "VOLT" RAO</h4>
                  <p className="font-mono text-[10px] text-[#A89880] uppercase tracking-wider mb-2">Senior Power Systems Engineer</p>
                  <p className="font-mono text-xs text-[#E8E0D0] leading-relaxed mb-3">
                    <strong>Tool (Q):</strong> Thermal view highlights hot pipes & failing pumps.
                  </p>
                  <p className="font-mono text-xs text-[#E8E0D0] leading-relaxed mb-4">
                    <strong>Perk:</strong> Heat clock runs 20% slower in Level 2.
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => {
                    audioEngine.playSelect();
                    setActiveOverlay('NONE');
                    startNewGame('VOLT');
                  }}
                  className="w-full font-mono text-xs font-bold py-2.5 px-4 text-[#1C1713] bg-[#F0A500] hover:bg-[#FFD166] active:translate-x-0.5 active:translate-y-0.5 transition-all shadow-[2px_2px_0px_#0A0806] cursor-crosshair flex items-center justify-center gap-2"
                >
                  <span>DEPLOY VOLT</span>
                  <span>&rarr;</span>
                </button>
              </div>

              {/* Dr. Ananya Sen */}
              <div
                onMouseEnter={() => audioEngine.playHover()}
                className="bg-[#241E18] border-2 border-[#4D3A28] hover:border-[#4A6B7A] p-5 shadow-[6px_6px_0px_#0A0806] flex flex-col justify-between group hover:scale-[1.015] transition-all"
              >
                <div>
                  <div className="w-full h-44 bg-[#18130F] mb-3 border border-[#4D3A28] flex items-center justify-center overflow-hidden relative">
                    <img src={ananyaImg} alt="Ananya" className="h-full object-contain pointer-events-none group-hover:scale-105 transition-transform" />
                  </div>
                  <h4 className="font-heading text-xl text-[#4A6B7A] mb-1">DR. ANANYA SEN</h4>
                  <p className="font-mono text-[10px] text-[#A89880] uppercase tracking-wider mb-2">Environmental Compliance Officer</p>
                  <p className="font-mono text-xs text-[#E8E0D0] leading-relaxed mb-3">
                    <strong>Tool (Q):</strong> Sample kit reads TDS, temp, and DO of water & pipes.
                  </p>
                  <p className="font-mono text-xs text-[#A89880] leading-relaxed mb-4">
                    <strong>Weakness:</strong> Sprint speed is 10% slower.
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => {
                    audioEngine.playSelect();
                    setActiveOverlay('NONE');
                    startNewGame('ANANYA');
                  }}
                  className="w-full font-mono text-xs font-bold py-2.5 px-4 text-[#1C1713] bg-[#4A6B7A] hover:bg-[#608B9E] text-white active:translate-x-0.5 active:translate-y-0.5 transition-all shadow-[2px_2px_0px_#0A0806] cursor-crosshair flex items-center justify-center gap-2"
                >
                  <span>DEPLOY DR. SEN</span>
                  <span>&rarr;</span>
                </button>
              </div>

              {/* Tara "Zero" D'Souza */}
              <div
                onMouseEnter={() => audioEngine.playHover()}
                className="bg-[#241E18] border-2 border-[#4D3A28] hover:border-[#4A7C59] p-5 shadow-[6px_6px_0px_#0A0806] flex flex-col justify-between group hover:scale-[1.015] transition-all"
              >
                <div>
                  <div className="w-full h-44 bg-[#18130F] mb-3 border border-[#4D3A28] flex items-center justify-center overflow-hidden relative">
                    <img src={taraImg} alt="Tara" className="h-full object-contain pointer-events-none group-hover:scale-105 transition-transform" />
                  </div>
                  <h4 className="font-heading text-xl text-[#4A7C59] mb-1">TARA "ZERO" D'SOUZA</h4>
                  <p className="font-mono text-[10px] text-[#A89880] uppercase tracking-wider mb-2">SCADA Specialist</p>
                  <p className="font-mono text-xs text-[#E8E0D0] leading-relaxed mb-3">
                    <strong>Tool (Q):</strong> Hack consoles remotely from up to 15m.
                  </p>
                  <p className="font-mono text-xs text-[#A89880] leading-relaxed mb-4">
                    <strong>Cost:</strong> Each remote hack adds Audit Pressure.
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => {
                    audioEngine.playSelect();
                    setActiveOverlay('NONE');
                    startNewGame('TARA');
                  }}
                  className="w-full font-mono text-xs font-bold py-2.5 px-4 text-white bg-[#4A7C59] hover:bg-[#5C9B6E] active:translate-x-0.5 active:translate-y-0.5 transition-all shadow-[2px_2px_0px_#0A0806] cursor-crosshair flex items-center justify-center gap-2"
                >
                  <span>DEPLOY TARA</span>
                  <span>&rarr;</span>
                </button>
              </div>
            </div>

            <div className="p-4 bg-[#16120E] border-t border-[#4D3A28] flex justify-center">
              <button
                type="button"
                onMouseEnter={() => audioEngine.playHover()}
                onClick={() => {
                  audioEngine.playSelect();
                  setActiveOverlay('NONE');
                }}
                className="font-mono text-xs text-[#A89880] hover:text-[#E8E0D0] border border-[#4D3A28] px-6 py-2 bg-[#201A14] cursor-crosshair shadow-[2px_2px_0px_#0A0806]"
              >
                &larr; BACK TO TITLE SCREEN
              </button>
            </div>
          </div>
        </div>
      )}

      {/* --- SPECIALISTS OVERLAY --- */}
      {activeOverlay === 'SPECIALISTS' && (
        <div className="absolute inset-0 z-40 bg-[#120F0C]/85 backdrop-blur-md flex flex-col items-center justify-center p-3 sm:p-6">
          <div className="relative w-full max-w-6xl bg-[#1C1713] border-2 border-[#54402C] shadow-[10px_10px_0px_#0A0806] tactical-corners animate-game-panel overflow-hidden flex flex-col max-h-[92vh]">
            <div className="crt-beam" />
            <div className="hazard-stripe h-2 w-full" />

            <div className="p-4 sm:p-6 border-b border-[#4D3A28] bg-[#16120E] flex justify-between items-center">
              <div>
                <span className="text-[10px] text-[#F0A500] uppercase font-bold tracking-[0.25em] block mb-1">
                  OPERATOR DOSSIERS // LEVEL 1 RECON
                </span>
                <h2 className="font-heading text-xl sm:text-3xl text-[#E8E0D0]">FACILITY SPECIALISTS</h2>
              </div>
              <button
                type="button"
                onMouseEnter={() => audioEngine.playHover()}
                onClick={() => {
                  audioEngine.playSelect();
                  setActiveOverlay('NONE');
                }}
                className="font-mono text-xs font-bold text-[#F0A500] hover:text-[#1C1713] hover:bg-[#F0A500] border border-[#F0A500] px-4 py-2 bg-[#241E18] cursor-crosshair transition-all"
              >
                [X] CLOSE
              </button>
            </div>

            <div className="p-4 sm:p-6 overflow-y-auto game-scrollbar grid grid-cols-1 md:grid-cols-3 gap-6">
              {/* Volt */}
              <div className="bg-[#241E18] border-2 border-[#4D3A28] p-5 shadow-[4px_4px_0px_#0A0806]">
                <div className="h-44 bg-[#18130F] mb-3 border border-[#4D3A28] flex items-center justify-center overflow-hidden">
                  <img src={voltImg} alt="Volt" className="h-full object-contain" />
                </div>
                <h4 className="font-heading text-lg text-[#F0A500] mb-1">KABIR "VOLT" RAO</h4>
                <p className="text-[10px] text-[#A89880] uppercase mb-2">Senior Power Systems Engineer</p>
                <p className="text-xs text-[#E8E0D0] mb-3">Power: 80 &middot; Water: 30 &middot; Compliance: 50 &middot; Crisis: 70</p>
                <p className="text-xs text-[#A89880]">Tool (Q): Thermal view reveals hot pipes.</p>
              </div>

              {/* Ananya */}
              <div className="bg-[#241E18] border-2 border-[#4D3A28] p-5 shadow-[4px_4px_0px_#0A0806]">
                <div className="h-44 bg-[#18130F] mb-3 border border-[#4D3A28] flex items-center justify-center overflow-hidden">
                  <img src={ananyaImg} alt="Ananya" className="h-full object-contain" />
                </div>
                <h4 className="font-heading text-lg text-[#4A6B7A] mb-1">DR. ANANYA SEN</h4>
                <p className="text-[10px] text-[#A89880] uppercase mb-2">Environmental Compliance Officer</p>
                <p className="text-xs text-[#E8E0D0] mb-3">Power: 20 &middot; Water: 90 &middot; Compliance: 80 &middot; Crisis: 50</p>
                <p className="text-xs text-[#A89880]">Tool (Q): Sample kit reads TDS, temp, and DO.</p>
              </div>

              {/* Tara */}
              <div className="bg-[#241E18] border-2 border-[#4D3A28] p-5 shadow-[4px_4px_0px_#0A0806]">
                <div className="h-44 bg-[#18130F] mb-3 border border-[#4D3A28] flex items-center justify-center overflow-hidden">
                  <img src={taraImg} alt="Tara" className="h-full object-contain" />
                </div>
                <h4 className="font-heading text-lg text-[#4A7C59] mb-1">TARA "ZERO" D'SOUZA</h4>
                <p className="text-[10px] text-[#A89880] uppercase mb-2">SCADA Specialist</p>
                <p className="text-xs text-[#E8E0D0] mb-3">Power: 40 &middot; Water: 80 &middot; Compliance: 60 &middot; Crisis: 40</p>
                <p className="text-xs text-[#A89880]">Tool (Q): Remote console hack up to 15m.</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* --- FIELD NOTES OVERLAY (ALL 15 ENTRIES) --- */}
      {activeOverlay === 'FIELD_NOTES' && (
        <div className="absolute inset-0 z-40 bg-[#120F0C]/85 backdrop-blur-md flex flex-col items-center justify-center p-3 sm:p-6">
          <div className="relative w-full max-w-4xl bg-[#1C1713] border-2 border-[#54402C] shadow-[10px_10px_0px_#0A0806] tactical-corners animate-game-panel overflow-hidden flex flex-col max-h-[92vh]">
            <div className="crt-beam" />
            <div className="hazard-stripe h-2 w-full" />

            <div className="p-4 sm:p-6 border-b border-[#4D3A28] bg-[#16120E] flex justify-between items-center">
              <div>
                <span className="text-[10px] text-[#F0A500] uppercase font-bold tracking-[0.25em] block mb-1">
                  FIELD NOTES CODEX // 15 VERIFIED ENTRIES
                </span>
                <h2 className="font-heading text-xl sm:text-3xl text-[#E8E0D0]">FIELD NOTES &middot; REAL DATA</h2>
              </div>
              <button
                type="button"
                onMouseEnter={() => audioEngine.playHover()}
                onClick={() => {
                  audioEngine.playSelect();
                  setActiveOverlay('NONE');
                }}
                className="font-mono text-xs font-bold text-[#F0A500] hover:text-[#1C1713] hover:bg-[#F0A500] border border-[#F0A500] px-4 py-2 bg-[#241E18] cursor-crosshair transition-all"
              >
                [X] CLOSE
              </button>
            </div>

            <div className="p-4 sm:p-6 space-y-4 overflow-y-auto game-scrollbar">
              {FIELD_NOTES.map((note) => (
                <div
                  key={note.id}
                  className="bg-[#241E18] border-l-4 border-l-[#F0A500] border-y border-r border-[#4D3A28] p-4 shadow-[3px_3px_0px_#0A0806]"
                >
                  <div className="flex justify-between items-center mb-1">
                    <span className="text-[10px] text-[#F0A500] font-bold tracking-wider">{note.tag}</span>
                    <span className="text-[9px] text-[#A89880]">{note.id}</span>
                  </div>
                  <h4 className="font-heading text-sm text-[#E8E0D0] mb-2">{note.title}</h4>
                  <p className="text-xs text-[#E8E0D0] leading-relaxed mb-2">{note.body}</p>
                  <p className="text-[10px] text-[#A89880] border-t border-[#3A2E20] pt-1">{note.source}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* --- CREDITS OVERLAY --- */}
      {activeOverlay === 'CREDITS' && (
        <div className="absolute inset-0 z-40 bg-[#120F0C]/85 backdrop-blur-md flex flex-col items-center justify-center p-3 sm:p-6">
          <div className="relative w-full max-w-3xl bg-[#1C1713] border-2 border-[#54402C] shadow-[10px_10px_0px_#0A0806] tactical-corners animate-game-panel overflow-hidden flex flex-col max-h-[92vh]">
            <div className="crt-beam" />
            <div className="hazard-stripe h-2 w-full" />

            <div className="p-4 sm:p-6 border-b border-[#4D3A28] bg-[#16120E] flex justify-between items-center">
              <div>
                <span className="text-[10px] text-[#F0A500] uppercase font-bold tracking-[0.25em] block mb-1">
                  SYSTEM ARCHITECTURE // APAS : BREACH
                </span>
                <h2 className="font-heading text-xl sm:text-3xl text-[#E8E0D0]">CREDITS &amp; LICENCES</h2>
              </div>
              <button
                type="button"
                onMouseEnter={() => audioEngine.playHover()}
                onClick={() => {
                  audioEngine.playSelect();
                  setActiveOverlay('NONE');
                }}
                className="font-mono text-xs font-bold text-[#F0A500] hover:text-[#1C1713] hover:bg-[#F0A500] border border-[#F0A500] px-4 py-2 bg-[#241E18] cursor-crosshair transition-all"
              >
                [X] CLOSE
              </button>
            </div>

            <div className="p-4 sm:p-6 space-y-4 overflow-y-auto game-scrollbar text-xs text-[#A89880] leading-relaxed">
              <div className="bg-[#241E18] p-4 border border-[#4D3A28]">
                <strong className="text-[#F0A500] block mb-1 uppercase tracking-wider">ENGINE &amp; SIMULATION</strong>
                React &middot; TypeScript &middot; Vite &middot; Three.js &middot; React Three Fiber &middot; Rapier &middot; Zustand &middot; Web Audio API
              </div>
              <div className="bg-[#241E18] p-4 border border-[#4D3A28]">
                <strong className="text-[#F0A500] block mb-1 uppercase tracking-wider">FONTS</strong>
                Rubik Mono One (SIL Open Font Licence) &middot; Space Mono (SIL Open Font Licence)
              </div>
              <div className="bg-[#241E18] p-4 border border-[#4D3A28]">
                <strong className="text-[#F0A500] block mb-1 uppercase tracking-wider">AUDIO</strong>
                100% synthesized in-browser with Web Audio API. Zero external audio files or samples.
              </div>
              <div className="bg-[#241E18] p-4 border border-[#4D3A28]">
                <strong className="text-[#F0A500] block mb-1 uppercase tracking-wider">CHARACTER ART</strong>
                Original hand-drawn comic character art by author. Zero copyrighted third-party assets.
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AttractMode;
