class_name CharacterModel
extends Node3D

@export var character_type: String = "VOLT" # "VOLT", "ANANYA", "TARA", "SUNITA", "ROHAN", "KULKARNI", "GUARD", "PEDESTRIAN"

var anim_player: AnimationPlayer
var root_pivot: Node3D
var torso: Node3D
var head: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var prop_accessory: Node3D
var blob_shadow: MeshInstance3D

var is_built: bool = false

func _ready() -> void:
	if not is_built:
		build_model()
		setup_animations()
		_enable_shadows(self)
		is_built = true

func rebuild_for_specialist(new_type: String) -> void:
	character_type = new_type
	build_model()
	setup_animations()
	_enable_shadows(self)
	is_built = true

func _enable_shadows(node: Node) -> void:
	if node is MeshInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for c in node.get_children():
		_enable_shadows(c)

func _create_material(color: Color) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat.albedo_color = color
	mat.roughness = 0.9
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	return mat

func _build_beveled_torso(top_w: float, bot_w: float, h: float, depth: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 8 vertices of a trapezoidal box wider at shoulders
	var tw2 = top_w * 0.5
	var bw2 = bot_w * 0.5
	var d2 = depth * 0.5
	var h2 = h * 0.5
	
	var v_tlf = Vector3(-tw2, h2, d2)
	var v_trf = Vector3(tw2, h2, d2)
	var v_trb = Vector3(tw2, h2, -d2)
	var v_tlb = Vector3(-tw2, h2, -d2)
	
	var v_blf = Vector3(-bw2, -h2, d2)
	var v_brf = Vector3(bw2, -h2, d2)
	var v_brb = Vector3(bw2, -h2, -d2)
	var v_blb = Vector3(-bw2, -h2, -d2)
	
	# Front face
	st.set_normal(Vector3(0, 0, 1))
	st.add_vertex(v_blf); st.add_vertex(v_trf); st.add_vertex(v_tlf)
	st.add_vertex(v_blf); st.add_vertex(v_brf); st.add_vertex(v_trf)
	
	# Back face
	st.set_normal(Vector3(0, 0, -1))
	st.add_vertex(v_brb); st.add_vertex(v_tlb); st.add_vertex(v_trb)
	st.add_vertex(v_brb); st.add_vertex(v_blb); st.add_vertex(v_tlb)
	
	# Left face
	st.set_normal(Vector3(-1, 0, 0))
	st.add_vertex(v_blb); st.add_vertex(v_tlf); st.add_vertex(v_tlb)
	st.add_vertex(v_blb); st.add_vertex(v_blf); st.add_vertex(v_tlf)
	
	# Right face
	st.set_normal(Vector3(1, 0, 0))
	st.add_vertex(v_brf); st.add_vertex(v_trb); st.add_vertex(v_trf)
	st.add_vertex(v_brf); st.add_vertex(v_brb); st.add_vertex(v_trb)
	
	# Top face
	st.set_normal(Vector3(0, 1, 0))
	st.add_vertex(v_tlf); st.add_vertex(v_trb); st.add_vertex(v_tlb)
	st.add_vertex(v_tlf); st.add_vertex(v_trf); st.add_vertex(v_trb)
	
	# Bottom face
	st.set_normal(Vector3(0, -1, 0))
	st.add_vertex(v_blb); st.add_vertex(v_brf); st.add_vertex(v_blf)
	st.add_vertex(v_blb); st.add_vertex(v_brb); st.add_vertex(v_brf)
	
	return st.commit()

func build_model() -> void:
	for child in get_children():
		child.free()
		
	root_pivot = Node3D.new()
	root_pivot.name = "RootPivot"
	add_child(root_pivot)
	
	# Color palettes and dimension scales
	var skin_color = Color("#4A2E1A")
	var clothes_color = Color("#222831")
	var accent_color = Color("#F0A500")
	var pants_color = Color("#1A1D24")
	var shoes_color = Color("#111317")
	var height_scale = 1.0
	var width_scale = 1.0
	
	match character_type:
		"VOLT":
			skin_color = Color("#4A2E1A") # Dark skin tone #4A2E1A
			clothes_color = Color("#2B303A") # Dark undershirt
			accent_color = Color("#F0A500") # Amber #F0A500
			pants_color = Color("#20232A")
			shoes_color = Color("#141518")
			height_scale = 1.06
			width_scale = 1.15
		"ANANYA":
			skin_color = Color("#7A4A2A") # Warm brown skin #7A4A2A
			clothes_color = Color("#F5F5F0") # White lab coat #F5F5F0
			accent_color = Color("#4A6B7A") # Teal #4A6B7A
			pants_color = Color("#3A4550")
			shoes_color = Color("#2B333C")
			height_scale = 1.0
			width_scale = 0.95
		"TARA":
			skin_color = Color("#8A6A3A") # Olive skin tone #8A6A3A
			clothes_color = Color("#4A7C59") # Olive hoodie #4A7C59
			accent_color = Color("#4A7C59") # Olive accent
			pants_color = Color("#1E2421")
			shoes_color = Color("#2A312B")
			height_scale = 0.97
			width_scale = 0.92
		"SUNITA":
			skin_color = Color("#6B4429")
			clothes_color = Color("#B34A3B") # Sari drape red-ochre
			accent_color = Color("#D97D54")
			pants_color = Color("#943E31")
			shoes_color = Color("#592E26")
			height_scale = 0.88
			width_scale = 0.94
		"ROHAN":
			skin_color = Color("#684630")
			clothes_color = Color("#1F242E") # Corporate shirt
			accent_color = Color("#3B82F6")
			pants_color = Color("#181B22")
			shoes_color = Color("#0F1115")
			height_scale = 1.08
			width_scale = 1.0
		"KULKARNI":
			skin_color = Color("#61402B")
			clothes_color = Color("#C2B280") # Khaki MPCB uniform
			accent_color = Color("#9E8B62")
			pants_color = Color("#A89968")
			shoes_color = Color("#3D3524")
			height_scale = 1.0
			width_scale = 1.12
		"GUARD":
			skin_color = Color("#5A3A24")
			clothes_color = Color("#1E2C3D") # Dark blue uniform
			accent_color = Color("#F0A500")
			pants_color = Color("#172331")
			shoes_color = Color("#0D131B")
			height_scale = 1.04
			width_scale = 1.08
		_: # PEDESTRIAN
			skin_color = Color("#6A452D")
			clothes_color = Color("#506070")
			accent_color = Color("#E0A96D")
			pants_color = Color("#2B333E")
			shoes_color = Color("#1B1F24")
			height_scale = 1.0
			width_scale = 1.0

	var mat_skin = _create_material(skin_color)
	var mat_clothes = _create_material(clothes_color)
	var mat_accent = _create_material(accent_color)
	var mat_pants = _create_material(pants_color)
	var mat_shoes = _create_material(shoes_color)
	var mat_white = _create_material(Color("#FFFFFF"))
	var mat_dark = _create_material(Color("#101014"))

	# GTA III Head-to-Body ratio 1:2.8 (Oversized head relative to body)
	# Body total height ~1.75m: Legs ~0.75m, Torso ~0.62m, Head ~0.42m
	
	# TORSO (Beveled box, wider at shoulders)
	torso = Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0, 0.95 * height_scale, 0)
	root_pivot.add_child(torso)
	
	var torso_mesh_inst = MeshInstance3D.new()
	var top_w = 0.58 * width_scale
	var bot_w = 0.44 * width_scale
	var torso_h = 0.62 * height_scale
	var torso_d = 0.32
	torso_mesh_inst.mesh = _build_beveled_torso(top_w, bot_w, torso_h, torso_d)
	torso_mesh_inst.material_override = mat_clothes
	torso.add_child(torso_mesh_inst)
	
	# Character specific Torso Overlays
	if character_type == "VOLT":
		# High-vis vest: bright orange-yellow chest panel over dark undershirt, reflective stripe = white quad strip
		var vest = MeshInstance3D.new()
		var v_mesh = BoxMesh.new()
		v_mesh.size = Vector3(top_w * 0.98, torso_h * 0.95, torso_d * 1.08)
		vest.mesh = v_mesh
		vest.material_override = mat_accent
		torso.add_child(vest)
		
		# Reflective stripe across vest
		var stripe = MeshInstance3D.new()
		var s_mesh = BoxMesh.new()
		s_mesh.size = Vector3(top_w * 1.02, 0.08, torso_d * 1.12)
		stripe.mesh = s_mesh
		stripe.position = Vector3(0, -0.05 * height_scale, 0)
		stripe.material_override = mat_white
		torso.add_child(stripe)
		
	elif character_type == "ANANYA":
		# Lab coat long coat over teal top: Lab coat extends below torso
		var coat_lower = MeshInstance3D.new()
		var cl_mesh = BoxMesh.new()
		cl_mesh.size = Vector3(bot_w * 1.15, 0.45 * height_scale, torso_d * 1.1)
		coat_lower.mesh = cl_mesh
		coat_lower.position = Vector3(0, -0.42 * height_scale, 0)
		coat_lower.material_override = mat_clothes
		torso.add_child(coat_lower)
		
		# Teal shirt collar / upper V visible
		var inner_top = MeshInstance3D.new()
		var it_mesh = BoxMesh.new()
		it_mesh.size = Vector3(top_w * 0.4, 0.22 * height_scale, torso_d * 1.05)
		inner_top.mesh = it_mesh
		inner_top.position = Vector3(0, 0.22 * height_scale, 0.01)
		inner_top.material_override = mat_accent
		torso.add_child(inner_top)
		
	elif character_type == "TARA":
		# Olive hoodie drawstrings (two thin cord meshes)
		for dx in [-0.07, 0.07]:
			var cord = MeshInstance3D.new()
			var c_mesh = CylinderMesh.new()
			c_mesh.top_radius = 0.012
			c_mesh.bottom_radius = 0.012
			c_mesh.height = 0.22
			cord.mesh = c_mesh
			cord.position = Vector3(dx, 0.12 * height_scale, 0.17)
			cord.material_override = mat_white
			torso.add_child(cord)
			
	elif character_type == "SUNITA":
		# Saree drape wrap
		var drape = MeshInstance3D.new()
		var d_mesh = BoxMesh.new()
		d_mesh.size = Vector3(top_w * 1.05, torso_h * 0.7, torso_d * 1.15)
		drape.mesh = d_mesh
		drape.position = Vector3(0.04, -0.05, 0)
		drape.rotation_degrees = Vector3(0, 0, -12)
		drape.material_override = mat_accent
		torso.add_child(drape)
		
	elif character_type == "KULKARNI":
		# Clipboard prop in hand/arm
		var clip = MeshInstance3D.new()
		var c_box = BoxMesh.new()
		c_box.size = Vector3(0.24, 0.32, 0.04)
		clip.mesh = c_box
		clip.position = Vector3(0.38, -0.1, 0.2)
		clip.rotation_degrees = Vector3(-20, 25, 0)
		var mat_board = _create_material(Color("#5C4033"))
		clip.material_override = mat_board
		torso.add_child(clip)

	# HEAD (8-sided cylinder with flat top/bottom, GTA III oversized proportions)
	head = Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, (torso_h * 0.5) + 0.22 * height_scale, 0)
	torso.add_child(head)
	
	var head_mesh_inst = MeshInstance3D.new()
	var h_cyl = CylinderMesh.new()
	h_cyl.radial_segments = 8
	h_cyl.rings = 0
	h_cyl.top_radius = 0.20
	h_cyl.bottom_radius = 0.19
	h_cyl.height = 0.36
	head_mesh_inst.mesh = h_cyl
	head_mesh_inst.material_override = mat_skin
	head.add_child(head_mesh_inst)
	
	# FACE FEATURES: Subdivided front quad with extruded nose, brow ridge, chin, eyes, mouth
	var face_node = Node3D.new()
	face_node.position = Vector3(0, 0, 0.19)
	head.add_child(face_node)
	
	# Brow ridge
	var brow = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.26, 0.04, 0.05)
	brow.mesh = b_box
	brow.position = Vector3(0, 0.08, 0)
	brow.material_override = mat_skin
	face_node.add_child(brow)
	
	# Nose: extruded small triangular prism or box
	var nose = MeshInstance3D.new()
	var n_box = BoxMesh.new()
	n_box.size = Vector3(0.045, 0.08, 0.06)
	nose.mesh = n_box
	nose.position = Vector3(0, 0.01, 0.025)
	nose.material_override = mat_skin
	face_node.add_child(nose)
	
	# Chin: tapered lower face
	var chin = MeshInstance3D.new()
	var ch_box = BoxMesh.new()
	var chin_width = 0.18
	if character_type == "VOLT":
		chin_width = 0.24 # Wide jaw
	elif character_type == "TARA":
		chin_width = 0.14 # Sharp cheekbones / narrow chin
	elif character_type == "ANANYA":
		chin_width = 0.19 # Round cheeks
	ch_box.size = Vector3(chin_width, 0.07, 0.04)
	chin.mesh = ch_box
	chin.position = Vector3(0, -0.13, 0.01)
	chin.material_override = mat_skin
	face_node.add_child(chin)
	
	# Eyes: two dark inset quads on face plane
	for eye_dx in [-0.07, 0.07]:
		var eye = MeshInstance3D.new()
		var e_quad = QuadMesh.new()
		var eye_h = 0.025
		if character_type == "TARA":
			eye_h = 0.018 # Slightly narrowed alert eyes
		e_quad.size = Vector2(0.045, eye_h)
		eye.mesh = e_quad
		eye.position = Vector3(eye_dx, 0.05, 0.012)
		eye.material_override = mat_dark
		face_node.add_child(eye)
		
	# Mouth: horizontal slot cut into lower face
	var mouth = MeshInstance3D.new()
	var m_quad = QuadMesh.new()
	m_quad.size = Vector2(0.09, 0.02)
	mouth.mesh = m_quad
	mouth.position = Vector3(0, -0.06, 0.012)
	if character_type == "VOLT":
		mouth.rotation_degrees = Vector3(0, 0, 4) # slight frown
	elif character_type == "ANANYA":
		mouth.rotation_degrees = Vector3(0, 0, -2) # slight upward curve
	mouth.material_override = mat_dark
	face_node.add_child(mouth)

	# CHARACTER HEAD SPECIFICS
	if character_type == "VOLT":
		# Hard hat: flattened hemisphere on top of head, amber #F0A500, with brim ring
		var hat_dome = MeshInstance3D.new()
		var dome_mesh = SphereMesh.new()
		dome_mesh.radius = 0.23
		dome_mesh.height = 0.26
		dome_mesh.radial_segments = 12
		dome_mesh.rings = 6
		hat_dome.mesh = dome_mesh
		hat_dome.position = Vector3(0, 0.14, 0)
		hat_dome.material_override = mat_accent
		head.add_child(hat_dome)
		
		# Brim ring
		var brim = MeshInstance3D.new()
		var br_mesh = CylinderMesh.new()
		br_mesh.top_radius = 0.27
		br_mesh.bottom_radius = 0.27
		br_mesh.height = 0.03
		brim.mesh = br_mesh
		brim.position = Vector3(0, 0.07, 0.02)
		brim.material_override = mat_accent
		head.add_child(brim)
		
	elif character_type == "ANANYA":
		# Hair tied back: small cylinder bun at back of head
		var bun = MeshInstance3D.new()
		var b_cyl = CylinderMesh.new()
		b_cyl.top_radius = 0.09
		b_cyl.bottom_radius = 0.09
		b_cyl.height = 0.12
		bun.mesh = b_cyl
		bun.position = Vector3(0, 0.04, -0.21)
		bun.rotation_degrees = Vector3(90, 0, 0)
		var mat_hair = _create_material(Color("#1A120B"))
		bun.material_override = mat_hair
		head.add_child(bun)
		
	elif character_type == "TARA":
		# Hoodie down around neck
		var hood = MeshInstance3D.new()
		var h_torus = TorusMesh.new()
		h_torus.inner_radius = 0.17
		h_torus.outer_radius = 0.24
		h_torus.ring_segments = 6
		h_torus.rings = 8
		hood.mesh = h_torus
		hood.position = Vector3(0, -0.16, -0.06)
		hood.rotation_degrees = Vector3(15, 0, 0)
		hood.material_override = mat_clothes
		head.add_child(hood)
		
	elif character_type == "SUNITA":
		# Grey hair bun at back
		var gbun = MeshInstance3D.new()
		var gb_cyl = CylinderMesh.new()
		gb_cyl.top_radius = 0.10
		gb_cyl.bottom_radius = 0.10
		gb_cyl.height = 0.12
		gbun.mesh = gb_cyl
		gbun.position = Vector3(0, 0.03, -0.21)
		gbun.rotation_degrees = Vector3(90, 0, 0)
		var mat_ghair = _create_material(Color("#9E9E9E"))
		gbun.material_override = mat_ghair
		head.add_child(gbun)
		
	elif character_type == "ROHAN":
		# Slick dark hair
		var rhair = MeshInstance3D.new()
		var rh_mesh = BoxMesh.new()
		rh_mesh.size = Vector3(0.40, 0.12, 0.42)
		rhair.mesh = rh_mesh
		rhair.position = Vector3(0, 0.15, -0.02)
		var mat_rhair = _create_material(Color("#101012"))
		rhair.material_override = mat_rhair
		head.add_child(rhair)
		
	elif character_type == "GUARD":
		# Security helmet
		var ghelm = MeshInstance3D.new()
		var gh_mesh = CylinderMesh.new()
		gh_mesh.top_radius = 0.23
		gh_mesh.bottom_radius = 0.24
		gh_mesh.height = 0.16
		ghelm.mesh = gh_mesh
		ghelm.position = Vector3(0, 0.14, 0)
		var mat_helm = _create_material(Color("#121A24"))
		ghelm.material_override = mat_helm
		head.add_child(ghelm)

	# ARMS (6-sided cylinders, slightly tapered)
	var arm_h = 0.58 * height_scale
	var arm_r_top = 0.08 * width_scale
	var arm_r_bot = 0.065 * width_scale
	var arm_dx = (top_w * 0.5) + (arm_r_top * 0.9)
	
	arm_l = Node3D.new()
	arm_l.name = "ArmL"
	arm_l.position = Vector3(-arm_dx, 0.24 * height_scale, 0)
	torso.add_child(arm_l)
	
	arm_r = Node3D.new()
	arm_r.name = "ArmR"
	arm_r.position = Vector3(arm_dx, 0.24 * height_scale, 0)
	torso.add_child(arm_r)
	
	for arm_node in [arm_l, arm_r]:
		var a_mesh_inst = MeshInstance3D.new()
		var a_cyl = CylinderMesh.new()
		a_cyl.radial_segments = 6
		a_cyl.rings = 1
		a_cyl.top_radius = arm_r_top
		a_cyl.bottom_radius = arm_r_bot
		a_cyl.height = arm_h
		a_mesh_inst.mesh = a_cyl
		a_mesh_inst.position = Vector3(0, -arm_h * 0.5, 0)
		a_mesh_inst.material_override = mat_clothes
		arm_node.add_child(a_mesh_inst)
		
		# HANDS (Blocky 4-finger mitten shape)
		var hand_node = Node3D.new()
		hand_node.position = Vector3(0, -arm_h, 0)
		arm_node.add_child(hand_node)
		
		# Palm mitten box
		var palm = MeshInstance3D.new()
		var p_box = BoxMesh.new()
		p_box.size = Vector3(0.09, 0.12, 0.06)
		palm.mesh = p_box
		palm.position = Vector3(0, -0.06, 0)
		palm.material_override = mat_skin
		hand_node.add_child(palm)
		
		# Angled thumb wedge
		var thumb = MeshInstance3D.new()
		var th_box = BoxMesh.new()
		th_box.size = Vector3(0.04, 0.06, 0.04)
		thumb.mesh = th_box
		var thumb_x = 0.05 if arm_node == arm_l else -0.05
		thumb.position = Vector3(thumb_x, -0.04, 0.02)
		thumb.rotation_degrees = Vector3(0, 0, 20 if arm_node == arm_l else -20)
		thumb.material_override = mat_skin
		hand_node.add_child(thumb)

	# LEGS (6-sided cylinders, slightly wider at thigh)
	var leg_h = 0.70 * height_scale
	var leg_r_top = 0.105 * width_scale
	var leg_r_bot = 0.082 * width_scale
	var leg_dx = bot_w * 0.28
	
	leg_l = Node3D.new()
	leg_l.name = "LegL"
	leg_l.position = Vector3(-leg_dx, 0.68 * height_scale, 0)
	root_pivot.add_child(leg_l)
	
	leg_r = Node3D.new()
	leg_r.name = "LegR"
	leg_r.position = Vector3(leg_dx, 0.68 * height_scale, 0)
	root_pivot.add_child(leg_r)
	
	for leg_node in [leg_l, leg_r]:
		var l_mesh_inst = MeshInstance3D.new()
		var l_cyl = CylinderMesh.new()
		l_cyl.radial_segments = 6
		l_cyl.rings = 1
		l_cyl.top_radius = leg_r_top
		l_cyl.bottom_radius = leg_r_bot
		l_cyl.height = leg_h
		l_mesh_inst.mesh = l_cyl
		l_mesh_inst.position = Vector3(0, -leg_h * 0.5, 0)
		l_mesh_inst.material_override = mat_pants
		leg_node.add_child(l_mesh_inst)
		
		# FEET (Flat elongated box, slight toe overhang)
		var foot = MeshInstance3D.new()
		var f_box = BoxMesh.new()
		f_box.size = Vector3(0.15 * width_scale, 0.11, 0.28)
		foot.mesh = f_box
		foot.position = Vector3(0, -leg_h - 0.04, 0.05)
		foot.material_override = mat_shoes
		leg_node.add_child(foot)
		
		# Foot trim
		if character_type == "VOLT" or character_type == "ANANYA" or character_type == "TARA":
			var trim = MeshInstance3D.new()
			var tr_box = BoxMesh.new()
			tr_box.size = Vector3(0.16 * width_scale, 0.03, 0.29)
			trim.mesh = tr_box
			trim.position = Vector3(0, -leg_h - 0.08, 0.05)
			trim.material_override = mat_accent
			leg_node.add_child(trim)

	# ACCESSORIES
	if character_type == "ANANYA":
		# Sample kit on hip: small box attached to belt area with teal trim
		prop_accessory = Node3D.new()
		var kit = MeshInstance3D.new()
		var k_box = BoxMesh.new()
		k_box.size = Vector3(0.18, 0.22, 0.14)
		kit.mesh = k_box
		kit.position = Vector3(0.28, -0.22, 0)
		kit.material_override = mat_accent
		prop_accessory.add_child(kit)
		torso.add_child(prop_accessory)
		
	elif character_type == "TARA":
		# Laptop bag: flat box on shoulder strap
		prop_accessory = Node3D.new()
		var bag = MeshInstance3D.new()
		var bag_box = BoxMesh.new()
		bag_box.size = Vector3(0.32, 0.25, 0.10)
		bag.mesh = bag_box
		bag.position = Vector3(-0.28, -0.12, 0.10)
		bag.rotation_degrees = Vector3(10, 0, 15)
		bag.material_override = mat_accent
		prop_accessory.add_child(bag)
		
		# Shoulder strap
		var strap = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(0.04, 0.65, 0.02)
		strap.mesh = s_box
		strap.position = Vector3(0.05, 0.06, 0.17)
		strap.rotation_degrees = Vector3(0, 0, -45)
		strap.material_override = mat_dark
		prop_accessory.add_child(strap)
		torso.add_child(prop_accessory)

	# Blob Shadow
	blob_shadow = MeshInstance3D.new()
	blob_shadow.name = "BlobShadow"
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 0.44 * width_scale
	s_cyl.bottom_radius = 0.44 * width_scale
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
	var base_torso_y = torso.position.y
	
	# IDLE: subtle breathing bob, 0.04 units Y, 2s loop
	var anim_idle = Animation.new()
	anim_idle.length = 2.0
	anim_idle.loop_mode = Animation.LOOP_LINEAR
	var t_track = anim_idle.add_track(Animation.TYPE_VALUE)
	anim_idle.track_set_path(t_track, "RootPivot/Torso:position:y")
	anim_idle.track_insert_key(t_track, 0.0, base_torso_y)
	anim_idle.track_insert_key(t_track, 1.0, base_torso_y - 0.04)
	anim_idle.track_insert_key(t_track, 2.0, base_torso_y)
	
	var id_arm_l = anim_idle.add_track(Animation.TYPE_VALUE)
	anim_idle.track_set_path(id_arm_l, "RootPivot/Torso/ArmL:rotation_degrees:x")
	anim_idle.track_insert_key(id_arm_l, 0.0, 0.0)
	anim_idle.track_insert_key(id_arm_l, 1.0, 3.0)
	anim_idle.track_insert_key(id_arm_l, 2.0, 0.0)
	
	var id_arm_r = anim_idle.add_track(Animation.TYPE_VALUE)
	anim_idle.track_set_path(id_arm_r, "RootPivot/Torso/ArmR:rotation_degrees:x")
	anim_idle.track_insert_key(id_arm_r, 0.0, 0.0)
	anim_idle.track_insert_key(id_arm_r, 1.0, -3.0)
	anim_idle.track_insert_key(id_arm_r, 2.0, 0.0)
	anim_lib.add_animation("idle", anim_idle)
	
	# WALK: arm swing opposite to leg, 0.6s cycle
	var anim_walk = Animation.new()
	anim_walk.length = 0.6
	anim_walk.loop_mode = Animation.LOOP_LINEAR
	
	var w_leg_l = anim_walk.add_track(Animation.TYPE_VALUE)
	anim_walk.track_set_path(w_leg_l, "RootPivot/LegL:rotation_degrees:x")
	anim_walk.track_insert_key(w_leg_l, 0.0, 26.0)
	anim_walk.track_insert_key(w_leg_l, 0.3, -26.0)
	anim_walk.track_insert_key(w_leg_l, 0.6, 26.0)
	
	var w_leg_r = anim_walk.add_track(Animation.TYPE_VALUE)
	anim_walk.track_set_path(w_leg_r, "RootPivot/LegR:rotation_degrees:x")
	anim_walk.track_insert_key(w_leg_r, 0.0, -26.0)
	anim_walk.track_insert_key(w_leg_r, 0.3, 26.0)
	anim_walk.track_insert_key(w_leg_r, 0.6, -26.0)
	
	var w_arm_l = anim_walk.add_track(Animation.TYPE_VALUE)
	anim_walk.track_set_path(w_arm_l, "RootPivot/Torso/ArmL:rotation_degrees:x")
	anim_walk.track_insert_key(w_arm_l, 0.0, -22.0)
	anim_walk.track_insert_key(w_arm_l, 0.3, 22.0)
	anim_walk.track_insert_key(w_arm_l, 0.6, -22.0)
	
	var w_arm_r = anim_walk.add_track(Animation.TYPE_VALUE)
	anim_walk.track_set_path(w_arm_r, "RootPivot/Torso/ArmR:rotation_degrees:x")
	anim_walk.track_insert_key(w_arm_r, 0.0, 22.0)
	anim_walk.track_insert_key(w_arm_r, 0.3, -22.0)
	anim_walk.track_insert_key(w_arm_r, 0.6, 22.0)
	anim_lib.add_animation("walk", anim_walk)
	
	# RUN: faster arm swing, forward lean 8 degrees, 0.35s
	var anim_run = Animation.new()
	anim_run.length = 0.35
	anim_run.loop_mode = Animation.LOOP_LINEAR
	
	var r_torso = anim_run.add_track(Animation.TYPE_VALUE)
	anim_run.track_set_path(r_torso, "RootPivot/Torso:rotation_degrees:x")
	anim_run.track_insert_key(r_torso, 0.0, 8.0)
	anim_run.track_insert_key(r_torso, 0.35, 8.0)
	
	var r_leg_l = anim_run.add_track(Animation.TYPE_VALUE)
	anim_run.track_set_path(r_leg_l, "RootPivot/LegL:rotation_degrees:x")
	anim_run.track_insert_key(r_leg_l, 0.0, 44.0)
	anim_run.track_insert_key(r_leg_l, 0.175, -44.0)
	anim_run.track_insert_key(r_leg_l, 0.35, 44.0)
	
	var r_leg_r = anim_run.add_track(Animation.TYPE_VALUE)
	anim_run.track_set_path(r_leg_r, "RootPivot/LegR:rotation_degrees:x")
	anim_run.track_insert_key(r_leg_r, 0.0, -44.0)
	anim_run.track_insert_key(r_leg_r, 0.175, 44.0)
	anim_run.track_insert_key(r_leg_r, 0.35, -44.0)
	
	var r_arm_l = anim_run.add_track(Animation.TYPE_VALUE)
	anim_run.track_set_path(r_arm_l, "RootPivot/Torso/ArmL:rotation_degrees:x")
	anim_run.track_insert_key(r_arm_l, 0.0, -38.0)
	anim_run.track_insert_key(r_arm_l, 0.175, 38.0)
	anim_run.track_insert_key(r_arm_l, 0.35, -38.0)
	
	var r_arm_r = anim_run.add_track(Animation.TYPE_VALUE)
	anim_run.track_set_path(r_arm_r, "RootPivot/Torso/ArmR:rotation_degrees:x")
	anim_run.track_insert_key(r_arm_r, 0.0, 38.0)
	anim_run.track_insert_key(r_arm_r, 0.175, -38.0)
	anim_run.track_insert_key(r_arm_r, 0.35, 38.0)
	anim_lib.add_animation("run", anim_run)
	
	# INTERACT: lean forward, right arm extends toward object
	var anim_interact = Animation.new()
	anim_interact.length = 0.6
	var i_torso = anim_interact.add_track(Animation.TYPE_VALUE)
	anim_interact.track_set_path(i_torso, "RootPivot/Torso:rotation_degrees:x")
	anim_interact.track_insert_key(i_torso, 0.0, 0.0)
	anim_interact.track_insert_key(i_torso, 0.3, 12.0)
	anim_interact.track_insert_key(i_torso, 0.6, 0.0)
	
	var i_arm_r = anim_interact.add_track(Animation.TYPE_VALUE)
	anim_interact.track_set_path(i_arm_r, "RootPivot/Torso/ArmR:rotation_degrees:x")
	anim_interact.track_insert_key(i_arm_r, 0.0, 0.0)
	anim_interact.track_insert_key(i_arm_r, 0.3, -70.0)
	anim_interact.track_insert_key(i_arm_r, 0.6, 0.0)
	anim_lib.add_animation("interact", anim_interact)
	
	# TOOL_USE: raise right hand to chest level, hold 1s, lower
	var anim_tool = Animation.new()
	anim_tool.length = 1.4
	var tl_arm = anim_tool.add_track(Animation.TYPE_VALUE)
	anim_tool.track_set_path(tl_arm, "RootPivot/Torso/ArmR:rotation_degrees:x")
	anim_tool.track_insert_key(tl_arm, 0.0, 0.0)
	anim_tool.track_insert_key(tl_arm, 0.2, -75.0)
	anim_tool.track_insert_key(tl_arm, 1.2, -75.0)
	anim_tool.track_insert_key(tl_arm, 1.4, 0.0)
	anim_lib.add_animation("tool_use", anim_tool)
	# Also alias "tool" to tool_use for compatibility
	anim_lib.add_animation("tool", anim_tool)
	
	# TALK: subtle head nod every 1.5s
	var anim_talk = Animation.new()
	anim_talk.length = 1.5
	anim_talk.loop_mode = Animation.LOOP_LINEAR
	var tk_head = anim_talk.add_track(Animation.TYPE_VALUE)
	anim_talk.track_set_path(tk_head, "RootPivot/Torso/Head:rotation_degrees:x")
	anim_talk.track_insert_key(tk_head, 0.0, 0.0)
	anim_talk.track_insert_key(tk_head, 0.35, 8.0)
	anim_talk.track_insert_key(tk_head, 0.7, 0.0)
	anim_talk.track_insert_key(tk_head, 1.1, 6.0)
	anim_talk.track_insert_key(tk_head, 1.5, 0.0)
	anim_lib.add_animation("talk", anim_talk)
	
	anim_player.add_animation_library("", anim_lib)
	anim_player.play("idle")

func play_anim(anim_name: String) -> void:
	if anim_player and anim_player.has_animation(anim_name):
		if anim_player.current_animation != anim_name:
			anim_player.play(anim_name)
