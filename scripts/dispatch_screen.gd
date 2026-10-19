class_name DispatchScreenController
extends Control

const CharModelScript = preload("res://scripts/character_model.gd")

@onready var cards_container: HBoxContainer = $CenterContainer/VBoxContainer/CardsHBox
@onready var deploy_button: Button = $CenterContainer/VBoxContainer/DeployButton

var specialists = ["VOLT", "ANANYA", "TARA"]
var selected_specialist: String = "VOLT"
var card_nodes: Dictionary = {}

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	build_specialist_cards()
	deploy_button.pressed.connect(_on_deploy_pressed)
	select_card("VOLT")

func build_specialist_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()
	card_nodes.clear()
	
	for key in specialists:
		var data = GameState.SPECIALISTS[key]
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(260, 480)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color("#1A1F2E")
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
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)
		card.add_child(vbox)
		
		# Top silhouette / SubViewport area
		var sub_vp_c = SubViewportContainer.new()
		sub_vp_c.custom_minimum_size = Vector2(250, 180)
		sub_vp_c.stretch = true
		var sub_vp = SubViewport.new()
		sub_vp.own_world_3d = true
		sub_vp.size = Vector2i(250, 180)
		sub_vp_c.add_child(sub_vp)
		
		var char_3d = CharModelScript.new()
		char_3d.character_type = key
		char_3d.position = Vector3(0, -0.2, 0)
		sub_vp.add_child(char_3d)
		
		var cam_3d = Camera3D.new()
		cam_3d.position = Vector3(0, 1.1, 2.2)
		cam_3d.fov = 40.0
		sub_vp.add_child(cam_3d)
		
		var light_3d = DirectionalLight3D.new()
		light_3d.rotation_degrees = Vector3(-30, 45, 0)
		light_3d.light_color = Color(1.0, 0.9, 0.8)
		sub_vp.add_child(light_3d)
		
		vbox.add_child(sub_vp_c)
		
		# Name & Role
		var lbl_name = Label.new()
		lbl_name.text = data["name"]
		lbl_name.add_theme_font_size_override("font_size", 15)
		lbl_name.modulate = data["accent"]
		lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl_name)
		
		var lbl_role = Label.new()
		lbl_role.text = data["role"]
		lbl_role.add_theme_font_size_override("font_size", 11)
		lbl_role.modulate = Color("#8A8FA8")
		lbl_role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl_role)
		
		# Tool
		var lbl_tool = Label.new()
		lbl_tool.text = "Q — " + data["tool_name"] + ":\n" + data["tool_desc"]
		lbl_tool.add_theme_font_size_override("font_size", 11)
		lbl_tool.modulate = Color("#E8E0D0")
		lbl_tool.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl_tool)
		
		# Upside & Downside
		var lbl_up = Label.new()
		lbl_up.text = "PRO: " + data["upside"]
		lbl_up.add_theme_font_size_override("font_size", 10)
		lbl_up.modulate = Color("#44DD66")
		lbl_up.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl_up)
		
		var lbl_down = Label.new()
		lbl_down.text = "CON: " + data["downside"]
		lbl_down.add_theme_font_size_override("font_size", 10)
		lbl_down.modulate = Color("#DD4444")
		lbl_down.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl_down)
		
		# 4 Stat Bars: Power, Water, Compliance, Crisis
		var stats = data["stats"]
		var stats_vbox = VBoxContainer.new()
		for stat_key in ["power", "water", "compliance", "crisis"]:
			var stat_row = HBoxContainer.new()
			var s_lbl = Label.new()
			s_lbl.custom_minimum_size = Vector2(75, 0)
			s_lbl.text = stat_key.to_upper()
			s_lbl.add_theme_font_size_override("font_size", 9)
			s_lbl.modulate = Color("#8A8FA8")
			stat_row.add_child(s_lbl)
			
			var p_bar = ProgressBar.new()
			p_bar.custom_minimum_size = Vector2(140, 10)
			p_bar.show_percentage = false
			p_bar.value = stats[stat_key]
			p_bar.max_value = 100.0
			
			var bg_style = StyleBoxFlat.new()
			bg_style.bg_color = Color("#0A0F1A")
			var fill_style = StyleBoxFlat.new()
			fill_style.bg_color = data["accent"]
			p_bar.add_theme_stylebox_override("background", bg_style)
			p_bar.add_theme_stylebox_override("fill", fill_style)
			
			stat_row.add_child(p_bar)
			stats_vbox.add_child(stat_row)
		vbox.add_child(stats_vbox)
		
		# Click and Hover handlers
		var btn_overlay = Button.new()
		btn_overlay.flat = true
		btn_overlay.anchors_preset = Control.PRESET_FULL_RECT
		btn_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
		btn_overlay.pressed.connect(func(): select_card(key))
		btn_overlay.mouse_entered.connect(func():
			if AudioEngine: AudioEngine.play_sfx("option_hover")
		)
		card.add_child(btn_overlay)
		
		cards_container.add_child(card)
		card_nodes[key] = {"card": card, "style": style, "accent": data["accent"]}

func select_card(key: String) -> void:
	selected_specialist = key
	GameState.selected_specialist = key
	if AudioEngine: AudioEngine.play_sfx("option_select")
	
	for k in card_nodes:
		var item = card_nodes[k]
		var style: StyleBoxFlat = item["style"]
		if k == key:
			style.border_width_left = 4
			style.border_width_top = 4
			style.border_width_right = 4
			style.border_width_bottom = 4
			item["card"].scale = Vector2(1.03, 1.03)
		else:
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			item["card"].scale = Vector2.ONE
			
	deploy_button.text = "DEPLOY SPECIALIST — " + GameState.SPECIALISTS[key]["name"]

func _on_deploy_pressed() -> void:
	if AudioEngine: AudioEngine.play_sfx("level_complete")
	get_tree().change_scene_to_file("res://scenes/level_0.tscn")
