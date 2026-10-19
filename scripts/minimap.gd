class_name MinimapControl
extends Control

@export var is_fullscreen: bool = false

var player_ref: Node3D = null
var pulse_time: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(600, 600) if is_fullscreen else Vector2(240, 240)

func _process(delta: float) -> void:
	pulse_time += delta
	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
	queue_redraw()

func _draw() -> void:
	var sz = get_size()
	var center = sz * 0.5
	var scale_factor = 2.5 if is_fullscreen else 1.35
	var font = ThemeDB.fallback_font
	
	# Background #05080F
	draw_rect(Rect2(Vector2.ZERO, sz), Color("#05080F"))
	
	# Full map title
	if is_fullscreen:
		draw_string(font, Vector2(center.x - 140, 28), "FACILITY MAP — AETHERSCALE RABALE", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color("#F0A500"))
	
	# Minimap Border: 2px solid #F0A500
	draw_rect(Rect2(Vector2.ZERO, sz), Color("#F0A500"), false, 2.0)
	
	# Cardinal "N": white 9px monospace at top center
	draw_string(font, Vector2(center.x - 4, 18 if not is_fullscreen else 44), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, Color(1, 1, 1, 0.9))
	
	# ZONE FILLS (8% opacity) & OUTLINES
	# Compound Boundary (-50..50, -50..50): white 1.5px polyline
	var comp_origin = center + Vector2(-50.0, -50.0) * scale_factor
	var comp_size = Vector2(100.0, 100.0) * scale_factor
	draw_rect(Rect2(comp_origin, comp_size), Color("#404040", 0.08), true) # Gate/neutral 8% fill
	draw_rect(Rect2(comp_origin, comp_size), Color(1.0, 1.0, 1.0, 0.8), false, 1.5) # White 1.5px outline
	
	# Server Hall Zone: cold #2040A0 tint (8% opacity)
	var hall_origin = center + Vector2(-45.0, -45.0) * scale_factor
	var hall_size = Vector2(30.0, 40.0) * scale_factor
	draw_rect(Rect2(hall_origin, hall_size), Color("#2040A0", 0.08), true)
	draw_rect(Rect2(hall_origin, hall_size), Color("#2040A0", 0.4), false, 1.0)
	
	# Creek Zone: blue #2060FF tint (8% opacity)
	var creek_origin = center + Vector2(60.0, -50.0) * scale_factor
	var creek_size = Vector2(50.0, 100.0) * scale_factor
	draw_rect(Rect2(creek_origin, creek_size), Color("#2060FF", 0.08), true)
	draw_rect(Rect2(creek_origin, creek_size), Color("#2060FF", 0.4), false, 1.0)
	
	# Rabale Colony: warm #FF8030 tint (8% opacity)
	var colony_origin = center + Vector2(-40.0, 70.0) * scale_factor
	var colony_size = Vector2(80.0, 60.0) * scale_factor
	draw_rect(Rect2(colony_origin, colony_size), Color("#FF8030", 0.08), true)
	draw_rect(Rect2(colony_origin, colony_size), Color("#FF8030", 0.4), false, 1.0)
	
	# Cooling Towers (-5..34, -35)
	for tx in [-5.0, 8.0, 21.0, 34.0]:
		var tp = center + Vector2(tx, -35.0) * scale_factor
		draw_circle(tp, 4.0 * (scale_factor / 1.35), Color("#5A6B80"))
		
	# SCADA Hub (20, 10)
	var scada_origin = center + Vector2(14.0, 5.0) * scale_factor
	var scada_size = Vector2(12.0, 10.0) * scale_factor
	draw_rect(Rect2(scada_origin, scada_size), Color(0.18, 0.28, 0.40, 0.3), true)
	draw_rect(Rect2(scada_origin, scada_size), Color("#4A8F9E"), false, 1.0)
	
	# ROADS: thin white lines 0.5px connecting zones
	var road_col = Color(1.0, 1.0, 1.0, 0.4)
	draw_line(center + Vector2(0, 50) * scale_factor, center + Vector2(0, 70) * scale_factor, road_col, 0.5) # Gate 4 to Colony
	draw_line(center + Vector2(0, 50) * scale_factor, center + Vector2(20, 10) * scale_factor, road_col, 0.5) # Gate 4 to SCADA
	draw_line(center + Vector2(0, 50) * scale_factor, center + Vector2(-27, 40) * scale_factor, road_col, 0.5) # Gate 4 to Substation
	draw_line(center + Vector2(-27, 40) * scale_factor, center + Vector2(-20, -25) * scale_factor, road_col, 0.5) # Substation to Server Hall
	draw_line(center + Vector2(20, 10) * scale_factor, center + Vector2(14, -35) * scale_factor, road_col, 0.5) # SCADA to Cooling Towers
	draw_line(center + Vector2(-20, -25) * scale_factor, center + Vector2(50, -20) * scale_factor, road_col, 0.5) # Server Hall to Outfall Creek
	
	# ZONE LABELS (monospace 8px white)
	var label_color = Color(1.0, 1.0, 1.0, 0.85)
	draw_string(font, center + Vector2(-15, 48) * scale_factor, "GATE 4", HORIZONTAL_ALIGNMENT_CENTER, -1, 8, label_color)
	draw_string(font, center + Vector2(75, -5) * scale_factor, "CREEK", HORIZONTAL_ALIGNMENT_CENTER, -1, 8, label_color)
	draw_string(font, center + Vector2(-15, 95) * scale_factor, "COLONY", HORIZONTAL_ALIGNMENT_CENTER, -1, 8, label_color)
	draw_string(font, center + Vector2(-30, -25) * scale_factor, "SERVER A", HORIZONTAL_ALIGNMENT_CENTER, -1, 8, label_color)
	draw_string(font, center + Vector2(14, -40) * scale_factor, "COOLING", HORIZONTAL_ALIGNMENT_CENTER, -1, 8, label_color)
	draw_string(font, center + Vector2(20, 12) * scale_factor, "SCADA", HORIZONTAL_ALIGNMENT_CENTER, -1, 8, label_color)
	
	# INTERACTABLES: 3px white circles with outer ring
	var interactables = get_tree().get_nodes_in_group("interactables")
	for item in interactables:
		if is_instance_valid(item):
			var ipos = center + Vector2(item.global_position.x, item.global_position.z) * scale_factor
			draw_circle(ipos, 2.0 if not is_fullscreen else 3.0, Color("#FFFFFF"))
			draw_circle(ipos, 3.5 if not is_fullscreen else 5.0, Color(1, 1, 1, 0.5), false, 1.0)
			
	# NPCS: 4px grey dots (only when within 35m)
	if player_ref and is_instance_valid(player_ref):
		var p_world = player_ref.global_position
		var char_models = get_tree().root.find_children("", "CharacterModel", true, false)
		for cm in char_models:
			if is_instance_valid(cm) and cm.get_parent() != player_ref:
				var dist = p_world.distance_to(cm.global_position)
				if dist <= 35.0:
					var npc_pos = center + Vector2(cm.global_position.x, cm.global_position.z) * scale_factor
					draw_circle(npc_pos, 2.5 if not is_fullscreen else 4.0, Color("#8A8FA8"))

	# DECISION MARKERS: small amber diamond ◆ where each decision was made
	var state = get_node_or_null("/root/GameState")
	if state and is_fullscreen:
		var decision_coords = []
		if state.current_level > 1:
			decision_coords.append(Vector2(-27.0, 40.0)) # L1 Substation
		if state.current_level > 2:
			decision_coords.append(Vector2(-20.0, -25.0)) # L2 Server Hall
		if state.current_level > 3:
			decision_coords.append(Vector2(40.0, -20.0)) # L3 Outfall
		if state.current_level > 4:
			decision_coords.append(Vector2(20.0, 14.5)) # L4 SCADA Hub
			
		for dc in decision_coords:
			var dpos = center + dc * scale_factor
			var d_size = 5.0
			var pts = PackedVector2Array([
				dpos + Vector2(0, -d_size),
				dpos + Vector2(d_size, 0),
				dpos + Vector2(0, d_size),
				dpos + Vector2(-d_size, 0)
			])
			draw_colored_polygon(pts, Color("#F0A500"))
			
	# CURRENT OBJECTIVE TARGET: pulsing amber circle 6px
	var mm = get_tree().root.find_child("MissionManager", true, false)
	if mm and mm.waypoint_marker and mm.waypoint_marker.is_active:
		var tgt = mm.waypoint_marker.target_pos
		var tgt_2d = center + Vector2(tgt.x, tgt.z) * scale_factor
		var pulse_scale = 1.0 + 0.25 * sin(pulse_time * 6.0)
		draw_circle(tgt_2d, 3.0 * pulse_scale, Color("#F0A500"))
		draw_circle(tgt_2d, 6.0 * pulse_scale, Color(0.94, 0.65, 0.0, 0.4), false, 1.5)
		
	# PLAYER: amber #F0A500 filled circle 7px + 10px amber direction arrow
	if player_ref and is_instance_valid(player_ref):
		var p_pos = center + Vector2(player_ref.global_position.x, player_ref.global_position.z) * scale_factor
		draw_circle(p_pos, 3.5, Color("#F0A500"))
		draw_circle(p_pos, 5.0, Color("#FFFFFF"), false, 1.0)
		
		# 10px amber arrow pointing in player's current facing direction
		var forward = -player_ref.global_transform.basis.z
		var dir_2d = Vector2(forward.x, forward.z).normalized()
		draw_line(p_pos, p_pos + dir_2d * 10.0, Color("#F0A500"), 2.0)
		
	# FULLSCREEN LEGEND (bottom-left)
	if is_fullscreen:
		var leg_w = 400.0
		var leg_h = 44.0
		var leg_x = 24.0
		var leg_y = sz.y - leg_h - 24.0
		
		draw_rect(Rect2(leg_x, leg_y, leg_w, leg_h), Color(0.04, 0.06, 0.10, 0.94))
		draw_rect(Rect2(leg_x, leg_y, leg_w, leg_h), Color("#F0A500"), false, 1.0)
		draw_string(font, Vector2(leg_x + 16, leg_y + 26), "● Player    ○ Objective    · NPC    ◇ Interactable", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#E8E0D0"))
