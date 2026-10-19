class_name DispatchScreenController
extends Control

const CharModelScript = preload("res://scripts/character_model.gd")

@onready var cards_container: HBoxContainer = $CenterContainer/VBoxContainer/CardsHBox
@onready var deploy_button: Button = $CenterContainer/VBoxContainer/DeployButton

var specialists = ["VOLT", "ANANYA", "TARA"]
var selected_specialist: String = "VOLT"
var card_nodes: Dictionary = {}
var rotating_models: Array = []

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	build_specialist_cards()
	deploy_button.pressed.connect(_on_deploy_pressed)
	select_card("VOLT")

func _process(delta: float) -> void:
	# Rotate 3D models 360 deg every 12 seconds
	var rot_speed = TAU / 12.0
	for model in rotating_models:
		if is_instance_valid(model):
			model.rotation.y += delta * rot_speed

func build_specialist_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()
	card_nodes.clear()
	rotating_models.clear()
	
	for key in specialists:
		var data = GameState.SPECIALISTS[key]
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(260, 520)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color("#111822")
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = data["accent"]
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_right = 4
		style.corner_radius_bottom_left = 4
		card.add_theme_stylebox_override("panel", style)
		
		var main_vbox = VBoxContainer.new()
		main_vbox.add_theme_constant_override("separation", 6)
		card.add_child(main_vbox)
		
		# TOP 40%: SubViewport 3D rotating preview (260x208)
		var sub_vp_c = SubViewportContainer.new()
		sub_vp_c.custom_minimum_size = Vector2(256, 208)
		sub_vp_c.stretch = true
		
		var sub_vp = SubViewport.new()
		sub_vp.own_world_3d = true
		sub_vp.size = Vector2i(256, 208)
		sub_vp_c.add_child(sub_vp)
		
		# 3D Environment with dark gradient background
		var env_node = WorldEnvironment.new()
		var env = Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color("#0A0F1A")
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color("#1A2030")
		env.ambient_light_energy = 0.5
		env_node.environment = env
		sub_vp.add_child(env_node)
		
		# Front directional light
		var front_light = DirectionalLight3D.new()
		front_light.rotation_degrees = Vector3(-25, 30, 0)
		front_light.light_color = Color(0.95, 0.95, 1.0)
		front_light.light_energy = 0.8
		sub_vp.add_child(front_light)
		
		# Rear rim light in character's accent color (GTA loading screen silhouette feel)
		var rim_light = DirectionalLight3D.new()
		rim_light.rotation_degrees = Vector3(25, 180, 0)
		rim_light.light_color = data["accent"]
		rim_light.light_energy = 2.8
		sub_vp.add_child(rim_light)
		
		# Character model
		var char_3d = CharModelScript.new()
		char_3d.character_type = key
		char_3d.position = Vector3(0, -0.4, 0)
		sub_vp.add_child(char_3d)
		rotating_models.append(char_3d)
		
		# Camera
		var cam_3d = Camera3D.new()
		cam_3d.position = Vector3(0, 0.8, 2.3)
		cam_3d.fov = 42.0
		sub_vp.add_child(cam_3d)
		
		main_vbox.add_child(sub_vp_c)
		
		# BOTTOM 60%: Character details & stat bars
		var details_margin = MarginContainer.new()
		details_margin.add_theme_constant_override("margin_left", 14)
		details_margin.add_theme_constant_override("margin_right", 14)
		details_margin.add_theme_constant_override("margin_top", 4)
		details_margin.add_theme_constant_override("margin_bottom", 10)
		
		var details_vbox = VBoxContainer.new()
		details_vbox.add_theme_constant_override("separation", 4)
		details_margin.add_child(details_vbox)
		
		# Character Name: 22px monospace, accent colour, bold
		var lbl_name = Label.new()
		lbl_name.text = data["name"]
		lbl_name.add_theme_font_size_override("font_size", 16)
		lbl_name.modulate = data["accent"]
		details_vbox.add_child(lbl_name)
		
		# Role: 13px monospace, #8A8FA8, italic
		var lbl_role = Label.new()
		lbl_role.text = data["role"]
		lbl_role.add_theme_font_size_override("font_size", 12)
		lbl_role.modulate = Color("#8A8FA8")
		details_vbox.add_child(lbl_role)
		
		# Blank line separator
		var sep1 = Control.new()
		sep1.custom_minimum_size = Vector2(0, 4)
		details_vbox.add_child(sep1)
		
		# Tool: [Q] — [tool name] 12px #E8E0D0
		var lbl_tool_title = Label.new()
		lbl_tool_title.text = "TOOL: [Q] — " + data["tool_name"].to_upper()
		lbl_tool_title.add_theme_font_size_override("font_size", 12)
		lbl_tool_title.modulate = Color("#E8E0D0")
		details_vbox.add_child(lbl_tool_title)
		
		# Tool description: 11px #8A8FA8, 2 lines max
		var lbl_tool_desc = Label.new()
		lbl_tool_desc.text = data["tool_desc"]
		lbl_tool_desc.add_theme_font_size_override("font_size", 11)
		lbl_tool_desc.modulate = Color("#8A8FA8")
		lbl_tool_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details_vbox.add_child(lbl_tool_desc)
		
		# Blank line separator
		var sep2 = Control.new()
		sep2.custom_minimum_size = Vector2(0, 4)
		details_vbox.add_child(sep2)
		
		# UPSIDE: green text, 11px
		var lbl_up = Label.new()
		lbl_up.text = "UPSIDE: " + data["upside"]
		lbl_up.add_theme_font_size_override("font_size", 11)
		lbl_up.modulate = Color("#44CC44")
		lbl_up.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details_vbox.add_child(lbl_up)
		
		# DOWNSIDE: red text, 11px
		var lbl_down = Label.new()
		lbl_down.text = "DOWNSIDE: " + data["downside"]
		lbl_down.add_theme_font_size_override("font_size", 11)
		lbl_down.modulate = Color("#EE4444")
		lbl_down.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details_vbox.add_child(lbl_down)
		
		# Blank line separator
		var sep3 = Control.new()
		sep3.custom_minimum_size = Vector2(0, 6)
		details_vbox.add_child(sep3)
		
		# Four stat bars: Label (8px) | Bar (fill% rounded) | Value (8px)
		var stats = data["stats"]
		var stats_vbox = VBoxContainer.new()
		stats_vbox.add_theme_constant_override("separation", 3)
		
		for stat_key in ["power", "water", "compliance", "crisis"]:
			var stat_row = HBoxContainer.new()
			stat_row.alignment = BoxContainer.ALIGNMENT_CENTER
			
			var s_lbl = Label.new()
			s_lbl.custom_minimum_size = Vector2(65, 0)
			s_lbl.text = stat_key.to_upper()
			s_lbl.add_theme_font_size_override("font_size", 9)
			s_lbl.modulate = Color("#8A8FA8")
			stat_row.add_child(s_lbl)
			
			var p_bar = ProgressBar.new()
			p_bar.custom_minimum_size = Vector2(125, 6) # Bar height 6px
			p_bar.show_percentage = false
			p_bar.value = stats[stat_key]
			p_bar.max_value = 100.0
			
			var bg_style = StyleBoxFlat.new()
			bg_style.bg_color = Color("#0A0F1A")
			bg_style.corner_radius_top_left = 3
			bg_style.corner_radius_top_right = 3
			bg_style.corner_radius_bottom_right = 3
			bg_style.corner_radius_bottom_left = 3
			
			var fill_style = StyleBoxFlat.new()
			fill_style.bg_color = data["accent"]
			fill_style.corner_radius_top_left = 3
			fill_style.corner_radius_top_right = 3
			fill_style.corner_radius_bottom_right = 3
			fill_style.corner_radius_bottom_left = 3
			
			p_bar.add_theme_stylebox_override("background", bg_style)
			p_bar.add_theme_stylebox_override("fill", fill_style)
			stat_row.add_child(p_bar)
			
			var v_lbl = Label.new()
			v_lbl.custom_minimum_size = Vector2(30, 0)
			v_lbl.text = str(stats[stat_key])
			v_lbl.add_theme_font_size_override("font_size", 9)
			v_lbl.modulate = Color("#E8E0D0")
			v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			stat_row.add_child(v_lbl)
			
			stats_vbox.add_child(stat_row)
		details_vbox.add_child(stats_vbox)
		
		main_vbox.add_child(details_margin)
		
		# Click and Hover handlers
		var btn_overlay = Button.new()
		btn_overlay.flat = true
		btn_overlay.anchors_preset = Control.PRESET_FULL_RECT
		btn_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
		
		var k_ref = key
		btn_overlay.pressed.connect(func(): select_card(k_ref))
		btn_overlay.mouse_entered.connect(func(): on_card_hover(k_ref, true))
		btn_overlay.mouse_exited.connect(func(): on_card_hover(k_ref, false))
		card.add_child(btn_overlay)
		
		cards_container.add_child(card)
		card_nodes[key] = {"card": card, "style": style, "accent": data["accent"], "base_pos_y": 0.0}

