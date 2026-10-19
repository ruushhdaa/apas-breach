class_name TitleScreenController
extends Control

@onready var world_subview: SubViewport = $SubViewportContainer/SubViewport
@onready var camera_pivot: Node3D = $SubViewportContainer/SubViewport/World/TitleCameraPivot
@onready var title_cam: Camera3D = $SubViewportContainer/SubViewport/World/TitleCameraPivot/Camera3D

@onready var menu_container: Control = $UI/CenterMenu
@onready var menu_vbox: VBoxContainer = $UI/CenterMenu/MenuVBox
@onready var press_any_key_lbl: Label = $UI/PressAnyKeyLabel
@onready var bottom_hhi_lbl: Label = $UI/BottomBar/HHI
@onready var bottom_ver_lbl: Label = $UI/BottomBar/Version

# Modals
@onready var settings_modal: PanelContainer = $UI/SettingsModal
@onready var specialists_modal: PanelContainer = $UI/SpecialistsModal
@onready var field_notes_modal: PanelContainer = $UI/FieldNotesModal

var menu_items = ["NEW GAME", "CONTINUE", "SPECIALISTS", "FIELD NOTES", "SETTINGS", "CREDITS", "QUIT"]
var current_menu_idx: int = 0
var menu_buttons: Array = []

var cam_time: float = 0.0
var has_pressed_any_key: bool = false
var pulse_time: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if AudioEngine:
		AudioEngine.current_bgm_mode = "TITLE"
		
	# Initialize Level 1 world at HHI 38
	if HHI:
		HHI.current_hhi = 38.0
		
	setup_menu()
	setup_settings_screen()
	setup_specialists_screen()
	setup_field_notes_screen()
	
	menu_container.visible = false
	press_any_key_lbl.visible = true

func _process(delta: float) -> void:
	# 45s looping camera pan
	cam_time = fmod(cam_time + delta, 45.0)
	update_cinematic_camera(cam_time)
	
	# Press any key pulsing text (1.2s loop 0.4->1.0->0.4)
	if not has_pressed_any_key:
		pulse_time += delta
		var alpha = 0.7 + 0.3 * sin(pulse_time * TAU / 1.2)
		press_any_key_lbl.modulate = Color(1.0, 1.0, 1.0, alpha)

func update_cinematic_camera(t: float) -> void:
	if not title_cam:
		return
		
	var cam_pos: Vector3
	var look_target: Vector3
	
	if t < 15.0:
		# Keyframe 0s->15s: position above Gate 4, looking at compound, drift toward cooling towers
		var progress = t / 15.0
		var p0 = Vector3(0.0, 8.0, 58.0)
		var p1 = Vector3(5.0, 14.0, -5.0)
		cam_pos = p0.lerp(p1, progress)
		var l0 = Vector3(0.0, 2.0, 30.0)
		var l1 = Vector3(14.0, 8.0, -35.0)
		look_target = l0.lerp(l1, progress)
	elif t < 30.0:
		# Keyframe 15s->30s: arc right to show creek and colony
		var progress = (t - 15.0) / 15.0
		var p1 = Vector3(5.0, 14.0, -5.0)
		var p2 = Vector3(45.0, 12.0, -10.0)
		cam_pos = p1.lerp(p2, progress)
		var l1 = Vector3(14.0, 8.0, -35.0)
		var l2 = Vector3(85.0, 1.0, 0.0)
		look_target = l1.lerp(l2, progress)
	else:
		# Keyframe 30s->45s: pull back wide aerial shot of full facility
		var progress = (t - 30.0) / 15.0
		var p2 = Vector3(45.0, 12.0, -10.0)
		var p3 = Vector3(0.0, 22.0, 75.0)
		cam_pos = p2.lerp(p3, progress)
		var l2 = Vector3(85.0, 1.0, 0.0)
		var l3 = Vector3(10.0, 3.0, 5.0)
		look_target = l2.lerp(l3, progress)
		
	title_cam.global_position = cam_pos
	title_cam.look_at(look_target, Vector3.UP)

func setup_menu() -> void:
	for child in menu_vbox.get_children():
		child.queue_free()
	menu_buttons.clear()
	
	var can_continue = GameState.has_save() if GameState else false
	
	for i in range(menu_items.size()):
		var item_name = menu_items[i]
		var btn = Button.new()
		btn.text = "▶ " + item_name if i == current_menu_idx else "   " + item_name
		btn.custom_minimum_size = Vector2(320, 44)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 26)
		btn.flat = true
		
		if item_name == "CONTINUE" and not can_continue:
			btn.disabled = true
			btn.modulate = Color(0.4, 0.4, 0.4, 0.5)
		else:
			btn.modulate = Color("#F0A500") if i == current_menu_idx else Color("#C8C0B0")
			
		var idx = i
		btn.pressed.connect(func(): on_menu_selected(idx))
		btn.mouse_entered.connect(func(): on_menu_hover(idx))
		menu_vbox.add_child(btn)
		menu_buttons.append(btn)

func on_menu_hover(idx: int) -> void:
	if menu_items[idx] == "CONTINUE" and not (GameState and GameState.has_save()):
		return
	current_menu_idx = idx
	update_menu_visuals()
	if AudioEngine: AudioEngine.play_sfx("option_hover")

func update_menu_visuals() -> void:
	for i in range(menu_buttons.size()):
		var btn = menu_buttons[i]
		var item_name = menu_items[i]
		if i == current_menu_idx:
			btn.text = "▶ " + item_name
			btn.modulate = Color("#F0A500")
			btn.position.x = 14.0 # Selected state slide in from left
		else:
			btn.text = "   " + item_name
			btn.position.x = 0.0
			if item_name == "CONTINUE" and not (GameState and GameState.has_save()):
				btn.modulate = Color(0.4, 0.4, 0.4, 0.5)
			else:
				btn.modulate = Color("#C8C0B0")

