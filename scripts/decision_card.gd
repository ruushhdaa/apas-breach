class_name DecisionCardController
extends CanvasLayer

signal decision_confirmed(decision_id: String, option_letter: String)

@onready var panel_container: PanelContainer = $CenterContainer/PanelContainer
@onready var situation_icon: Label = $CenterContainer/PanelContainer/Margin/VBoxContainer/HeaderHBox/SituationIcon
@onready var situation_title: Label = $CenterContainer/PanelContainer/Margin/VBoxContainer/HeaderHBox/SituationTitle
@onready var subline_label: Label = $CenterContainer/PanelContainer/Margin/VBoxContainer/SublineLabel
@onready var options_container: VBoxContainer = $CenterContainer/PanelContainer/Margin/VBoxContainer/OptionsContainer
@onready var projection_label: Label = $CenterContainer/PanelContainer/Margin/VBoxContainer/ProjectionLabel
@onready var confirm_button: Button = $CenterContainer/PanelContainer/Margin/VBoxContainer/ConfirmButton

# Debrief
@onready var debrief_panel: PanelContainer = $CenterContainer/DebriefPanel
@onready var debrief_title: Label = $CenterContainer/DebriefPanel/Margin/VBoxContainer/DebriefTitle
@onready var debrief_hhi: Label = $CenterContainer/DebriefPanel/Margin/VBoxContainer/DebriefHHI
@onready var debrief_body: Label = $CenterContainer/DebriefPanel/Margin/VBoxContainer/DebriefBody
@onready var next_hint_label: Label = $CenterContainer/DebriefPanel/Margin/VBoxContainer/NextHintLabel
@onready var debrief_close_btn: Button = $CenterContainer/DebriefPanel/Margin/VBoxContainer/DebriefCloseButton

var current_card_data: Dictionary = {}
var selected_option: String = ""
var option_panels: Dictionary = {}
var option_buttons: Dictionary = {}
var is_debrief_active: bool = false

var hhi_before_decision: float = 38.0
var tier_before_decision: String = "CRITICAL"

func _ready() -> void:
	visible = false
	debrief_panel.visible = false
	confirm_button.pressed.connect(_on_confirm_pressed)
	if debrief_close_btn:
		debrief_close_btn.pressed.connect(close_debrief)

