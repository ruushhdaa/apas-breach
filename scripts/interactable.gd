class_name InteractableArea3D
extends Area3D

signal interacted(player)

@export var prompt_text: String = "INTERACT"
@export var hold_required: bool = false
@export var is_mash: bool = false
@export var interact_distance: float = 3.5
@export var max_visible_distance: float = 15.0

var prompt_container: Node3D
var prompt_bg: MeshInstance3D
var prompt_label: Label3D
var pulse_time: float = 0.0
var player_in_range: bool = false
var cached_player: Node3D

func _ready() -> void:
	add_to_group("interactables")
	collision_layer = 4
	collision_mask = 2 # Player layer
	
	setup_visual_prompt()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func setup_visual_prompt() -> void:
	prompt_container = Node3D.new()
	prompt_container.name = "PromptContainer"
	prompt_container.position = Vector3(0, 2.0, 0)
	add_child(prompt_container)
	
	# Pill background mesh (dark semi-transparent rounded box/plane)
	prompt_bg = MeshInstance3D.new()
	var bg_box = BoxMesh.new()
	bg_box.size = Vector3(2.4, 0.5, 0.04)
	prompt_bg.mesh = bg_box
	var mat_bg = StandardMaterial3D.new()
	mat_bg.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_bg.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_bg.albedo_color = Color(0.04, 0.06, 0.1, 0.85)
	mat_bg.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_bg.material_override = mat_bg
	prompt_container.add_child(prompt_bg)
	
	# White billboard text
	prompt_label = Label3D.new()
	prompt_label.name = "PromptLabel"
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.text = get_formatted_prompt()
	prompt_label.font_size = 24
	prompt_label.outline_size = 2
	prompt_label.outline_modulate = Color("#000000")
	prompt_label.modulate = Color("#FFFFFF")
	prompt_label.position = Vector3(0, 0, 0.03)
	prompt_label.pixel_size = 0.008
	prompt_container.add_child(prompt_label)
	
	prompt_container.visible = false

func get_formatted_prompt() -> String:
	if is_mash:
		return "[E × 10] " + prompt_text.to_upper()
	elif hold_required:
		return "[Hold E] " + prompt_text.to_upper()
	else:
		return "[E] " + prompt_text.to_upper()

func _process(delta: float) -> void:
	if not cached_player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			cached_player = players[0]
			
	if cached_player and prompt_container:
		var dist = global_position.distance_to(cached_player.global_position)
		if dist <= max_visible_distance:
			prompt_container.visible = true
			pulse_time += delta * 3.0
			var s = 1.0 + 0.04 * sin(pulse_time)
			prompt_container.scale = Vector3(s, s, s)
			# Scale pill width to fit text length
			var char_len = prompt_label.text.length()
			var desired_width = max(1.8, char_len * 0.11)
			if prompt_bg.mesh is BoxMesh:
				prompt_bg.mesh.size.x = desired_width
		else:
			prompt_container.visible = false

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.is_in_group("player"):
		player_in_range = true
		cached_player = body
		body.current_interactable = self
		if AudioEngine: AudioEngine.play_sfx("interact_prompt")
		
		# In-game control reminders (show once per action, 3s duration)
		if is_mash:
			GameState.trigger_context_hint("mash_valve", "[Mash E] to force")
		elif hold_required:
			GameState.trigger_context_hint("console_hold", "[Hold E] to open")
		else:
			GameState.trigger_context_hint("interact", "[E] to interact")

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D and body.is_in_group("player"):
		player_in_range = false
		if body.current_interactable == self:
			body.current_interactable = null

func requires_hold() -> bool:
	return hold_required

func set_hold_progress(prog: float) -> void:
	if prog > 0.0:
		prompt_label.text = "[Hold E] HOLDING... " + str(int(prog * 100)) + "%"
		prompt_label.modulate = Color("#FFDD44")
	else:
		prompt_label.text = get_formatted_prompt()
		prompt_label.modulate = Color("#FFFFFF")

func interact(player_node: Node3D) -> void:
	emit_signal("interacted", player_node)
