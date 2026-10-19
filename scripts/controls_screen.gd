class_name ControlsScreen
extends CanvasLayer

signal controls_closed

@onready var btn_got_it: Button = $Panel/VBox/BottomBar/BtnGotIt
@onready var lbl_skip: Label = $Panel/VBox/BottomBar/LblSkip

var is_from_pause: bool = false

func _ready() -> void:
	if btn_got_it:
		btn_got_it.pressed.connect(_on_got_it_pressed)
		
	if is_from_pause:
		btn_got_it.text = "CLOSE"
		if lbl_skip: lbl_skip.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_SPACE or event.physical_keycode == KEY_ENTER or event.physical_keycode == KEY_ESCAPE:
			_on_got_it_pressed()

func _on_got_it_pressed() -> void:
	if AudioEngine: AudioEngine.play_sfx("menu_confirm")
	GameState.controls_seen = true
	visible = false
	controls_closed.emit()
	if not is_from_pause:
		get_tree().change_scene_to_file("res://scenes/dispatch_screen.tscn")
	else:
		queue_free()
