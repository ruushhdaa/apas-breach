class_name FieldNotesData
extends RefCounted

const NOTES = [
	{
		"id": 1,
		"title": "NOTE 01 — WATER INTENSITY IN HYPERSCALE COOLING",
		"content": "Modern hyperscale data centres with evaporative cooling consume approximately 1.0 to 5.0 litres of water for every kilowatt-hour (kWh) of compute energy delivered. In high-density facilities, this translates to millions of litres per day drawn from local water grids.",
		"source": "TODO_VERIFY: Cooling tower water consumption metrics, 2024"
	},
	{
		"id": 2,
		"title": "NOTE 02 — EVAPORATIVE VS AIR COOLING TRADEOFF",
		"content": "Evaporative cooling achieves a lower PUE (~1.15) by exploiting the latent heat of water vaporisation (2.26 MJ/kg). Pure dry air cooling avoids water consumption entirely, but increases fan and chiller auxiliary load, raising PUE to 1.45–1.60 in hot ambient climates.",
		"source": "TODO_VERIFY: ASHRAE TC 9.9 Thermal Guidelines for Data Processing Environments"
	},
	{
		"id": 3,
		"title": "NOTE 03 — THERMAL EFFLUENT & ESTUARINE HEALTH",
		"content": "Discharging cooling tower blowdown at elevated temperatures (above 38°C) into shallow estuarine waters creates a thermal barrier. Thermal pollution reduces dissolved gas solubility and destabilises benthic micro-ecosystems.",
		"source": "TODO_VERIFY: Central Pollution Control Board (CPCB) Thermal Discharge Standards"
	},
	{
		"id": 4,
		"title": "NOTE 04 — DISSOLVED OXYGEN THRESHOLDS",
		"content": "Dissolved Oxygen (DO) below 4.0 mg/L induces severe hypoxia in estuarine fish and crustacean larvae. At DO levels under 2.0 mg/L, mass fish mortality and toxic anaerobic decomposition accelerate along mudflat banks.",
		"source": "TODO_VERIFY: Maharashtra Pollution Control Board Water Quality Criteria"
	},
	{
		"id": 5,
		"title": "NOTE 05 — MUMBAI METROPOLITAN REGION WATER STRESS",
		"content": "The Thane-Belapur and Rabale industrial belts share municipal supply pipelines with dense urban settlements. When large industrial users divert potable municipal water without sanction, surrounding colonies face acute rationing and tanker dependency.",
		"source": "TODO_VERIFY: Navi Mumbai Municipal Corporation (NMMC) Water Supply Master Plan"
	},
	{
		"id": 6,
		"title": "NOTE 06 — GLOBAL DATA CENTRE WATER FOOTPRINT",
		"content": "Worldwide data centre water withdrawal is estimated to exceed 200 billion litres annually. As AI compute clusters expand, localized water footprints increasingly concentrate in already stressed municipal watersheds.",
		"source": "TODO_VERIFY: Nature NPJ Clean Water — Environmental footprints of AI infrastructure"
	},
	{
		"id": 7,
		"title": "NOTE 07 — ZERO LIQUID DISCHARGE (ZLD) TECHNOLOGY",
		"content": "ZLD installations combine reverse osmosis and multi-effect thermal evaporators to recover up to 98% of process blowdown water. While virtually eliminating effluent discharge, ZLD requires substantial additional electricity (1.5–3.0 MW per facility).",
		"source": "TODO_VERIFY: Industrial Water Treatment Manual — CPCB Guidelines on ZLD"
	},
	{
		"id": 8,
		"title": "NOTE 08 — THANE CREEK FLAMINGO SANCTUARY",
		"content": "Thane Creek is a declared Ramsar wetland and winter sanctuary for over 100,000 Lesser and Greater Flamingos (Phoenicopterus roseus). Mudflat algae and benthic crustaceans form their primary food web, vulnerable to salinity and chemical spikes.",
		"source": "TODO_VERIFY: Thane Creek Flamingo Sanctuary Management Plan"
	},
	{
		"id": 9,
		"title": "NOTE 09 — STP WATER RECYCLING & CIRCULARITY",
		"content": "Sewage Treatment Plant (STP) tertiary-treated water provides a viable alternative makeup source for cooling towers. Utilizing STP water frees municipal potable supply for human consumption while requiring higher filtration to manage organic fouling.",
		"source": "TODO_VERIFY: Ministry of Jal Shakti Circular Economy Guidelines"
	},
	{
		"id": 10,
		"title": "NOTE 10 — PUE METRIC INTERPRETATION",
		"content": "Power Usage Effectiveness (PUE) measures total facility power divided by IT compute power. A PUE of 1.15 represents top-tier energy efficiency, but low PUE achieved purely via water evaporation can mask excessive hydrological consumption.",
		"source": "TODO_VERIFY: Green Grid PUE Technical Standard"
	},
	{
		"id": 11,
		"title": "NOTE 11 — BLOWDOWN TOTAL DISSOLVED SOLIDS (TDS)",
		"content": "Cooling tower evaporation concentrates dissolved minerals. Blowdown water typically exhibits TDS between 900 and 3000 ppm. Estuarine discharge limits in sensitive creek zones require TDS not to exceed 2100 ppm.",
		"source": "TODO_VERIFY: Environment (Protection) Rules — Effluent Standards for Industrial Waters"
	},
	{
		"id": 12,
		"title": "NOTE 12 — RAPID CLUSTER EXPANSION IN MAHARASHTRA",
		"content": "The Navi Mumbai and Thane data centre corridor accounts for over 50% of upcoming hyperscale capacity in India, driven by submarine cable landings. Infrastructure clustering creates severe hyper-localized utility competition.",
		"source": "TODO_VERIFY: Knight Frank India Data Centre Market Report"
	},
	{
		"id": 13,
		"title": "NOTE 13 — CYCLES OF CONCENTRATION (CoC)",
		"content": "Cycles of Concentration measures the ratio of dissolved solids in recirculating water to makeup water. Higher CoC (4.0–6.0) reduces blowdown volume and freshwater withdrawal, but increases scaling risk on heat exchangers.",
		"source": "TODO_VERIFY: Industrial Cooling Technology Handbook"
	},
	{
		"id": 14,
		"title": "NOTE 14 — ESTUARINE DISSOLVED OXYGEN RECOVERY",
		"content": "Following a major thermal effluent or organic shock event, tidal flushing in shallow creek channels can require several weeks to restore natural dissolved oxygen saturation levels and macroinvertebrate populations.",
		"source": "TODO_VERIFY: National Institute of Oceanography (NIO) Thane Creek Ecological Survey"
	},
	{
		"id": 15,
		"title": "NOTE 15 — COMMUNITY TRUST DYNAMICS",
		"content": "When industrial facilities operate clandestine bypass connections during municipal water rationing, public transparency is irrevocably compromised. Social license to operate cannot be restored solely through regulatory compliance penalties.",
		"source": "TODO_VERIFY: Environmental Governance & Public Trust Case Studies"
	}
]
