extends SceneTree

const SimScript = preload("res://scripts/simulation.gd")

func _init() -> void:
	print("--- Running APAS: BREACH Simulation Baseline Test ---")
	var sim = SimScript.new()
	var res = sim.run_baseline_test()
	print("Baseline Test Result:")
	print("  PUE: ", res["pue"], " (Target: 1.150)")
	print("  Tj: ", res["tj"], " °C (Target: 71.5°C)")
	print("  Potable MLD: ", res["potable_mld"], " MLD (Target: 2.50 MLD)")
	print("  Pass: ", res["pass"])
	
	if res["pass"]:
		print(">>> BASELINE TEST PASSED SUCCESSFULLY <<<")
		quit(0)
	else:
		printerr(">>> BASELINE TEST FAILED <<<")
		quit(1)
