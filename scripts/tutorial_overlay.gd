class_name TutorialOverlayController
extends CanvasLayer

signal tutorial_completed

@onready var container_beat1: Control = $Beat1_WASD
@onready var walk_progress_bar: ProgressBar = $Beat1_WASD/WalkProgressBar

@onready var container_beat2: Control = $Beat2_Camera
@onready var container_beat3: Control = $Beat3_Interact
@onready var container_beat4: Control = $Beat4_Tool
@onready var tool_readout: PanelContainer = $Beat4_Tool/ReadoutPanel

@onready var container_beat5: Control = $Beat5_Sprint
@onready var sprint_timer_lbl: Label = $Beat5_Sprint/Center/VBox/SprintTimerLabel

@onready var container_beat6: Control = $Beat6_HUDTour
@onready var container_beat7: Control = $Beat7_DecisionDemo
@onready var container_beat8: Control = $Beat8_Ready

var active_beat: int = 0
var is_active: bool = false
var demo_timer: float = 0.0

func _ready() -> void:
	hide_all_beats()

func hide_all_beats() -> void:
	container_beat1.visible = false
	container_beat2.visible = false
	container_beat3.visible = false
	container_beat4.visible = false
	container_beat5.visible = false
	container_beat6.visible = false
	container_beat7.visible = false
	container_beat8.visible = false

func start_tutorial() -> void:
	is_active = true
	set_beat(1)

func set_beat(beat: int) -> void:
	active_beat = beat
	hide_all_beats()
	
	match beat:
		1:
			container_beat1.visible = true
			walk_progress_bar.value = 0.0
		2:
			container_beat2.visible = true
		3:
			container_beat3.visible = true
		4:
			container_beat4.visible = true
			tool_readout.visible = false
		5:
			container_beat5.visible = true
			sprint_timer_lbl.text = "GATE CLOSING IN: 10.0s"
		6:
			container_beat6.visible = true
		7:
			container_beat7.visible = true
			demo_timer = 0.0
			# Auto-progress demo card after 3.5 seconds
			get_tree().create_timer(3.5).timeout.connect(func():
				if active_beat == 7 and is_active:
					set_beat(8)
			)
		8:
			container_beat8.visible = true
			var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			container_beat8.modulate.a = 0.0
			tween.tween_property(container_beat8, "modulate:a", 1.0, 0.6)
			tween.tween_interval(1.8)
			tween.tween_property(container_beat8, "modulate:a", 0.0, 0.6)
			await tween.finished
			complete_tutorial()

func update_walk_progress(dist: float) -> void:
	if walk_progress_bar:
		walk_progress_bar.value = clamp(dist / 10.0 * 100.0, 0.0, 100.0)

func show_tool_readout() -> void:
	if tool_readout:
		tool_readout.visible = true
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tool_readout.modulate.a = 0.0
		tween.tween_property(tool_readout, "modulate:a", 1.0, 0.3)
		tween.tween_interval(2.5)
		tween.tween_property(tool_readout, "modulate:a", 0.0, 0.3)
		await tween.finished
		tool_readout.visible = false

func update_sprint_timer(sec: float) -> void:
	if sprint_timer_lbl:
		sprint_timer_lbl.text = "GATE CLOSING IN: %.1fs" % max(0.0, sec)

func complete_tutorial() -> void:
	is_active = false
	hide_all_beats()
	tutorial_completed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_SPACE or event.physical_keycode == KEY_E or event.physical_keycode == KEY_ENTER:
			if active_beat == 6:
				set_beat(7)
			elif active_beat == 7:
				set_beat(8)
	elif event is InputEventMouseButton and event.pressed:
		if active_beat == 6:
			set_beat(7)
		elif active_beat == 7:
			set_beat(8)

