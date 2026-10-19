import React, { useEffect, useRef } from 'react';
import * as THREE from 'three';
import { useGameStore } from '../../store/gameStore';
import voltImg from '../../assets/characters/volt.png';
import ananyaImg from '../../assets/characters/ananya.png';
import taraImg from '../../assets/characters/tara.png';

interface PlayerControllerProps {
  scene: THREE.Scene;
  camera: THREE.PerspectiveCamera;
  domElement: HTMLElement;
  onInteract: () => void;
  onNearInteractable: (prompt: string | null) => void;
  onPlayerPosUpdate?: (pos: THREE.Vector3) => void;
}

export const PlayerController: React.FC<PlayerControllerProps> = ({
  scene,
  camera,
  domElement,
  onInteract,
  onNearInteractable,
  onPlayerPosUpdate,
}) => {
  const specialist = useGameStore((state) => state.specialist);
  const toggleQTool = useGameStore((state) => state.toggleQTool);
  const toggleMap = useGameStore((state) => state.toggleMap);
  const toggleDevPanel = useGameStore((state) => state.toggleDevPanel);

  // Position & Physics state
  const playerPos = useRef(new THREE.Vector3(0, 0, 45)); // Spawn at (0, 0, 45)
  const playerVel = useRef(new THREE.Vector3(0, 0, 0));
  const keys = useRef<{ [k: string]: boolean }>({});

  // Camera Orbit state
  const camYaw = useRef<number>(Math.PI); // Facing north (towards compound center)
  const camPitch = useRef<number>(0.28);
  const isPointerLocked = useRef<boolean>(false);

  // Character Sprite & Blob Shadow
  const spriteRef = useRef<THREE.Sprite | null>(null);
  const shadowRef = useRef<THREE.Mesh | null>(null);

  // Character textures
  useEffect(() => {
    const texLoader = new THREE.TextureLoader();
    let imgPath = voltImg;
    if (specialist === 'ANANYA') imgPath = ananyaImg;
    if (specialist === 'TARA') imgPath = taraImg;

    const texture = texLoader.load(imgPath);
    texture.magFilter = THREE.NearestFilter;
    texture.minFilter = THREE.NearestFilter;

    // Sprite
    const spriteMat = new THREE.SpriteMaterial({
      map: texture,
      transparent: true,
      depthWrite: false,
    });
    const sprite = new THREE.Sprite(spriteMat);
    sprite.scale.set(2.4, 3.6, 1);
    sprite.position.copy(playerPos.current).add(new THREE.Vector3(0, 1.8, 0));
    scene.add(sprite);
    spriteRef.current = sprite;

    // Blob Shadow (dark circular decal on ground)
    const shadowGeo = new THREE.CircleGeometry(0.85, 12);
    const shadowMat = new THREE.MeshBasicMaterial({
      color: 0x050403,
      transparent: true,
      opacity: 0.55,
      depthWrite: false,
    });
    const shadow = new THREE.Mesh(shadowGeo, shadowMat);
    shadow.rotation.x = -Math.PI / 2;
    shadow.position.copy(playerPos.current).add(new THREE.Vector3(0, 0.03, 0));
    scene.add(shadow);
    shadowRef.current = shadow;

    return () => {
      scene.remove(sprite);
      scene.remove(shadow);
      spriteMat.dispose();
      shadowMat.dispose();
      texture.dispose();
    };
  }, [scene, specialist]);

  // Pointer Lock & Mouse Orbit
  useEffect(() => {
    const onClick = () => {
      if (!isPointerLocked.current) {
        domElement.requestPointerLock?.();
      }
    };

    const onPointerLockChange = () => {
      isPointerLocked.current = document.pointerLockElement === domElement;
    };

    const onMouseMove = (e: MouseEvent) => {
      if (!isPointerLocked.current) return;
      const sens = 0.0022;
      camYaw.current -= e.movementX * sens;
      camPitch.current -= e.movementY * sens;
      camPitch.current = Math.max(0.08, Math.min(1.2, camPitch.current));
    };

    domElement.addEventListener('click', onClick);
    document.addEventListener('pointerlockchange', onPointerLockChange);
    document.addEventListener('mousemove', onMouseMove);

    return () => {
      domElement.removeEventListener('click', onClick);
      document.removeEventListener('pointerlockchange', onPointerLockChange);
      document.removeEventListener('mousemove', onMouseMove);
    };
  }, [domElement]);

  // Keyboard controls
  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      keys.current[e.code] = true;

      if (e.code === 'KeyE') {
        onInteract();
      } else if (e.code === 'KeyQ') {
        toggleQTool();
      } else if (e.code === 'KeyM') {
        toggleMap();
      } else if (e.code === 'F1') {
        e.preventDefault();
        toggleDevPanel();
      }
    };

    const onKeyUp = (e: KeyboardEvent) => {
      keys.current[e.code] = false;
    };

    window.addEventListener('keydown', onKeyDown);
    window.addEventListener('keyup', onKeyUp);

    return () => {
      window.removeEventListener('keydown', onKeyDown);
      window.removeEventListener('keyup', onKeyUp);
    };
  }, [onInteract, toggleQTool, toggleMap, toggleDevPanel]);

  // Main Movement & Camera Loop
  useEffect(() => {
    let frameId: number;
    let clock = new THREE.Clock();

    const updatePhysicsAndCamera = () => {
      frameId = requestAnimationFrame(updatePhysicsAndCamera);
      const dt = Math.min(0.1, clock.getDelta());
      const elapsed = clock.getElapsedTime();

      // Determine movement direction relative to camera yaw
      let moveX = 0;
      let moveZ = 0;

      if (keys.current['KeyW'] || keys.current['ArrowUp']) moveZ -= 1;
      if (keys.current['KeyS'] || keys.current['ArrowDown']) moveZ += 1;
      if (keys.current['KeyA'] || keys.current['ArrowLeft']) moveX -= 1;
      if (keys.current['KeyD'] || keys.current['ArrowRight']) moveX += 1;

      const isMoving = moveX !== 0 || moveZ !== 0;

      // Base speeds
      let speed = 6.2; // 6.2 m/s base run
      if (keys.current['ShiftLeft'] || keys.current['ShiftRight']) {
        speed *= 1.8; // Sprint
        if (specialist === 'ANANYA') speed *= 0.90; // Ananya is 10% slower on sprint
      }

      if (isMoving) {
        const inputAngle = Math.atan2(moveX, moveZ);
        const moveAngle = camYaw.current + inputAngle;

        const targetVelX = Math.sin(moveAngle) * speed;
        const targetVelZ = Math.cos(moveAngle) * speed;

        playerVel.current.x = targetVelX;
        playerVel.current.z = targetVelZ;
      } else {
        playerVel.current.x *= 0.8;
        playerVel.current.z *= 0.8;
      }

      // Apply movement to position
      playerPos.current.x += playerVel.current.x * dt;
      playerPos.current.z += playerVel.current.z * dt;

      // Compound bounding collisions (x -48..48, z -48..125)
      playerPos.current.x = Math.max(-48, Math.min(108, playerPos.current.x));
      playerPos.current.z = Math.max(-48, Math.min(125, playerPos.current.z));

      // Wall collision for compound perimeter except Gate 4 gap (-6..6 at z=50)
      if (Math.abs(playerPos.current.z - 50) < 1.2) {
        if (playerPos.current.x < -6.0 || playerPos.current.x > 6.0) {
          // Push back out
          playerPos.current.z = playerPos.current.z > 50 ? 51.3 : 48.7;
        }
      }

      // Update Sprite & Blob Shadow
      if (spriteRef.current && shadowRef.current) {
        // Idle/moving bobbing
        const bob = isMoving ? Math.sin(elapsed * 14) * 0.12 : Math.sin(elapsed * 2.5) * 0.04;
        spriteRef.current.position.set(
          playerPos.current.x,
          1.8 + bob,
          playerPos.current.z
        );
        shadowRef.current.position.set(
          playerPos.current.x,
          0.03,
          playerPos.current.z
        );
      }

      // Third-person chase camera: distance 7, height 3.2, FOV 55
      const camDist = 7.0;
      const camHeight = 3.2;

      const idealCamX = playerPos.current.x - Math.sin(camYaw.current) * Math.cos(camPitch.current) * camDist;
      const idealCamY = playerPos.current.y + camHeight + Math.sin(camPitch.current) * camDist * 0.6;
      const idealCamZ = playerPos.current.z - Math.cos(camYaw.current) * Math.cos(camPitch.current) * camDist;

      camera.position.set(idealCamX, Math.max(0.8, idealCamY), idealCamZ);
      const lookTarget = new THREE.Vector3(playerPos.current.x, playerPos.current.y + 1.8, playerPos.current.z);
      camera.lookAt(lookTarget);

      onPlayerPosUpdate?.(playerPos.current);

      // Check proximity to key interactable trigger zones
      checkInteractableZones(playerPos.current);
    };

    // Trigger zones checking
    const checkInteractableZones = (pos: THREE.Vector3) => {
      // 1. Colony Tanker Queue: Sunita Tai at (-15, 0, 80)
      const distTanker = pos.distanceTo(new THREE.Vector3(-15, 0, 80));
      if (distTanker < 5.0) {
        onNearInteractable('[E] TALK TO SUNITA TAI // COLONY TANKER QUEUE');
        return;
      }

      // 2. Municipal Meter Substation: (-28, 0, 44)
      const distSubstation = pos.distanceTo(new THREE.Vector3(-28, 0, 44));
      if (distSubstation < 4.5) {
        onNearInteractable('[E] INSPECT MUNICIPAL METER CABINET');
        return;
      }

      // 3. Bypass Pipe behind substation: (-32, 0, 42)
      const distPipe = pos.distanceTo(new THREE.Vector3(-32, 0, 42));
      if (distPipe < 4.5) {
        onNearInteractable('[Q] SCAN HIDDEN UNMETERED BYPASS PIPE');
        return;
      }

      // 4. Server Hall A Door: (-15, 0, -25)
      const distDoor = pos.distanceTo(new THREE.Vector3(-15, 0, -25));
      if (distDoor < 4.0) {
        onNearInteractable('[E] ENTER SERVER HALL A // PUMP GALLERY');
        return;
      }

      // 5. Outfall Canal & Blowdown Valve: (40, 0, -20)
      const distValve = pos.distanceTo(new THREE.Vector3(40, 0, -20));
      if (distValve < 4.5) {
        onNearInteractable('[E] DISLODGE SEIZED BLOWDOWN VALVE');
        return;
      }

      // 6. SCADA Hub Console: (20, 0, 10)
      const distSCADA = pos.distanceTo(new THREE.Vector3(20, 0, 10));
      if (distSCADA < 5.0) {
        onNearInteractable('[E] ACCESS SCADA MASTER CONSOLE');
        return;
      }

      // 7. Audit Stage: (0, 0, 58)
      const distAudit = pos.distanceTo(new THREE.Vector3(0, 0, 58));
      if (distAudit < 5.0) {
        onNearInteractable('[E] COMMENCE MPCB DAWN AUDIT');
        return;
      }

      onNearInteractable(null);
    };

    updatePhysicsAndCamera();

    return () => {
      cancelAnimationFrame(frameId);
    };
  }, [camera, domElement, onNearInteractable, onPlayerPosUpdate, specialist]);

  return null;
};
