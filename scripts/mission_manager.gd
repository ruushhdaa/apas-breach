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
var tutorial_overlay: TutorialOverlayController

var in_tutorial: bool = true
var tutorial_beat: int = 1
var tutorial_start_pos: Vector3 = Vector3.ZERO
var initial_cam_yaw: float = 0.0
var tutorial_walk_dist: float = 0.0
var tutorial_sprint_timer: float = 10.0

var current_level_idx: int = 0
var current_beat: int = 1

var waypoint_marker: WaypointMarker

# Ending state
var game_finished: bool = false
var final_score: float = 0.0

func _ready() -> void:
	world = get_parent().get_node_or_null("World")
	hud = get_parent().get_node_or_null("HUD")
	decision_card_layer = get_parent().get_node_or_null("DecisionCardLayer")
	tutorial_overlay = get_parent().get_node_or_null("TutorialOverlay")
	
	if tutorial_overlay:
		tutorial_overlay.tutorial_completed.connect(finish_tutorial)
	
	if world:
		player = world.get_node_or_null("Player")
		waypoint_marker = WaypointMarker.new()
		waypoint_marker.name = "WaypointMarker"
		world.add_child(waypoint_marker)
		
	if player:
		tutorial_start_pos = player.global_position
		initial_cam_yaw = player.camera_rot_y
		
	if decision_card_layer:
		decision_card_layer.decision_confirmed.connect(on_decision_confirmed)
		
	# Start Tutorial (Level 0)
	start_level(0)

func start_level(level_idx: int) -> void:
	current_level_idx = level_idx
	current_beat = 1
	GameState.set_level(level_idx)
	if AudioEngine:
		AudioEngine.set_bgm_level(level_idx)
	level_started.emit(level_idx)
	
	match level_idx:
		0:
			in_tutorial = true
			tutorial_beat = 1
			tutorial_walk_dist = 0.0
			tutorial_sprint_timer = 12.0
			set_objective_beat("Walk to the gate ahead")
			if waypoint_marker:
				waypoint_marker.set_target(Vector3(0, 0, 42.0))
			if tutorial_overlay:
				tutorial_overlay.start_tutorial()
		1:
			in_tutorial = false
			set_level_beat(1, 1)
			GameState.trigger_dialogue("MEERA", "You're on a warrant. Municipal reservoir's at 14%. Find the meter at the municipal substation.")
		2:
			set_level_beat(2, 1)
			GameState.heat_clock_active = true
			GameState.heat_clock_val = 72.0
			GameState.trigger_dialogue("ROHAN", "Pump A seal failed! Server Hall A. Move now before thermal runaway!")
		3:
			set_level_beat(3, 1)
			GameState.trigger_dialogue("MEERA", "Creek DO just dropped to 2.2mg/L. Legal minimum is 4.0. Get to the outfall canal immediately!")
		4:
			set_level_beat(4, 1)
			GameState.trigger_dialogue("TARA", "Budget window open. Access the SCADA Hub to commit the cooling retrofit.")
		5:
			set_level_beat(5, 1)
			GameState.trigger_dialogue("MEERA", "Dr. Kulkarni has arrived from MPCB in his inspection vehicle. Present your findings at the stage!")

func set_level_beat(level: int, beat: int) -> void:
	current_level_idx = level
	current_beat = beat
	
	match level:
		1:
			match beat:
				1:
					set_objective_beat("Make your way to the tanker queue [M for map]")
					set_waypoint(Vector3(-15.0, 0.0, 80.0))
				2:
					show_toast("TANKER QUEUE REACHED")
					set_objective_beat("Talk to the resident waiting at the tankers [E]")
					set_waypoint(Vector3(-12.5, 0.0, 80.0))
				3:
					show_toast("RESIDENT TESTIMONY DOCUMENTED")
					set_objective_beat("Inspect the meter cabinet at the substation [Hold E]")
					set_waypoint(Vector3(-23.9, 1.2, 44.0))
				4:
					show_toast("METER READING LOGGED")
					set_objective_beat("Scan the pipe behind the substation [Q]")
					set_waypoint(Vector3(-33.0, 0.4, 44.0))
				5:
					show_toast("BYPASS PIPE IDENTIFIED")
					set_objective_beat("Access the console and make your decision")
					set_waypoint(Vector3(-27.0, 1.0, 40.0))
		2:
			match beat:
				1:
					set_objective_beat("Get to Server Hall A — emergency in progress")
					set_waypoint(Vector3(-16.0, 1.0, -22.0))
				3:
					show_toast("SERVER HALL A REACHED")
					set_objective_beat("Fix the pump: open V2, then V5, then close V1")
					set_waypoint(Vector3(-16.0, 1.2, -25.0))
				5:
					show_toast("PUMP VALVES CONFIGURED")
					set_objective_beat("Tj critical — make a cooling decision now")
					set_waypoint(Vector3(-20.0, 1.0, -25.0))
		3:
			match beat:
				1:
					set_objective_beat("Get to the outfall canal — creek DO dropping")
					set_waypoint(Vector3(50.0, 0.0, -20.0))
				3:
					show_toast("OUTFALL REACHED")
					set_objective_beat("Sample the canal water with your tool [Q]")
					set_waypoint(Vector3(50.0, 0.0, -20.0))
				4:
					show_toast("WATER SAMPLES RECORDED")
					set_objective_beat("Force the blowdown valve open [Mash E × 10]")
					set_waypoint(Vector3(40.0, 1.0, -20.0))
				5:
					show_toast("BLOWDOWN VALVE FORCED OPEN")
					set_objective_beat("Make a decision on the discharge")
					set_waypoint(Vector3(40.0, 1.0, -20.0))
		4:
			match beat:
				1:
					set_objective_beat("Access the SCADA hub — budget window is open")
					set_waypoint(Vector3(20.0, 1.0, 14.5))
				3:
					show_toast("SCADA ACCESS GRANTED")
					set_objective_beat("Deal with Rohan's offer")
					set_waypoint(Vector3(22.0, 0.0, 11.0))
				4:
					show_toast("ROHAN CONFRONTATION RESOLVED")
					set_objective_beat("Choose a cooling system retrofit")
					set_waypoint(Vector3(20.0, 1.0, 14.5))
		5:
			match beat:
				1:
					set_objective_beat("Proceed to the audit stage at the facility entrance")
					set_waypoint(Vector3(2.5, 1.0, 58.0))
				3:
					show_toast("AUDIT STAGE REACHED")
					set_objective_beat("Answer the inspector's questions accurately")
					set_waypoint(Vector3(2.5, 1.0, 58.0))
				4:
					show_toast("TECHNICAL INQUIRY COMPLETE")
					set_objective_beat("Make your final disclosure decision")
					set_waypoint(Vector3(2.5, 1.0, 58.0))

