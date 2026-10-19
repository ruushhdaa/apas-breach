class_name HHIEngine
extends Node

signal hhi_changed(new_hhi: float, tier_name: String)
signal tier_changed(tier_name: String)

# Tier Definitions
const TIERS = {
	"RESTORED": {
		"min": 85.0, "max": 100.0,
		"sky_color": Color("#1A3A5C"),
		"fog_color": Color("#1A3A5C"),
		"creek_color": Color("#2277BB"),
		"fog_density": 0.006,
		"steam_amount": 35,
		"label_color": Color("#44DD88")
	},
	"RECOVERING": {
		"min": 65.0, "max": 84.99,
		"sky_color": Color("#2C3A1A"),
		"fog_color": Color("#2C3A1A"),
		"creek_color": Color("#4A7A6A"),
		"fog_density": 0.012,
		"steam_amount": 25,
		"label_color": Color("#88DD44")
	},
	"STRAINED": {
		"min": 45.0, "max": 64.99,
		"sky_color": Color("#2E2010"),
		"fog_color": Color("#2E2010"),
		"creek_color": Color("#635030"),
		"fog_density": 0.022,
		"steam_amount": 18,
		"label_color": Color("#E0A020")
	},
	"CRITICAL": {
		"min": 25.0, "max": 44.99,
		"sky_color": Color("#1A0A00"),
		"fog_color": Color("#1A0A00"),
		"creek_color": Color("#382010"),
		"fog_density": 0.038,
		"steam_amount": 10,
		"label_color": Color("#F0A500")
	},
	"COLLAPSE": {
		"min": 0.0, "max": 24.99,
		"sky_color": Color("#0A0800"),
		"fog_color": Color("#0A0800"),
		"creek_color": Color("#11100D"),
		"fog_density": 0.055,
		"steam_amount": 0,
		"label_color": Color("#DD3322")
	}
}

# Current Values
var raw_hhi: float = 38.0
var current_hhi: float = 38.0
var manual_override: bool = false
var override_hhi: float = 38.0
var current_tier: String = "CRITICAL"

# Breakdown components (0.0 to 1.0)
var comp_water: float = 0.0
var comp_creek: float = 0.0
var comp_thermal: float = 1.0
var comp_energy: float = 1.0
var comp_trust: float = 0.3

func _ready() -> void:
	current_tier = get_tier_name(current_hhi)

func _process(delta: float) -> void:
	if not manual_override:
		calculate_raw()
		# Smooth over ~3 seconds
		var lerp_weight = clamp(delta / 3.0, 0.01, 1.0)
		var old_hhi = current_hhi
		current_hhi = lerp(current_hhi, raw_hhi, lerp_weight)
	else:
		current_hhi = override_hhi
		raw_hhi = override_hhi
		
	var new_tier = get_tier_name(current_hhi)
	if new_tier != current_tier:
		current_tier = new_tier
		tier_changed.emit(current_tier)
		
	hhi_changed.emit(current_hhi, current_tier)

func calculate_raw() -> void:
	# Pull from Simulation and GameState autoloads if available
	var sim = get_node_or_null("/root/Simulation")
	var state = get_node_or_null("/root/GameState")
	
	var potable_mld: float = 2.50
	var effluent_mld: float = 0.50
	var tj: float = 71.5
	var pue: float = 1.150
	var trust_val: float = 30.0
	var toxicity: float = 1.0
	
	if sim:
		potable_mld = sim.potable_mld
		effluent_mld = sim.effluent_mld
		tj = sim.tj
		pue = sim.pue
	if state:
		trust_val = state.trust
		
	# Component calculations
	comp_water = 1.0 - clamp(potable_mld / 2.5, 0.0, 1.0)
	comp_creek = 1.0 - clamp((effluent_mld * toxicity) / 0.5, 0.0, 1.0)
	
	if tj <= 75.0:
		comp_thermal = 1.0
	elif tj >= 90.0:
		comp_thermal = 0.0
	else:
		comp_thermal = 1.0 - ((tj - 75.0) / 15.0)
		
	comp_energy = clamp((1.6 - pue) / 0.45, 0.0, 1.0)
	comp_trust = clamp(trust_val / 100.0, 0.0, 1.0)
	
	raw_hhi = 100.0 * (
		0.30 * comp_water +
		0.25 * comp_creek +
		0.20 * comp_thermal +
		0.15 * comp_energy +
		0.10 * comp_trust
	)
	raw_hhi = clamp(raw_hhi, 0.0, 100.0)

func get_tier_name(val: float) -> String:
	if val >= 85.0:
		return "RESTORED"
	elif val >= 65.0:
		return "RECOVERING"
	elif val >= 45.0:
		return "STRAINED"
	elif val >= 25.0:
		return "CRITICAL"
	else:
		return "COLLAPSE"

func get_tier_data(tier_name: String = "") -> Dictionary:
	if tier_name == "":
		tier_name = current_tier
	if TIERS.has(tier_name):
		return TIERS[tier_name]
	return TIERS["CRITICAL"]

func force_tier(tier_name: String) -> void:
	if TIERS.has(tier_name):
		manual_override = true
		match tier_name:
			"RESTORED": override_hhi = 92.0
			"RECOVERING": override_hhi = 75.0
			"STRAINED": override_hhi = 55.0
			"CRITICAL": override_hhi = 38.0
			"COLLAPSE": override_hhi = 15.0
		current_hhi = override_hhi
		current_tier = tier_name
		tier_changed.emit(current_tier)
		hhi_changed.emit(current_hhi, current_tier)