func open_card(card_data: Dictionary) -> void:
	current_card_data = card_data
	selected_option = ""
	visible = true
	debrief_panel.visible = false
	panel_container.visible = true
	is_debrief_active = false
	
	if AudioEngine: AudioEngine.play_sfx("decision_open")
	
	hhi_before_decision = HHI.current_hhi if HHI else 38.0
	tier_before_decision = HHI.current_tier_name if HHI else "CRITICAL"
	
	# Header setup
	var sit_type = card_data.get("situation_type", "pipe")
	match sit_type:
		"flame": situation_icon.text = "🔥"
		"drop": situation_icon.text = "💧"
		"lock": situation_icon.text = "🔒"
		_: situation_icon.text = "☵"
		
	situation_title.text = card_data.get("title", "CRITICAL FACILITY DECISION")
	subline_label.text = card_data.get("subline", "SIMULATION TELEMETRY ACTIVE")
	
	# Clear old options
	for child in options_container.get_children():
		child.queue_free()
	option_panels.clear()
	option_buttons.clear()
	
	var options = card_data.get("options", [])
	for opt in options:
		var letter = opt["letter"]
		var opt_panel = PanelContainer.new()
		
		var p_style = StyleBoxFlat.new()
		p_style.bg_color = Color("#0E1420")
		p_style.border_width_left = 1
		p_style.border_width_top = 1
		p_style.border_width_right = 1
		p_style.border_width_bottom = 1
		p_style.border_color = Color("#2A3445")
		p_style.corner_radius_top_left = 4
		p_style.corner_radius_top_right = 4
		p_style.corner_radius_bottom_right = 4
		p_style.corner_radius_bottom_left = 4
		opt_panel.add_theme_stylebox_override("panel", p_style)
		
		var m_box = MarginContainer.new()
		m_box.add_theme_constant_override("margin_left", 14)
		m_box.add_theme_constant_override("margin_right", 14)
		m_box.add_theme_constant_override("margin_top", 10)
		m_box.add_theme_constant_override("margin_bottom", 10)
		opt_panel.add_child(m_box)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		m_box.add_child(vbox)
		
		# Top row: Letter badge [A] in circle + Option title (14px white bold) + Shortcut reminder
		var top_row = HBoxContainer.new()
		top_row.add_theme_constant_override("separation", 10)
		
		var badge = Label.new()
		badge.text = " " + letter + " "
		badge.add_theme_font_size_override("font_size", 14)
		badge.modulate = Color("#F0A500")
		top_row.add_child(badge)
		
		var title_lbl = Label.new()
		title_lbl.text = opt["text"].to_upper()
		title_lbl.add_theme_font_size_override("font_size", 14)
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_row.add_child(title_lbl)
		
		var sc_lbl = Label.new()
		sc_lbl.text = "[" + letter + "]"
		sc_lbl.add_theme_font_size_override("font_size", 12)
		sc_lbl.modulate = Color("#8A8FA8")
		top_row.add_child(sc_lbl)
		
		vbox.add_child(top_row)
		
		# Description: 12px #8A8FA8, 2 lines max
		if opt.has("desc"):
			var desc_lbl = Label.new()
			desc_lbl.text = opt["desc"]
			desc_lbl.add_theme_font_size_override("font_size", 12)
			desc_lbl.modulate = Color("#8A8FA8")
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(desc_lbl)
			
		# Consequence preview row with stat arrows & magnitude
		var prev_row = HBoxContainer.new()
		var p_text = opt.get("preview", "")
		var prev_lbl = Label.new()
		prev_lbl.text = "EFFECTS: " + p_text
		prev_lbl.add_theme_font_size_override("font_size", 12)
		prev_lbl.modulate = Color("#F0A500")
		prev_row.add_child(prev_lbl)
		vbox.add_child(prev_row)
		
		# Plain English tradeoff explanation line
		if opt.has("tradeoff"):
			var trade_lbl = Label.new()
			trade_lbl.text = "→ " + opt["tradeoff"]
			trade_lbl.add_theme_font_size_override("font_size", 11)
			trade_lbl.modulate = Color("#9EABB8")
			trade_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(trade_lbl)
			
		# Check requirements (min_evidence, cost_budget, max_pressure)
		var is_locked = false
		if opt.has("min_evidence") and GameState.evidence < opt["min_evidence"]:
			is_locked = true
			var lock_lbl = Label.new()
			lock_lbl.text = "🔒 LOCKED: Requires Evidence ≥ " + str(opt["min_evidence"])
			lock_lbl.modulate = Color("#DD4444")
			vbox.add_child(lock_lbl)
		if opt.has("cost_budget") and GameState.budget < opt["cost_budget"]:
			is_locked = true
			var lock_lbl = Label.new()
			lock_lbl.text = "🔒 INSUFFICIENT BUDGET (Cost: " + str(opt["cost_budget"]) + " CR)"
			lock_lbl.modulate = Color("#DD4444")
			vbox.add_child(lock_lbl)
		if opt.has("max_pressure") and GameState.pressure >= opt["max_pressure"]:
			is_locked = true
			var lock_lbl = Label.new()
			lock_lbl.text = "🔒 AUDIT PRESSURE TOO HIGH"
			lock_lbl.modulate = Color("#DD4444")
			vbox.add_child(lock_lbl)
			
		# Click overlay button
		var btn = Button.new()
		btn.flat = true
		btn.anchors_preset = Control.PRESET_FULL_RECT
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		btn.disabled = is_locked
		
		var l_ref = letter
		btn.pressed.connect(func(): select_option(l_ref))
		btn.mouse_entered.connect(func():
			if not is_locked and AudioEngine: AudioEngine.play_sfx("option_hover")
		)
		opt_panel.add_child(btn)
		
		options_container.add_child(opt_panel)
		option_panels[letter] = {"panel": opt_panel, "style": p_style, "disabled": is_locked}
		option_buttons[letter] = btn
		
	# Auto-select first available option
	for opt in options:
		var l = opt["letter"]
		if not option_panels[l]["disabled"]:
			select_option(l)
			break

func select_option(letter: String) -> void:
	if not option_panels.has(letter) or option_panels[letter]["disabled"]:
		return
		
	selected_option = letter
	if AudioEngine: AudioEngine.play_sfx("option_select")
	
	# Highlight chosen option #1A2540 with glowing amber border
	for l in option_panels:
		var item = option_panels[l]
		var style: StyleBoxFlat = item["style"]
		if l == letter:
			style.bg_color = Color("#1A2540")
			style.border_color = Color("#F0A500")
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
		else:
			style.bg_color = Color("#0E1420")
			style.border_color = Color("#2A3445")
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			
	update_projection_and_confirm()

