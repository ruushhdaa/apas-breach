class_name MinimapControl
extends Control

@export var is_fullscreen: bool = false

var map_scale: float = 1.6 # World meters to minimap pixels
var player_ref: Node3D = null

func _ready() -> void:
	custom_minimum_size = Vector2(600, 600) if is_fullscreen else Vector2(220, 220)

func _process(_delta: float) -> void:
	if not player_ref:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_ref = players[0]
	queue_redraw()

func _draw() -> void:
	var size = get_size()
	var center = size * 0.5
	
	# Background
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.06, 0.10, 0.92))
	draw_rect(Rect2(Vector2.ZERO, size), Color("#F0A500"), false, 2.0)
	
	# World coordinates center around Gate 4 (0, 0)
	var scale_factor = 2.4 if is_fullscreen else 1.3
	
	# Draw Compound Zones (GTA III map vector outlines)
	# Main Facility Boundary (-50..50, -50..50)
	var compound_rect = Rect2(center + Vector2(-45, -50) * scale_factor, Vector2(90, 100) * scale_factor)
	draw_rect(compound_rect, Color("#2C3440"), false, 1.5)
	
	# Creek (x 60..100, z -50..50)
	var creek_rect = Rect2(center + Vector2(45, -45) * scale_factor, Vector2(35, 90) * scale_factor)
	draw_rect(creek_rect, Color(0.15, 0.45, 0.70, 0.6), true)
	draw_rect(creek_rect, Color("#3388CC"), false, 1.5)
	
	# Rabale Colony (z 70..120)
	var colony_rect = Rect2(center + Vector2(-35, 55) * scale_factor, Vector2(70, 45) * scale_factor)
	draw_rect(colony_rect, Color(0.4, 0.3, 0.2, 0.5), true)
	draw_rect(colony_rect, Color("#8C6239"), false, 1.5)
	
	# Server Hall A (-45..-15, -45..-5)
	var hall_rect = Rect2(center + Vector2(-40, -40) * scale_factor, Vector2(25, 30) * scale_factor)
	draw_rect(hall_rect, Color("#1A2028"), true)
	draw_rect(hall_rect, Color("#4A5568"), false, 1.5)
	
	# Cooling Towers (-5..35, -35)
	for tx in [-5.0, 8.0, 21.0, 34.0]:
		var tp = center + Vector2(tx, -35.0) * scale_factor
		draw_circle(tp, 4.0 * (scale_factor / 1.3), Color("#5A6B80"))
		
	# SCADA Hub (20, 10)
	var scada_rect = Rect2(center + Vector2(15, 5) * scale_factor, Vector2(12, 10) * scale_factor)
	draw_rect(scada_rect, Color("#253245"), true)
	draw_rect(scada_rect, Color("#4A8F9E"), false, 1.5)
	
	# Labels
	draw_string(ThemeDB.fallback_font, center + Vector2(-20, 48) * scale_factor, "GATE 4", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color("#F0A500"))
	draw_string(ThemeDB.fallback_font, center + Vector2(50, -5) * scale_factor, "CREEK", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color("#4FC3F7"))
	draw_string(ThemeDB.fallback_font, center + Vector2(-20, 75) * scale_factor, "COLONY", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color("#D4A373"))
	draw_string(ThemeDB.fallback_font, center + Vector2(-38, -25) * scale_factor, "SERVER A", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color("#A0AEC0"))
	draw_string(ThemeDB.fallback_font, center + Vector2(15, -40) * scale_factor, "COOLING", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color("#A0AEC0"))
	
	# Cardinal Direction "N"
	draw_string(ThemeDB.fallback_font, Vector2(center.x - 4, 18), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color("#FFFFFF"))
	
	# Draw Interactables (White dots)
	var interactables = get_tree().get_nodes_in_group("interactables")
	for item in interactables:
		if is_instance_valid(item):
			var pos_2d = center + Vector2(item.global_position.x, item.global_position.z) * scale_factor
			draw_circle(pos_2d, 3.0, Color("#FFFFFF"))
			
	# Draw Player (Amber dot with heading pointer)
	if player_ref and is_instance_valid(player_ref):
		var p_pos = center + Vector2(player_ref.global_position.x, player_ref.global_position.z) * scale_factor
		draw_circle(p_pos, 5.0, Color("#F0A500"))
		draw_circle(p_pos, 6.0, Color("#000000"), false, 1.0)
		
		# Heading arrow
		var forward = -player_ref.global_transform.basis.z
		var dir_2d = Vector2(forward.x, forward.z).normalized()
		draw_line(p_pos, p_pos + dir_2d * 8.0, Color("#F0A500"), 2.0)
		
	# Fullscreen Legend
	if is_fullscreen:
		var leg_y = size.y - 80.0
		draw_rect(Rect2(20, leg_y, size.x - 40, 65), Color(0.08, 0.12, 0.18, 0.95))
		draw_rect(Rect2(20, leg_y, size.x - 40, 65), Color("#F0A500"), false, 1.0)
		
		# Legend items
		draw_circle(Vector2(45, leg_y + 25), 5.0, Color("#F0A500"))
		draw_string(ThemeDB.fallback_font, Vector2(60, leg_y + 30), "Auditor (Player)", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#E8E0D0"))
		
		draw_circle(Vector2(200, leg_y + 25), 4.0, Color("#FFFFFF"))
		draw_string(ThemeDB.fallback_font, Vector2(215, leg_y + 30), "Interactable / Console", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#E8E0D0"))
		
		draw_rect(Rect2(390, leg_y + 20, 16, 12), Color("#3388CC"))
		draw_string(ThemeDB.fallback_font, Vector2(415, leg_y + 30), "Thane Creek Estuary", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#E8E0D0"))
		
		draw_string(ThemeDB.fallback_font, Vector2(35, leg_y + 52), "[M] CLOSE MAP OVERLAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#F0A500"))
