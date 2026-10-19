class_name HUDController
extends CanvasLayer

@onready var top_bar: PanelContainer = $TopBar
@onready var hhi_label: Label = $TopBar/HBox/HHILabel
@onready var clock_label: Label = $TopBar/HBox/ClockLabel
@onready var level_label: Label = $TopBar/HBox/LevelLabel

@onready var right_panel: PanelContainer = $RightPanel
@onready var row_w: Label = $RightPanel/VBox/RowW/Value
@onready var row_p: Label = $RightPanel/VBox/RowP/Value
@onready var row_h: Label = $RightPanel/VBox/RowH/Value
@onready var row_c: Label = $RightPanel/VBox/RowC/Value
@onready var row_t: Label = $RightPanel/VBox/RowT/Value
@onready var row_s: Label = $RightPanel/VBox/RowS/Value

@onready var arrow_w: Label = $RightPanel/VBox/RowW/Arrow
@onready var arrow_p: Label = $RightPanel/VBox/RowP/Arrow
@onready var arrow_h: Label = $RightPanel/VBox/RowH/Arrow
@onready var arrow_c: Label = $RightPanel/VBox/RowC/Arrow
@onready var arrow_t: Label = $RightPanel/VBox/RowT/Arrow
@onready var arrow_s: Label = $RightPanel/VBox/RowS/Arrow

@onready var radio_panel: PanelContainer = $RadioArea
@onready var radio_portrait: ColorRect = $RadioArea/HBox/Portrait
@onready var radio_speaker: Label = $RadioArea/HBox/VBox/SpeakerLabel
@onready var radio_text: Label = $RadioArea/HBox/VBox/TextLabel

@onready var timers_vbox: VBoxContainer = $TimersArea
@onready var scramble_label: Label = $TimersArea/ScrambleLabel
@onready var sump_label: Label = $TimersArea/SumpLabel
@onready var evidence_hbox: HBoxContainer = $TimersArea/EvidenceHBox

@onready var corner_minimap: Control = $CornerMinimap
@onready var fullscreen_map: Control = $FullscreenMapLayer/CenterContainer/FullscreenMap
@onready var fullscreen_map_layer: CanvasLayer = $FullscreenMapLayer

@onready var grain_rect: ColorRect = $PostProcess/FilmGrain
@onready var vignette_rect: ColorRect = $PostProcess/Vignette
@onready var crosshair: Control = $Crosshair

# Typewriter state
var full_dialogue_text: String = ""
var typewriter_idx: int = 0
var typewriter_timer: float = 0.0
var radio_fade_timer: float = 0.0

# Previous values for delta arrows
var prev_potable: float = 2.50
var prev_pue: float = 1.15
var prev_tj: float = 71.5
var prev_creek: float = 35.0
var prev_trust: float = 30.0
var prev_sla: float = 100.0

var pulse_time: float = 0.0

func _ready() -> void:
	if fullscreen_map_layer:
		fullscreen_map_layer.visible = false
	radio_panel.visible = false
	setup_evidence_icons()
	setup_signals()
	setup_custom_crosshair()

func setup_signals() -> void:
	if GameState:
		GameState.dialogue_triggered.connect(on_dialogue_triggered)
		GameState.state_updated.connect(update_hud_display)
	if HHI:
		HHI.hhi_changed.connect(on_hhi_changed)

func setup_evidence_icons() -> void:
	for child in evidence_hbox.get_children():
		child.queue_free()
	for i in range(6):
		var slot = ColorRect.new()
		slot.name = "Slot_" + str(i)
		slot.custom_minimum_size = Vector2(16, 16)
		slot.color = Color("#1A202C")
		evidence_hbox.add_child(slot)

func setup_custom_crosshair() -> void:
	# Hide OS cursor and show 24x24 crosshair
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func toggle_fullscreen_map() -> void:
	if fullscreen_map_layer:
		fullscreen_map_layer.visible = !fullscreen_map_layer.visible
		if AudioEngine: AudioEngine.play_sfx("option_hover")

func on_dialogue_triggered(speaker: String, text: String, color: Color) -> void:
	full_dialogue_text = text
	typewriter_idx = 0
	typewriter_timer = 0.0
	radio_fade_timer = 6.0
	
	radio_speaker.text = speaker.to_upper()
	radio_speaker.modulate = color
	radio_portrait.color = color
	radio_text.text = ""
	radio_panel.visible = true
	radio_panel.modulate.a = 1.0
	
	if speaker.to_upper().contains("ROHAN"):
		if AudioEngine: AudioEngine.play_sfx("rohan_dialogue")
	else:
		if AudioEngine: AudioEngine.play_sfx("meera_dialogue")

