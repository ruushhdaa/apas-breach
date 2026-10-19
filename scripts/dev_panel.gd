class_name DevPanelController
extends CanvasLayer

@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var close_btn: Button = $CenterContainer/PanelContainer/VBox/CloseButton

# Sim controls
@onready var it_slider: HSlider = $CenterContainer/PanelContainer/VBox/SimBox/ITSlider
@onready var it_label: Label = $CenterContainer/PanelContainer/VBox/SimBox/ITLabel
@onready var throttle_slider: HSlider = $CenterContainer/PanelContainer/VBox/SimBox/ThrottleSlider
@onready var throttle_label: Label = $CenterContainer/PanelContainer/VBox/SimBox/ThrottleLabel
@onready var topo_option: OptionButton = $CenterContainer/PanelContainer/VBox/SimBox/HBoxTopo/TopoOption
@onready var water_option: OptionButton = $CenterContainer/PanelContainer/VBox/SimBox/HBoxTopo/WaterOption

# HHI jump buttons
@onready var btn_restored: Button = $CenterContainer/PanelContainer/VBox/HHIBox/BtnRestored
@onready var btn_recovering: Button = $CenterContainer/PanelContainer/VBox/HHIBox/BtnRecovering
@onready var btn_strained: Button = $CenterContainer/PanelContainer/VBox/HHIBox/BtnStrained
@onready var btn_critical: Button = $CenterContainer/PanelContainer/VBox/HHIBox/BtnCritical
@onready var btn_collapse: Button = $CenterContainer/PanelContainer/VBox/HHIBox/BtnCollapse

# GameState controls
@onready var level_jump_1: Button = $CenterContainer/PanelContainer/VBox/StateBox/HBoxLvl/L1
@onready var level_jump_2: Button = $CenterContainer/PanelContainer/VBox/StateBox/HBoxLvl/L2
@onready var level_jump_3: Button = $CenterContainer/PanelContainer/VBox/StateBox/HBoxLvl/L3
@onready var level_jump_4: Button = $CenterContainer/PanelContainer/VBox/StateBox/HBoxLvl/L4
@onready var level_jump_5: Button = $CenterContainer/PanelContainer/VBox/StateBox/HBoxLvl/L5

@onready var trust_spin: SpinBox = $CenterContainer/PanelContainer/VBox/StateBox/Grid/TrustSpin
@onready var sla_spin: SpinBox = $CenterContainer/PanelContainer/VBox/StateBox/Grid/SLASpin
@onready var evidence_spin: SpinBox = $CenterContainer/PanelContainer/VBox/StateBox/Grid/EvidenceSpin
@onready var pressure_spin: SpinBox = $CenterContainer/PanelContainer/VBox/StateBox/Grid/PressureSpin

# Fail state toggles
@onready var toggle_scramble: CheckButton = $CenterContainer/PanelContainer/VBox/FailBox/ToggleScramble
@onready var toggle_sump: CheckButton = $CenterContainer/PanelContainer/VBox/FailBox/ToggleSump
@onready var toggle_audio_mute: CheckButton = $CenterContainer/PanelContainer/VBox/FailBox/ToggleMute

func _ready() -> void:
	visible = false
	setup_dev_listeners()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F1:
			toggle_panel()

func toggle_panel() -> void:
	visible = !visible
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		sync_controls()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func setup_dev_listeners() -> void:
	close_btn.pressed.connect(toggle_panel)
	
	# Sim
	it_slider.value_changed.connect(func(v):
		Simulation.it_load = v
		it_label.text = "IT Load: " + str(int(v)) + " MW"
	)
	throttle_slider.value_changed.connect(func(v):
		Simulation.throttle_pct = v
		throttle_label.text = "Throttle: " + str(int(v)) + "%"
	)
	topo_option.item_selected.connect(func(idx):
		var topos = ["HYBRID_EVAP", "DRY", "DTC"]
		Simulation.set_topology(topos[idx])
	)
	water_option.item_selected.connect(func(idx):
		var sources = ["POTABLE", "STP"]
		Simulation.set_water_source(sources[idx])
	)
	
	# HHI
	btn_restored.pressed.connect(func(): HHI.force_tier("RESTORED"))
	btn_recovering.pressed.connect(func(): HHI.force_tier("RECOVERING"))
	btn_strained.pressed.connect(func(): HHI.force_tier("STRAINED"))
	btn_critical.pressed.connect(func(): HHI.force_tier("CRITICAL"))
	btn_collapse.pressed.connect(func(): HHI.force_tier("COLLAPSE"))
	
	# State
	level_jump_1.pressed.connect(func(): jump_to_level(1))
	level_jump_2.pressed.connect(func(): jump_to_level(2))
	level_jump_3.pressed.connect(func(): jump_to_level(3))
	level_jump_4.pressed.connect(func(): jump_to_level(4))
	level_jump_5.pressed.connect(func(): jump_to_level(5))
	
	trust_spin.value_changed.connect(func(v): GameState.trust = v)
	sla_spin.value_changed.connect(func(v): GameState.sla = v)
	evidence_spin.value_changed.connect(func(v): GameState.evidence = int(v))
	pressure_spin.value_changed.connect(func(v): GameState.pressure = v)
	
	toggle_scramble.toggled.connect(func(on):
		GameState.scramble_active = on
		GameState.scramble_timer = 90.0 if on else 0.0
	)
	toggle_sump.toggled.connect(func(on):
		GameState.sump_active = on
		GameState.sump_timer = 240.0 if on else 0.0
	)
	toggle_audio_mute.toggled.connect(func(_on):
		AudioEngine.toggle_mute()
	)

func jump_to_level(lvl: int) -> void:
	var mgr = get_tree().root.find_child("MissionManager", true, false)
	if mgr:
		mgr.start_level(lvl)
	else:
		GameState.set_level(lvl)

func sync_controls() -> void:
	if Simulation:
		it_slider.value = Simulation.it_load
		throttle_slider.value = Simulation.throttle_pct
	if GameState:
		trust_spin.value = GameState.trust
		sla_spin.value = GameState.sla
		evidence_spin.value = GameState.evidence
		pressure_spin.value = GameState.pressure
		toggle_scramble.button_pressed = GameState.scramble_active
		toggle_sump.button_pressed = GameState.sump_active
	if AudioEngine:
		toggle_audio_mute.button_pressed = AudioEngine.is_muted