func on_card_hover(key: String, hovered: bool) -> void:
	if not card_nodes.has(key): return
	var item = card_nodes[key]
	var card: Control = item["card"]
	var style: StyleBoxFlat = item["style"]
	
	if hovered:
		style.border_color = item["accent"].lightened(0.3)
		# Card lifts 4px (transform y -4px)
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "position:y", -4.0, 0.12)
		if AudioEngine: AudioEngine.play_sfx("option_hover")
	else:
		if key != selected_specialist:
			style.border_color = item["accent"]
			var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(card, "position:y", 0.0, 0.12)

func select_card(key: String) -> void:
	selected_specialist = key
	GameState.selected_specialist = key
	if AudioEngine: AudioEngine.play_sfx("option_select")
	
	for k in card_nodes:
		var item = card_nodes[k]
		var style: StyleBoxFlat = item["style"]
		var card: Control = item["card"]
		if k == key:
			style.bg_color = Color("#1A2A3A") # Selected background #1A2A3A
			style.border_width_left = 3
			style.border_width_top = 3
			style.border_width_right = 3
			style.border_width_bottom = 3
			style.border_color = item["accent"].lightened(0.4)
			card.position.y = -4.0
		else:
			style.bg_color = Color("#111822") # Default background #111822
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.border_color = item["accent"]
			card.position.y = 0.0
			
	var spec_name = GameState.SPECIALISTS[key]["name"]
	deploy_button.text = "DEPLOY — " + spec_name

func _on_deploy_pressed() -> void:
	if AudioEngine: AudioEngine.play_sfx("level_complete")
	# 0.1s scale-up animation then transition
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(deploy_button, "scale", Vector2(1.06, 1.06), 0.1)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/level_0.tscn")
