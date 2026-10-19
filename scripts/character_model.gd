class_name CharacterModel
extends Node3D

@export var character_type: String = "VOLT" # "VOLT", "ANANYA", "TARA", "SUNITA", "ROHAN", "KULKARNI", "GUARD", "PEDESTRIAN"

var anim_player: AnimationPlayer
var root_pivot: Node3D
var torso: MeshInstance3D
var head: MeshInstance3D
var arm_l: MeshInstance3D
var arm_r: MeshInstance3D
var leg_l: MeshInstance3D
var leg_r: MeshInstance3D
var prop_accessory: Node3D
var blob_shadow: MeshInstance3D

var is_built: bool = false

func _ready() -> void:
	if not is_built:
		build_model()
		setup_animations()
		is_built = true

func rebuild_for_specialist(new_type: String) -> void:
	character_type = new_type
	build_model()
	setup_animations()
	is_built = true

func build_model() -> void:
	for child in get_children():
		child.free()
		
	root_pivot = Node3D.new()
	root_pivot.name = "RootPivot"
	add_child(root_pivot)
	
	# Determine scale & color scheme based on character type
	var skin_color = Color("#5C3B24") # Dark/brown
	var clothes_color = Color("#222831")
	var accent_color = Color("#F0A500")
	var height_scale = 1.0
	var width_scale = 1.0
	
	match character_type:
		"VOLT":
			skin_color = Color("#4D301C")
			clothes_color = Color("#2B303A")
			accent_color = Color("#F0A500") # Amber high-vis
			height_scale = 1.08
			width_scale = 1.15
		"ANANYA":
			skin_color = Color("#664228")
			clothes_color = Color("#FFFFFF") # Lab coat
			accent_color = Color("#4A8F9E") # Teal
			height_scale = 1.0
			width_scale = 0.95
		"TARA":
			skin_color = Color("#785236")
			clothes_color = Color("#2E382E") # Dark hoodie
			accent_color = Color("#4A7C59") # Olive
			height_scale = 0.96
			width_scale = 0.90
		"SUNITA":
			skin_color = Color("#593822")
			clothes_color = Color("#B34A3B") # Saree red-ochre
			accent_color = Color("#D97D54")
			height_scale = 0.92
			width_scale = 0.95
		"ROHAN":
			skin_color = Color("#613F29")
			clothes_color = Color("#1F242E") # Corporate dark shirt
			accent_color = Color("#D9534F")
			height_scale = 1.02
			width_scale = 1.0
		"KULKARNI":
			skin_color = Color("#5E3B26")
			clothes_color = Color("#E6E8EA") # Govt white uniform
			accent_color = Color("#1D4E89")
			height_scale = 1.0
			width_scale = 1.05
		"GUARD":
			skin_color = Color("#553520")
			clothes_color = Color("#324357") # Security navy
			accent_color = Color("#F0C040")
			height_scale = 1.04
			width_scale = 1.1
		_: # PEDESTRIAN
			skin_color = Color("#613F29")
			clothes_color = Color("#5A6978")
			accent_color = Color("#D4A373")
			height_scale = 0.98
			width_scale = 0.98
			
	# Materials (GTA 3 Flat Shaded PS2 Aesthetic)
	var mat_skin = StandardMaterial3D.new()
	mat_skin.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_skin.albedo_color = skin_color
	
	var mat_clothes = StandardMaterial3D.new()
	mat_clothes.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_clothes.albedo_color = clothes_color
	
	var mat_accent = StandardMaterial3D.new()
	mat_accent.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_accent.albedo_color = accent_color
	
	var mat_pants = StandardMaterial3D.new()
	mat_pants.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_pants.albedo_color = Color("#1E232B")
	
	var mat_shoes = StandardMaterial3D.new()
	mat_shoes.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_shoes.albedo_color = Color("#111317")
	
	# Torso (Blocky GTA III shape)
	torso = MeshInstance3D.new()
	torso.name = "Torso"
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.55 * width_scale, 0.7 * height_scale, 0.35)
	torso.mesh = t_box
	torso.position = Vector3(0, 1.15 * height_scale, 0)
	torso.material_override = mat_clothes
	root_pivot.add_child(torso)
	
	# Vest / Accent overlay on Torso
	if character_type == "VOLT":
		var vest = MeshInstance3D.new()
		var v_box = BoxMesh.new()
		v_box.size = Vector3(0.58 * width_scale, 0.65 * height_scale, 0.38)
		vest.mesh = v_box
		vest.material_override = mat_accent
		torso.add_child(vest)
	elif character_type == "ANANYA":
		var lapels = MeshInstance3D.new()
		var l_box = BoxMesh.new()
		l_box.size = Vector3(0.3 * width_scale, 0.5 * height_scale, 0.38)
		lapels.mesh = l_box
		lapels.position = Vector3(0, -0.05, 0)
		lapels.material_override = mat_accent
		torso.add_child(lapels)
	elif character_type == "TARA":
		var pouch = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(0.4 * width_scale, 0.25 * height_scale, 0.38)
		pouch.mesh = p_box
		pouch.position = Vector3(0, -0.2, 0)
		pouch.material_override = mat_accent
		torso.add_child(pouch)
		
	# Head (Slightly oversized GTA III proportions)
	head = MeshInstance3D.new()
	head.name = "Head"
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.36, 0.38, 0.36)
	head.mesh = h_box
	head.position = Vector3(0, 0.55 * height_scale, 0)
	head.material_override = mat_skin
	torso.add_child(head)
	
	# Hard hat for Volt
	if character_type == "VOLT":
		var hat = MeshInstance3D.new()
		var hat_box = BoxMesh.new()
		hat_box.size = Vector3(0.42, 0.18, 0.44)
		hat.mesh = hat_box
		hat.position = Vector3(0, 0.22, 0)
		hat.material_override = mat_accent
		head.add_child(hat)
		
	# Hair / Bun for Ananya
	if character_type == "ANANYA":
		var hair = MeshInstance3D.new()
		var hair_box = BoxMesh.new()
		hair_box.size = Vector3(0.38, 0.18, 0.4)
		hair.mesh = hair_box
		hair.position = Vector3(0, 0.15, -0.05)
		var mat_hair = StandardMaterial3D.new()
		mat_hair.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mat_hair.albedo_color = Color("#1A120B")
		hair.material_override = mat_hair
		head.add_child(hair)
		
	# Hoodie trim for Tara
	if character_type == "TARA":
		var hood = MeshInstance3D.new()
		var hood_box = BoxMesh.new()
		hood_box.size = Vector3(0.42, 0.38, 0.38)
		hood.mesh = hood_box
		hood.position = Vector3(0, 0.05, -0.06)
		hood.material_override = mat_clothes
		head.add_child(hood)
		
	# Arms
	var arm_size = Vector3(0.18, 0.65 * height_scale, 0.18)
	var a_mesh = BoxMesh.new()
	a_mesh.size = arm_size
	
	arm_l = MeshInstance3D.new()
	arm_l.name = "ArmL"
	arm_l.mesh = a_mesh
	arm_l.position = Vector3(-0.38 * width_scale, 0.0, 0)
	arm_l.material_override = mat_clothes
	torso.add_child(arm_l)
	
	arm_r = MeshInstance3D.new()
	arm_r.name = "ArmR"
	arm_r.mesh = a_mesh
	arm_r.position = Vector3(0.38 * width_scale, 0.0, 0)
	arm_r.material_override = mat_clothes
	torso.add_child(arm_r)
	
	# Hands
	for arm in [arm_l, arm_r]:
		var hand = MeshInstance3D.new()
		var hand_box = BoxMesh.new()
		hand_box.size = Vector3(0.14, 0.15, 0.14)
		hand.mesh = hand_box
		hand.position = Vector3(0, -0.36 * height_scale, 0)
		hand.material_override = mat_skin
		arm.add_child(hand)
		
	# Legs
	var leg_size = Vector3(0.22 * width_scale, 0.75 * height_scale, 0.22)
	var l_mesh = BoxMesh.new()
	l_mesh.size = leg_size
	
	leg_l = MeshInstance3D.new()
	leg_l.name = "LegL"
	leg_l.mesh = l_mesh
	leg_l.position = Vector3(-0.16 * width_scale, 0.42 * height_scale, 0)
	leg_l.material_override = mat_pants
	root_pivot.add_child(leg_l)
	
	leg_r = MeshInstance3D.new()
	leg_r.name = "LegR"
	leg_r.mesh = l_mesh
	leg_r.position = Vector3(0.16 * width_scale, 0.42 * height_scale, 0)
	leg_r.material_override = mat_pants
	root_pivot.add_child(leg_r)
	
	# Shoes
	for leg in [leg_l, leg_r]:
		var shoe = MeshInstance3D.new()
		var shoe_box = BoxMesh.new()
		shoe_box.size = Vector3(0.24 * width_scale, 0.14, 0.32)
		shoe.mesh = shoe_box
		shoe.position = Vector3(0, -0.38 * height_scale, 0.05)
		shoe.material_override = mat_shoes
		leg.add_child(shoe)
		
	# Specialist Hip / Bag Props
	if character_type == "ANANYA":
		# Sample Kit visible on hip
		prop_accessory = Node3D.new()
		var kit = MeshInstance3D.new()
		var kit_box = BoxMesh.new()
		kit_box.size = Vector3(0.2, 0.24, 0.16)
		kit.mesh = kit_box
		kit.position = Vector3(0.32, -0.15, 0)
		var mat_kit = StandardMaterial3D.new()
		mat_kit.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mat_kit.albedo_color = Color("#85A3B2")
		kit.material_override = mat_kit
		prop_accessory.add_child(kit)
		torso.add_child(prop_accessory)
	elif character_type == "TARA":
		# Laptop bag across shoulder
		prop_accessory = Node3D.new()
		var bag = MeshInstance3D.new()
		var bag_box = BoxMesh.new()
		bag_box.size = Vector3(0.32, 0.28, 0.12)
		bag.mesh = bag_box
		bag.position = Vector3(-0.3, -0.1, 0.1)
		bag.rotation_degrees = Vector3(10, 0, 15)
		var mat_bag = StandardMaterial3D.new()
		mat_bag.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mat_bag.albedo_color = Color("#222A22")
		bag.material_override = mat_bag
		prop_accessory.add_child(bag)
		torso.add_child(prop_accessory)
		
	# Blob Shadow (Decal-like flat cylinder under character)
	blob_shadow = MeshInstance3D.new()
	blob_shadow.name = "BlobShadow"
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 0.45 * width_scale
	s_cyl.bottom_radius = 0.45 * width_scale
	s_cyl.height = 0.01
	blob_shadow.mesh = s_cyl
	blob_shadow.position = Vector3(0, 0.01, 0)
	var mat_shadow = StandardMaterial3D.new()
	mat_shadow.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_shadow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_shadow.albedo_color = Color(0.1, 0.12, 0.18, 0.4)
	blob_shadow.material_override = mat_shadow
	add_child(blob_shadow)

