import type { RadioMessage } from '../../store/gameStore';

export interface LevelConfig {
  number: number;
  title: string;
  timeStr: string;
  skyMood: string;
  startRadio: RadioMessage;
  initialObjective: string;
}

export const LEVEL_CONFIGS: Record<number, LevelConfig> = {
  1: {
    number: 1,
    title: 'METER 4',
    timeStr: '16:30',
    skyMood: 'Harsh afternoon haze, 42°C feel',
    startRadio: {
      id: 'L1-START',
      speaker: 'MEERA',
      title: 'MEERA JOSHI // MPCB COORDINATOR',
      text: "You're on site under an emergency inspection warrant. Reservoir's at 14 percent. Tankers are queuing outside while this place draws millions of litres. Find Sunita tai at the colony queue, then check the municipal meter at the substation.",
    },
    initialObjective: 'Walk outside Gate 4 to Rabale colony (-15, 0, 80). Interview Sunita tai.',
  },
  2: {
    number: 2,
    title: 'EIGHTY-FIVE',
    timeStr: '19:00',
    skyMood: 'Dusk orange smog, perimeter floodlights active',
    startRadio: {
      id: 'L2-START',
      speaker: 'ROHAN',
      title: 'ROHAN VAIDYA // FACILITY DIRECTOR',
      text: "We have an emergency. Pump A primary mechanical seal just sheared in Server Hall A. Junction temperatures are spiking toward 85°C. Get inside and realign the pump gallery before we trip thermal runaway.",
    },
    initialObjective: 'Enter Server Hall A (-15, 0, -25). Realign pump gallery valves.',
  },
  3: {
    number: 3,
    title: 'BLOWDOWN',
    timeStr: '23:00',
    skyMood: 'Deep night, sodium streetlights, toxic chemical vapour over canal',
    startRadio: {
      id: 'L3-START',
      speaker: 'MEERA',
      title: 'MEERA JOSHI // MPCB COORDINATOR',
      text: "Sensors down at Thane Creek just flagged dissolved oxygen at 2.2 mg/L. Legal limit is 4.0. The creek is suffocating. Find the outfall canal at the east perimeter.",
    },
    initialObjective: 'Proceed to outfall canal (50, 0, -20). Sample discharge and inspect blowdown valve.',
  },
  4: {
    number: 4,
    title: 'REBUILD',
    timeStr: '03:00',
    skyMood: 'Pre-dawn dead calm, silent compound',
    startRadio: {
      id: 'L4-START',
      speaker: 'MEERA',
      title: 'TARA D\'SOUZA // SCADA SPECIALIST',
      text: "We have an overhaul window before dawn audit. Management allocated emergency remediation capital. Head into the SCADA Hub at (20, 0, 10) to re-engineer the cooling train.",
    },
    initialObjective: 'Enter SCADA Hub (20, 0, 10). Reconfigure cooling topology before sunrise.',
  },
  5: {
    number: 5,
    title: 'DAWN AUDIT',
    timeStr: '06:05',
    skyMood: 'Sunrise horizon, high tension',
    startRadio: {
      id: 'L5-START',
      speaker: 'MEERA',
      title: 'MEERA JOSHI // MPCB COORDINATOR',
      text: "Dr. Kulkarni just pulled up at Gate 4 in the state inspection vehicle. Walk up to the audit stage. Whatever evidence you collected tonight is what we bring to the table.",
    },
    initialObjective: 'Meet MPCB Inspector Dr. Kulkarni at the audit stage (0, 0, 58).',
  },
};