func on_hhi_changed(val: float, tier_name: String) -> void:
	hhi_label.text = str(int(val)) + " — " + tier_name
	var tier_data = HHI.get_tier_data(tier_name)
	hhi_label.modulate = tier_data.get("label_color", Color("#F0A500"))

func _process(delta: float) -> void:
	pulse_time += delta
	update_typewriter(delta)
	update_timers(delta)
	update_hud_display()
	update_film_grain_seed()

func update_typewriter(delta: float) -> void:
	if radio_panel.visible:
		if typewriter_idx < full_dialogue_text.length():
			typewriter_timer += delta
			if typewriter_timer >= 0.025: # 25ms per char
				typewriter_timer = 0.0
				typewriter_idx += 1
				radio_text.text = full_dialogue_text.substr(0, typewriter_idx)
		else:
			radio_fade_timer -= delta
			if radio_fade_timer <= 1.0:
				radio_panel.modulate.a = clamp(radio_fade_timer, 0.0, 1.0)
			if radio_fade_timer <= 0.0:
				radio_panel.visible = false

func update_timers(delta: float) -> void:
	if not GameState:
		return
		
	# Scramble Timer
	if GameState.scramble_active:
		scramble_label.visible = true
		var mins = int(GameState.scramble_timer) / 60
		var secs = int(GameState.scramble_timer) % 60
		scramble_label.text = "SCRAMBLE: %d:%02d" % [mins, secs]
		if GameState.scramble_timer < 30.0:
			var scale_pulse = 1.0 + 0.1 * sin(pulse_time * 8.0)
			scramble_label.scale = Vector2(scale_pulse, scale_pulse)
			scramble_label.modulate = Color("#FF2222")
		else:
			scramble_label.scale = Vector2.ONE
			scramble_label.modulate = Color("#E04444")
	else:
		scramble_label.visible = false
		
	# Sump Timer
	if GameState.sump_active:
		sump_label.visible = true
		var mins = int(GameState.sump_timer) / 60
		var secs = int(GameState.sump_timer) % 60
		sump_label.text = "SUMP: %d:%02d" % [mins, secs]
	else:
		sump_label.visible = false

func update_hud_display() -> void:
	if not GameState:
		return
		
	clock_label.text = GameState.in_game_clock
	level_label.text = GameState.level_name
	
	# Update Evidence slots
	var slots = evidence_hbox.get_children()
	for i in range(slots.size()):
		if i < GameState.evidence:
			slots[i].color = Color("#F0A500") # Filled bright amber
		else:
			slots[i].color = Color("#1A202C") # Dark empty
			
	var sim = get_node_or_null("/root/Simulation")
	if sim:
		row_w.text = "%.2f MLD" % sim.potable_mld
		row_p.text = "%.3f" % sim.pue
		row_h.text = "%.1f °C" % sim.tj
		row_c.text = "%.0f%%" % sim.creek_health_pct
		row_t.text = "%.0f" % GameState.trust
		row_s.text = "%.0f%%" % GameState.sla
		
		# Delta Arrows (↑ green if improving, ↓ red if worsening)
		update_arrow(arrow_w, sim.potable_mld, prev_potable, false) # Lower potable is better
		update_arrow(arrow_p, sim.pue, prev_pue, false)                 # Lower PUE is better
		update_arrow(arrow_h, sim.tj, prev_tj, false)                   # Lower Tj is better
		update_arrow(arrow_c, sim.creek_health_pct, prev_creek, true)   # Higher creek is better
		update_arrow(arrow_t, GameState.trust, prev_trust, true)        # Higher trust is better
		update_arrow(arrow_s, GameState.sla, prev_sla, true)            # Higher SLA is better
		
		prev_potable = sim.potable_mld
		prev_pue = sim.pue
		prev_tj = sim.tj
		prev_creek = sim.creek_health_pct
		prev_trust = GameState.trust
		prev_sla = GameState.sla

func update_arrow(lbl: Label, curr: float, prev: float, higher_is_better: bool) -> void:
	var diff = curr - prev
	if abs(diff) < 0.005:
		lbl.text = "—"
		lbl.modulate = Color("#888888")
	elif diff > 0.0:
		lbl.text = "↑"
		lbl.modulate = Color("#44DD66") if higher_is_better else Color("#DD4444")
	else:
		lbl.text = "↓"
		lbl.modulate = Color("#DD4444") if higher_is_better else Color("#44DD66")

func update_film_grain_seed() -> void:
	if grain_rect and grain_rect.material is ShaderMaterial:
		grain_rect.material.set_shader_parameter("timer_seed", float(Time.get_ticks_msec()) * 0.001)
