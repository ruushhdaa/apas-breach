class_name WaypointMarker
extends Node3D

var arrow_inst: MeshInstance3D
var pulse_time: float = 0.0
var target_pos: Vector3 = Vector3.ZERO
var is_active: bool = false
var cached_player: Node3D

func _ready() -> void:
	arrow_inst = MeshInstance3D.new()
	var prism = PrismMesh.new()
	prism.size = Vector3(0.9, 1.2, 0.1)
	arrow_inst.mesh = prism
	arrow_inst.rotation_degrees = Vector3(180, 0, 0) # Points down
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("#F0A500")
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	arrow_inst.material_override = mat
	add_child(arrow_inst)
	visible = false

func set_target(pos: Vector3) -> void:
	target_pos = pos
	global_position = pos + Vector3(0, 3.2, 0)
	is_active = true
	visible = true

func clear_target() -> void:
	is_active = false
	visible = false

func _process(delta: float) -> void:
	if not is_active:
		visible = false
		return
		
	if not cached_player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			cached_player = players[0]
			
	if cached_player:
		var dist = global_position.distance_to(cached_player.global_position)
		# Disappears when within 4m or further than 30m
		if dist <= 4.0 or dist > 30.0:
			visible = false
		else:
			visible = true
			pulse_time += delta
			var s = 0.9 + 0.2 * (sin(pulse_time * TAU / 1.2) * 0.5 + 0.5)
			arrow_inst.scale = Vector3(s, s, s)
			# Bobbing slightly
			arrow_inst.position.y = sin(pulse_time * 3.0) * 0.15
