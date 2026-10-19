import React, { useEffect, useRef } from 'react';
import * as THREE from 'three';
import { useGameStore } from '../../store/gameStore';
import { audioEngine } from '../audio/audioEngine';
import { LEVEL_CONFIGS } from './levelData';

interface LevelControllerProps {
  playerPos: THREE.Vector3;
}

export const LevelController: React.FC<LevelControllerProps> = ({ playerPos }) => {
  const currentLevel = useGameStore((state) => state.currentLevel);
  const currentBeat = useGameStore((state) => state.currentBeat);
  const persistent = useGameStore((state) => state.persistent);

  const setObjective = useGameStore((state) => state.setObjective);
  const setBeat = useGameStore((state) => state.setBeat);
  const showRadio = useGameStore((state) => state.showRadio);
  const collectEvidence = useGameStore((state) => state.collectEvidence);
  const modifyPersistent = useGameStore((state) => state.modifyPersistent);
  const setSimInputs = useGameStore((state) => state.setSimInputs);
  const openDecisionCard = useGameStore((state) => state.openDecisionCard);
  const showDebrief = useGameStore((state) => state.showDebrief);

  // Level-specific mini-puzzle states
  const valvePuzzleOrder = useRef<number[]>([]);

  // Start of Level configuration
  useEffect(() => {
    const cfg = LEVEL_CONFIGS[currentLevel];
    if (cfg) {
      setObjective(cfg.initialObjective);
      showRadio(cfg.startRadio);
    }
  }, [currentLevel, setObjective, showRadio]);

  // Handle interaction trigger at current location
  const handleInteract = () => {
    audioEngine.playInteract();

    // ──────────────────────────────────────────
    // LEVEL 1: METER 4
    // ──────────────────────────────────────────
    if (currentLevel === 1) {
      // Beat 1: Sunita Tai at Tanker Queue (-15, 0, 80)
      if (playerPos.distanceTo(new THREE.Vector3(-15, 0, 80)) < 5.0 && currentBeat <= 1) {
        showRadio({
          id: 'L1-SUNITA',
          speaker: 'SUNITA',
          title: 'SUNITA TAI // RABALE RESIDENT',
          text: "We haven't had clean tap water in six days. The municipal tanker comes once if we're lucky, and half the neighbourhood fights for twenty litres. Meanwhile, the server plant has security guarding their intake lines.",
        });
        modifyPersistent({ trust: 5 });
        collectEvidence('EV-01', 'Colony resident testimony: 6 days without tap water, tanker rationing.');
        setBeat(2);
        setObjective('Head inside Gate 4 to the Municipal Meter Substation (-28, 0, 44).');
        return;
      }

      // Beat 2: Meter cabinet at Substation (-28, 0, 44)
      if (playerPos.distanceTo(new THREE.Vector3(-28, 0, 44)) < 4.5 && currentBeat === 2) {
        collectEvidence('EV-02', 'Municipal meter discrepancy: 28.9 L/s raw draw vs 5.8 L/s logged on SCADA.');
        showRadio({
          id: 'L1-METER',
          speaker: 'MEERA',
          title: 'MEERA JOSHI // MPCB COORDINATOR',
          text: "Look at the dial: 28.9 L/s continuous intake! SCADA telemetry sent to state regulators claims only 5.8 L/s. Now scan the manifold behind the building to trace where the unmetered balance is routing.",
        });
        setBeat(3);
        setObjective('Scan the raw intake pipe behind the substation (-32, 0, 42).');
        return;
      }

      // Beat 3: Scan unmetered bypass pipe behind substation
      if (playerPos.distanceTo(new THREE.Vector3(-32, 0, 42)) < 5.0 && currentBeat === 3) {
        collectEvidence('EV-03', 'Physical bypass trace: 1200mm unmetered direct line feeding cooling basins.');
        showRadio({
          id: 'L1-ROHAN-WARNING',
          speaker: 'ROHAN',
          title: 'ROHAN VAIDYA // FACILITY DIRECTOR',
          text: "Whatever you think you're scanning, step back. You're authorized for paperwork only. Don't touch that bypass valve or you'll trigger an operational cascade.",
        });
        setBeat(4);
        setObjective('Access the substation control console (-28, 0, 44) to resolve the bypass.');
        return;
      }

      // Beat 4: Console Decision at Substation
      if (playerPos.distanceTo(new THREE.Vector3(-28, 0, 44)) < 4.5 && currentBeat >= 4) {
        openDecisionCard({
          title: 'UNMETERED BYPASS DETECTED // 28.9 L/S',
          subtitle: 'The bypass draws 2.5 MLD directly from the municipal reservoir. What is your call?',
          options: [
            {
              key: 'A',
              title: 'CLOSE IT NOW',
              description: 'Shut the bypass valve immediately. Water intake drops, but cooling basins risk starvation.',
              effects: { w: '↓↓↓', h: '↑↑↑', t: '↑', s: '↓' },
            },
            {
              key: 'B',
              title: 'THROTTLE COMPUTE 30%',
              description: 'Reduce batch server loads. Moderate water savings, keeps bypass open temporarily.',
              effects: { w: '↓', h: '↓', s: '↓↓' },
            },
            {
              key: 'C',
              title: 'LOG AND REPORT',
              description: 'Document the evidence with MPCB. Leave line open to preserve paper trail.',
              effects: { t: '↑↑' },
            },
          ],
          onSelect: (opt) => {
            if (opt === 'A') {
              modifyPersistent({ trust: 10, sla: -10 });
              setSimInputs({ throttlePct: 0 });
              useGameStore.setState({
                activeTimers: {
                  ...useGameStore.getState().activeTimers,
                  scramble: { remaining: 90, active: true },
                },
              });
            } else if (opt === 'B') {
              modifyPersistent({ pressure: 15, sla: -20 });
              setSimInputs({ throttlePct: 30 });
            } else {
              modifyPersistent({ trust: 15, pressure: -10 });
              collectEvidence('EV-04', 'Formal MPCB notification log filed with verified intake photos.');
            }

            showDebrief({
              levelNumber: 1,
              title: 'LEVEL 1 COMPLETE: METER 4 RESOLUTION',
              summary:
                opt === 'A'
                  ? 'Bypass closed immediately. Basins are draining fast — a 90-second emergency scramble is underway to align Server Hall A.'
                  : opt === 'B'
                  ? 'Batch compute throttled by 30%. Rohan is furious about SLA violations, but thermal load is dampened.'
                  : 'Evidence submitted to MPCB. Paper trail secured without operational trip.',
              deltas: {
                potableMLD: opt === 'A' ? '-1.80 MLD' : '-0.60 MLD',
                junctionTemp: opt === 'A' ? '+5.2 °C' : '-3.1 °C',
                pue: '1.150',
                creekEffluent: '0.50 MLD',
                trustDelta: '+10%',
                slaDelta: opt === 'A' ? '-10%' : opt === 'B' ? '-20%' : '0%',
              },
              onContinue: () => {},
            });
          },
        });
        return;
      }
    }

    // ──────────────────────────────────────────
    // LEVEL 2: EIGHTY-FIVE
    // ──────────────────────────────────────────
    if (currentLevel === 2) {
      // Enter Server Hall A door at (-15, 0, -25)
      if (playerPos.distanceTo(new THREE.Vector3(-15, 0, -25)) < 4.5 && currentBeat <= 1) {
        setBeat(2);
        showRadio({
          id: 'L2-HALL-ENTER',
          speaker: 'ROHAN',
          title: 'ROHAN VAIDYA // FACILITY DIRECTOR',
          text: "You're inside the pump gallery. Realign the bypass valves V1, V2, V5. Check thermal highlights to find the correct sequence before silicon heats past 85°C.",
        });
        setObjective('Realign the 3 pump gallery valves (Open V2, then V5, then Close V1).');
        return;
      }

      // Valve Alignment puzzle at Pump Gallery (-25, 0, -25)
      if (playerPos.distanceTo(new THREE.Vector3(-25, 0, -25)) < 6.0 && currentBeat === 2) {
        // Toggle sequence
        valvePuzzleOrder.current.push(2);
        audioEngine.playSelect();

        if (valvePuzzleOrder.current.length >= 3) {
          audioEngine.playLevelComplete();
          setBeat(3);
          showRadio({
            id: 'L2-VALVES-ALIGNED',
            speaker: 'MEERA',
            title: 'MEERA JOSHI // MPCB COORDINATOR',
            text: "Valve sequence locked. Auxiliary cooling loop engaged. Now head to the Server Hall master console at (-30, 0, -25) to commit a thermal stopgap.",
          });
          setObjective('Access Server Hall console (-30, 0, -25) for cooling stopgap.');
        }
        return;
      }

      // Hall console decision at (-30, 0, -25)
      if (playerPos.distanceTo(new THREE.Vector3(-30, 0, -25)) < 5.0 && currentBeat >= 3) {
        openDecisionCard({
          title: 'JUNCTION TEMP SPIKING // SILICON AT 84°C',
          subtitle: 'Emergency stopgap required to prevent thermal runaway. Select cooling measure:',
          options: [
            {
              key: 'A',
              title: 'FLOOD TOWERS WITH MAKEUP WATER',
              description: 'Emergency cold water flood. Rapid cool down, but consumes massive water budget.',
              effects: { h: '↓↓↓', w: '↑↑↑', t: '↓↓' },
            },
            {
              key: 'B',
              title: 'SHED 20% COMPUTE LOAD',
              description: 'Drop domestic batch jobs. Sensitive national data cannot route offshore.',
              effects: { h: '↓↓', s: '↓↓', w: '↓' },
            },
            {
              key: 'C',
              title: 'BRING IN DRY BACKUP UNITS',
              description: 'Engage in-row dry coolers. Zero water penalty, but massive electrical power spike.',
              effects: { h: '↓', p: '↑↑↑' },
            },
          ],
          onSelect: (opt) => {
            if (opt === 'A') {
              modifyPersistent({ trust: -10 });
              setSimInputs({ makeupFloodMultiplier: 1.65 });
            } else if (opt === 'B') {
              modifyPersistent({ sla: -20 });
              setSimInputs({ throttlePct: 20 });
            } else {
              setSimInputs({ extraAuxMW: 12, evapShareOverride: 0.35 });
            }

            showDebrief({
              levelNumber: 2,
              title: 'LEVEL 2 DEBRIEF: THERMAL RUNAWAY CONTAINED',
              summary:
                opt === 'A'
                  ? 'Towers flooded with emergency municipal water. Silicon temperature dropped back to 68°C, but colony taps have dried completely.'
                  : opt === 'B'
                  ? 'Batch compute shed. National workloads prioritized. SLA slipped by 20%, but no water was wasted.'
                  : 'In-row dry coolers activated. Power consumption spiked by 12 MW, pushing PUE to 1.27.',
              deltas: {
                potableMLD: opt === 'A' ? '+1.65 MLD' : '0.00 MLD',
                junctionTemp: '-12.4 °C',
                pue: opt === 'C' ? '1.270' : '1.150',
                creekEffluent: '0.65 MLD',
                trustDelta: opt === 'A' ? '-10%' : '+5%',
                slaDelta: opt === 'B' ? '-20%' : '0%',
              },
              onContinue: () => {},
            });
          },
        });
        return;
      }
    }

    // ──────────────────────────────────────────
    // LEVEL 3: BLOWDOWN
    // ──────────────────────────────────────────
    if (currentLevel === 3) {
      // Approach outfall canal (50, 0, -20)
      if (playerPos.distanceTo(new THREE.Vector3(50, 0, -20)) < 6.0 && currentBeat <= 1) {
        collectEvidence('EV-05', 'Creek telemetry: Dissolved Oxygen 2.2 mg/L (Critical), TDS 2470 ppm, Temp 46°C.');
        showRadio({
          id: 'L3-SAMPLED',
          speaker: 'MEERA',
          title: 'DR. ANANYA SEN // COMPLIANCE',
          text: "Water sample complete: TDS 2470 ppm, temperature 46°C, dissolved oxygen collapsed at 2.2 mg/L. The blowdown valve at (40, 0, -20) is stuck wide open.",
        });
        setBeat(2);
        setObjective('Reach the seized blowdown valve at (40, 0, -20) and dislodge it.');
        return;
      }

      // Blowdown valve at (40, 0, -20)
      if (playerPos.distanceTo(new THREE.Vector3(40, 0, -20)) < 5.0 && currentBeat >= 2) {
        openDecisionCard({
          title: 'BASIN TDS 2470 PPM // OUTFALL DISCHARGE RUNNING',
          subtitle: 'Chemical-laden cooling blowdown is pouring into Thane Creek. Choose mitigation:',
          options: [
            {
              key: 'A',
              title: 'EMERGENCY ZLD ACTIVATION',
              description: 'Route all blowdown through Zero Liquid Discharge train. Reclaims 98% water.',
              effects: { c: '↑↑↑', w: '↓', p: '↓↓' },
              costBudget: 20,
            },
            {
              key: 'B',
              title: 'DILUTE AND DISCHARGE',
              description: 'Mix blowdown with fresh municipal water. Dilutes ppm, but total toxin mass leaves.',
              effects: { c: '↑', w: '↑↑' },
              costBudget: 5,
            },
            {
              key: 'C',
              title: 'SEAL VALVE AND HOLD',
              description: 'Shut valve completely without treatment. Starts a 4-minute Sump Overflow timer.',
              effects: { c: '↑↑' },
            },
          ],
          onSelect: (opt) => {
            if (opt === 'A') {
              modifyPersistent({ budget: -20, trust: 15 });
              setSimInputs({ zld: true });
            } else if (opt === 'B') {
              modifyPersistent({ budget: -5, trust: -10 });
            } else {
              useGameStore.setState({
                activeTimers: {
                  ...useGameStore.getState().activeTimers,
                  sump: { remaining: 240, active: true },
                },
              });
            }

            showDebrief({
              levelNumber: 3,
              title: 'LEVEL 3 DEBRIEF: BLOWDOWN MITIGATION',
              summary:
                opt === 'A'
                  ? 'Zero Liquid Discharge crystallisers fired up. Effluent discharge dropped to 0 MLD. Distillate returned to cooling loop.'
                  : opt === 'B'
                  ? 'Dilution streams activated. Water readings appear within regulatory limits on paper, but chemical mass was dumped.'
                  : 'Outfall valve sealed. Effluent redirected into retention basin. A 4-minute countdown has begun before the sump overflows.',
              deltas: {
                potableMLD: opt === 'A' ? '-0.45 MLD' : '+0.50 MLD',
                junctionTemp: '71.5 °C',
                pue: opt === 'A' ? '1.185' : '1.150',
                creekEffluent: opt === 'A' ? '0.00 MLD' : '0.50 MLD',
                trustDelta: opt === 'A' ? '+15%' : '-10%',
                slaDelta: '0%',
              },
              onContinue: () => {},
            });
          },
        });
        return;
      }
    }

    // ──────────────────────────────────────────
    // LEVEL 4: REBUILD
    // ──────────────────────────────────────────
    if (currentLevel === 4) {
      if (playerPos.distanceTo(new THREE.Vector3(20, 0, 10)) < 5.0) {
        openDecisionCard({
          title: 'MASTER COOLING RE-ENGINEERING // PRE-DAWN',
          subtitle: `Available Budget: ₹${persistent.budget} L (Evidence bonus applied). Commit permanent architecture:`,
          options: [
            {
              key: 'A',
              title: 'FULL DTC CONVERSION',
              description: 'Direct-to-chip dielectric liquid cooling. 80% water reduction, superb heat transfer.',
              effects: { w: '↓↓↓', p: '↓', h: '↓↓' },
              costBudget: 40,
              minEvidence: 3,
            },
            {
              key: 'B',
              title: 'HYBRID WITH STP SEWAGE WATER',
              description: 'Switch evaporative cooling to treated municipal sewage. Zero potable drinking water used.',
              effects: { w: '↓↓↓', c: '↑' },
              costBudget: 20,
            },
            {
              key: 'C',
              title: 'OPTIMISE EXISTING TOWERS',
              description: 'Patch seals, tune fan variable frequency drives, and apply 10% permanent compute throttle.',
              effects: { w: '↓', h: '↓' },
              costBudget: 10,
            },
          ],
          onSelect: (opt) => {
            if (opt === 'A') {
              modifyPersistent({ budget: -40, trust: 25 });
              setSimInputs({ topology: 'DTC', zld: true });
            } else if (opt === 'B') {
              modifyPersistent({ budget: -20, trust: 20 });
              setSimInputs({ waterSource: 'STP' });
            } else {
              modifyPersistent({ budget: -10, trust: 5 });
              setSimInputs({ throttlePct: 10 });
            }

            // Reset sump timer if running
            useGameStore.setState({
              activeTimers: {
                ...useGameStore.getState().activeTimers,
                sump: null,
              },
            });

            showDebrief({
              levelNumber: 4,
              title: 'LEVEL 4 DEBRIEF: RE-ENGINEERING COMMITTED',
              summary:
                opt === 'A'
                  ? 'Facility transitioned to Direct-to-Chip architecture. Potable water intake plummeted to 0 MLD. Basin load eliminated.'
                  : opt === 'B'
                  ? 'Intake valves swapped to secondary treated sewage from Rabale STP. Municipal drinking water lines isolated.'
                  : 'Existing towers tuned. Power and water trimmed marginally.',
              deltas: {
                potableMLD: opt === 'A' || opt === 'B' ? '0.00 MLD' : '1.80 MLD',
                junctionTemp: opt === 'A' ? '64.0 °C' : '71.5 °C',
                pue: opt === 'A' ? '1.220' : '1.150',
                creekEffluent: '0.00 MLD',
                trustDelta: '+20%',
                slaDelta: '0%',
              },
              onContinue: () => {},
            });
          },
        });
        return;
      }
    }

    // ──────────────────────────────────────────
    // LEVEL 5: DAWN AUDIT
    // ──────────────────────────────────────────
    if (currentLevel === 5) {
      if (playerPos.distanceTo(new THREE.Vector3(0, 0, 58)) < 5.0) {
        openDecisionCard({
          title: 'MPCB STATE INSPECTION // DAWN AUDIT',
          subtitle: `Inspector Dr. Kulkarni has arrived. Evidence held: ${persistent.evidence}/6. Choose your audit posture:`,
          options: [
            {
              key: 'A',
              title: 'FULL DISCLOSURE',
              description: 'Submit all evidence, expose historical bypass, present the new clean architecture.',
              effects: { t: '↑↑', s: '↓' },
              minEvidence: 4,
            },
            {
              key: 'B',
              title: 'PARTIAL COMPLIANCE',
              description: 'Present only current compliant numbers, bury bypass log. Facility avoids penalties.',
              effects: { s: '↑' },
            },
            {
              key: 'C',
              title: 'PUBLIC WHISTLEBLOW',
              description: 'Transmit complete telemetry dossier directly to Meera Joshi and state press corps.',
              effects: { t: '↑↑↑' },
              minEvidence: 5,
            },
          ],
          onSelect: (opt) => {
            if (opt === 'A') {
              modifyPersistent({ trust: 30, sla: -10 });
            } else if (opt === 'B') {
              modifyPersistent({ trust: -15, pressure: 20 });
            } else {
              modifyPersistent({ trust: 40, sla: -50, pressure: -40 });
            }

            useGameStore.getState().triggerGameComplete();
          },
        });
        return;
      }
    }
  };

  // Listen to keyboard 'E'
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.code === 'KeyE') {
        handleInteract();
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  });

  return null;
};