func set_objective_beat(text: String) -> void:
	if hud and hud.has_method("set_objective"):
		hud.set_objective(text)

func show_toast(action_text: String) -> void:
	if hud and hud.has_method("show_beat_toast"):
		hud.show_beat_toast(action_text)

func set_waypoint(target_pos: Vector3) -> void:
	if waypoint_marker:
		waypoint_marker.set_target(target_pos)

func _process(delta: float) -> void:
	if in_tutorial:
		process_tutorial(delta)
	else:
		process_level_progression(delta)

func _input(event: InputEvent) -> void:
	if in_tutorial and event.is_action_pressed("skip_action"):
		skip_tutorial()

func process_tutorial(delta: float) -> void:
	if not player:
		return
		
	match tutorial_beat:
		1: # WASD Movement 10m
			tutorial_walk_dist += player.velocity.length() * delta
			if tutorial_overlay:
				tutorial_overlay.update_walk_progress(tutorial_walk_dist)
			if tutorial_walk_dist >= 10.0 or player.global_position.distance_to(tutorial_start_pos) >= 10.0:
				tutorial_beat = 2
				initial_cam_yaw = player.camera_rot_y
				show_toast("MOVEMENT — GOOD")
				set_objective_beat("Rotate the camera with your mouse")
				if waypoint_marker: waypoint_marker.clear_target()
				if tutorial_overlay: tutorial_overlay.set_beat(2)
		2: # Camera orbit 90 deg (~1.5 rad)
			if abs(player.camera_rot_y - initial_cam_yaw) >= 1.4:
				tutorial_beat = 3
				show_toast("CAMERA CONTROL")
				set_objective_beat("Sprint to the gate — hold Shift")
				tutorial_sprint_timer = 12.0
				if waypoint_marker: waypoint_marker.set_target(Vector3(0.0, 1.0, 50.0))
				if tutorial_overlay: tutorial_overlay.set_beat(3)
		3: # Sprint
			if player.is_sprinting:
				tutorial_sprint_timer = 12.0
			else:
				tutorial_sprint_timer -= delta
			if tutorial_overlay:
				tutorial_overlay.update_sprint_timer(tutorial_sprint_timer)
				
			if player.global_position.z <= 51.5 and player.global_position.distance_to(Vector3(0, 0, 50)) < 6.0:
				tutorial_beat = 4
				show_toast("SPRINT")
				set_objective_beat("Talk to the guard [E]")
				if waypoint_marker: waypoint_marker.set_target(Vector3(2.5, 0.0, 49.0))
				if tutorial_overlay: tutorial_overlay.set_beat(4)
		4: # Interact with Guard
			var guard_pos = Vector3(2.5, 0.0, 49.0)
			if player.global_position.distance_to(guard_pos) < 4.0 and Input.is_action_just_pressed("interact"):
				tutorial_beat = 5
				show_toast("INTERACT")
				set_objective_beat("Scan the pipe with your tool [Q]")
				if waypoint_marker: waypoint_marker.set_target(Vector3(-33.0, 0.4, 44.0))
				if tutorial_overlay: tutorial_overlay.set_beat(5)
		5: # Specialist tool
			if Input.is_action_just_pressed("tool_action"):
				tutorial_beat = 6
				show_toast("SPECIALIST TOOL")
				set_objective_beat("HUD INTERFACE OVERVIEW (PRESS SPACE TO ADVANCE)")
				if waypoint_marker: waypoint_marker.clear_target()
				if tutorial_overlay:
					tutorial_overlay.show_tool_readout()
					tutorial_overlay.set_beat(6)
		6: # HUD explanation tour
			if Input.is_action_just_pressed("skip_action") or Input.is_action_just_pressed("interact"):
				tutorial_beat = 7
				show_toast("INTERFACE ACKNOWLEDGED")
				set_objective_beat("DECISION ENGINE PREVIEW (PRESS SPACE TO ADVANCE)")
				if tutorial_overlay: tutorial_overlay.set_beat(7)
		7: # Decision preview
			if Input.is_action_just_pressed("skip_action") or Input.is_action_just_pressed("interact"):
				tutorial_beat = 8
				show_toast("DECISION ENGINE VERIFIED")
				set_objective_beat("YOU ARE READY. GOOD LUCK.")
				if tutorial_overlay: tutorial_overlay.set_beat(8)

