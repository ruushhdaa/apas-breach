class_name VehicleBuilder
extends Node

static func create_water_tanker() -> Node3D:
	var root = Node3D.new()
	root.name = "WaterTanker"
	
	# Chassis
	var chassis = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(2.4, 0.6, 6.0)
	chassis.mesh = c_box
	chassis.position = Vector3(0, 0.8, 0)
	var mat_chassis = StandardMaterial3D.new()
	mat_chassis.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_chassis.albedo_color = Color("#2A313D")
	chassis.material_override = mat_chassis
	root.add_child(chassis)
	
	# Cabin
	var cab = MeshInstance3D.new()
	var cab_box = BoxMesh.new()
	cab_box.size = Vector3(2.3, 1.8, 2.0)
	cab.mesh = cab_box
	cab.position = Vector3(0, 1.9, 1.8)
	var mat_cab = StandardMaterial3D.new()
	mat_cab.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_cab.albedo_color = Color("#B37D2A") # Weathered yellow/tan tanker cab
	cab.material_override = mat_cab
	root.add_child(cab)
	
	# Windshield
	var glass = MeshInstance3D.new()
	var g_box = BoxMesh.new()
	g_box.size = Vector3(2.1, 0.7, 0.1)
	glass.mesh = g_box
	glass.position = Vector3(0, 2.2, 2.82)
	var mat_glass = StandardMaterial3D.new()
	mat_glass.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_glass.albedo_color = Color("#2E3D4D")
	glass.material_override = mat_glass
	root.add_child(glass)
	
	# Cylindrical Water Tank
	var tank = MeshInstance3D.new()
	var t_cyl = CylinderMesh.new()
	t_cyl.top_radius = 1.05
	t_cyl.bottom_radius = 1.05
	t_cyl.height = 3.6
	tank.mesh = t_cyl
	tank.rotation_degrees = Vector3(90, 0, 0)
	tank.position = Vector3(0, 1.8, -1.0)
	var mat_tank = StandardMaterial3D.new()
	mat_tank.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_tank.albedo_color = Color("#4D6680") # Blue-grey municipal water tank
	tank.material_override = mat_tank
	root.add_child(tank)
	
	# Tank Label / Sign: "NMMC WATER SUPPLY"
	var lbl = Label3D.new()
	lbl.text = "NMMC EMERGENCY POTABLE WATER"
	lbl.font_size = 32
	lbl.modulate = Color("#FFFFFF")
	lbl.outline_modulate = Color("#000000")
	lbl.outline_size = 4
	lbl.position = Vector3(1.1, 1.8, -1.0)
	lbl.rotation_degrees = Vector3(0, 90, 0)
	lbl.pixel_size = 0.007
	root.add_child(lbl)
	
	# 6 Wheels
	var wheel_pos = [
		Vector3(-1.25, 0.45, 1.8), Vector3(1.25, 0.45, 1.8),
		Vector3(-1.25, 0.45, -0.8), Vector3(1.25, 0.45, -0.8),
		Vector3(-1.25, 0.45, -2.2), Vector3(1.25, 0.45, -2.2)
	]
	var mat_wheel = StandardMaterial3D.new()
	mat_wheel.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_wheel.albedo_color = Color("#15181C")
	for p in wheel_pos:
		var w = MeshInstance3D.new()
		var w_cyl = CylinderMesh.new()
		w_cyl.top_radius = 0.45
		w_cyl.bottom_radius = 0.45
		w_cyl.height = 0.35
		w.mesh = w_cyl
		w.rotation_degrees = Vector3(0, 0, 90)
		w.position = p
		w.material_override = mat_wheel
		root.add_child(w)
		
	return root

