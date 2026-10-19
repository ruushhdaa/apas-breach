class_name PlayerController
extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 9.0
@export var gravity: float = 9.8
@export var mouse_sensitivity: float = 0.003

const CharModelScript = preload("res://scripts/character_model.gd")

var spring_arm: SpringArm3D
var camera: Camera3D
var model_node: Node3D
var camera_rot_x: float = -0.15 # rad (~ -8 deg)
var camera_rot_y: float = 0.0

var is_sprinting: bool = false
var current_interactable: Node3D = null
var interact_hold_time: float = 0.0
var target_hold_time: float = 2.0
var is_holding_interact: bool = false
var tool_active: bool = false
var footstep_cooldown: float = 0.0

# Q tool thermal highlight overlay (for Volt)
var thermal_view_active: bool = false

func _ready() -> void:
	# Find or instantiate camera and spring arm
	setup_camera()
	setup_model()
	# Default to captured mouse during gameplay
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func setup_camera() -> void:
	spring_arm = get_node_or_null("SpringArm3D")
	if not spring_arm:
		spring_arm = SpringArm3D.new()
		spring_arm.name = "SpringArm3D"
		spring_arm.spring_length = 7.0
		spring_arm.position = Vector3(0, 1.8, 0)
		add_child(spring_arm)
		
		camera = Camera3D.new()
		camera.name = "Camera3D"
		camera.fov = 55.0
		camera.position = Vector3(0, 1.4, 0)
		spring_arm.add_child(camera)
	else:
		camera = spring_arm.get_node_or_null("Camera3D")

