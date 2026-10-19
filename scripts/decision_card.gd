class_name DecisionCardController
extends CanvasLayer

signal decision_confirmed(decision_id: String, option_letter: String)

@onready var panel_container: PanelContainer = $CenterContainer/PanelContainer
@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel
@onready var options_container: VBoxContainer = $CenterContainer/PanelContainer/VBoxContainer/OptionsContainer
@onready var confirm_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ConfirmButton
@onready var debrief_panel: PanelContainer = $CenterContainer/DebriefPanel
@onready var debrief_title: Label = $CenterContainer/DebriefPanel/VBoxContainer/DebriefTitle
@onready var debrief_body: Label = $CenterContainer/DebriefPanel/VBoxContainer/DebriefBody
@onready var debrief_hhi: Label = $CenterContainer/DebriefPanel/VBoxContainer/DebriefHHI

var current_card_data: Dictionary = {}
var selected_option: String = ""
var option_buttons: Dictionary = {}
var is_debrief_active: bool = false
var debrief_timer: float = 0.0

func _ready() -> void:
	visible = false
	debrief_panel.visible = false
	confirm_button.pressed.connect(_on_confirm_pressed)

func open_card(card_data: Dictionary) -> void:
	current_card_data = card_data
	selected_option = ""
	visible = true
	debrief_panel.visible = false
	panel_container.visible = true
	is_debrief_active = false
	
	if AudioEngine: AudioEngine.play_sfx("decision_open")
	
	title_label.text = card_data.get("title", "SYSTEM DECISION REQUIRED")
	
	# Clear old options
	for child in options_container.get_children():
		child.queue_free()
	option_buttons.clear()
	
	var options = card_data.get("options", [])
	for opt in options:
		var letter = opt["letter"]
		var btn = Button.new()
		btn.text = "[" + letter + "] " + opt["text"]
		btn.custom_minimum_size = Vector2(560, 48)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Consequence label below
		var vbox = VBoxContainer.new()
		vbox.add_child(btn)
		
		var preview_lbl = Label.new()
		preview_lbl.text = "   Consequences: " + opt.get("preview", "")
		preview_lbl.modulate = Color("#A0A5B5")
		vbox.add_child(preview_lbl)
		
		# Check requirements (e.g. Evidence >= 3, Budget, etc.)
		var can_pick = true
		if opt.has("min_evidence"):
			if GameState.evidence < opt["min_evidence"]:
				can_pick = false
				preview_lbl.text += " (REQUIRES EVIDENCE >= " + str(opt["min_evidence"]) + " — LOCKED)"
				btn.disabled = true
		if opt.has("cost_budget"):
			if GameState.budget < opt["cost_budget"]:
				can_pick = false
				preview_lbl.text += " (COST: " + str(opt["cost_budget"]) + " CR — INSUFFICIENT BUDGET)"
				btn.disabled = true
		if opt.has("max_pressure"):
			if GameState.pressure >= opt["max_pressure"]:
				can_pick = false
				preview_lbl.text += " (AUDIT PRESSURE TOO HIGH — LOCKED)"
				btn.disabled = true
				
		btn.pressed.connect(func(): select_option(letter))
		btn.mouse_entered.connect(func():
			if AudioEngine: AudioEngine.play_sfx("option_hover")
		)
		
		options_container.add_child(vbox)
		option_buttons[letter] = btn
		
	# Select first available option by default
	for opt in options:
		var l = opt["letter"]
		if not option_buttons[l].disabled:
			select_option(l)
			break
			
	update_confirm_button()

func select_option(letter: String) -> void:
	if not option_buttons.has(letter) or option_buttons[letter].disabled:
		return
	selected_option = letter
	if AudioEngine: AudioEngine.play_sfx("option_select")
	
	for l in option_buttons:
		if l == letter:
			option_buttons[l].modulate = Color("#F0A500")
		else:
			option_buttons[l].modulate = Color("#FFFFFF")
	update_confirm_button()

func update_confirm_button() -> void:
	if selected_option != "":
		confirm_button.text = "CONFIRM OPTION [" + selected_option + "] (ENTER)"
		confirm_button.disabled = false
	else:
		confirm_button.text = "SELECT AN OPTION"
		confirm_button.disabled = true

func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	if is_debrief_active:
		if event.is_action_pressed("interact") or event.is_action_pressed("skip_action"):
			close_debrief()
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_A: select_option("A")
			KEY_B: select_option("B")
			KEY_C: select_option("C")
			KEY_ENTER: _on_confirm_pressed()

func _on_confirm_pressed() -> void:
	if selected_option == "":
		return
	var card_id = current_card_data.get("id", "")
	apply_consequences(card_id, selected_option)
	panel_container.visible = false
	show_debrief(card_id, selected_option)