func update_projection_and_confirm() -> void:
	confirm_button.text = "CONFIRM [" + selected_option + "] — ARE YOU SURE? (ENTER)"
	confirm_button.disabled = false
	
	# Compute projected HHI using simulation engine rules
	var proj_hhi = hhi_before_decision
	var card_id = current_card_data.get("id", "")
	match card_id:
		"LEVEL1_BYPASS":
			match selected_option:
				"A": proj_hhi = 44.0 # Scramble
				"B": proj_hhi = 48.0 # Throttled
				"C": proj_hhi = 42.0 # Logged
		"LEVEL2_HEAT":
			match selected_option:
				"A": proj_hhi = 35.0 # Flood
				"B": proj_hhi = 52.0 # Shed
				"C": proj_hhi = 48.0 # Dry
		"LEVEL3_BLOWDOWN":
			match selected_option:
				"A": proj_hhi = 62.0 # ZLD
				"B": proj_hhi = 40.0 # Dilute
				"C": proj_hhi = 50.0 # Sump
		"LEVEL4_REBUILD":
			match selected_option:
				"A": proj_hhi = 78.0 # DTC
				"B": proj_hhi = 72.0 # STP
				"C": proj_hhi = 58.0 # Optimize
		"LEVEL5_FINAL":
			match selected_option:
				"A": proj_hhi = 88.0 # Full disclosure
				"B": proj_hhi = 65.0 # Partial
				"C": proj_hhi = 95.0 # Whistleblow
				
	var proj_tier = HHI.calculate_tier_name(proj_hhi) if HHI else "STRAINED"
	projection_label.text = "PROJECTED HHI CHANGE: " + str(int(hhi_before_decision)) + " (" + tier_before_decision + ") → ~" + str(int(proj_hhi)) + " (" + proj_tier + ")"

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
			KEY_ENTER, KEY_SPACE: _on_confirm_pressed()

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
					state.trust += 5.0
					state.sla -= 5.0
					state.scramble_active = true
					state.scramble_timer = 90.0
					if sim:
						sim.potable_mld = 1.2
						sim.tj += 8.0
					state.trigger_dialogue("MEERA", "Bypass closed! Sump supply collapsed — reach Server Hall A in 90 seconds before servers starve!")
				"B": # Throttle compute 30%
					state.sla -= 15.0
					state.pressure += 15.0
					if sim:
						sim.throttle_pct = 30.0
					state.trigger_dialogue("ROHAN", "You cut compute by 30%. Clients are screaming and our SLA is tanking.")
				"C": # Log and report
					state.trust += 10.0
					state.pressure = max(0.0, state.pressure - 10.0)
					state.add_evidence_item("bypass_log", "Meter Bypass Audit Report Documented")
					state.trigger_dialogue("MEERA", "Smart move. We have the data logged. Paper trail is airtight.")
					
		"LEVEL2_HEAT":
			state.heat_clock_active = false
			match option_letter:
				"A": # Flood towers with makeup water
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
					state.pressure += 20.0
					if sim:
						sim.potable_mld += 0.4
					state.trigger_dialogue("MEERA", "Dilution hides the TDS number on paper, but the same mass of biocide enters Thane Creek.")
				"C": # Seal and hold
					state.sump_active = true
					state.sump_timer = 240.0
					state.trigger_dialogue("MEERA", "Retention sump sealed! 4 minutes before overflow. Rebuild cooling in Level 4 to avoid disaster!")
					
		"LEVEL4_REBUILD":
			match option_letter:
				"A": # Full DTC
					state.budget -= 40
					if sim:
						sim.current_topology = "DTC"
					state.trust += 15.0
					state.trigger_dialogue("TARA", "Direct-To-Chip liquid loop operational! PUE normalized, water draw reduced to 0.45 L/kWh.")
				"B": # Hybrid with STP
					state.budget -= 20
					if sim:
						sim.water_source = "STP"
					state.trust += 20.0
					state.trigger_dialogue("MEERA", "STP treated sewage line connected! Municipal potable draw collapsed to 0 MLD. Drinking water returned to Rabale.")
				"C": # Optimise existing
					state.budget -= 10
					if sim:
						sim.throttle_pct += 10.0
					state.trigger_dialogue("ROHAN", "Modest gains, but capital reserves remain intact.")
			if state.sump_active:
				state.sump_active = false
				state.trigger_dialogue("SYSTEM", "Sump overflow neutralized by cooling rebuild.")
				
		"LEVEL5_FINAL":
			match option_letter:
				"A": # Full disclosure
					state.trust += 20.0
					state.sla -= 10.0
					state.trigger_dialogue("DR. KULKARNI", "Compliance records substantiate full remedial compliance. Facility permitted under strict monitoring.")
				"B": # Partial disclosure
					state.pressure += 10.0
					state.trigger_dialogue("DR. KULKARNI", "Conditional pass issued. Statutory warning registered against environmental records.")
				"C": # Whistleblow
					state.trust += 30.0
					state.sla = 0.0
					state.trigger_dialogue("DR. KULKARNI", "Full statutory audit seizure enacted. Immediate public injunction on facility operation.")

	if state:
		state.start_world_transition(6.0)