func setup_model() -> void:
	model_node = get_node_or_null("CharacterModel")
	if not model_node:
		model_node = CharModelScript.new()
		model_node.name = "CharacterModel"
		add_child(model_node)
		
	var spec = "VOLT"
	if GameState:
		spec = GameState.selected_specialist
	if model_node.has_method("rebuild_for_specialist"):
		model_node.rebuild_for_specialist(spec)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_rot_y -= event.relative.x * mouse_sensitivity
		camera_rot_x -= event.relative.y * mouse_sensitivity
		camera_rot_x = clamp(camera_rot_x, deg_to_rad(-30.0), deg_to_rad(20.0))
		update_camera_rotation()
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if spring_arm:
				spring_arm.spring_length = clamp(spring_arm.spring_length - 0.5, 3.0, 10.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if spring_arm:
				spring_arm.spring_length = clamp(spring_arm.spring_length + 0.5, 3.0, 10.0)

	if event.is_action_pressed("tool_action"):
		trigger_specialist_tool()

	if event.is_action_pressed("hint"):
		play_radio_hint()

	if event.is_action_pressed("toggle_map"):
		var hud = get_tree().root.find_child("HUD", true, false)
		if hud and hud.has_method("toggle_fullscreen_map"):
			hud.toggle_fullscreen_map()

	if event.is_action_pressed("pause_menu"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func update_camera_rotation() -> void:
	if spring_arm:
		spring_arm.rotation = Vector3(camera_rot_x, camera_rot_y, 0)

func _physics_process(delta: float) -> void:
	# Apply Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# Calculate Movement Direction relative to camera orientation
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"): input_dir.y -= 1.0
	if Input.is_action_pressed("move_backward"): input_dir.y += 1.0
	if Input.is_action_pressed("move_left"): input_dir.x -= 1.0
	if Input.is_action_pressed("move_right"): input_dir.x += 1.0
	input_dir = input_dir.normalized()
	
	is_sprinting = Input.is_action_pressed("sprint")
	var speed = walk_speed
	if is_sprinting:
		speed = sprint_speed
		if GameState and GameState.selected_specialist == "ANANYA":
			speed *= 0.9 # Downside: Ananya sprint 10% slower
			
	var cam_yaw = camera_rot_y
	var move_vec = Vector3.ZERO
	if input_dir != Vector2.ZERO:
		var forward = Vector3(-sin(cam_yaw), 0, -cos(cam_yaw))
		var right = Vector3(cos(cam_yaw), 0, -sin(cam_yaw))
		move_vec = (forward * -input_dir.y + right * input_dir.x).normalized()
		
		# Rotate character model toward direction of motion
		var target_angle = atan2(move_vec.x, move_vec.z)
		if model_node and model_node.root_pivot:
			model_node.root_pivot.rotation.y = lerp_angle(model_node.root_pivot.rotation.y, target_angle, 0.2)
			
	velocity.x = move_vec.x * speed
	velocity.z = move_vec.z * speed
	
	move_and_slide()
	
	# Animations and Audio footsteps
	if model_node:
		if move_vec.length() > 0.1:
			var is_inside = (global_position.x >= -46.0 and global_position.x <= -14.0 and global_position.z >= -46.0 and global_position.z <= -4.0) or (global_position.x >= 14.0 and global_position.x <= 26.0 and global_position.z >= 5.0 and global_position.z <= 16.0)
			if is_sprinting:
				model_node.play_anim("run")
				footstep_cooldown -= delta
				if footstep_cooldown <= 0.0:
					footstep_cooldown = 0.30
					if AudioEngine: AudioEngine.play_footstep(true, is_inside)
			else:
				model_node.play_anim("walk")
				footstep_cooldown -= delta
				if footstep_cooldown <= 0.0:
					footstep_cooldown = 0.55
					if AudioEngine: AudioEngine.play_footstep(false, is_inside)
		else:
			if not tool_active:
				model_node.play_anim("idle")

	# Proximity check for Q tool contextual reminder
	if global_position.distance_to(Vector3(-33.0, 0.4, 44.0)) <= 12.0:
		GameState.trigger_context_hint("tool_pipe", "[Q] to scan")
				
	# Handle Interactable Hold Logic (e.g. 2s for meter cabinet)
	handle_interaction(delta)

func handle_interaction(delta: float) -> void:
	if current_interactable and is_instance_valid(current_interactable):
		if Input.is_action_pressed("interact"):
			if current_interactable.has_method("requires_hold") and current_interactable.requires_hold():
				is_holding_interact = true
				interact_hold_time += delta
				if current_interactable.has_method("set_hold_progress"):
					current_interactable.set_hold_progress(interact_hold_time / target_hold_time)
				if interact_hold_time >= target_hold_time:
					interact_hold_time = 0.0
					current_interactable.interact(self)
					if model_node: model_node.play_anim("interact")
			else:
				if Input.is_action_just_pressed("interact"):
					current_interactable.interact(self)
					if model_node: model_node.play_anim("interact")
		else:
			is_holding_interact = false
			interact_hold_time = 0.0
			if current_interactable.has_method("set_hold_progress"):
				current_interactable.set_hold_progress(0.0)

func trigger_specialist_tool() -> void:
	if not GameState:
		return
	tool_active = true
	if model_node:
		model_node.play_anim("tool")
	
	# Muzzle flash lens-flare equivalent at scan point
	var scan_target = global_position - transform.basis.z * 1.8 + Vector3(0, 1.0, 0)
	trigger_scan_flash(scan_target)
	
	var spec = GameState.selected_specialist
	match spec:
		"VOLT":
			# Thermal View (Q key) — highlights hot pipes, overheating components in orange
			thermal_view_active = !thermal_view_active
			var world = get_parent()
			if world and world.has_method("toggle_thermal_view"):
				world.toggle_thermal_view(thermal_view_active)
			GameState.trigger_dialogue("KABIR 'VOLT' RAO", "Thermal scan active. Checking thermal signatures.")
			if AudioEngine: AudioEngine.play_sfx("option_select")
			
		"ANANYA":
			# Sample Kit (Q key) — reads TDS, temperature, DO of water source or pipe in range
			check_water_sampling()
			
		"TARA":
			# Remote Hack (Q key) — interact with any console from 15m away
			check_remote_hack()
			
	await get_tree().create_timer(1.0).timeout
	tool_active = false

func trigger_scan_flash(target_point: Vector3) -> void:
	var flash_light = OmniLight3D.new()
	flash_light.light_color = Color("#44AACC")
	flash_light.light_energy = 5.0
	flash_light.omni_range = 3.5
	flash_light.position = target_point
	get_parent().add_child(flash_light)
	
	if GameState:
		GameState.request_particle("q_tool_scan", target_point)
	
	get_tree().create_timer(0.2).timeout.connect(func():
		if is_instance_valid(flash_light):
			flash_light.queue_free()
	)

func check_water_sampling() -> void:
	# Detect nearby water source or outfall within 15m
	var world = get_parent()
	var dist_canal = global_position.distance_to(Vector3(50, 0, -20))
	var dist_pipe = global_position.distance_to(Vector3(-28, 0, 44))
	
	if dist_canal <= 25.0:
		GameState.add_evidence_item("canal_sample", "Outfall Canal Water Sample (TDS 2470ppm, DO 2.2mg/L)")
		GameState.trigger_dialogue("DR. ANANYA SEN", "Sample logged: TDS 2470ppm, Temp 46°C, DO 2.2mg/L. Violates minimum 4.0mg/L!")
		if AudioEngine: AudioEngine.play_sfx("evidence_collect")
	elif dist_pipe <= 15.0:
		GameState.add_evidence_item("pipe_bypass", "Unmetered 1200mm Municipal Bypass Pipe")
		GameState.trigger_dialogue("DR. ANANYA SEN", "Bypass pipe sample confirmed: Municipal potable feed diverted directly.")
		if AudioEngine: AudioEngine.play_sfx("evidence_collect")
	else:
		GameState.trigger_dialogue("DR. ANANYA SEN", "Sample kit ready. No direct water source in close range.")

func check_remote_hack() -> void:
	# Tara can interact from 15m away
	GameState.pressure += 5.0 # Downside: each remote hack adds +5 audit pressure
	var consoles = get_tree().get_nodes_in_group("interactables")
	var hacked = false
	for c in consoles:
		if c.global_position.distance_to(global_position) <= 18.0:
			hacked = true
			c.interact(self)
			GameState.trigger_dialogue("TARA D'SOUZA", "Remote SCADA link established. Valve logs bypassed (+5 Audit Pressure).")
			if AudioEngine: AudioEngine.play_sfx("option_select")
			break
	if not hacked:
		GameState.trigger_dialogue("TARA D'SOUZA", "Remote hack scanning... No unsecured SCADA terminal in 18m range.")

func play_radio_hint() -> void:
	if not GameState:
		return
	match GameState.current_level:
		0: GameState.trigger_dialogue("MEERA", "Follow the gate path forward and talk to the guard.")
		1: GameState.trigger_dialogue("MEERA", "Check the tanker queue in the colony, then inspect the municipal meter cabinet at (-28, 44).")
		2: GameState.trigger_dialogue("MEERA", "Get inside Server Hall A! Solve the valve sequence: open V2, then V5, then close V1!")
		3: GameState.trigger_dialogue("MEERA", "The outfall canal is discharging thermal effluent at (50, -20). Force open the seized blowdown valve!")
		4: GameState.trigger_dialogue("TARA", "We have a budget window. Access the SCADA consoles at (20, 10) to overhaul the cooling topology.")
		5: GameState.trigger_dialogue("MEERA", "Dr. Kulkarni has arrived at Gate 4 stage. Present our evidence accurately to pass the audit!")
