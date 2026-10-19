// APAS : BREACH — Field Notes Codex
// 15 factual entries on data centre thermal and water systems.
// All citations marked as TODO_VERIFY for verification.

export interface FieldNote {
  id: string;
  tag: string;
  title: string;
  body: string;
  source: string;
  confidence: 'illustrative' | 'verify-before-claiming';
  levelUnlocked: number;
}

export const FIELD_NOTES: FieldNote[] = [
  {
    id: 'FN-01',
    tag: 'WATER USE // COMPUTATION',
    title: 'Water Consumption per Kilowatt-Hour',
    body: 'Hyperscale data centres consume between 1 and 5 litres of water per kilowatt-hour of compute, depending heavily on ambient climate and cooling topology.',
    source: 'TODO_VERIFY — Lawrence Berkeley National Laboratory / Industry Benchmarks',
    confidence: 'verify-before-claiming',
    levelUnlocked: 1,
  },
  {
    id: 'FN-02',
    tag: 'THERMODYNAMICS // EFFICIENCY',
    title: 'Evaporative vs Air-Cooled Systems',
    body: 'Evaporative cooling uses far less electrical power than direct air-cooled chillers because water phase change absorbs huge latent heat (2.26 MJ/kg).',
    source: 'TODO_VERIFY — ASHRAE Technical Committee 9.9 Thermal Guidelines',
    confidence: 'verify-before-claiming',
    levelUnlocked: 1,
  },
  {
    id: 'FN-03',
    tag: 'CREEK ECOLOGY // HEAT',
    title: 'Thermal Pollution in Natural Waterways',
    body: 'Discharging warm water raises creek ambient temperatures, lowering dissolved gas capacity and triggering microbial blooms that suffocate estuarine species.',
    source: 'TODO_VERIFY — Central Pollution Control Board (CPCB) Thermal Discharge Standards',
    confidence: 'verify-before-claiming',
    levelUnlocked: 1,
  },
  {
    id: 'FN-04',
    tag: 'AQUATIC BIOLOGY // DO',
    title: 'Critical Dissolved Oxygen Thresholds',
    body: 'Dissolved oxygen below 4 mg/L severely stresses fish and benthic fauna. Below 2 mg/L, hypoxia causes mass mortality in tidal creek networks.',
    source: 'TODO_VERIFY — Indian Standard IS 10500 / Marine Biodiversity Surveys',
    confidence: 'verify-before-claiming',
    levelUnlocked: 2,
  },
  {
    id: 'FN-05',
    tag: 'REGIONAL HYDROLOGY // BASIN',
    title: 'Navi Mumbai & Thane Regional Water Stress',
    body: 'During peak summer pre-monsoon months, industrial corridors draw from shared municipal reservoirs that frequently dip below 15% capacity, triggering residential tanker supply.',
    source: 'TODO_VERIFY — Maharashtra Water Resources Regulatory Authority (MWRRA)',
    confidence: 'verify-before-claiming',
    levelUnlocked: 2,
  },
  {
    id: 'FN-06',
    tag: 'GLOBAL SCALE // VOLUME',
    title: 'Global Data Centre Water Footprint',
    body: 'Global data centre infrastructure consumes approximately 200 billion litres of water annually, with direct evaporative cooling and indirect power-generation water combined.',
    source: 'TODO_VERIFY — Environmental Research Letters / Global Footprint Network',
    confidence: 'verify-before-claiming',
    levelUnlocked: 2,
  },
  {
    id: 'FN-07',
    tag: 'REMEDIATION // RECOVERY',
    title: 'Zero Liquid Discharge (ZLD) Technology',
    body: 'Thermal brine concentrators and crystallisers recover up to 98% of industrial blowdown as pure distillate, but demand 35-50 kWh of electrical energy per cubic metre processed.',
    source: 'TODO_VERIFY — Bureau of Energy Efficiency (BEE) Industrial Water Audits',
    confidence: 'verify-before-claiming',
    levelUnlocked: 3,
  },
  {
    id: 'FN-08',
    tag: 'SANCTUARY // MIGRATION',
    title: 'Thane Creek Flamingo Habitat',
    body: 'Thane Creek is a Ramsar wetland and winter feeding ground for over 100,000 Lesser and Greater Flamingos (Phoenicopterus roseus) dependent on benthic algae and brine shrimp.',
    source: 'TODO_VERIFY — Bombay Natural History Society (BNHS) Wetland Reports',
    confidence: 'verify-before-claiming',
    levelUnlocked: 3,
  },
  {
    id: 'FN-09',
    tag: 'CIRCULAR ECONOMY // STP',
    title: 'Sewage Treatment Plant (STP) Water Reuse',
    body: 'Switching cooling towers to secondary or tertiary treated municipal sewage eliminates potable water consumption, though higher mineral content lowers operating concentration cycles.',
    source: 'TODO_VERIFY — MIDC Industrial Water Circularity Guidelines',
    confidence: 'verify-before-claiming',
    levelUnlocked: 3,
  },
  {
    id: 'FN-10',
    tag: 'METRICS // TRADEOFF',
    title: 'The PUE Paradox in Hot Climates',
    body: 'A stellar Power Usage Effectiveness (PUE) of 1.15 in a 42°C climate usually conceals massive water consumption: power efficiency is achieved by evaporating local drinking water.',
    source: 'TODO_VERIFY — The Green Grid / Uptime Institute Technical Whitepapers',
    confidence: 'verify-before-claiming',
    levelUnlocked: 4,
  },
  {
    id: 'FN-11',
    tag: 'CHEMISTRY // SCALING',
    title: 'Cooling Tower Blowdown Mineral TDS',
    body: 'As pure water evaporates, dissolved solids concentrate. Blowdown water typically contains 900 to 3,000 ppm of total dissolved solids, biocides, and scale inhibitors.',
    source: 'TODO_VERIFY — Cooling Technology Institute (CTI) Water Treatment Guidelines',
    confidence: 'verify-before-claiming',
    levelUnlocked: 4,
  },
  {
    id: 'FN-12',
    tag: 'INFRASTRUCTURE // GROWTH',
    title: 'Indian Data Centre Capacity Trajectory',
    body: 'India’s operational data centre capacity is doubling approximately every 36 months, with the Mumbai-Navi Mumbai corridor hosting over 50% of the national compute density.',
    source: 'TODO_VERIFY — JLL / Cushman & Wakefield Data Centre Market Reports',
    confidence: 'verify-before-claiming',
    levelUnlocked: 4,
  },
  {
    id: 'FN-13',
    tag: 'CONTROL // CONCENTRATION',
    title: 'Cycles of Concentration (CoC)',
    body: 'Operating at higher Cycles of Concentration reduces raw water intake, but exponentially increases basin scaling risk and chemical toxicity in the effluent discharge.',
    source: 'TODO_VERIFY — NALCO Water Handbook / Industrial Heat Rejection',
    confidence: 'verify-before-claiming',
    levelUnlocked: 5,
  },
  {
    id: 'FN-14',
    tag: 'RESTORATION // LAG',
    title: 'Estuarine Dissolved Oxygen Lag',
    body: 'Once a tidal basin becomes hypoxic, dissolved oxygen recovery takes several weeks after discharge ceases, as decomposing organic matter keeps benthic oxygen demand elevated.',
    source: 'TODO_VERIFY — National Institute of Oceanography (NIO) Estuarine Studies',
    confidence: 'verify-before-claiming',
    levelUnlocked: 5,
  },
  {
    id: 'FN-15',
    tag: 'SOCIAL IMPACT // TRUST',
    title: 'Community Trust and Social Licence',
    body: 'When critical community utilities run dry while commercial neighbours consume millions of litres daily, public trust fractures irreversibly, escalating regulatory scrutiny and protests.',
    source: 'TODO_VERIFY — Centre for Science and Environment (CSE) Social Impact Audits',
    confidence: 'illustrative',
    levelUnlocked: 5,
  },
];
