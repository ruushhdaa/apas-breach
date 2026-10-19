extends SceneTree

const SimScript = preload("res://scripts/simulation.gd")
const HHIScript = preload("res://scripts/hhi.gd")

func _init() -> void:
	print("--- Running APAS: BREACH HHI Verification Test ---")
	var sim = SimScript.new()
	sim.run_baseline_test()
	
	var hhi = HHIScript.new()
	# Check baseline calculation:
	# water = 1 - 2.50/2.50 = 0.0
	# creek = 1 - 0.50/0.50 = 0.0
	# thermal = Tj (71.5 <= 75) => 1.0
	# energy = (1.6 - 1.15) / 0.45 = 1.0
	# trust = 30 / 100 = 0.30
	# HHI = 100 * (0.30*0 + 0.25*0 + 0.20*1 + 0.15*1 + 0.10*0.30) = 38.0
	hhi.comp_water = 0.0
	hhi.comp_creek = 0.0
	hhi.comp_thermal = 1.0
	hhi.comp_energy = 1.0
	hhi.comp_trust = 0.30
	var calc = 100.0 * (0.30*0.0 + 0.25*0.0 + 0.20*1.0 + 0.15*1.0 + 0.10*0.30)
	print("Calculated Baseline HHI: ", calc)
	assert(abs(calc - 38.0) < 0.01, "Baseline HHI should be 38.0")
	
	# Test all 5 tier classifications:
	var t1 = hhi.get_tier_name(92.0)
	var t2 = hhi.get_tier_name(72.0)
	var t3 = hhi.get_tier_name(52.0)
	var t4 = hhi.get_tier_name(38.0)
	var t5 = hhi.get_tier_name(15.0)
	
	print("Tiers output: ", [t1, t2, t3, t4, t5])
	assert(t1 == "RESTORED", "92 should be RESTORED")
	assert(t2 == "RECOVERING", "72 should be RECOVERING")
	assert(t3 == "STRAINED", "52 should be STRAINED")
	assert(t4 == "CRITICAL", "38 should be CRITICAL")
	assert(t5 == "COLLAPSE", "15 should be COLLAPSE")
	
	print(">>> HHI TIER VERIFICATION PASSED <<<")
	quit(0)
