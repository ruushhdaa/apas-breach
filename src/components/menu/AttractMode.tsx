import React, { useEffect, useRef, useState } from 'react';
import * as THREE from 'three';
import { audioManager } from '../../game/audio/audioManager';
import voltImg from '../../assets/characters/volt.png';
import ananyaImg from '../../assets/characters/ananya.png';
import taraImg from '../../assets/characters/tara.png';

type ActiveOverlay = 'NONE' | 'DISPATCH' | 'SPECIALISTS' | 'FIELD_NOTES' | 'CREDITS';

interface SpecialistInfo {
  id: string;
  name: string;
  role: string;
  accent: string;
  image: string;
  xPos: number;
  tool: string;
  weakness: string;
  stats: { label: string; value: number }[];
  backdrop: React.ReactNode;
}

const specialistsData: SpecialistInfo[] = [
  {
    id: 'volt',
    name: 'KABIR "VOLT" RAO',
    role: 'Senior Power Systems Engineer',
    accent: '#F0A500',
    image: voltImg,
    xPos: -3.5,
    tool: 'Volt catches energy spikes before they cascade. He keeps the servers cool when the grid begins to buckle.',
    weakness: 'Water is not his problem until it is. He treats cooling as a power issue.',
    stats: [
      { label: 'Power Analysis', value: 90 },
      { label: 'Water Systems', value: 30 },
      { label: 'Compliance', value: 40 },
      { label: 'Crisis Response', value: 85 },
    ],
    backdrop: (
      <svg className="absolute inset-0 w-full h-full pointer-events-none opacity-30" viewBox="0 0 280 260" fill="none">
        <rect x="20" y="20" width="70" height="220" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />
        <line x1="20" y1="55" x2="90" y2="55" stroke="#3A4156" strokeWidth="1" />
        <line x1="20" y1="90" x2="90" y2="90" stroke="#3A4156" strokeWidth="1" />
        <line x1="20" y1="125" x2="90" y2="125" stroke="#3A4156" strokeWidth="1" />
        <line x1="20" y1="160" x2="90" y2="160" stroke="#3A4156" strokeWidth="1" />
        <line x1="20" y1="195" x2="90" y2="195" stroke="#3A4156" strokeWidth="1" />
        <rect x="105" y="10" width="75" height="230" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />
        <line x1="105" y1="45" x2="180" y2="45" stroke="#3A4156" strokeWidth="1" />
        <line x1="105" y1="80" x2="180" y2="80" stroke="#3A4156" strokeWidth="1" />
        <line x1="105" y1="115" x2="180" y2="115" stroke="#3A4156" strokeWidth="1" />
        <line x1="105" y1="150" x2="180" y2="150" stroke="#3A4156" strokeWidth="1" />
        <line x1="105" y1="185" x2="180" y2="185" stroke="#3A4156" strokeWidth="1" />
        <line x1="105" y1="220" x2="180" y2="220" stroke="#3A4156" strokeWidth="1" />
        <rect x="195" y="20" width="65" height="220" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />
        <line x1="195" y1="55" x2="260" y2="55" stroke="#3A4156" strokeWidth="1" />
        <line x1="195" y1="90" x2="260" y2="90" stroke="#3A4156" strokeWidth="1" />
        <line x1="195" y1="125" x2="260" y2="125" stroke="#3A4156" strokeWidth="1" />
        <line x1="195" y1="160" x2="260" y2="160" stroke="#3A4156" strokeWidth="1" />
        <line x1="195" y1="195" x2="260" y2="195" stroke="#3A4156" strokeWidth="1" />
      </svg>
    ),
  },
  {
    id: 'ananya',
    name: 'DR. ANANYA SEN',
    role: 'Environmental Compliance Officer',
    accent: '#4A6B7A',
    image: ananyaImg,
    xPos: 0,
    tool: 'Ananya has access to the creek monitoring network. She can see what the facility is doing to the water before the regulator does.',
    weakness: 'She has no authority over operations. She can only advise. You decide.',
    stats: [
      { label: 'Power Analysis', value: 20 },
      { label: 'Water Systems', value: 90 },
      { label: 'Compliance', value: 80 },
      { label: 'Crisis Response', value: 50 },
    ],
    backdrop: (
      <svg className="absolute inset-0 w-full h-full pointer-events-none opacity-30" viewBox="0 0 280 260" fill="none">
        <rect x="0" y="45" width="280" height="26" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />
        <circle cx="70" cy="58" r="16" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />
        <circle cx="70" cy="58" r="7" fill="#1A1F2E" stroke="#3A4156" strokeWidth="1" />
        <rect x="0" y="115" width="280" height="34" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />
        <circle cx="210" cy="132" r="20" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />
        <circle cx="210" cy="132" r="8" fill="#1A1F2E" stroke="#3A4156" strokeWidth="1" />
        <rect x="0" y="185" width="280" height="22" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />
        <circle cx="130" cy="196" r="14" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />
      </svg>
    ),
  },
  {
    id: 'tara',
    name: "TARA \"ZERO\" D'SOUZA",
    role: 'Water Use Efficiency Lead',
    accent: '#4A7C59',
    image: taraImg,
    xPos: 3.5,
    tool: 'Tara controls the recirculation ratios. She can stretch the water budget further than anyone else — but not forever.',
    weakness: 'Her optimisations take time to kick in. In a fast crisis, she is always one step behind.',
    stats: [
      { label: 'Power Analysis', value: 40 },
      { label: 'Water Systems', value: 80 },
      { label: 'Compliance', value: 60 },
      { label: 'Crisis Response', value: 40 },
    ],
    backdrop: (
      <svg className="absolute inset-0 w-full h-full pointer-events-none opacity-30" viewBox="0 0 280 260" fill="none">
        <rect x="15" y="25" width="250" height="210" fill="#252B3B" stroke="#3A4156" strokeWidth="1" />
        <line x1="15" y1="65" x2="265" y2="65" stroke="#3A4156" strokeWidth="1" />
        <line x1="15" y1="105" x2="265" y2="105" stroke="#3A4156" strokeWidth="1" />
        <line x1="15" y1="145" x2="265" y2="145" stroke="#3A4156" strokeWidth="1" />
        <line x1="15" y1="185" x2="265" y2="185" stroke="#3A4156" strokeWidth="1" />
        <line x1="65" y1="25" x2="65" y2="235" stroke="#3A4156" strokeWidth="1" />
        <line x1="115" y1="25" x2="115" y2="235" stroke="#3A4156" strokeWidth="1" />
        <line x1="165" y1="25" x2="165" y2="235" stroke="#3A4156" strokeWidth="1" />
        <line x1="215" y1="25" x2="215" y2="235" stroke="#3A4156" strokeWidth="1" />
      </svg>
    ),
  },
];

