// APAS : BREACH — Physics & Simulation Engine
// Pure TypeScript, no React, no side effects.

export type CoolingTopology = 'HYBRID_EVAP' | 'DRY' | 'DTC';
export type WaterSource = 'POTABLE' | 'STP';

export interface SimInputs {
  itLoadMW: number;            // Default 100 MW
  throttlePct: number;         // 0 to 50%
  topology: CoolingTopology;   // HYBRID_EVAP, DRY, DTC
  waterSource: WaterSource;     // POTABLE, STP
  zld: boolean;                // Zero Liquid Discharge train active
  evapShareOverride?: number;  // Optional manual override
  extraAuxMW: number;          // Additional auxiliary equipment power
  makeupFloodMultiplier: number; // For emergency cooling flood (e.g. 1.65)
  cocOverride?: number;        // Optional Cycles of Concentration override
  toxicityIndex: number;       // Chemical toxicity multiplier (1.0 default)
}

export interface SimOutputs {
  itLoadNetMW: number;
  heatMW: number;
  evapShare: number;
  evapRateLs: number;          // E (L/s)
  blowdownRateLs: number;      // B (L/s)
  driftRateLs: number;         // Drift (L/s)
  withdrawalLs: number;        // Total water intake (L/s)
  recoveredLs: number;         // Water recovered by ZLD (L/s)
  potableMLD: number;          // Potable water draw (Million Litres/Day)
  totalWaterMLD: number;       // Total water draw (Million Litres/Day)
  consumptionMLD: number;      // Evaporated water (Million Litres/Day)
  effluentMLD: number;         // Discharged wastewater to creek (Million Litres/Day)
  basinTDS: number;            // Basin total dissolved solids (ppm)
  junctionTempC: number;       // Tj (°C)
  pue: number;                 // Power Usage Effectiveness
  wuePotable: number;          // L / IT kWh (potable)
  wueTotal: number;            // L / IT kWh (total)
  auxMW: number;
  zldMW: number;
  saltCakeTonsPerDay: number;
}

export const SIM_CONSTANTS = {
  heatFraction: 0.985,
  latentHeatMJkg: 2.26,        // 2.26 MJ/kg of water
  driftFraction: 0.005,        // 0.5% of evaporation
  zldEnergyKwhPerM3: 45,       // 45 kWh / m³ blowdown
  zldRecoveryRate: 0.98,       // 98% condensate recovered
};

export const TOPOLOGY_PARAMS: Record<CoolingTopology, {
  evapShare: number;
  auxFraction: number;
  coolantTempC: number;
  tempRiseC: number;
}> = {
  HYBRID_EVAP: {
    evapShare: 0.528,
    auxFraction: 0.15,
    coolantTempC: 22,
    tempRiseC: 49.5,
  },
  DRY: {
    evapShare: 0.0,
    auxFraction: 0.48,
    coolantTempC: 34,
    tempRiseC: 45.8,
  },
  DTC: {
    evapShare: 0.45,
    auxFraction: 0.22,
    coolantTempC: 18,
    tempRiseC: 46.0,
  },
};

export const SOURCE_PARAMS: Record<WaterSource, {
  makeupTDS: number;
  coc: number;
}> = {
  POTABLE: {
    makeupTDS: 180,
    coc: 5.0,
  },
  STP: {
    makeupTDS: 650,
    coc: 3.8,
  },
};

export const DEFAULT_SIM_INPUTS: SimInputs = {
  itLoadMW: 100,
  throttlePct: 0,
  topology: 'HYBRID_EVAP',
  waterSource: 'POTABLE',
  zld: false,
  extraAuxMW: 0,
  makeupFloodMultiplier: 1.0,
  toxicityIndex: 1.0,
};