func apply_consequences(card_id: String, option_letter: String) -> void:
	var sim = get_node_or_null("/root/Simulation")
	var state = GameState
	
	match card_id:
		"LEVEL1_BYPASS":
			match option_letter:
				"A": # Close it now
					# W↓↓↓ H↑↑↑ T↑ S↓, Scramble timer 90s
					state.trust += 5.0
					state.sla -= 5.0
					state.scramble_active = true
					state.scramble_timer = 90.0
					if sim:
						sim.potable_mld = 1.2
						sim.tj += 8.0
					state.trigger_dialogue("MEERA", "Bypass closed! Sump supply collapsed — reach Server Hall A in 90 seconds before servers starve!")
				"B": # Throttle compute 30%
					# W↓ H↓ S↓↓
					state.sla -= 15.0
					state.pressure += 15.0
					if sim:
						sim.throttle_pct = 30.0
					state.trigger_dialogue("ROHAN", "You cut compute by 30%. Clients are screaming and our SLA is tanking.")
				"C": # Log and report
					# T↑↑ Evidence+1 Pressure↓10
					state.trust += 10.0
					state.pressure = max(0.0, state.pressure - 10.0)
					state.add_evidence_item("bypass_log", "Meter Bypass Audit Report Documented")
					state.trigger_dialogue("MEERA", "Smart move. We have the data logged. Paper trail is airtight.")
					
		"LEVEL2_HEAT":
			state.heat_clock_active = false
			match option_letter:
				"A": # Flood towers with makeup water
					# H↓↓↓ W↑↑↑ C↑ T↓↓
					if sim:
						sim.makeup_flood_multiplier = 1.65
						sim.tj = 70.0
					state.trust -= 10.0
					state.trigger_dialogue("ROHAN", "Towers flooded. Temperatures down, but we just pulled another 1.2 MLD from Rabale's main line.")
				"B": # Shed 20% more compute
					state.sla -= 20.0
					if sim:
						sim.throttle_pct = min(50.0, sim.throttle_pct + 20.0)
					state.trigger_dialogue("ROHAN", "More workload dumped. You're killing our enterprise SLA.")
				"C": # Dry backup coolers
					# P spikes
					if sim:
						sim.extra_aux = 30.0
						sim.tj = 74.0
					state.trigger_dialogue("MEERA", "Dry backup fans engaged. Power meter is spinning like crazy, but we spared the water.")
					
		"LEVEL3_BLOWDOWN":
			match option_letter:
				"A": # Emergency ZLD Activation
					state.budget -= 20
					if sim:
						sim.zld_active = true
					state.trust += 10.0
					state.trigger_dialogue("MEERA", "Zero Liquid Discharge online! Creek discharge dropped to zero. Water recovered internally.")
				"B": # Dilute and discharge
					state.budget -= 5
					if sim:
						sim.diluted_discharge = true
					state.pressure += 10.0
					state.trigger_dialogue("ROHAN", "Basin diluted. Still technically exceeding salinity thresholds, but outfall is moving.")
				"C": # Seal valve and hold
					if sim:
						sim.valve_sealed = true
					state.sump_active = true
					state.sump_timer = 240.0 # 4 minutes
					state.trigger_dialogue("MEERA", "Valve sealed! Retention sump is filling rapidly. You have 4 minutes to overhaul cooling in Level 4!")
					
		"LEVEL4_REBUILD":
			if state.sump_active:
				# Resolve sump hold
				state.sump_active = false
			match option_letter:
				"A": # Full DTC conversion
					state.budget -= 40
					if sim:
						sim.set_topology("DTC")
						sim.throttle_pct = 0.0
					state.trust += 15.0
					state.trigger_dialogue("TARA", "Direct-To-Chip cooling loop active. 0.45 L/kWh efficiency achieved!")
				"B": # Hybrid with STP water
					state.budget -= 20
					if sim:
						sim.set_water_source("STP")
						sim.throttle_pct = 0.0
					state.trust += 20.0
					state.trigger_dialogue("TARA", "Sewage Treatment Plant connection locked in. Zero potable municipal draw!")
				"C": # Optimise existing
					state.budget -= 10
					if sim:
						sim.throttle_pct = 10.0
					state.trigger_dialogue("ROHAN", "Optimised existing pumps. Preserved our capex budget.")
					
		"LEVEL5_FINAL":
			match option_letter:
				"A": # Full Disclosure
					state.trust += 20.0
					state.sla -= 10.0
					state.pressure = max(0.0, state.pressure - 25.0)
				"B": # Partial Disclosure
					state.trust -= 10.0
					state.pressure += 15.0
				"C": # Whistleblow
					state.trust += 30.0
					state.sla = 0.0
					state.pressure = 0.0
					
	state.decisions_history.append({"card": card_id, "option": option_letter})
	decision_confirmed.emit(card_id, option_letter)
	state.start_world_transition(6.0)

func show_debrief(card_id: String, option_letter: String) -> void:
	is_debrief_active = true
	debrief_panel.visible = true
	debrief_timer = 6.0
	
	debrief_title.text = "DECISION CONFIRMED — OPTION " + option_letter
	var desc = "World transition underway. Hydraulic and electrical parameters are balancing."
	match card_id:
		"LEVEL1_BYPASS": desc = "Municipal meter analysis logged. Downstream flows adjusted."
		"LEVEL2_HEAT": desc = "Thermal crisis contained. Server junction temperatures stabilizing."
		"LEVEL3_BLOWDOWN": desc = "Creek effluent protocol executed. Water quality sensors updating."
		"LEVEL4_REBUILD": desc = "Cooling topology overhaul deployed. Simulation parameters locked."
		"LEVEL5_FINAL": desc = "Regulatory audit report submitted to MPCB Inspector Dr. Kulkarni."
	debrief_body.text = desc
	
	var hhi_node = get_node_or_null("/root/HHI")
	if hhi_node:
		debrief_hhi.text = "LIVE HHI: " + str(int(hhi_node.current_hhi)) + " — " + hhi_node.current_tier
		debrief_hhi.modulate = hhi_node.get_tier_data()["label_color"]

func _process(delta: float) -> void:
	if is_debrief_active:
		debrief_timer -= delta
		if debrief_timer <= 0.0:
			close_debrief()

func close_debrief() -> void:
	is_debrief_active = false
	debrief_panel.visible = false
	visible = false
