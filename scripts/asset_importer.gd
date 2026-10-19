class_name AssetImporter
extends RefCounted

# AssetImporter: Handles loading, importing, and material overriding for 3D assets in APAS: BREACH
# Ensures all assets conform to the GTA III PS2 visual aesthetic.

static var model_cache: Dictionary = {}

static func apply_psx_material(node: Node, tint_color: Color = Color.WHITE) -> void:
	if not node:
		return
		
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		
		# Process material
		var orig_mat = mi.material_override
		if not orig_mat and mi.mesh and mi.mesh.get_surface_count() > 0:
			orig_mat = mi.mesh.surface_get_material(0)
			
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.roughness = 1.0
		mat.metallic = 0.0
		mat.normal_enabled = false
		
		if orig_mat is StandardMaterial3D or orig_mat is ORMMaterial3D:
			mat.albedo_color = orig_mat.albedo_color * tint_color
			mat.albedo_texture = orig_mat.albedo_texture
		else:
			mat.albedo_color = tint_color
			
		mi.material_override = mat
		
	for child in node.get_children():
		apply_psx_material(child, tint_color)

static func load_gltf_or_fallback(file_path: String) -> Node3D:
	if model_cache.has(file_path):
		return model_cache[file_path].duplicate()
		
	if not FileAccess.file_exists(file_path):
		push_warning("Asset not found at path: %s" % file_path)
		return null
		
	var doc = GLTFDocument.new()
	var state = GLTFState.new()
	var err = doc.append_from_file(file_path, state)
	if err == OK:
		var scene_root = doc.generate_scene(state)
		if scene_root:
			apply_psx_material(scene_root)
			model_cache[file_path] = scene_root
			return scene_root.duplicate()
	else:
		push_warning("Failed to import asset %s (Error code: %d). Skipping and using fallback primitives." % [file_path, err])
		
	return null

static func get_military_gatehouse() -> Node3D:
	var path = "res://src/assets/CITY/Military_Post/Military_Post.glb"
	var inst = load_gltf_or_fallback(path)
	if inst:
		inst.scale = Vector3(0.5, 0.5, 0.5)
		return inst
	return null

static func get_cooling_tower_mesh() -> Node3D:
	var path = "res://src/assets/CITY/Cooling_Tower/cooling_tower.glb"
	if FileAccess.file_exists(path):
		var inst = load_gltf_or_fallback(path)
		if inst: return inst
	return null
