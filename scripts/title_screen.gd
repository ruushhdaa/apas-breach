class_name TitleScreenController
extends Control

@onready var menu_vbox: VBoxContainer = $UI/CenterMenu/MenuVBox
@onready var mute_button: Button = $UI/MuteButton
@onready var hhi_readout: Label = $UI/HHIReadout
@onready var camera_pivot: Node3D = $SubViewportContainer/SubViewport/World/TitleCameraPivot
@onready var title_cam: Camera3D = $SubViewportContainer/SubViewport/World/TitleCameraPivot/Camera3D

var menu_items = ["NEW GAME", "LOAD GAME", "SPECIALISTS", "FIELD NOTES", "CREDITS", "QUIT"]
var current_menu_idx: int = 0
var menu_labels: Array = []
var cam_pan_angle: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if AudioEngine:
		AudioEngine.current_bgm_mode = "TITLE"
	setup_menu()
	if mute_button:
		mute_button.pressed.connect(_on_mute_pressed)

func setup_menu() -> void:
	for child in menu_vbox.get_children():
		child.queue_free()
	menu_labels.clear()
	
	for i in range(menu_items.size()):
		var item_name = menu_items[i]
		var btn = Button.new()
		btn.text = "> " + item_name if i == current_menu_idx else "  " + item_name
		btn.custom_minimum_size = Vector2(280, 42)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 22)
		
		if item_name == "LOAD GAME":
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5, 0.6)
		else:
			btn.modulate = Color("#F0A500") if i == current_menu_idx else Color("#E8E0D0")
			
		var idx = i
		btn.pressed.connect(func(): on_menu_selected(idx))
		btn.mouse_entered.connect(func(): on_menu_hover(idx))
		menu_vbox.add_child(btn)
		menu_labels.append(btn)

func on_menu_hover(idx: int) -> void:
	if menu_items[idx] == "LOAD GAME":
		return
	current_menu_idx = idx
	update_menu_visuals()
	if AudioEngine: AudioEngine.play_sfx("option_hover")

func update_menu_visuals() -> void:
	for i in range(menu_labels.size()):
		var btn = menu_labels[i]
		var item_name = menu_items[i]
		if i == current_menu_idx:
			btn.text = "> " + item_name
			btn.modulate = Color("#F0A500")
		else:
			btn.text = "  " + item_name
			if item_name == "LOAD GAME":
				btn.modulate = Color(0.5, 0.5, 0.5, 0.6)
			else:
				btn.modulate = Color("#E8E0D0")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.physical_keycode:
			KEY_UP:
				current_menu_idx = (current_menu_idx - 1 + menu_items.size()) % menu_items.size()
				if menu_items[current_menu_idx] == "LOAD GAME":
					current_menu_idx = (current_menu_idx - 1 + menu_items.size()) % menu_items.size()
				update_menu_visuals()
				if AudioEngine: AudioEngine.play_sfx("option_hover")
			KEY_DOWN:
				current_menu_idx = (current_menu_idx + 1) % menu_items.size()
				if menu_items[current_menu_idx] == "LOAD GAME":
					current_menu_idx = (current_menu_idx + 1) % menu_items.size()
				update_menu_visuals()
				if AudioEngine: AudioEngine.play_sfx("option_hover")
			KEY_ENTER:
				on_menu_selected(current_menu_idx)

func on_menu_selected(idx: int) -> void:
	if AudioEngine: AudioEngine.play_sfx("option_select")
	match menu_items[idx]:
		"NEW GAME":
			get_tree().change_scene_to_file("res://scenes/dispatch_screen.tscn")
		"SPECIALISTS":
			get_tree().change_scene_to_file("res://scenes/dispatch_screen.tscn")
		"FIELD NOTES":
			open_field_notes_modal()
		"CREDITS":
			get_tree().change_scene_to_file("res://scenes/credits.tscn")
		"QUIT":
			get_tree().quit()

func open_field_notes_modal() -> void:
	var modal = get_node_or_null("UI/FieldNotesModal")
	if modal:
		modal.visible = true

func _on_mute_pressed() -> void:
	if AudioEngine:
		var muted = AudioEngine.toggle_mute()
		mute_button.text = "AUDIO: [MUTED]" if muted else "AUDIO: [ON]"

func _process(delta: float) -> void:
	# Camera pan across facility compound (loop every 45s)
	cam_pan_angle += delta * (TAU / 45.0)
	if camera_pivot:
		camera_pivot.rotation.y = cam_pan_angle