export function runSimulation(inputs: SimInputs): SimOutputs {
  const top = TOPOLOGY_PARAMS[inputs.topology];
  const src = SOURCE_PARAMS[inputs.waterSource];

  const effectiveItMW = inputs.itLoadMW * (1 - Math.min(0.5, Math.max(0, inputs.throttlePct)) / 100);
  const heatMW = effectiveItMW * SIM_CONSTANTS.heatFraction;

  const evapShare = inputs.evapShareOverride !== undefined ? inputs.evapShareOverride : top.evapShare;
  const coc = inputs.cocOverride !== undefined ? inputs.cocOverride : src.coc;

  // Evaporation rate E in L/s: (heatMW * evapShare) / 2.26
  let evapRateLs = (heatMW * evapShare) / SIM_CONSTANTS.latentHeatMJkg;
  evapRateLs *= inputs.makeupFloodMultiplier;

  // Blowdown B in L/s: E / (CoC - 1)
  const blowdownRateLs = coc > 1 ? evapRateLs / (coc - 1) : 0;

  // Drift in L/s: 0.005 * E
  const driftRateLs = SIM_CONSTANTS.driftFraction * evapRateLs;

  // ZLD calculation
  let recoveredLs = 0;
  let zldMW = 0;
  let effluentLs = blowdownRateLs;
  let saltCakeTonsPerDay = 0;

  // Basin TDS = makeupTDS * CoC
  const basinTDS = src.makeupTDS * coc;

  if (inputs.zld && blowdownRateLs > 0) {
    recoveredLs = blowdownRateLs * SIM_CONSTANTS.zldRecoveryRate;
    effluentLs = blowdownRateLs - recoveredLs; // Remaining 2% as brine/slurry
    // Energy cost: 45 kWh/m³
    const blowdownM3PerHr = (blowdownRateLs * 3600) / 1000;
    zldMW = (blowdownM3PerHr * SIM_CONSTANTS.zldEnergyKwhPerM3) / 1000;

    // Salt mass: blowdown m³ * (basinTDS mg/L / 1000 g / 1000 kg)
    const blowdownM3PerDay = (blowdownRateLs * 86400) / 1000;
    saltCakeTonsPerDay = (blowdownM3PerDay * basinTDS * 1e-6);
  }

  // Net withdrawal rate = E + B + drift - recovered
  const withdrawalLs = evapRateLs + blowdownRateLs + driftRateLs - recoveredLs;

  // Conversion to MLD (Million Litres per Day): L/s * 86,400 s/day / 1,000,000 L/ML = L/s * 0.0864
  const totalWaterMLD = (withdrawalLs * 86.4) / 1000;
  const potableMLD = inputs.waterSource === 'POTABLE' ? totalWaterMLD : 0;
  const consumptionMLD = ((evapRateLs + driftRateLs) * 86.4) / 1000;
  const effluentMLD = inputs.zld ? 0 : (effluentLs * 86.4) / 1000;

  // Junction Temperature Tj = coolant + rise * (IT / 100)
  const junctionTempC = top.coolantTempC + top.tempRiseC * (effectiveItMW / 100);

  // Aux Power = auxFraction * IT
  const auxMW = top.auxFraction * effectiveItMW;

  // PUE = (IT + aux + extraAux + zldMW) / IT
  const pue = effectiveItMW > 0
    ? (effectiveItMW + auxMW + inputs.extraAuxMW + zldMW) / effectiveItMW
    : 1.0;

  // Water Use Effectiveness (WUE) in L / IT kWh
  // IT kWh per second = effectiveItMW * 1000 kW / 3600 h = effectiveItMW / 3.6
  const itKwhPerSec = (effectiveItMW * 1000) / 3600;
  const wuePotable = itKwhPerSec > 0 && inputs.waterSource === 'POTABLE' ? withdrawalLs / itKwhPerSec : 0;
  const wueTotal = itKwhPerSec > 0 ? withdrawalLs / itKwhPerSec : 0;

  return {
    itLoadNetMW: effectiveItMW,
    heatMW,
    evapShare,
    evapRateLs,
    blowdownRateLs,
    driftRateLs,
    withdrawalLs,
    recoveredLs,
    potableMLD,
    totalWaterMLD,
    consumptionMLD,
    effluentMLD,
    basinTDS,
    junctionTempC,
    pue,
    wuePotable,
    wueTotal,
    auxMW,
    zldMW,
    saltCakeTonsPerDay,
  };
}