const fieldNotesCards = [
  {
    label: 'WATER USE',
    fact: 'A hyperscale data centre can consume between 1 and 5 litres of water per kilowatt-hour of compute, depending on cooling method and climate.',
    source: 'SOURCE — [TODO_VERIFY]',
  },
  {
    label: 'COOLING SYSTEMS',
    fact: 'Evaporative cooling towers are significantly more water-intensive than air-cooled systems, but they consume far less electricity to achieve the same heat rejection.',
    source: 'SOURCE — [TODO_VERIFY]',
  },
  {
    label: 'THERMAL DISCHARGE',
    fact: 'Warm water discharged into natural waterways raises ambient temperature, reduces dissolved oxygen, and disrupts aquatic ecosystems — a process called thermal pollution.',
    source: 'SOURCE — [TODO_VERIFY]',
  },
];

export const AttractMode: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [activeOverlay, setActiveOverlay] = useState<ActiveOverlay>('NONE');
  const [isMuted, setIsMuted] = useState<boolean>(true);
  const [hhiValue, setHhiValue] = useState<number>(38);
  const [audioStarted, setAudioStarted] = useState<boolean>(false);
  const [selectedSpecialist, setSelectedSpecialist] = useState<string | null>(null);

  const mouseRef = useRef<{ x: number; y: number }>({ x: 0, y: 0 });
  const gameModeRef = useRef<boolean>(false);
  const targetCamPosRef = useRef<THREE.Vector3 | null>(null);
  const targetLookAtRef = useRef<THREE.Vector3 | null>(null);

  // Subscribe to audio state
  useEffect(() => {
    return audioManager.subscribe((muted) => {
      setIsMuted(muted);
      if (!muted) setAudioStarted(true);
    });
  }, []);

  const handleAudioToggle = () => {
    const newMuted = audioManager.toggleMute();
    setIsMuted(newMuted);
    setAudioStarted(true);
  };

  // Slowly ticking HHI readout: baseline 38
  useEffect(() => {
    const values = [38, 38, 37.9, 38.1, 38, 38.2, 38];
    let idx = 0;
    const interval = setInterval(() => {
      idx = (idx + 1) % values.length;
      setHhiValue(values[idx]);
    }, 2800);
    return () => clearInterval(interval);
  }, []);

  // Mouse tracking for subtle camera tilt (±5 degrees)
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

  // Specialist selection handler (NEW GAME flow)
  const handleSelectSpecialist = (spec: SpecialistInfo) => {
    setSelectedSpecialist(spec.name);
    gameModeRef.current = true;
    setActiveOverlay('NONE');
    // Snap camera smoothly towards player position at Gate 4
    targetCamPosRef.current = new THREE.Vector3(spec.xPos, 2.8, 54);
    targetLookAtRef.current = new THREE.Vector3(spec.xPos * 0.4, 3.2, 10);
  };

  // Return to attract mode from game mode
  const handleReturnToAttract = () => {
    setSelectedSpecialist(null);
    gameModeRef.current = false;
    targetCamPosRef.current = null;
    targetLookAtRef.current = null;
  };

  // --- THREE.JS FULLSCREEN SCENE SETUP ---
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    // 1. Scene & Exponential Fog (Dusk smog at HHI 38 baseline)
    const scene = new THREE.Scene();
    const fogColor = new THREE.Color(0x2c1b0e); // Orange-brown dusk sky
    scene.background = fogColor;
    scene.fog = new THREE.FogExp2(fogColor.getHex(), 0.022);

    // 2. Camera (FOV 55 matching gameplay camera)
    const camera = new THREE.PerspectiveCamera(55, window.innerWidth / window.innerHeight, 0.5, 300);
    camera.position.set(0, 14, 68);

    // 3. Renderer (540p internal resolution with nearest-neighbour upscale)
    const renderer = new THREE.WebGLRenderer({ canvas, antialias: false, powerPreference: 'high-performance' });
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

    // 4. Lighting: Flat-shaded retro GTA III dusk lighting
    const ambientLight = new THREE.AmbientLight(0x2a3142, 0.9);
    scene.add(ambientLight);

    const dirLight = new THREE.DirectionalLight(0xf0a500, 1.4); // Warm amber horizon sun
    dirLight.position.set(-60, 32, 45);
    scene.add(dirLight);

    const hemiLight = new THREE.HemisphereLight(0x3a5a8a, 0x2c1b0e, 0.4);
    scene.add(hemiLight);

    // 5. Materials (Flat shaded, no PBR, retro 2001 style)
    const matAsphalt = new THREE.MeshLambertMaterial({ color: 0x1b202c });
    const matRoad = new THREE.MeshLambertMaterial({ color: 0x221a15 });
    const matConcrete = new THREE.MeshLambertMaterial({ color: 0x2a3142 });
    const matWall = new THREE.MeshLambertMaterial({ color: 0x252b3b });
    const matTower = new THREE.MeshLambertMaterial({ color: 0x2a3142 });
    const matTowerRim = new THREE.MeshLambertMaterial({ color: 0x1a1f2e });
    const matCreek = new THREE.MeshLambertMaterial({ color: 0x3d2b1f }); // Murky creek at HHI 38
    const matColony = new THREE.MeshLambertMaterial({ color: 0x342921 });
    const matAmberLight = new THREE.MeshBasicMaterial({ color: 0xf0a500 });
    const matSteam = new THREE.MeshBasicMaterial({ color: 0xf2ece4, transparent: true, opacity: 0.35 });

    // --- GEOMETRY: FACILITY COMPOUND BLOCKOUT (SPEC.md Section 5) ---
    // Ground inside compound (x -50..50, z -50..50)
    const compoundGround = new THREE.Mesh(new THREE.PlaneGeometry(100, 100), matAsphalt);
    compoundGround.rotation.x = -Math.PI / 2;
    compoundGround.position.set(0, 0, 0);
    scene.add(compoundGround);

    // Road outside (z 50..70)
    const roadOutside = new THREE.Mesh(new THREE.PlaneGeometry(140, 25), matRoad);
    roadOutside.rotation.x = -Math.PI / 2;
    roadOutside.position.set(0, 0.02, 62.5);
    scene.add(roadOutside);

    // Colony ground (z 70..130)
    const colonyGround = new THREE.Mesh(new THREE.PlaneGeometry(160, 60), matColony);
    colonyGround.rotation.x = -Math.PI / 2;
    colonyGround.position.set(0, -0.05, 100);
    scene.add(colonyGround);

    // Creek plane (x 60..110, z -50..50)
    const creek = new THREE.Mesh(new THREE.PlaneGeometry(50, 100), matCreek);
    creek.rotation.x = -Math.PI / 2;
    creek.position.set(85, -0.2, 0);
    scene.add(creek);

    // Outfall canal (from 50,0,-20 to creek at 60)
    const canal = new THREE.Mesh(new THREE.BoxGeometry(16, 0.4, 4), matCreek);
    canal.position.set(56, -0.15, -20);
    scene.add(canal);

    // Compound walls (x -50..50, z -50..50, y 0..4) with Gate 4 opening at (0,0,50)
    const wallN = new THREE.Mesh(new THREE.BoxGeometry(100, 3.5, 1.2), matWall);
    wallN.position.set(0, 1.75, -50);
    scene.add(wallN);

    const wallW = new THREE.Mesh(new THREE.BoxGeometry(1.2, 3.5, 100), matWall);
    wallW.position.set(-50, 1.75, 0);
    scene.add(wallW);

    const wallE = new THREE.Mesh(new THREE.BoxGeometry(1.2, 3.5, 100), matWall);
    wallE.position.set(50, 1.75, 0);
    scene.add(wallE);

    const wallSL = new THREE.Mesh(new THREE.BoxGeometry(44, 3.5, 1.2), matWall);
    wallSL.position.set(-28, 1.75, 50);
    scene.add(wallSL);

    const wallSR = new THREE.Mesh(new THREE.BoxGeometry(44, 3.5, 1.2), matWall);
    wallSR.position.set(28, 1.75, 50);
    scene.add(wallSR);

    // Gate 4 Posts (amber hazard accents)
    const gatePostL = new THREE.Mesh(new THREE.BoxGeometry(1.4, 4.2, 1.4), matAmberLight);
    gatePostL.position.set(-5.5, 2.1, 50);
    scene.add(gatePostL);
    const gatePostR = new THREE.Mesh(new THREE.BoxGeometry(1.4, 4.2, 1.4), matAmberLight);
    gatePostR.position.set(5.5, 2.1, 50);
    scene.add(gatePostR);

    // Server Hall A (x -45..-15, z -45..-5)
    const serverHall = new THREE.Mesh(new THREE.BoxGeometry(30, 8, 40), matConcrete);
    serverHall.position.set(-30, 4, -25);
    scene.add(serverHall);

    // SCADA Hub (box at 20, 0, 10, 16x10x5)
    const scadaHub = new THREE.Mesh(new THREE.BoxGeometry(16, 5, 10), matWall);
    scadaHub.position.set(20, 2.5, 10);
    scene.add(scadaHub);

    // Substation (box at -28, 0, 44, 8x6x4)
    const substation = new THREE.Mesh(new THREE.BoxGeometry(8, 4, 6), matConcrete);
    substation.position.set(-28, 2, 44);
    scene.add(substation);

    // Audit stage (0, 0, 58)
    const auditStage = new THREE.Mesh(new THREE.BoxGeometry(12, 0.3, 8), matConcrete);
    auditStage.position.set(0, 0.15, 58);
    scene.add(auditStage);

    // MPCB vehicle (box at 8, 0, 62)
    const mpcbVehicle = new THREE.Mesh(new THREE.BoxGeometry(3, 2, 5), matWall);
    mpcbVehicle.position.set(8, 1, 62);
    scene.add(mpcbVehicle);

    // Colony Buildings with glowing amber window dots in background
    const colonyCoords = [
      [-35, 78, 12, 11, 14],
      [-18, 92, 14, 13, 12],
      [5, 82, 10, 15, 16],
      [24, 76, 12, 10, 10],
      [42, 95, 16, 12, 14],
      [-5, 110, 15, 16, 18],
      [20, 112, 12, 13, 12],
    ];
    colonyCoords.forEach(([cx, cz, w, h, d]) => {
      const bldg = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), matColony);
      bldg.position.set(cx, h / 2, cz);
      scene.add(bldg);

      // Glowing amber windows
      const win = new THREE.Mesh(new THREE.BoxGeometry(1.2, 1.4, 0.2), matAmberLight);
      win.position.set(cx, h * 0.65, cz - d / 2 - 0.1);
      scene.add(win);
    });

    // Water Tanker Queue at (-15, 0, 80)
    for (let t = 0; t < 3; t++) {
      const tanker = new THREE.Mesh(new THREE.BoxGeometry(2.8, 2.2, 6), matAmberLight);
      tanker.position.set(-15, 1.1, 74 + t * 7);
      scene.add(tanker);
    }

    // Cooling Towers (4 cylinders at x = -5, 8, 21, 34, z = -35)
    const towersX = [-5, 8, 21, 34];
    const steamPuffsList: THREE.Mesh[] = [];

    towersX.forEach((tx) => {
      const tower = new THREE.Mesh(new THREE.CylinderGeometry(3.2, 4.4, 12, 16), matTower);
      tower.position.set(tx, 6, -35);
      scene.add(tower);

      const rim = new THREE.Mesh(new THREE.TorusGeometry(3.2, 0.4, 8, 16), matTowerRim);
      rim.rotation.x = Math.PI / 2;
      rim.position.set(tx, 12, -35);
      scene.add(rim);

      // Rising steam puffs per cooling tower
      for (let s = 0; s < 5; s++) {
        const puff = new THREE.Mesh(new THREE.SphereGeometry(1.6 + s * 0.4, 7, 6), matSteam);
        puff.position.set(tx + (Math.random() - 0.5) * 1.5, 12.5 + s * 2.2, -35 + (Math.random() - 0.5) * 1.5);
        puff.userData = {
          baseX: tx,
          baseY: 12.5,
          baseZ: -35,
          speed: 0.04 + Math.random() * 0.03,
          offset: Math.random() * 10,
        };
        scene.add(puff);
        steamPuffsList.push(puff);
      }
    });

    // --- BILLBOARD SPRITES FOR THE 3 SPECIALISTS AT GATE 4 ---
    const texLoader = new THREE.TextureLoader();
    const voltTexture = texLoader.load(voltImg);
    const ananyaTexture = texLoader.load(ananyaImg);
    const taraTexture = texLoader.load(taraImg);

    [voltTexture, ananyaTexture, taraTexture].forEach((t) => {
      t.magFilter = THREE.NearestFilter;
      t.minFilter = THREE.NearestFilter;
    });

    const createHeroSprite = (texture: THREE.Texture, x: number) => {
      const spriteMat = new THREE.SpriteMaterial({
        map: texture,
        transparent: true,
        depthWrite: false,
      });
      const sprite = new THREE.Sprite(spriteMat);
      sprite.scale.set(3.2, 4.8, 1);
      sprite.position.set(x, 2.4, 48);
      scene.add(sprite);
      return sprite;
    };

    const voltSprite = createHeroSprite(voltTexture, -3.5);
    const ananyaSprite = createHeroSprite(ananyaTexture, 0);
    const taraSprite = createHeroSprite(taraTexture, 3.5);

    // --- CINEMATIC 45-SECOND CAMERA PATH ---
    // Start above Gate 4 looking at compound, drift toward cooling towers,
    // then arc around to show the creek and colony, loop every 45s.
    const camSpline = new THREE.CatmullRomCurve3([
      new THREE.Vector3(0, 14, 68),     // Above Gate 4 looking across compound
      new THREE.Vector3(-15, 15, 15),   // Drifting past Server Hall toward cooling towers
      new THREE.Vector3(12, 13, -15),   // Near cooling towers looking at steam
      new THREE.Vector3(60, 15, 10),    // Creek and outfall canal view
      new THREE.Vector3(30, 18, 70),    // Colony background view looking back at compound
    ], true); // Closed loop

    const lookSpline = new THREE.CatmullRomCurve3([
      new THREE.Vector3(0, 4, 10),      // Looking into compound past Gate 4
      new THREE.Vector3(10, 8, -35),    // Looking at cooling towers
      new THREE.Vector3(14, 11, -35),   // Cooling towers steam
      new THREE.Vector3(80, 0, 0),      // Murky creek and canal
      new THREE.Vector3(0, 4, 30),      // Looking towards compound
    ], true);

    // --- ANIMATION LOOP ---
    let frameId: number;
    const clock = new THREE.Clock();
    const currentCamPos = new THREE.Vector3();
    const currentLookTarget = new THREE.Vector3();

    const animate = () => {
      frameId = requestAnimationFrame(animate);
      const elapsed = clock.getElapsedTime();

      if (!gameModeRef.current) {
        // 45-second normalized loop (0 to 1)
        const t = (elapsed % 45) / 45;
        const splinePos = camSpline.getPointAt(t);
        const splineLook = lookSpline.getPointAt(t);

        // Mouse offset: subtle responsiveness (±5 degrees)
        const mouseOffsetX = mouseRef.current.x * 3.0;
        const mouseOffsetY = -mouseRef.current.y * 2.0;

        currentCamPos.set(splinePos.x + mouseOffsetX, splinePos.y + mouseOffsetY, splinePos.z);
        currentLookTarget.set(splineLook.x + mouseOffsetX * 0.4, splineLook.y + mouseOffsetY * 0.4, splineLook.z);

        camera.position.copy(currentCamPos);
        camera.lookAt(currentLookTarget);
      } else if (targetCamPosRef.current && targetLookAtRef.current) {
        // Camera smoothly snaps to player position when specialist selected
        camera.position.lerp(targetCamPosRef.current, 0.05);
        currentLookTarget.lerp(targetLookAtRef.current, 0.05);
        camera.lookAt(currentLookTarget);
      }

      // Rising steam puffs animation
      steamPuffsList.forEach((puff) => {
        puff.position.y += puff.userData.speed;
        puff.position.x += Math.sin(elapsed + puff.userData.offset) * 0.02;
        if (puff.position.y > 23) {
          puff.position.y = puff.userData.baseY;
          puff.position.x = puff.userData.baseX + (Math.random() - 0.5) * 1.5;
        }
      });

      // Specialists idle animation: gentle sway (0.3px / 2s loop)
      const swayPeriod = (elapsed / 2) * Math.PI * 2; // 2s loop
      voltSprite.position.x = -3.5 + Math.sin(swayPeriod) * 0.04;
      voltSprite.position.y = 2.4 + Math.cos(swayPeriod) * 0.02;

      ananyaSprite.position.x = 0 + Math.sin(swayPeriod + 1.2) * 0.04;
      ananyaSprite.position.y = 2.4 + Math.cos(swayPeriod + 1.2) * 0.02;

      taraSprite.position.x = 3.5 + Math.sin(swayPeriod + 2.4) * 0.04;
      taraSprite.position.y = 2.4 + Math.cos(swayPeriod + 2.4) * 0.02;

      renderer.render(scene, camera);
    };

    animate();

    return () => {
      cancelAnimationFrame(frameId);
      window.removeEventListener('resize', updateSize);
      renderer.dispose();
    };
  }, []);

  return (
    <div className="relative w-screen h-screen overflow-hidden bg-[#1A1F2E] font-mono select-none">
      {/* 3D WebGL Canvas: 540p scaled pixelated */}
      <canvas
        ref={canvasRef}
        className="w-full h-full block cursor-crosshair"
        style={{ imageRendering: 'pixelated' }}
        onClick={() => {
          if (isMuted) handleAudioToggle();
        }}
      />

      {/* Retro CRT Scanlines & Film Grain Overlay */}
      <div className="scanlines absolute inset-0 pointer-events-none opacity-25" />
      <div className="film-grain" />

      {/* Dark Vignette Overlay: radial gradient */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background: 'radial-gradient(circle at center, transparent 35%, rgba(0, 0, 0, 0.45) 100%)',
        }}
      />

      {/* --- FLOATING MENU OVERLAY (GTA III ATTRACT MODE TITLE SCREEN) --- */}
      {activeOverlay === 'NONE' && !selectedSpecialist && (
        <div className="absolute top-10 sm:top-14 left-1/2 -translate-x-1/2 flex flex-col items-center z-30 select-none pointer-events-auto">
          {/* Top Center: Game Title with slight flicker animation */}
          <h1
            className="font-heading text-4xl sm:text-6xl md:text-7xl text-[#F0A500] tracking-wider text-center drop-shadow-[0_4px_12px_rgba(0,0,0,0.95)] animate-title-flicker"
            style={{ letterSpacing: '0.08em' }}
          >
            APAS <span className="text-[#E8E0D0]">:</span> BREACH
          </h1>

          {/* Below title: Four menu items stacked vertically in Space Mono */}
          <div className="mt-8 sm:mt-10 flex flex-col items-center space-y-4 sm:space-y-5">
            <button
              type="button"
              onClick={() => setActiveOverlay('DISPATCH')}
              className="font-mono text-xl sm:text-2xl text-[#E8E0D0] hover:text-[#F0A500] hover:drop-shadow-[0_0_12px_rgba(240,165,0,0.9)] cursor-crosshair transition-all duration-150 tracking-wider flex items-center gap-2 group"
            >
              <span className="text-[#F0A500] group-hover:translate-x-1 transition-transform">&gt;</span>
              <span>NEW GAME</span>
            </button>

            <button
              type="button"
              onClick={() => setActiveOverlay('SPECIALISTS')}
              className="font-mono text-xl sm:text-2xl text-[#E8E0D0] hover:text-[#F0A500] hover:drop-shadow-[0_0_12px_rgba(240,165,0,0.9)] cursor-crosshair transition-all duration-150 tracking-wider flex items-center gap-2 group"
            >
              <span className="text-[#F0A500] group-hover:translate-x-1 transition-transform">&gt;</span>
              <span>SPECIALISTS</span>
            </button>

            <button
              type="button"
              onClick={() => setActiveOverlay('FIELD_NOTES')}
              className="font-mono text-xl sm:text-2xl text-[#E8E0D0] hover:text-[#F0A500] hover:drop-shadow-[0_0_12px_rgba(240,165,0,0.9)] cursor-crosshair transition-all duration-150 tracking-wider flex items-center gap-2 group"
            >
              <span className="text-[#F0A500] group-hover:translate-x-1 transition-transform">&gt;</span>
              <span>FIELD NOTES</span>
            </button>

            <button
              type="button"
              onClick={() => setActiveOverlay('CREDITS')}
              className="font-mono text-xl sm:text-2xl text-[#E8E0D0] hover:text-[#F0A500] hover:drop-shadow-[0_0_12px_rgba(240,165,0,0.9)] cursor-crosshair transition-all duration-150 tracking-wider flex items-center gap-2 group"
            >
              <span className="text-[#F0A500] group-hover:translate-x-1 transition-transform">&gt;</span>
              <span>CREDITS</span>
            </button>
          </div>
        </div>
      )}

      {/* In-game HUD when specialist was selected (snap camera, game starts) */}
      {selectedSpecialist && activeOverlay === 'NONE' && (
        <div className="absolute top-8 left-8 z-30 bg-[#1A1F2E]/90 border border-[#F0A500] p-4 comic-shadow">
          <p className="font-heading text-sm text-[#F0A500] tracking-wide mb-1">AUDIT ACTIVE &middot; GATE 4</p>
          <p className="font-mono text-xs text-[#E8E0D0]">OPERATOR: {selectedSpecialist}</p>
          <p className="font-mono text-[10px] text-[#8A8FA8] mt-2 mb-3">THE WORLD IS RUNNING LIVE. SHIFT IN PROGRESS.</p>
          <button
            type="button"
            onClick={handleReturnToAttract}
            className="font-mono text-[10px] text-[#F0A500] hover:text-[#E8E0D0] border border-[#3A4156] px-2.5 py-1 bg-[#252B3B] cursor-crosshair"
          >
            &larr; TITLE SCREEN
          </button>
        </div>
      )}

      {/* Bottom Left: Live HHI readout in Space Mono 11px #F0A500 */}
      <div className="absolute bottom-6 left-6 sm:left-10 z-30 font-mono text-[11px] text-[#F0A500] tracking-wider select-none flex items-center gap-2 bg-[#1A1F2E]/80 border border-[#3A4156] px-3 py-1.5 comic-shadow-sm">
        <span className="inline-block w-2 h-2 rounded-full bg-[#CC2200] animate-pulse" />
        <span>HHI: {hhiValue} &mdash; CRITICAL</span>
      </div>

      {/* Bottom Right: Audio toggle (CLICK TO UNMUTE until started, then speaker icon) */}
      <div className="absolute bottom-6 right-6 sm:right-10 z-30 select-none">
        <button
          type="button"
          onClick={handleAudioToggle}
          className="font-mono text-[11px] text-[#E8E0D0] hover:text-[#F0A500] cursor-crosshair flex items-center gap-2 tracking-wider transition-colors bg-[#1A1F2E]/80 border border-[#3A4156] px-3 py-1.5 comic-shadow-sm focus:outline-none"
        >
          {!audioStarted ? (
            <span className="text-[#F0A500] animate-pulse">CLICK TO UNMUTE</span>
          ) : (
            <span className="flex items-center gap-2 text-[#F0A500] hover:text-[#E8E0D0]">
              <svg className="w-4 h-4 fill-current" viewBox="0 0 24 24">
                {isMuted ? (
                  <path d="M3.63 3.63a.996.996 0 000 1.41L7.29 8.7 7 9H4v6h3l5 5v-6.71l4.92 4.92c-.57.38-1.21.67-1.92.86v2.06c1.3-.34 2.47-.94 3.44-1.73l1.83 1.83a.996.996 0 101.41-1.41L5.05 3.63a.996.996 0 00-1.42 0zM12 4L9.91 6.09 12 8.18V4z" />
                ) : (
                  <path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z" />
                )}
              </svg>
              <span className="text-[10px] text-[#8A8FA8]">{isMuted ? 'MUTED' : 'LIVE'}</span>
            </span>
          )}
        </button>
      </div>

      {/* --- OVERLAY PANELS (OPENED DIRECTLY OVER LIVE 3D SCENE) --- */}

      {/* 1. SPECIALISTS OVERLAY */}
      {activeOverlay === 'SPECIALISTS' && (
        <div className="absolute inset-0 z-40 bg-[#1A1F2E]/85 backdrop-blur-sm flex flex-col items-center justify-center p-4 sm:p-8">
          <div className="w-full max-w-6xl bg-[#252B3B] border-2 border-[#3A4156] comic-shadow p-6 sm:p-8 max-h-[92vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-6 border-b border-[#3A4156] pb-4">
              <div>
                <h2 className="font-heading text-2xl sm:text-3xl text-[#E8E0D0]">FACILITY SPECIALISTS</h2>
                <p className="font-mono text-xs text-[#8A8FA8] mt-1">
                  Each specialist sees the facility differently. Each gives you a different edge — and a different blind spot.
                </p>
              </div>
              <button
                type="button"
                onClick={() => setActiveOverlay('NONE')}
                className="font-mono text-xs text-[#F0A500] hover:text-[#E8E0D0] border border-[#3A4156] px-4 py-2 bg-[#1A1F2E] cursor-crosshair"
              >
                [X] CLOSE
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 justify-items-center">
              {specialistsData.map((spec) => (
                <div
                  key={spec.id}
                  className="w-full max-w-[340px] bg-[#1A1F2E] border border-[#3A4156] hover:border-[#F0A500] transition-colors comic-shadow flex flex-col justify-between overflow-hidden"
                >
                  {/* Top 55%: Character Art & Backdrop */}
                  <div className="relative w-full h-[250px] bg-[#1A1F2E] flex items-center justify-center overflow-hidden border-b border-[#3A4156]/60">
                    {spec.backdrop}
                    <img
                      src={spec.image}
                      alt={spec.name}
                      className="relative z-10 w-full h-full object-contain pointer-events-none select-none"
                    />
                  </div>

                  {/* Bottom 45%: Details & Stat Bars */}
                  <div className="p-5 flex-1 flex flex-col justify-between">
                    <div>
                      <h3 className="font-heading text-xl tracking-wide mb-1" style={{ color: spec.accent }}>
                        {spec.name}
                      </h3>
                      <p className="font-mono text-[10px] text-[#8A8FA8] uppercase tracking-[0.18em] mb-3">
                        {spec.role}
                      </p>
                      <p className="font-mono text-xs text-[#E8E0D0] leading-relaxed mb-3">
                        {spec.tool}
                      </p>
                      <p className="font-mono text-xs text-[#8A8FA8] leading-relaxed mb-5">
                        <span className="text-[#CC2200] font-bold">BLIND SPOT — </span>
                        {spec.weakness}
                      </p>
                    </div>

                    <div className="space-y-2.5 pt-3 border-t border-[#3A4156]">
                      {spec.stats.map((stat) => (
                        <div key={stat.label}>
                          <div className="flex justify-between font-mono text-[10px] text-[#8A8FA8] mb-0.5">
                            <span>{stat.label}</span>
                            <span>{stat.value}</span>
                          </div>
                          <div className="w-full h-1.5 bg-[#3A4156] overflow-hidden">
                            <div
                              className="h-full transition-all duration-700 ease-out"
                              style={{
                                backgroundColor: spec.accent,
                                width: `${stat.value}%`,
                              }}
                            />
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* 2. FIELD NOTES OVERLAY */}
      {activeOverlay === 'FIELD_NOTES' && (
        <div className="absolute inset-0 z-40 bg-[#1A1F2E]/85 backdrop-blur-sm flex flex-col items-center justify-center p-4 sm:p-8">
          <div className="w-full max-w-4xl bg-[#252B3B] border-2 border-[#3A4156] comic-shadow p-6 sm:p-8 max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-6 border-b border-[#3A4156] pb-4">
              <div>
                <h2 className="font-heading text-2xl sm:text-3xl text-[#E8E0D0]">FIELD NOTES</h2>
                <p className="font-mono text-xs text-[#8A8FA8] mt-1">
                  The facts behind the fiction. Real data. Real systems. Real consequences.
                </p>
              </div>
              <button
                type="button"
                onClick={() => setActiveOverlay('NONE')}
                className="font-mono text-xs text-[#F0A500] hover:text-[#E8E0D0] border border-[#3A4156] px-4 py-2 bg-[#1A1F2E] cursor-crosshair"
              >
                [X] CLOSE
              </button>
            </div>

            <div className="space-y-4">
              {fieldNotesCards.map((card) => (
                <div
                  key={card.label}
                  className="bg-[#1A1F2E] border-l-4 border-l-[#F0A500] border-y border-r border-[#3A4156] p-5 comic-shadow"
                >
                  <span className="font-mono text-[11px] text-[#F0A500] uppercase tracking-[0.2em] block mb-2 font-bold">
                    {card.label}
                  </span>
                  <p className="font-mono text-xs text-[#E8E0D0] leading-relaxed mb-3">
                    {card.fact}
                  </p>
                  <div className="font-mono text-[10px] text-[#8A8FA8] pt-2 border-t border-[#3A4156]/40">
                    {card.source}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* 3. CREDITS OVERLAY */}
      {activeOverlay === 'CREDITS' && (
        <div className="absolute inset-0 z-40 bg-[#1A1F2E]/85 backdrop-blur-sm flex flex-col items-center justify-center p-4 sm:p-8">
          <div className="w-full max-w-3xl bg-[#252B3B] border-2 border-[#3A4156] comic-shadow p-6 sm:p-8 max-h-[90vh] overflow-y-auto">
            <div className="flex justify-between items-center mb-6 border-b border-[#3A4156] pb-4">
              <h2 className="font-heading text-2xl sm:text-3xl text-[#E8E0D0]">CREDITS &amp; LICENCES</h2>
              <button
                type="button"
                onClick={() => setActiveOverlay('NONE')}
                className="font-mono text-xs text-[#F0A500] hover:text-[#E8E0D0] border border-[#3A4156] px-4 py-2 bg-[#1A1F2E] cursor-crosshair"
              >
                [X] CLOSE
              </button>
            </div>

            <div className="space-y-5 font-mono text-xs text-[#8A8FA8] leading-relaxed">
              <div className="bg-[#1A1F2E] p-4 border border-[#3A4156]">
                <strong className="text-[#F0A500] block mb-1">ENGINE &amp; SIMULATION</strong>
                Three.js (WebGL retro-shaded pipeline) &middot; React &middot; TypeScript &middot; Vite
              </div>
              <div className="bg-[#1A1F2E] p-4 border border-[#3A4156]">
                <strong className="text-[#F0A500] block mb-1">TYPOGRAPHY</strong>
                Rubik Mono One (SIL Open Font Licence) &middot; Space Mono (SIL Open Font Licence)
              </div>
              <div className="bg-[#1A1F2E] p-4 border border-[#3A4156]">
                <strong className="text-[#F0A500] block mb-1">SOUND DESIGN</strong>
                Synthesized live via Web Audio API. Zero external audio samples used.
              </div>
              <div className="bg-[#1A1F2E] p-4 border border-[#3A4156]">
                <strong className="text-[#F0A500] block mb-1">CHARACTER ART</strong>
                Original hand-drawn comic character art. Zero copyrighted assets.
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 4. DISPATCH OVERLAY (NEW GAME FLOW) */}
      {activeOverlay === 'DISPATCH' && (
        <div className="absolute inset-0 z-40 bg-[#1A1F2E]/90 backdrop-blur-md flex flex-col items-center justify-center p-4 sm:p-8">
          <div className="w-full max-w-4xl bg-[#252B3B] border-2 border-[#F0A500] comic-shadow p-6 sm:p-8 text-center">
            <h2 className="font-heading text-2xl sm:text-4xl text-[#F0A500] mb-2 tracking-wide">
              DISPATCH &middot; SELECT SPECIALIST
            </h2>
            <p className="font-mono text-xs text-[#8A8FA8] tracking-widest uppercase mb-8">
              CHOOSE YOUR AUDITOR FOR SHIFT 16:30 &rarr; SUNRISE
            </p>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8 text-left">
              {specialistsData.map((spec) => (
                <button
                  key={spec.id}
                  type="button"
                  onClick={() => handleSelectSpecialist(spec)}
                  className="bg-[#1A1F2E] border-2 border-[#3A4156] hover:border-[#F0A500] p-5 text-left transition-all comic-shadow cursor-crosshair group"
                >
                  <h4 className="font-heading text-base sm:text-lg mb-1 group-hover:text-[#F0A500]" style={{ color: spec.accent }}>
                    {spec.name}
                  </h4>
                  <p className="font-mono text-[10px] text-[#8A8FA8] uppercase mb-2">{spec.role}</p>
                  <p className="font-mono text-xs text-[#E8E0D0] leading-relaxed">{spec.tool}</p>
                  <div className="mt-4 pt-2 border-t border-[#3A4156] flex justify-between items-center">
                    <span className="font-mono text-[10px] text-[#F0A500] uppercase font-bold">DISPATCH &rarr;</span>
                  </div>
                </button>
              ))}
            </div>

            <button
              type="button"
              onClick={() => setActiveOverlay('NONE')}
              className="font-mono text-xs text-[#8A8FA8] hover:text-[#E8E0D0] border border-[#3A4156] px-6 py-2.5 bg-[#1A1F2E] cursor-crosshair"
            >
              &larr; BACK TO MENU
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default AttractMode;
