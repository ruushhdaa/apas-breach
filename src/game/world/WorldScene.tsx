import React, { useEffect, useRef } from 'react';
import * as THREE from 'three';
import { useGameStore } from '../../store/gameStore';

interface WorldSceneProps {
  scene: THREE.Scene;
  qToolActive: boolean;
  specialistId: string | null;
  onInteractableTrigger?: (id: string, inRange: boolean) => void;
}

export const WorldScene: React.FC<WorldSceneProps> = ({
  scene,
  qToolActive,
  specialistId,
}) => {
  const hhiTier = useGameStore((state) => state.hhiTier);
  const hhi = useGameStore((state) => state.hhi);
  const currentLevel = useGameStore((state) => state.currentLevel);

  const steamPuffsRef = useRef<THREE.Mesh[]>([]);
  const canalMeshRef = useRef<THREE.Mesh | null>(null);
  const creekMeshRef = useRef<THREE.Mesh | null>(null);
  const thermalPipesRef = useRef<THREE.Mesh[]>([]);
  const boomBarrierRef = useRef<THREE.Mesh | null>(null);
  const emergencyLightRef = useRef<THREE.PointLight | null>(null);

  // Initialize all world geometry once
  useEffect(() => {
    // 1. Procedural 64x64 textures with NearestFilter
    const createProceduralTexture = (type: 'asphalt' | 'hazard' | 'concrete') => {
      const cvs = document.createElement('canvas');
      cvs.width = 64;
      cvs.height = 64;
      const ctx = cvs.getContext('2d')!;

      if (type === 'asphalt') {
        ctx.fillStyle = '#1B1713';
        ctx.fillRect(0, 0, 64, 64);
        for (let i = 0; i < 180; i++) {
          const v = Math.random() > 0.5 ? '#241E18' : '#14100C';
          ctx.fillStyle = v;
          ctx.fillRect(Math.floor(Math.random() * 64), Math.floor(Math.random() * 64), 1, 1);
        }
      } else if (type === 'hazard') {
        ctx.fillStyle = '#1E1812';
        ctx.fillRect(0, 0, 64, 64);
        ctx.fillStyle = '#F0A500';
        for (let i = -64; i < 128; i += 16) {
          ctx.beginPath();
          ctx.moveTo(i, 0);
          ctx.lineTo(i + 8, 0);
          ctx.lineTo(i + 8 + 64, 64);
          ctx.lineTo(i + 64, 64);
          ctx.fill();
        }
      } else {
        ctx.fillStyle = '#2A241E';
        ctx.fillRect(0, 0, 64, 64);
        for (let i = 0; i < 120; i++) {
          ctx.fillStyle = Math.random() > 0.5 ? '#362E26' : '#201A14';
          ctx.fillRect(Math.floor(Math.random() * 64), Math.floor(Math.random() * 64), 1, 1);
        }
      }

      const tex = new THREE.CanvasTexture(cvs);
      tex.magFilter = THREE.NearestFilter;
      tex.minFilter = THREE.NearestFilter;
      tex.wrapS = THREE.RepeatWrapping;
      tex.wrapT = THREE.RepeatWrapping;
      return tex;
    };

    const texAsphalt = createProceduralTexture('asphalt');
    texAsphalt.repeat.set(12, 12);

    const texHazard = createProceduralTexture('hazard');
    texHazard.repeat.set(8, 1);

    const texConcrete = createProceduralTexture('concrete');
    texConcrete.repeat.set(6, 6);

    // --- MATERIALS (Flat shaded low-poly) ---
    const matAsphalt = new THREE.MeshLambertMaterial({ map: texAsphalt });
    const matRoad = new THREE.MeshLambertMaterial({ color: 0x181410 });
    const matConcrete = new THREE.MeshLambertMaterial({ map: texConcrete });
    const matWall = new THREE.MeshLambertMaterial({ color: 0x241E18 });
    const matTower = new THREE.MeshLambertMaterial({ color: 0x242630 });
    const matTowerRim = new THREE.MeshLambertMaterial({ color: 0x1A1D24 });
    const matColony = new THREE.MeshLambertMaterial({ color: 0x3A3028 });
    const matAmberLight = new THREE.MeshBasicMaterial({ color: 0xf0a500 });
    const matRedAlert = new THREE.MeshBasicMaterial({ color: 0xcc2200 });
    const matSteam = new THREE.MeshBasicMaterial({ color: 0xf2ece4, transparent: true, opacity: 0.35 });
    const matHazard = new THREE.MeshBasicMaterial({ map: texHazard });
    const matCreek = new THREE.MeshLambertMaterial({ color: hhiTier.creekColor, transparent: true, opacity: hhiTier.creekOpacity });
    creekMeshRef.current = new THREE.Mesh(new THREE.PlaneGeometry(50, 100), matCreek);

    // --- 1. COMPOUND GROUND: x -50..50, z -50..50 ---
    const ground = new THREE.Mesh(new THREE.PlaneGeometry(100, 100), matAsphalt);
    ground.rotation.x = -Math.PI / 2;
    ground.position.set(0, 0, 0);
    scene.add(ground);

    // Hazard stripe perimeter along fence line
    const hazardBorderS = new THREE.Mesh(new THREE.PlaneGeometry(96, 1.2), matHazard);
    hazardBorderS.rotation.x = -Math.PI / 2;
    hazardBorderS.position.set(0, 0.02, 48.5);
    scene.add(hazardBorderS);

    // --- 2. ROAD OUTSIDE: z 50..70 ---
    const road = new THREE.Mesh(new THREE.PlaneGeometry(140, 22), matRoad);
    road.rotation.x = -Math.PI / 2;
    road.position.set(0, 0.01, 61);
    scene.add(road);

    // Road dashed white center line
    for (let rx = -60; rx <= 60; rx += 12) {
      const dash = new THREE.Mesh(new THREE.PlaneGeometry(5, 0.4), new THREE.MeshBasicMaterial({ color: 0xcccccc }));
      dash.rotation.x = -Math.PI / 2;
      dash.position.set(rx, 0.025, 61);
      scene.add(dash);
    }

    // --- 3. RABALE COLONY: z 70..130 ---
    const colonyGround = new THREE.Mesh(new THREE.PlaneGeometry(160, 60), matColony);
    colonyGround.rotation.x = -Math.PI / 2;
    colonyGround.position.set(0, -0.05, 100);
    scene.add(colonyGround);

    // 8 Chawl buildings with varied heights 6-14m
    const colonyData = [
      [-36, 78, 12, 10, 14],
      [-18, 92, 14, 12, 12],
      [4, 82, 10, 14, 16],
      [22, 76, 12, 9, 10],
      [40, 95, 16, 11, 14],
      [-5, 110, 15, 13, 18],
      [18, 114, 12, 8, 12],
      [-28, 115, 14, 9, 14],
    ];

    colonyData.forEach(([cx, cz, w, h, d]) => {
      const bldg = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), matColony);
      bldg.position.set(cx, h / 2, cz);
      scene.add(bldg);

      // Window grid painted with amber and dark squares
      for (let wy = 2; wy < h - 1; wy += 3) {
        for (let wx = -w / 2 + 2; wx < w / 2 - 1; wx += 3) {
          const isLit = (Math.sin(cx + cz + wy + wx) > 0.2);
          const win = new THREE.Mesh(
            new THREE.PlaneGeometry(1.2, 1.4),
            isLit ? matAmberLight : new THREE.MeshBasicMaterial({ color: 0x1a1510 })
          );
          win.position.set(cx + wx, wy, cz - d / 2 - 0.05);
          scene.add(win);
        }
      }
    });

    // Water Tanker Queue at (-15, 0, 80)
    for (let t = 0; t < 3; t++) {
      const tankerBody = new THREE.Mesh(new THREE.BoxGeometry(2.6, 2.2, 6.2), matAmberLight);
      tankerBody.position.set(-15, 1.4, 73 + t * 7.5);
      scene.add(tankerBody);

      const tankerCab = new THREE.Mesh(new THREE.BoxGeometry(2.4, 1.8, 2.0), matWall);
      tankerCab.position.set(-15, 1.2, 70 + t * 7.5);
      scene.add(tankerCab);
    }

    // Dry public tap at (-10, 0, 90)
    const tapPole = new THREE.Mesh(new THREE.CylinderGeometry(0.12, 0.12, 1.8, 6), matConcrete);
    tapPole.position.set(-10, 0.9, 90);
    scene.add(tapPole);
    const spigot = new THREE.Mesh(new THREE.BoxGeometry(0.15, 0.15, 0.5), matWall);
    spigot.position.set(-10, 1.4, 89.7);
    scene.add(spigot);

    // Tea Stall at (5, 0, 85)
    const teaStall = new THREE.Mesh(new THREE.BoxGeometry(4, 2.8, 3.5), matConcrete);
    teaStall.position.set(5, 1.4, 85);
    scene.add(teaStall);
    const teaCanopy = new THREE.Mesh(new THREE.BoxGeometry(4.4, 0.15, 4), matAmberLight);
    teaCanopy.position.set(5, 2.8, 85);
    scene.add(teaCanopy);

    // Laundry Lines between buildings
    const laundryMat = new THREE.MeshBasicMaterial({ color: 0x998877 });
    const line = new THREE.Mesh(new THREE.CylinderGeometry(0.04, 0.04, 18, 4), laundryMat);
    line.rotation.z = Math.PI / 2;
    line.position.set(-8, 4.5, 98);
    scene.add(line);

    // --- 4. CREEK & MANGROVES: x 60..110, z -50..50 ---
    creekMeshRef.current.rotation.x = -Math.PI / 2;
    creekMeshRef.current.position.set(85, -0.2, 0);
    scene.add(creekMeshRef.current);

    // Mangrove silhouettes along creek boundary (x = 58)
    const matMangrove = new THREE.MeshLambertMaterial({ color: 0x18281a });
    for (let mz = -45; mz <= 45; mz += 6) {
      const trunk = new THREE.Mesh(new THREE.CylinderGeometry(0.3, 0.5, 3.5, 5), matWall);
      trunk.position.set(58 + Math.sin(mz) * 2, 1.75, mz);
      scene.add(trunk);

      const foliage = new THREE.Mesh(new THREE.ConeGeometry(2.5, 4.5, 5), matMangrove);
      foliage.position.set(58 + Math.sin(mz) * 2, 4.5, mz);
      scene.add(foliage);
    }

    // --- 5. OUTFALL CANAL: (50, 0, -20) running east to creek ---
    const canalGeo = new THREE.BoxGeometry(18, 0.6, 4.5);
    const canal = new THREE.Mesh(canalGeo, matCreek);
    canal.position.set(58, -0.2, -20);
    scene.add(canal);
    canalMeshRef.current = canal;

    // --- 6. COMPOUND WALLS (x -50..50, z -50..50, height 3.5) ---
    // North wall
    const wallN = new THREE.Mesh(new THREE.BoxGeometry(100, 3.5, 1.2), matWall);
    wallN.position.set(0, 1.75, -50);
    scene.add(wallN);

    // West wall
    const wallW = new THREE.Mesh(new THREE.BoxGeometry(1.2, 3.5, 100), matWall);
    wallW.position.set(-50, 1.75, 0);
    scene.add(wallW);

    // East wall
    const wallE = new THREE.Mesh(new THREE.BoxGeometry(1.2, 3.5, 100), matWall);
    wallE.position.set(50, 1.75, 0);
    scene.add(wallE);

    // South wall left of Gate 4
    const wallSL = new THREE.Mesh(new THREE.BoxGeometry(44, 3.5, 1.2), matWall);
    wallSL.position.set(-28, 1.75, 50);
    scene.add(wallSL);

    // South wall right of Gate 4
    const wallSR = new THREE.Mesh(new THREE.BoxGeometry(44, 3.5, 1.2), matWall);
    wallSR.position.set(28, 1.75, 50);
    scene.add(wallSR);

    // --- 7. GATE 4 & GATEHOUSE: (0, 0, 50) ---
    const gateHouse = new THREE.Mesh(new THREE.BoxGeometry(4, 3.2, 4), matConcrete);
    gateHouse.position.set(-7.5, 1.6, 50);
    scene.add(gateHouse);

    // Gate Posts
    const gatePostL = new THREE.Mesh(new THREE.BoxGeometry(1.4, 4.2, 1.4), matAmberLight);
    gatePostL.position.set(-5.5, 2.1, 50);
    scene.add(gatePostL);
    const gatePostR = new THREE.Mesh(new THREE.BoxGeometry(1.4, 4.2, 1.4), matAmberLight);
    gatePostR.position.set(5.5, 2.1, 50);
    scene.add(gatePostR);

    // Boom barrier arm
    const boomBarrier = new THREE.Mesh(new THREE.BoxGeometry(10, 0.25, 0.25), matHazard);
    boomBarrier.position.set(0, 1.2, 50);
    scene.add(boomBarrier);
    boomBarrierRef.current = boomBarrier;

    // Signboard: "AETHERSCALE MAH-04 // AUTHORISED ENTRY ONLY"
    const signPost = new THREE.Mesh(new THREE.CylinderGeometry(0.1, 0.1, 2.8, 4), matWall);
    signPost.position.set(8.5, 1.4, 52);
    scene.add(signPost);
    const signBoard = new THREE.Mesh(new THREE.BoxGeometry(3.4, 1.4, 0.1), matWall);
    signBoard.position.set(8.5, 2.5, 52);
    scene.add(signBoard);

    // --- 8. MUNICIPAL METER SUBSTATION: (-28, 0, 44) ---
    const substation = new THREE.Mesh(new THREE.BoxGeometry(7, 4.2, 6), matConcrete);
    substation.position.set(-28, 2.1, 44);
    scene.add(substation);

    // Meter Cabinet on outside wall
    const meterCabinet = new THREE.Mesh(new THREE.BoxGeometry(1.4, 1.8, 0.4), matAmberLight);
    meterCabinet.position.set(-28, 1.8, 47.1);
    scene.add(meterCabinet);

    // Hidden bypass pipe behind substation
    const bypassPipe = new THREE.Mesh(new THREE.CylinderGeometry(0.6, 0.6, 12, 8), matWall);
    bypassPipe.rotation.x = Math.PI / 2;
    bypassPipe.position.set(-32, 0.6, 42);
    scene.add(bypassPipe);
    thermalPipesRef.current.push(bypassPipe);

    // --- 9. SERVER HALL A: x -45..-15, z -45..-5 ---
    const serverHall = new THREE.Mesh(new THREE.BoxGeometry(30, 8, 40), matConcrete);
    serverHall.position.set(-30, 4, -25);
    scene.add(serverHall);

    // Server Hall Door at (-15, 0, -25)
    const hallDoor = new THREE.Mesh(new THREE.BoxGeometry(0.3, 3.4, 2.4), matWall);
    hallDoor.position.set(-14.9, 1.7, -25);
    scene.add(hallDoor);

    // Red emergency flicker light at Server Hall entrance
    const redLight = new THREE.PointLight(0xcc2200, 1.8, 25);
    redLight.position.set(-16, 3.8, -25);
    scene.add(redLight);
    emergencyLightRef.current = redLight;

    // --- 10. COOLING TOWERS: 4 towers at x = -5, 8, 21, 34, z = -35 ---
    const towersX = [-5, 8, 21, 34];
    towersX.forEach((tx) => {
      // Lathe hyperbolic profile
      const points: THREE.Vector2[] = [];
      for (let i = 0; i <= 12; i++) {
        const y = i;
        const normY = (y - 6) / 6; // -1 to 1
        const r = 3.6 + normY * normY * 0.9;
        points.push(new THREE.Vector2(r, y));
      }
      const towerGeo = new THREE.LatheGeometry(points, 16);
      const tower = new THREE.Mesh(towerGeo, matTower);
      tower.position.set(tx, 0, -35);
      scene.add(tower);

      const rim = new THREE.Mesh(new THREE.TorusGeometry(4.3, 0.4, 6, 16), matTowerRim);
      rim.rotation.x = Math.PI / 2;
      rim.position.set(tx, 12, -35);
      scene.add(rim);

      // Instanced rising steam puff spheres
      for (let s = 0; s < 6; s++) {
        const puff = new THREE.Mesh(new THREE.SphereGeometry(1.4 + s * 0.35, 6, 5), matSteam);
        puff.position.set(tx + (Math.random() - 0.5) * 1.5, 12.5 + s * 2.4, -35 + (Math.random() - 0.5) * 1.5);
        puff.userData = {
          baseX: tx,
          baseY: 12.5,
          baseZ: -35,
          speed: 0.04 + Math.random() * 0.03,
          offset: Math.random() * 10,
        };
        scene.add(puff);
        steamPuffsRef.current.push(puff);
      }
    });

    // Stuck blowdown valve at (40, 0, -20)
    const valveWheel = new THREE.Mesh(new THREE.TorusGeometry(0.6, 0.12, 6, 12), matRedAlert);
    valveWheel.rotation.x = Math.PI / 2;
    valveWheel.position.set(40, 1.2, -20);
    scene.add(valveWheel);

    // --- 11. SCADA HUB: (20, 0, 10), size 16x10x5 ---
    const scadaHub = new THREE.Mesh(new THREE.BoxGeometry(16, 5, 10), matWall);
    scadaHub.position.set(20, 2.5, 10);
    scene.add(scadaHub);

    // Glowing cyan/amber interior console window
    const scadaWin = new THREE.Mesh(new THREE.PlaneGeometry(8, 2.2), matAmberLight);
    scadaWin.position.set(20, 2.5, 15.05);
    scene.add(scadaWin);

    // --- 12. AUDIT STAGE: (0, 0, 58) outside Gate 4 ---
    const auditPlatform = new THREE.Mesh(new THREE.BoxGeometry(10, 0.3, 8), matConcrete);
    auditPlatform.position.set(0, 0.15, 58);
    scene.add(auditPlatform);

    // MPCB Inspection Vehicle at (8, 0, 62)
    const mpcbCar = new THREE.Mesh(new THREE.BoxGeometry(3.2, 1.8, 5.6), matConcrete);
    mpcbCar.position.set(8, 0.9, 62);
    scene.add(mpcbCar);

    // Traffic barrier cones around audit stage
    for (let c = -4; c <= 4; c += 2) {
      const cone = new THREE.Mesh(new THREE.ConeGeometry(0.3, 0.8, 6), matAmberLight);
      cone.position.set(c, 0.4, 54.5);
      scene.add(cone);
    }

    // --- 13. PROPS: Cars, Auto-rickshaws, Pipe racks ---
    // Parked auto-rickshaws at colony edge
    for (let r = 0; r < 2; r++) {
      const rickshaw = new THREE.Mesh(new THREE.BoxGeometry(1.8, 1.6, 2.8), matAmberLight);
      rickshaw.position.set(-6 + r * 3, 0.8, 76);
      scene.add(rickshaw);
    }

    // Pipe rack corridor running north-south
    for (let pz = -30; pz <= 30; pz += 15) {
      const rackGantry = new THREE.Mesh(new THREE.BoxGeometry(0.3, 5, 0.3), matWall);
      rackGantry.position.set(12, 2.5, pz);
      scene.add(rackGantry);

      const overheadPipe = new THREE.Mesh(new THREE.CylinderGeometry(0.25, 0.25, 15, 6), matConcrete);
      overheadPipe.position.set(12, 4.8, pz + 7.5);
      scene.add(overheadPipe);
      thermalPipesRef.current.push(overheadPipe);
    }
  }, [scene]);

  // Reactive updates: Sky color, exponential fog, creek color, steam spawn rate
  useEffect(() => {
    // 1. Scene Fog & Background
    const targetFogColor = new THREE.Color(hhiTier.skyColor);
    scene.background = targetFogColor;
    if (scene.fog) {
      (scene.fog as THREE.FogExp2).color = targetFogColor;
      (scene.fog as THREE.FogExp2).density = hhiTier.fogDensity;
    } else {
      scene.fog = new THREE.FogExp2(targetFogColor.getHex(), hhiTier.fogDensity);
    }

    // 2. Creek & Canal Color
    if (creekMeshRef.current) {
      const creekMat = creekMeshRef.current.material as THREE.MeshLambertMaterial;
      creekMat.color.setHex(hhiTier.creekColor);
      creekMat.opacity = hhiTier.creekOpacity;
    }
    if (canalMeshRef.current) {
      const canalMat = canalMeshRef.current.material as THREE.MeshLambertMaterial;
      canalMat.color.setHex(hhiTier.creekColor);
    }
  }, [hhiTier, scene]);

  // Q-Tool Thermal Highlighting (Kabir "Volt" Rao)
  useEffect(() => {
    thermalPipesRef.current.forEach((pipe) => {
      const mat = pipe.material as THREE.MeshLambertMaterial;
      if (qToolActive && specialistId === 'VOLT') {
        mat.emissive = new THREE.Color(0xff4500); // Thermal glowing orange
      } else {
        mat.emissive = new THREE.Color(0x000000);
      }
    });
  }, [qToolActive, specialistId]);

  // Animation Loop for Steam and Emergency Lights
  useEffect(() => {
    let animId: number;
    let clock = new THREE.Clock();

    const animateWorld = () => {
      animId = requestAnimationFrame(animateWorld);
      const elapsed = clock.getElapsedTime();

      // Steam puffs rising
      steamPuffsRef.current.forEach((puff) => {
        puff.position.y += puff.userData.speed;
        puff.position.x += Math.sin(elapsed + puff.userData.offset) * 0.02;
        if (puff.position.y > 22) {
          puff.position.y = puff.userData.baseY;
          puff.position.x = puff.userData.baseX + (Math.random() - 0.5) * 1.5;
        }
      });

      // Emergency light flicker (Level 2 or Critical/Collapse)
      if (emergencyLightRef.current) {
        if (currentLevel >= 2 || hhi <= 44) {
          emergencyLightRef.current.intensity = (Math.sin(elapsed * 12) > 0.1) ? 2.2 : 0.3;
        } else {
          emergencyLightRef.current.intensity = 0.6;
        }
      }
    };

    animateWorld();
    return () => cancelAnimationFrame(animId);
  }, [currentLevel, hhi]);

  return null;
};