static func create_mpcb_van() -> Node3D:
	var root = Node3D.new()
	root.name = "MPCBVan"
	
	# Body
	var body = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(2.0, 1.6, 4.2)
	body.mesh = b_box
	body.position = Vector3(0, 1.2, 0)
	var mat_body = StandardMaterial3D.new()
	mat_body.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_body.albedo_color = Color("#E6E8ED") # White official van
	body.material_override = mat_body
	root.add_child(body)
	
	# Blue Stripe
	var stripe = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(2.02, 0.25, 4.22)
	stripe.mesh = s_box
	stripe.position = Vector3(0, 1.1, 0)
	var mat_stripe = StandardMaterial3D.new()
	mat_stripe.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_stripe.albedo_color = Color("#1D4E89") # Maharashtra Govt Blue
	stripe.material_override = mat_stripe
	root.add_child(stripe)
	
	# Beacon / Red-Blue lightbar
	var bar = MeshInstance3D.new()
	var bar_box = BoxMesh.new()
	bar_box.size = Vector3(1.0, 0.15, 0.3)
	bar.mesh = bar_box
	bar.position = Vector3(0, 2.1, 0.6)
	var mat_bar = StandardMaterial3D.new()
	mat_bar.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_bar.albedo_color = Color("#D92B2B")
	bar.material_override = mat_bar
	root.add_child(bar)
	
	# Windows
	var glass = MeshInstance3D.new()
	var g_box = BoxMesh.new()
	g_box.size = Vector3(1.9, 0.6, 1.0)
	glass.mesh = g_box
	glass.position = Vector3(0, 1.5, 1.6)
	var mat_glass = StandardMaterial3D.new()
	mat_glass.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_glass.albedo_color = Color("#1E2833")
	glass.material_override = mat_glass
	root.add_child(glass)
	
	# Signage
	var lbl = Label3D.new()
	lbl.text = "MPCB — POLLUTION CONTROL BOARD"
	lbl.font_size = 28
	lbl.modulate = Color("#1D4E89")
	lbl.outline_modulate = Color("#FFFFFF")
	lbl.outline_size = 3
	lbl.position = Vector3(1.02, 1.2, 0)
	lbl.rotation_degrees = Vector3(0, 90, 0)
	lbl.pixel_size = 0.007
	root.add_child(lbl)
	
	# Wheels
	var wheel_pos = [
		Vector3(-1.05, 0.4, 1.3), Vector3(1.05, 0.4, 1.3),
		Vector3(-1.05, 0.4, -1.3), Vector3(1.05, 0.4, -1.3)
	]
	var mat_wheel = StandardMaterial3D.new()
	mat_wheel.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_wheel.albedo_color = Color("#15181C")
	for p in wheel_pos:
		var w = MeshInstance3D.new()
		var w_cyl = CylinderMesh.new()
		w_cyl.top_radius = 0.38
		w_cyl.bottom_radius = 0.38
		w_cyl.height = 0.28
		w.mesh = w_cyl
		w.rotation_degrees = Vector3(0, 0, 90)
		w.position = p
		w.material_override = mat_wheel
		root.add_child(w)
		
	return root

static func create_auto_rickshaw() -> Node3D:
	var root = Node3D.new()
	root.name = "AutoRickshaw"
	
	# Lower Body
	var body = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(1.3, 0.7, 2.2)
	body.mesh = b_box
	body.position = Vector3(0, 0.55, 0)
	var mat_body = StandardMaterial3D.new()
	mat_body.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_body.albedo_color = Color("#1C4426") # Dark Green
	body.material_override = mat_body
	root.add_child(body)
	
	# Yellow Hood / Roof
	var roof = MeshInstance3D.new()
	var r_box = BoxMesh.new()
	r_box.size = Vector3(1.32, 0.8, 1.8)
	roof.mesh = r_box
	roof.position = Vector3(0, 1.3, -0.15)
	var mat_roof = StandardMaterial3D.new()
	mat_roof.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_roof.albedo_color = Color("#E6A817") # Classic Auto Yellow
	roof.material_override = mat_roof
	root.add_child(roof)
	
	# Wheels (1 front, 2 rear)
	var mat_wheel = StandardMaterial3D.new()
	mat_wheel.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_wheel.albedo_color = Color("#15181C")
	
	var wf = MeshInstance3D.new()
	var wf_cyl = CylinderMesh.new()
	wf_cyl.top_radius = 0.25
	wf_cyl.bottom_radius = 0.25
	wf_cyl.height = 0.18
	wf.mesh = wf_cyl
	wf.rotation_degrees = Vector3(0, 0, 90)
	wf.position = Vector3(0, 0.25, 0.9)
	wf.material_override = mat_wheel
	root.add_child(wf)
	
	for side in [-0.7, 0.7]:
		var wr = MeshInstance3D.new()
		wr.mesh = wf_cyl
		wr.rotation_degrees = Vector3(0, 0, 90)
		wr.position = Vector3(side, 0.25, -0.7)
		wr.material_override = mat_wheel
		root.add_child(wr)
		
	return root
