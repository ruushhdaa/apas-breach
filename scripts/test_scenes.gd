extends SceneTree

const SimScript = preload("res://scripts/simulation.gd")
const HHIScript = preload("res://scripts/hhi.gd")
const GameStateScript = preload("res://scripts/game_state.gd")
const AudioScript = preload("res://autoloads/audio_engine.gd")

func _init() -> void:
	print("--- Validating All PackedScenes ---")
	
	# Add autoload singletons to root if not already present
	if not root.has_node("Simulation"):
		var sim = SimScript.new()
		sim.name = "Simulation"
		root.add_child(sim)
		
	if not root.has_node("HHI"):
		var hhi = HHIScript.new()
		hhi.name = "HHI"
		root.add_child(hhi)
		
	if not root.has_node("GameState"):
		var gs = GameStateScript.new()
		gs.name = "GameState"
		root.add_child(gs)
		
	if not root.has_node("AudioEngine"):
		var aud = AudioScript.new()
		aud.name = "AudioEngine"
		root.add_child(aud)
		
	var scenes = [
		"res://scenes/title_screen.tscn",
		"res://scenes/dispatch_screen.tscn",
		"res://scenes/world.tscn",
		"res://scenes/player.tscn",
		"res://scenes/hud.tscn",
		"res://scenes/decision_card.tscn",
		"res://scenes/level_0.tscn",
		"res://scenes/dev_panel.tscn",
		"res://scenes/ending_layer.tscn",
		"res://scenes/game_over_layer.tscn",
		"res://scenes/pause_menu.tscn",
		"res://scenes/credits.tscn"
	]
	
	for s_path in scenes:
		print("Validating scene: ", s_path)
		var scn = ResourceLoader.load(s_path)
		assert(scn != null, "Failed to load scene: " + s_path)
		var inst = scn.instantiate()
		assert(inst != null, "Failed to instantiate scene: " + s_path)
		root.add_child(inst)
		inst.queue_free()
		print("  -> OK!")
		
	print("==================================================")
	print(">>> ALL SCENES LOADED & INSTANTIATED CLEANLY <<<")
	print("==================================================")
	quit(0)
