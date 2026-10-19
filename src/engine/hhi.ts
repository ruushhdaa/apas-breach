import type { SimOutputs } from './simulation';

export type HHITier = 'COLLAPSE' | 'CRITICAL' | 'STRAINED' | 'RECOVERING' | 'RESTORED';

export interface HHIComponents {
  water: number;   // 0 to 1
  creek: number;   // 0 to 1
  thermal: number; // 0 to 1
  energy: number;  // 0 to 1
  trust: number;   // 0 to 1
}

export interface HHITierConfig {
  name: HHITier;
  label: string;
  min: number;
  max: number;
  skyColorHex: string;
  skyColor: number;
  fogDensity: number;
  steamSpawnRate: number; // 0.10 to 1.00
  creekColor: number;
  creekOpacity: number;
}

export const HHI_TIERS: Record<HHITier, HHITierConfig> = {
  COLLAPSE: {
    name: 'COLLAPSE',
    label: 'SYSTEM COLLAPSE',
    min: 0,
    max: 24,
    skyColorHex: '#0A0800',
    skyColor: 0x0a0800,
    fogDensity: 0.040,
    steamSpawnRate: 1.0,
    creekColor: 0x1f160e, // Dark murky sludge
    creekOpacity: 0.95,
  },
  CRITICAL: {
    name: 'CRITICAL',
    label: 'CRITICAL STRESS',
    min: 25,
    max: 44,
    skyColorHex: '#1A0A00',
    skyColor: 0x1a0a00,
    fogDensity: 0.030,
    steamSpawnRate: 0.85,
    creekColor: 0x3d2b1f, // Murky brown
    creekOpacity: 0.88,
  },
  STRAINED: {
    name: 'STRAINED',
    label: 'STRAINED OPERATION',
    min: 45,
    max: 64,
    skyColorHex: '#2E2010',
    skyColor: 0x2e2010,
    fogDensity: 0.022,
    steamSpawnRate: 0.60,
    creekColor: 0x47432b, // Cloudy green-brown
    creekOpacity: 0.70,
  },
  RECOVERING: {
    name: 'RECOVERING',
    label: 'RECOVERING BASIN',
    min: 65,
    max: 84,
    skyColorHex: '#2C3A1A',
    skyColor: 0x2c3a1a,
    fogDensity: 0.014,
    steamSpawnRate: 0.35,
    creekColor: 0x2b4a3a, // Greenish clear
    creekOpacity: 0.45,
  },
  RESTORED: {
    name: 'RESTORED',
    label: 'BASIN RESTORED',
    min: 85,
    max: 100,
    skyColorHex: '#1A3A5C',
    skyColor: 0x1a3a5c,
    fogDensity: 0.008,
    steamSpawnRate: 0.10,
    creekColor: 0x1a4568, // Clear reflective blue
    creekOpacity: 0.25,
  },
};

function clamp01(v: number): number {
  return Math.min(1, Math.max(0, v));
}

export function calculateHHI(
  sim: SimOutputs,
  trustScore: number, // 0 to 100
  toxicityIndex: number = 1.0
): { hhi: number; components: HHIComponents; tier: HHITierConfig } {
  // 1. Water component: 1 - clamp(potableMLD / 2.5)
  const water = 1 - clamp01(sim.potableMLD / 2.5);

  // 2. Creek component: 1 - clamp(effluentMLD * toxicity / 0.5)
  const creek = 1 - clamp01((sim.effluentMLD * toxicityIndex) / 0.5);

  // 3. Thermal component: Tj <= 75 -> 1; Tj >= 90 -> 0; linear between
  let thermal = 1;
  if (sim.junctionTempC >= 90) {
    thermal = 0;
  } else if (sim.junctionTempC > 75) {
    thermal = 1 - (sim.junctionTempC - 75) / 15;
  }
  thermal = clamp01(thermal);

  // 4. Energy component: clamp((1.6 - PUE) / 0.45)
  const energy = clamp01((1.6 - sim.pue) / 0.45);

  // 5. Trust component: Trust / 100
  const trust = clamp01(trustScore / 100);

  // Weighted sum (0 to 100)
  const hhiRaw = 100 * (
    0.30 * water +
    0.25 * creek +
    0.20 * thermal +
    0.15 * energy +
    0.10 * trust
  );

  const hhi = Math.round(hhiRaw * 10) / 10;
  const tier = getHHITier(hhi);

  return {
    hhi,
    components: { water, creek, thermal, energy, trust },
    tier,
  };
}

export function getHHITier(hhi: number): HHITierConfig {
  if (hhi <= 24) return HHI_TIERS.COLLAPSE;
  if (hhi <= 44) return HHI_TIERS.CRITICAL;
  if (hhi <= 64) return HHI_TIERS.STRAINED;
  if (hhi <= 84) return HHI_TIERS.RECOVERING;
  return HHI_TIERS.RESTORED;
}
