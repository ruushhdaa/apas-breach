class_name SimulationEngine
extends Node

# Physical constants
const HEAT_FRACTION: float = 0.985
const LATENT_HEAT: float = 2.26
const DRIFT: float = 0.005

# Topology Presets
const TOPOLOGIES = {
	"HYBRID_EVAP": {"evap_share": 0.528, "aux": 0.15, "coolant": 22.0, "rise": 49.5},
	"DRY":         {"evap_share": 0.0,   "aux": 0.48, "coolant": 34.0, "rise": 45.8},
	"DTC":         {"evap_share": 0.45,  "aux": 0.22, "coolant": 18.0, "rise": 46.0}
}

# Water Source Presets
const WATER_SOURCES = {
	"POTABLE": {"makeup_tds": 180.0, "coc": 5.0},
	"STP":     {"makeup_tds": 650.0, "coc": 3.8}
}

# State Variables
var it_load: float = 100.0 # MW base load
var throttle_pct: float = 0.0 # Percentage compute reduction
var current_topology: String = "HYBRID_EVAP"
var current_water_source: String = "POTABLE"
var zld_active: bool = false
var zld_mw: float = 0.0
var extra_aux: float = 0.0
var makeup_flood_multiplier: float = 1.0
var valve_sealed: bool = false
var diluted_discharge: bool = false

# Live Output Readings
var effective_it: float = 100.0
var heat_mw: float = 98.5
var e_ls: float = 23.012
var b_ls: float = 5.753
var drift_ls: float = 0.115
var withdrawal_ls: float = 28.88
var potable_mld: float = 2.50
var stp_mld: float = 0.0
var effluent_mld: float = 0.50
var basin_tds: float = 2470.0
var creek_do: float = 2.2 # mg/L
var creek_temp: float = 46.0 # °C
var creek_health_pct: float = 35.0
var tj: float = 71.5
var pue: float = 1.150

func _ready() -> void:
	calculate()

func _process(_delta: float) -> void:
	calculate()

func set_topology(topo_name: String) -> void:
	if TOPOLOGIES.has(topo_name):
		current_topology = topo_name
		calculate()

func set_water_source(source_name: String) -> void:
	if WATER_SOURCES.has(source_name):
		current_water_source = source_name
		calculate()

func calculate() -> void:
	var topo = TOPOLOGIES[current_topology]
	var water = WATER_SOURCES[current_water_source]
	
	var evap_share: float = topo["evap_share"]
	var aux: float = topo["aux"]
	var coolant: float = topo["coolant"]
	var rise: float = topo["rise"]
	var coc: float = water["coc"]
	
	effective_it = it_load * (1.0 - (throttle_pct / 100.0))
	effective_it = max(effective_it, 10.0) # Ensure no division by zero
	
	heat_mw = effective_it * HEAT_FRACTION
	
	# Evaporation in liters per second
	e_ls = (evap_share * heat_mw / LATENT_HEAT) * makeup_flood_multiplier
	
	# Blowdown in liters per second
	if coc > 1.0:
		b_ls = e_ls / (coc - 1.0)
	else:
		b_ls = 0.0
		
	# Drift in liters per second
	drift_ls = DRIFT * e_ls
	
	# Water recovery and discharge
	var recovered_ls: float = 0.0
	var actual_zld_power: float = 0.0
	
	if zld_active:
		recovered_ls = 0.98 * b_ls
		effluent_mld = 0.0
		actual_zld_power = 2.5
	elif valve_sealed:
		recovered_ls = 0.0
		effluent_mld = 0.0
		actual_zld_power = 0.0
	else:
		recovered_ls = 0.0
		var discharge_ls = b_ls
		if diluted_discharge:
			discharge_ls *= 1.3
		effluent_mld = (discharge_ls * 86.4) / 1000.0
		actual_zld_power = 0.0
		
	withdrawal_ls = e_ls + b_ls + drift_ls - recovered_ls
	var total_mld: float = (withdrawal_ls * 86.4) / 1000.0
	
	if current_water_source == "POTABLE":
		potable_mld = total_mld
		stp_mld = 0.0
	else:
		potable_mld = 0.0
		stp_mld = total_mld
		
	# Silicon junction temperature
	tj = coolant + rise * (effective_it / 100.0)
	
	# PUE
	var total_power = effective_it + (aux * effective_it) + extra_aux + actual_zld_power
	pue = total_power / effective_it
	
	# Update Environmental Creek Readings
	if zld_active:
		creek_do = 6.2
		creek_temp = 28.0
		basin_tds = 400.0
		creek_health_pct = 95.0
	elif valve_sealed:
		creek_do = 5.0
		creek_temp = 30.0
		basin_tds = 800.0
		creek_health_pct = 80.0
	elif diluted_discharge:
		creek_do = 3.6
		creek_temp = 36.0
		basin_tds = 1850.0
		creek_health_pct = 55.0
	else:
		creek_do = 2.2
		creek_temp = 46.0
		basin_tds = 2470.0
		creek_health_pct = 35.0

# Baseline verification helper
func run_baseline_test() -> Dictionary:
	current_topology = "HYBRID_EVAP"
	current_water_source = "POTABLE"
	it_load = 100.0
	throttle_pct = 0.0
	zld_active = false
	extra_aux = 0.0
	makeup_flood_multiplier = 1.0
	valve_sealed = false
	diluted_discharge = false
	calculate()
	
	var pue_ok = abs(pue - 1.150) < 0.001
	var tj_ok = abs(tj - 71.5) < 0.1
	var potable_ok = abs(potable_mld - 2.50) < 0.01
	
	return {
		"pass": pue_ok and tj_ok and potable_ok,
		"pue": pue,
		"tj": tj,
		"potable_mld": potable_mld
	}