func show_debrief(card_id: String, option_letter: String) -> void:
	is_debrief_active = true
	debrief_panel.visible = true
	if AudioEngine: AudioEngine.play_sfx("level_complete")
	
	var hhi_after = HHI.current_hhi if HHI else 52.0
	var tier_after = HHI.current_tier_name if HHI else "STRAINED"
	debrief_hhi.text = "HYDRO HEALTH INDEX: " + str(int(hhi_before_decision)) + " (" + tier_before_decision + ") → " + str(int(hhi_after)) + " (" + tier_after + ")"
	
	var sim = get_node_or_null("/root/Simulation")
	var sim_creek = snappedf(sim.creek_health_pct, 1.0) if sim else 35.0
	var sim_potable = snappedf(sim.potable_mld, 0.01) if sim else 2.50
	
	match card_id:
		"LEVEL1_BYPASS":
			debrief_title.text = "METER 4 DECISION COMMITTED"
			debrief_body.text = "POTABLE DRAW: 2.50 MLD → " + str(sim_potable) + " MLD — MUNICIPAL BYPASS RESTRICTED\n" + \
				"COMMUNITY TRUST: " + str(int(GameState.trust)) + " — RESIDENTS NOTICED TANKER INTAKE SHIFT\n" + \
				"AUDIT PRESSURE: " + str(int(GameState.pressure)) + "/100 — REGULATORY EVIDENCE DOCUMENTED"
			next_hint_label.text = "NEXT OBJECTIVE: Head to Server Hall A"
		"LEVEL2_HEAT":
			debrief_title.text = "THERMAL EVENT CONTROL COMMITTED"
			debrief_body.text = "JUNCTION TEMP: 84.0°C → " + str(snappedf(sim.tj, 0.1)) + "°C — SILICON MELTDOWN AVERTED\n" + \
				"FACILITY SLA: " + str(int(GameState.sla)) + "% — ENTERPRISE WORKLOAD MANAGED\n" + \
				"COMMUNITY TRUST: " + str(int(GameState.trust)) + " — LOCAL GRID WATER VOLUMES ADJUSTED"
			next_hint_label.text = "NEXT OBJECTIVE: Proceed to Outfall Canal"
		"LEVEL3_BLOWDOWN":
			debrief_title.text = "CREEK DISCHARGE INTERVENTION COMMITTED"
			debrief_body.text = "CREEK HEALTH: " + str(sim_creek) + "% — BIOCIDE EFFLUENT LEVEL MODIFIED\n" + \
				"ESTUARY IMPACT: THANE CREEK FLAMINGO HABITAT DISSOLVED OXYGEN SHIFT\n" + \
				"CAPITAL BUDGET REMAINING: " + str(GameState.budget) + " CR"
			next_hint_label.text = "NEXT OBJECTIVE: Enter the SCADA Hub"
		"LEVEL4_REBUILD":
			debrief_title.text = "COOLING RETROFIT ARCHITECTURE APPLIED"
			debrief_body.text = "COOLING TOPOLOGY: " + str(sim.current_topology) + " (" + str(sim.water_source) + " WATER)\n" + \
				"POTABLE DRAW: " + str(sim_potable) + " MLD | PUE: " + str(snappedf(sim.pue, 0.001)) + "\n" + \
				"COMMUNITY TRUST: " + str(int(GameState.trust)) + " — SUBSTANTIAL WATER RESTORATION ACKNOWLEDGED"
			next_hint_label.text = "NEXT OBJECTIVE: Proceed to MPCB Audit Stage"
		"LEVEL5_FINAL":
			debrief_title.text = "FINAL STATUTORY DETERMINATION COMMITTED"
			debrief_body.text = "AUDIT VERDICT RECORDED BY MPCB INSPECTOR DR. KULKARNI\n" + \
				"FINAL EVIDENCE SCORE: " + str(GameState.evidence) + "/6 VERIFIED DOSSIERS\n" + \
				"COMMUNITY TRUST: " + str(int(GameState.trust)) + " | FINAL SLA: " + str(int(GameState.sla)) + "%"
			next_hint_label.text = "GENERATING FINAL SCORECARD..."

func close_debrief() -> void:
	if not is_debrief_active:
		return
	is_debrief_active = false
	visible = false
	debrief_panel.visible = false
	var cid = current_card_data.get("id", "")
	var opt = selected_option
	decision_confirmed.emit(cid, opt)