func process_level_progression(_delta: float) -> void:
	if not player: return
	
	match current_level_idx:
		1:
			if current_beat == 1:
				if player.global_position.distance_to(Vector3(-15.0, 0.0, 80.0)) < 7.0:
					set_level_beat(1, 2)
			elif current_beat == 2:
				if GameState.evidence >= 1: # Sunita talked to
					set_level_beat(1, 3)
			elif current_beat == 3:
				if GameState.evidence >= 2: # Cabinet opened
					set_level_beat(1, 4)
			elif current_beat == 4:
				if GameState.evidence >= 3: # Bypass scanned with Q
					set_level_beat(1, 5)
		2:
			if current_beat == 1:
				if player.global_position.distance_to(Vector3(-16.0, 1.0, -22.0)) < 8.0:
					set_level_beat(2, 3)
			elif current_beat == 3:
				if world and world.valve_solved:
					set_level_beat(2, 5)
		3:
			if current_beat == 1:
				if player.global_position.distance_to(Vector3(50.0, 0.0, -20.0)) < 8.0:
					set_level_beat(3, 3)
			elif current_beat == 3:
				if Input.is_action_just_pressed("tool_action") and player.global_position.distance_to(Vector3(50.0, 0.0, -20.0)) < 10.0:
					GameState.add_evidence_item("outfall_sample", "Outfall Lab Sample: DO 2.2 mg/L, TDS 2470 ppm, 46°C")
					set_level_beat(3, 4)
			elif current_beat == 4:
				if world and world.blowdown_valve_opened:
					set_level_beat(3, 5)
		4:
			if current_beat == 1:
				if player.global_position.distance_to(Vector3(20.0, 1.0, 14.5)) < 6.0:
					set_level_beat(4, 3)
			elif current_beat == 3:
				if player.global_position.distance_to(Vector3(22.0, 0.0, 11.0)) < 5.0 and Input.is_action_just_pressed("interact"):
					GameState.trigger_dialogue("ROHAN", "I can make this audit disappear. 50 lakhs. Inspector never sees this room.")
					GameState.pressure += 10.0
					GameState.trust += 5.0
					set_level_beat(4, 4)
		5:
			if current_beat == 1:
				if player.global_position.distance_to(Vector3(2.5, 1.0, 58.0)) < 6.0:
					set_level_beat(5, 3)
			elif current_beat == 3:
				if world and world.audit_step >= 3:
					set_level_beat(5, 4)

func skip_tutorial() -> void:
	if in_tutorial:
		if tutorial_overlay:
			tutorial_overlay.hide_all_beats()
			tutorial_overlay.is_active = false
		finish_tutorial()

func finish_tutorial() -> void:
	in_tutorial = false
	if tutorial_overlay:
		tutorial_overlay.hide_all_beats()
		tutorial_overlay.is_active = false
	GameState.trigger_dialogue("MEERA", "Good luck, Auditor. Beginning Level 1.")
	if AudioEngine: AudioEngine.play_sfx("level_complete")
	start_level(1)

func on_decision_confirmed(card_id: String, option_letter: String) -> void:
	match card_id:
		"LEVEL1_BYPASS":
			show_toast("BYPASS DECISION COMMITTED")
			await get_tree().create_timer(6.0).timeout
			start_level(2)
		"LEVEL2_HEAT":
			show_toast("COOLING DECISION COMMITTED")
			await get_tree().create_timer(6.0).timeout
			start_level(3)
		"LEVEL3_BLOWDOWN":
			show_toast("EFFLUENT DECISION COMMITTED")
			await get_tree().create_timer(6.0).timeout
			start_level(4)
		"LEVEL4_REBUILD":
			show_toast("RETROFIT ARCHITECTURE APPLIED")
			await get_tree().create_timer(8.0).timeout
			start_level(5)
		"LEVEL5_FINAL":
			show_toast("FINAL AUDIT DISCLOSURE SUBMITTED")
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