func _input(event: InputEvent) -> void:
	if not has_pressed_any_key:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			has_pressed_any_key = true
			press_any_key_lbl.visible = false
			menu_container.visible = true
			if AudioEngine:
				AudioEngine.play_sfx("option_select")
			return
			
	if settings_modal.visible or specialists_modal.visible or field_notes_modal.visible:
		if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
			close_all_modals()
		return
		
	if event is InputEventKey and event.pressed:
		match event.physical_keycode:
			KEY_UP, KEY_W:
				current_menu_idx = (current_menu_idx - 1 + menu_items.size()) % menu_items.size()
				if menu_items[current_menu_idx] == "CONTINUE" and not (GameState and GameState.has_save()):
					current_menu_idx = (current_menu_idx - 1 + menu_items.size()) % menu_items.size()
				update_menu_visuals()
				if AudioEngine: AudioEngine.play_sfx("option_hover")
			KEY_DOWN, KEY_S:
				current_menu_idx = (current_menu_idx + 1) % menu_items.size()
				if menu_items[current_menu_idx] == "CONTINUE" and not (GameState and GameState.has_save()):
					current_menu_idx = (current_menu_idx + 1) % menu_items.size()
				update_menu_visuals()
				if AudioEngine: AudioEngine.play_sfx("option_hover")
			KEY_ENTER, KEY_SPACE:
				on_menu_selected(current_menu_idx)

func on_menu_selected(idx: int) -> void:
	if AudioEngine: AudioEngine.play_sfx("option_select")
	match menu_items[idx]:
		"NEW GAME":
			if GameState and not GameState.controls_seen:
				get_tree().change_scene_to_file("res://scenes/controls_screen.tscn")
			else:
				get_tree().change_scene_to_file("res://scenes/dispatch_screen.tscn")
		"CONTINUE":
			if GameState and GameState.load_game():
				get_tree().change_scene_to_file("res://scenes/level_0.tscn")
		"SPECIALISTS":
			open_specialists_modal()
		"FIELD NOTES":
			open_field_notes_modal()
		"SETTINGS":
			open_settings_modal()
		"CREDITS":
			get_tree().change_scene_to_file("res://scenes/credits.tscn")
		"QUIT":
			get_tree().quit()

# ----------------- MODALS -----------------
func close_all_modals() -> void:
	settings_modal.visible = false
	specialists_modal.visible = false
	field_notes_modal.visible = false
	menu_container.visible = true

func open_settings_modal() -> void:
	menu_container.visible = false
	settings_modal.visible = true

func open_specialists_modal() -> void:
	menu_container.visible = false
	specialists_modal.visible = true

func open_field_notes_modal() -> void:
	menu_container.visible = false
	field_notes_modal.visible = true

func setup_settings_screen() -> void:
	var vbox = settings_modal.find_child("SettingsVBox", true, false)
	if not vbox: return
	
	var master_slider = vbox.find_child("MasterSlider", true, false)
	var bgm_slider = vbox.find_child("BGMSlider", true, false)
	var sfx_slider = vbox.find_child("SFXSlider", true, false)
	var res_opt = vbox.find_child("ResOption", true, false)
	var fs_chk = vbox.find_child("FullscreenCheck", true, false)
	var grain_chk = vbox.find_child("GrainCheck", true, false)
	var back_btn = vbox.find_child("BackButton", true, false)
	
	if master_slider:
		master_slider.value = 100
		master_slider.value_changed.connect(func(v): AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(v / 100.0)))
	if bgm_slider:
		bgm_slider.value = 80
	if sfx_slider:
		sfx_slider.value = 90
		
	if res_opt:
		res_opt.clear()
		res_opt.add_item("540p (960x540) [PS2 Chunky]")
		res_opt.add_item("720p (1280x720)")
		res_opt.add_item("1080p (1920x1080)")
		res_opt.select(1)
		res_opt.item_selected.connect(func(idx):
			match idx:
				0: DisplayServer.window_set_size(Vector2i(960, 540))
				1: DisplayServer.window_set_size(Vector2i(1280, 720))
				2: DisplayServer.window_set_size(Vector2i(1920, 1080))
		)
		
	if fs_chk:
		fs_chk.toggled.connect(func(pressed):
			if pressed:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		)
		
	if back_btn:
		back_btn.pressed.connect(close_all_modals)

func setup_specialists_screen() -> void:
	var back_btn = specialists_modal.find_child("SpecBackButton", true, false)
	if back_btn:
		back_btn.pressed.connect(close_all_modals)

func setup_field_notes_screen() -> void:
	var vbox = field_notes_modal.find_child("NotesVBox", true, false)
	var back_btn = field_notes_modal.find_child("NotesBackButton", true, false)
	if back_btn:
		back_btn.pressed.connect(close_all_modals)
	if not vbox: return
	
	for child in vbox.get_children():
		child.queue_free()
		
	for i in range(FieldNotesData.NOTES.size()):
		var note = FieldNotesData.NOTES[i]
		var n_label = Label.new()
		n_label.text = "#" + str(i + 1) + " — " + note["title"].to_upper() + "\n" + note["content"] + "\n[Source: " + note["source"] + "]\n"
		n_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		n_label.add_theme_font_size_override("font_size", 13)
		n_label.modulate = Color("#E8E0D0")
		vbox.add_child(n_label)
