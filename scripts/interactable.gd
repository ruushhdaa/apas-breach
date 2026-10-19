class_name InteractableArea3D
extends Area3D

signal interacted(player)

@export var prompt_text: String = "INTERACT"
@export var hold_required: bool = false
@export var interact_distance: float = 3.5

var prompt_label: Label3D
var progress_bar_mesh: MeshInstance3D
var pulse_time: float = 0.0
var player_in_range: bool = false

func _ready() -> void:
	add_to_group("interactables")
	collision_layer = 4
	collision_mask = 2 # Player layer
	
	setup_visual_prompt()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func setup_visual_prompt() -> void:
	prompt_label = Label3D.new()
	prompt_label.name = "PromptLabel"
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.text = "[E] " + prompt_text
	prompt_label.font_size = 26
	prompt_label.outline_size = 3
	prompt_label.outline_modulate = Color("#000000")
	prompt_label.modulate = Color("#F0A500")
	prompt_label.position = Vector3(0, 1.8, 0)
	prompt_label.visible = false
	prompt_label.pixel_size = 0.008
	add_child(prompt_label)

func _process(delta: float) -> void:
	if player_in_range and prompt_label:
		pulse_time += delta * 4.0
		var s = 1.0 + 0.08 * sin(pulse_time)
		prompt_label.scale = Vector3(s, s, s)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.is_in_group("player"):
		player_in_range = true
		prompt_label.visible = true
		body.current_interactable = self
		if AudioEngine: AudioEngine.play_sfx("interact_prompt")

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D and body.is_in_group("player"):
		player_in_range = false
		prompt_label.visible = false
		if body.current_interactable == self:
			body.current_interactable = null

func requires_hold() -> bool:
	return hold_required

func set_hold_progress(prog: float) -> void:
	if prog > 0.0:
		prompt_label.text = "[E] HOLDING... " + str(int(prog * 100)) + "%"
		prompt_label.modulate = Color("#FFDD44")
	else:
		prompt_label.text = "[E] " + prompt_text
		prompt_label.modulate = Color("#F0A500")

func interact(player: Node3D) -> void:
	emit_signal("interacted", player)
