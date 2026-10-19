class_name MissionManager
extends Node

signal tutorial_step_changed(step_text: String)
signal level_started(level: int)
signal game_ended(outcome_tier: String, score: float)

@export var skip_tutorial_enabled: bool = true

var world: Node3D
var player: CharacterBody3D
var hud: CanvasLayer
var decision_card_layer: CanvasLayer

var in_tutorial: bool = true
var tutorial_beat: int = 1
var tutorial_start_pos: Vector3 = Vector3.ZERO
var initial_cam_yaw: float = 0.0

var level_1_started: bool = false
var level_2_started: bool = false
var level_3_started: bool = false
var level_4_started: bool = false
var level_5_started: bool = false

# Ending state
var game_finished: bool = false
var final_score: float = 0.0

func _ready() -> void:
	world = get_parent().get_node_or_null("World")
	hud = get_parent().get_node_or_null("HUD")
	decision_card_layer = get_parent().get_node_or_null("DecisionCardLayer")
	
	if world:
		player = world.get_node_or_null("Player")
		
	if player:
		tutorial_start_pos = player.global_position
		initial_cam_yaw = player.camera_rot_y
		
	if decision_card_layer:
		decision_card_layer.decision_confirmed.connect(on_decision_confirmed)
		
	# Start Tutorial (Level 0)
	start_level(0)

func start_level(level_idx: int) -> void:
	GameState.set_level(level_idx)
	if AudioEngine:
		AudioEngine.set_bgm_level(level_idx)
	level_started.emit(level_idx)
	
	match level_idx:
		0:
			in_tutorial = true
			tutorial_beat = 1
			GameState.trigger_dialogue("SYSTEM", "TUTORIAL: MOVE WITH [WASD]. (PRESS [SPACE] TO SKIP)")
		1:
			in_tutorial = false
			level_1_started = true
			GameState.trigger_dialogue("MEERA", "You're on a warrant. Municipal reservoir's at 14%. Find the meter at the municipal substation.")
		2:
			level_2_started = true
			GameState.heat_clock_active = true
			GameState.heat_clock_val = 72.0
			GameState.trigger_dialogue("ROHAN", "Pump A seal failed! Server Hall A. Move now before thermal runaway!")
		3:
			level_3_started = true
			GameState.trigger_dialogue("MEERA", "Creek DO just dropped to 2.2mg/L. Legal minimum is 4.0. Get to the outfall canal immediately!")
		4:
			level_4_started = true
			GameState.trigger_dialogue("TARA", "Budget window open. We have capital to overhaul the cooling topology at the SCADA Hub.")
		5:
			level_5_started = true
			GameState.trigger_dialogue("MEERA", "Dr. Kulkarni has arrived from MPCB in his inspection vehicle. Present your findings at the stage!")

func _process(delta: float) -> void:
	if in_tutorial:
		process_tutorial(delta)

func _input(event: InputEvent) -> void:
	if in_tutorial and event.is_action_pressed("skip_action"):
		skip_tutorial()

func process_tutorial(_delta: float) -> void:
	if not player:
		return
		
	match tutorial_beat:
		1: # Move 10m forward
			if player.global_position.distance_to(tutorial_start_pos) >= 10.0:
				tutorial_beat = 2
				GameState.trigger_dialogue("SYSTEM", "APPROACH THE SECURITY GATEHOUSE AND TALK TO THE GUARD — [E]")
		2: # Talk to guard
			var guard_pos = Vector3(2.5, 0.0, 49.0)
			if player.global_position.distance_to(guard_pos) < 4.0 and Input.is_action_just_pressed("interact"):
				tutorial_beat = 3
				GameState.trigger_dialogue("GUARD", "Warrant checked. You're clear to enter the facility.")
				await get_tree().create_timer(2.0).timeout
				GameState.trigger_dialogue("SYSTEM", "USE YOUR SPECIALIST TOOL — [Q]")
		3: # Use tool
			if Input.is_action_just_pressed("tool_action"):
				tutorial_beat = 4
				tutorial_start_pos = player.global_position
				GameState.trigger_dialogue("SYSTEM", "ORBIT CAMERA — HOLD LEFT CLICK + MOVE MOUSE")
		4: # Orbit camera 90 deg (~1.5 rad)
			if abs(player.camera_rot_y - initial_cam_yaw) >= 1.2:
				tutorial_beat = 5
				GameState.trigger_dialogue("SYSTEM", "SPRINT TO GATE 4 BARRIER — HOLD [SHIFT] + [W]")
		5: # Sprint forward to gate
			if player.is_sprinting and player.global_position.z <= 51.0:
				tutorial_beat = 6
				GameState.trigger_dialogue("MEERA", "Your meters on the right are live. Watch water draw, PUE, and temperature.")
				await get_tree().create_timer(3.0).timeout
				tutorial_beat = 7
				GameState.trigger_dialogue("MEERA", "The entire world reacts to your decisions. Every choice has a consequence.")
				world.apply_hhi_visuals(20.0, 2.0)
				await get_tree().create_timer(2.5).timeout
				world.apply_hhi_visuals(38.0, 2.0)
				await get_tree().create_timer(2.5).timeout
				finish_tutorial()

func skip_tutorial() -> void:
	if in_tutorial:
		finish_tutorial()

func finish_tutorial() -> void:
	in_tutorial = false
	GameState.trigger_dialogue("MEERA", "Good luck, Auditor. Beginning Level 1.")
	if AudioEngine: AudioEngine.play_sfx("level_complete")
	start_level(1)

func on_decision_confirmed(card_id: String, option_letter: String) -> void:
	match card_id:
		"LEVEL1_BYPASS":
			await get_tree().create_timer(6.0).timeout
			start_level(2)
		"LEVEL2_HEAT":
			await get_tree().create_timer(6.0).timeout
			start_level(3)
		"LEVEL3_BLOWDOWN":
			await get_tree().create_timer(6.0).timeout
			start_level(4)
		"LEVEL4_REBUILD":
			await get_tree().create_timer(8.0).timeout
			start_level(5)
		"LEVEL5_FINAL":
			await get_tree().create_timer(4.0).timeout
			trigger_ending_sequence(option_letter)

func trigger_ending_sequence(final_option: String) -> void:
	game_finished = true
	var hhi_val = HHI.current_hhi
	
	# Score = HHI×0.5 + Trust×0.3 + Evidence×5 + (100-Pressure)×0.2
	final_score = (hhi_val * 0.5) + (GameState.trust * 0.3) + (GameState.evidence * 5.0) + ((100.0 - GameState.pressure) * 0.2)
	
	var outcome_tier = "COLLAPSE"
	if hhi_val >= 80.0:
		outcome_tier = "RESTORED"
	elif hhi_val >= 55.0:
		outcome_tier = "STRAINED"
	elif hhi_val >= 30.0:
		outcome_tier = "BREACH"
	else:
		outcome_tier = "COLLAPSE"
		
	# Aerial camera pull-back
	if player and player.spring_arm:
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(player.spring_arm, "spring_length", 35.0, 4.0)
		tween.parallel().tween_property(player.spring_arm, "position:y", 15.0, 4.0)
		
	await get_tree().create_timer(4.0).timeout
	
	# Show ending overlay
	var ending_layer = get_parent().get_node_or_null("EndingLayer")
	if ending_layer and ending_layer.has_method("display_ending"):
		ending_layer.display_ending(outcome_tier, final_score, hhi_val, final_option)
