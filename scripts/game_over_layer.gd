class_name GameOverLayerController
extends CanvasLayer

@onready var title_label: Label = $CenterContainer/Panel/VBox/TitleLabel
@onready var subtext_label: Label = $CenterContainer/Panel/VBox/SubtextLabel
@onready var retry_button: Button = $CenterContainer/Panel/VBox/HBox/RetryButton
@onready var menu_button: Button = $CenterContainer/Panel/VBox/HBox/MenuButton

func _ready() -> void:
	visible = false
	if GameState:
		GameState.game_over_triggered.connect(on_game_over)
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func on_game_over(reason: String, subtext: String) -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	title_label.text = reason
	subtext_label.text = subtext
	if AudioEngine:
		AudioEngine.play_sfx("game_over")

func _on_retry_pressed() -> void:
	GameState.is_game_over = false
	GameState.scramble_active = false
	GameState.sump_active = false
	GameState.heat_clock_active = false
	var mgr = get_tree().root.find_child("MissionManager", true, false)
	if mgr:
		mgr.start_level(GameState.current_level)
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_menu_pressed() -> void:
	GameState.reset_game()
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
