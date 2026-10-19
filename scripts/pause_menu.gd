class_name PauseMenuController
extends CanvasLayer

const FieldNotesData = preload("res://scripts/field_notes_data.gd")

@onready var resume_btn: Button = $CenterContainer/Panel/VBox/ResumeBtn
@onready var mute_btn: Button = $CenterContainer/Panel/VBox/MuteBtn
@onready var notes_btn: Button = $CenterContainer/Panel/VBox/NotesBtn
@onready var quit_btn: Button = $CenterContainer/Panel/VBox/QuitBtn

@onready var notes_modal: PanelContainer = $CenterContainer/FieldNotesModal
@onready var close_notes_btn: Button = $CenterContainer/FieldNotesModal/VBox/CloseNotesBtn
@onready var notes_vbox: VBoxContainer = $CenterContainer/FieldNotesModal/VBox/Scroll/NotesVBox

func _ready() -> void:
	visible = false
	notes_modal.visible = false
	resume_btn.pressed.connect(toggle_pause)
	mute_btn.pressed.connect(_on_mute_pressed)
	notes_btn.pressed.connect(_on_notes_pressed)
	close_notes_btn.pressed.connect(_on_close_notes_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			# Check if debrief or dev panel is open first
			var dev = get_parent().get_node_or_null("DevPanelLayer")
			if dev and dev.visible:
				return
			toggle_pause()

func toggle_pause() -> void:
	visible = !visible
	notes_modal.visible = false
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().paused = true
		if AudioEngine:
			mute_btn.text = "AUDIO: [MUTED]" if AudioEngine.is_muted else "AUDIO: [ON]"
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_tree().paused = false

func _on_mute_pressed() -> void:
	if AudioEngine:
		var muted = AudioEngine.toggle_mute()
		mute_btn.text = "AUDIO: [MUTED]" if muted else "AUDIO: [ON]"

func _on_notes_pressed() -> void:
	notes_modal.visible = true
	# Populate unlocked field notes
	for child in notes_vbox.get_children():
		child.queue_free()
		
	for note in FieldNotesData.NOTES:
		var is_unlocked = GameState.field_notes_found.has(note["id"])
		var box = PanelContainer.new()
		var vb = VBoxContainer.new()
		box.add_child(vb)
		
		var t_lbl = Label.new()
		t_lbl.text = note["title"] if is_unlocked else "NOTE %02d — [LOCKED IN-WORLD DOCUMENT]" % note["id"]
		t_lbl.modulate = Color("#F0A500") if is_unlocked else Color("#666666")
		vb.add_child(t_lbl)
		
		if is_unlocked:
			var c_lbl = Label.new()
			c_lbl.text = note["content"] + "\nSource: " + note["source"]
			c_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			c_lbl.modulate = Color("#D0D5DD")
			vb.add_child(c_lbl)
			
		notes_vbox.add_child(box)

func _on_close_notes_pressed() -> void:
	notes_modal.visible = false

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