func setup_animations() -> void:
	anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	add_child(anim_player)
	
	var anim_lib = AnimationLibrary.new()
	
	# IDLE
	var anim_idle = Animation.new()
	anim_idle.length = 2.0
	anim_idle.loop_mode = Animation.LOOP_LINEAR
	
	var t_track = anim_idle.add_track(Animation.TYPE_VALUE)
	anim_idle.track_set_path(t_track, "RootPivot/Torso:position:y")
	anim_idle.track_insert_key(t_track, 0.0, torso.position.y)
	anim_idle.track_insert_key(t_track, 1.0, torso.position.y - 0.02)
	anim_idle.track_insert_key(t_track, 2.0, torso.position.y)
	
	var a_track_l = anim_idle.add_track(Animation.TYPE_VALUE)
	anim_idle.track_set_path(a_track_l, "RootPivot/Torso/ArmL:rotation_degrees:x")
	anim_idle.track_insert_key(a_track_l, 0.0, 0.0)
	anim_idle.track_insert_key(a_track_l, 1.0, 3.0)
	anim_idle.track_insert_key(a_track_l, 2.0, 0.0)
	
	var a_track_r = anim_idle.add_track(Animation.TYPE_VALUE)
	anim_idle.track_set_path(a_track_r, "RootPivot/Torso/ArmR:rotation_degrees:x")
	anim_idle.track_insert_key(a_track_r, 0.0, 0.0)
	anim_idle.track_insert_key(a_track_r, 1.0, -3.0)
	anim_idle.track_insert_key(a_track_r, 2.0, 0.0)
	anim_lib.add_animation("idle", anim_idle)
	
	# WALK
	var anim_walk = Animation.new()
	anim_walk.length = 0.8
	anim_walk.loop_mode = Animation.LOOP_LINEAR
	
	var w_leg_l = anim_walk.add_track(Animation.TYPE_VALUE)
	anim_walk.track_set_path(w_leg_l, "RootPivot/LegL:rotation_degrees:x")
	anim_walk.track_insert_key(w_leg_l, 0.0, 25.0)
	anim_walk.track_insert_key(w_leg_l, 0.4, -25.0)
	anim_walk.track_insert_key(w_leg_l, 0.8, 25.0)
	
	var w_leg_r = anim_walk.add_track(Animation.TYPE_VALUE)
	anim_walk.track_set_path(w_leg_r, "RootPivot/LegR:rotation_degrees:x")
	anim_walk.track_insert_key(w_leg_r, 0.0, -25.0)
	anim_walk.track_insert_key(w_leg_r, 0.4, 25.0)
	anim_walk.track_insert_key(w_leg_r, 0.8, -25.0)
	
	var w_arm_l = anim_walk.add_track(Animation.TYPE_VALUE)
	anim_walk.track_set_path(w_arm_l, "RootPivot/Torso/ArmL:rotation_degrees:x")
	anim_walk.track_insert_key(w_arm_l, 0.0, -20.0)
	anim_walk.track_insert_key(w_arm_l, 0.4, 20.0)
	anim_walk.track_insert_key(w_arm_l, 0.8, -20.0)
	
	var w_arm_r = anim_walk.add_track(Animation.TYPE_VALUE)
	anim_walk.track_set_path(w_arm_r, "RootPivot/Torso/ArmR:rotation_degrees:x")
	anim_walk.track_insert_key(w_arm_r, 0.0, 20.0)
	anim_walk.track_insert_key(w_arm_r, 0.4, -20.0)
	anim_walk.track_insert_key(w_arm_r, 0.8, 20.0)
	anim_lib.add_animation("walk", anim_walk)
	
	# RUN
	var anim_run = Animation.new()
	anim_run.length = 0.5
	anim_run.loop_mode = Animation.LOOP_LINEAR
	
	var r_leg_l = anim_run.add_track(Animation.TYPE_VALUE)
	anim_run.track_set_path(r_leg_l, "RootPivot/LegL:rotation_degrees:x")
	anim_run.track_insert_key(r_leg_l, 0.0, 42.0)
	anim_run.track_insert_key(r_leg_l, 0.25, -42.0)
	anim_run.track_insert_key(r_leg_l, 0.5, 42.0)
	
	var r_leg_r = anim_run.add_track(Animation.TYPE_VALUE)
	anim_run.track_set_path(r_leg_r, "RootPivot/LegR:rotation_degrees:x")
	anim_run.track_insert_key(r_leg_r, 0.0, -42.0)
	anim_run.track_insert_key(r_leg_r, 0.25, 42.0)
	anim_run.track_insert_key(r_leg_r, 0.5, -42.0)
	
	var r_arm_l = anim_run.add_track(Animation.TYPE_VALUE)
	anim_run.track_set_path(r_arm_l, "RootPivot/Torso/ArmL:rotation_degrees:x")
	anim_run.track_insert_key(r_arm_l, 0.0, -35.0)
	anim_run.track_insert_key(r_arm_l, 0.25, 35.0)
	anim_run.track_insert_key(r_arm_l, 0.5, -35.0)
	
	var r_arm_r = anim_run.add_track(Animation.TYPE_VALUE)
	anim_run.track_set_path(r_arm_r, "RootPivot/Torso/ArmR:rotation_degrees:x")
	anim_run.track_insert_key(r_arm_r, 0.0, 35.0)
	anim_run.track_insert_key(r_arm_r, 0.25, -35.0)
	anim_run.track_insert_key(r_arm_r, 0.5, 35.0)
	anim_lib.add_animation("run", anim_run)
	
	# INTERACT
	var anim_interact = Animation.new()
	anim_interact.length = 0.6
	var i_arm_r = anim_interact.add_track(Animation.TYPE_VALUE)
	anim_interact.track_set_path(i_arm_r, "RootPivot/Torso/ArmR:rotation_degrees:x")
	anim_interact.track_insert_key(i_arm_r, 0.0, 0.0)
	anim_interact.track_insert_key(i_arm_r, 0.3, -65.0)
	anim_interact.track_insert_key(i_arm_r, 0.6, 0.0)
	anim_lib.add_animation("interact", anim_interact)
	
	# TOOL
	var anim_tool = Animation.new()
	anim_tool.length = 1.0
	var tl_arm = anim_tool.add_track(Animation.TYPE_VALUE)
	anim_tool.track_set_path(tl_arm, "RootPivot/Torso/ArmR:rotation_degrees:x")
	anim_tool.track_insert_key(tl_arm, 0.0, 0.0)
	anim_tool.track_insert_key(tl_arm, 0.2, -80.0)
	anim_tool.track_insert_key(tl_arm, 0.8, -80.0)
	anim_tool.track_insert_key(tl_arm, 1.0, 0.0)
	anim_lib.add_animation("tool", anim_tool)
	
	anim_player.add_animation_library("", anim_lib)
	anim_player.play("idle")

func play_anim(anim_name: String) -> void:
	if anim_player and anim_player.has_animation(anim_name):
		if anim_player.current_animation != anim_name:
			anim_player.play(anim_name)
