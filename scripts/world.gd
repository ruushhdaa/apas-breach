class_name GameWorld
extends Node3D

const CharModelScript = preload("res://scripts/character_model.gd")
const FieldNotesData = preload("res://scripts/field_notes_data.gd")
const InteractableAreaScript = preload("res://scripts/interactable.gd")
const VehicleBuilderScript = preload("res://scripts/vehicle_builder.gd")

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $DirectionalLight3D
var creek_mesh: MeshInstance3D
@onready var player: CharacterBody3D = $Player

# Live Label3Ds to update every second
var live_labels: Array = []
var steam_emitters: Array = []
var red_emergency_lights: Array = []

# Valve puzzle state (Level 2)
var valve_sequence: Array = []
var valve_solved: bool = false

# Blowdown valve mash state (Level 3)
var blowdown_mash_count: int = 0
var blowdown_mash_timer: float = 0.0
var blowdown_valve_opened: bool = false

# SCADA hub acknowledged panels (Level 4)
var scada_panels_acknowledged: int = 0

# Audit questionnaire state (Level 5)
var audit_step: int = 0

# In-world dynamic references
var meter_cabinet_opened: bool = false
var bypass_pipe_mesh: MeshInstance3D

func _ready() -> void:
	build_environment_geometry()
	build_zones()
	build_field_notes()
	build_npcs()
	setup_signals()
	apply_hhi_visuals(HHI.current_hhi, 0.0) # instant initial
	
	# Start clock/labels update timer
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(update_live_world_readouts)
	add_child(timer)
	timer.start()
	update_live_world_readouts()

func setup_signals() -> void:
	if GameState:
		GameState.world_transition_started.connect(trigger_world_transition)
		GameState.state_updated.connect(update_level_flow)

func build_environment_geometry() -> void:
	# Ground compound (Concrete / Tarmac)
	var ground = MeshInstance3D.new()
	var g_box = BoxMesh.new()
	g_box.size = Vector3(140.0, 0.2, 120.0)
	ground.mesh = g_box
	ground.position = Vector3(0, -0.1, 0)
	var mat_g = StandardMaterial3D.new()
	mat_g.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_g.albedo_color = Color("#22262B")
	ground.material_override = mat_g
	add_child(ground)
	
	# Static body for ground collision
	var g_body = StaticBody3D.new()
	var g_col = CollisionShape3D.new()
	var g_shape = BoxShape3D.new()
	g_shape.size = Vector3(140.0, 0.2, 120.0)
	g_col.shape = g_shape
	g_body.position = Vector3(0, -0.1, 0)
	g_body.add_child(g_col)
	add_child(g_body)
	
	# Rabale Colony Ground (Dirt / Paved)
	var colony_ground = MeshInstance3D.new()
	var cg_box = BoxMesh.new()
	cg_box.size = Vector3(100.0, 0.2, 80.0)
	colony_ground.mesh = cg_box
	colony_ground.position = Vector3(0, -0.09, 100.0)
	var mat_cg = StandardMaterial3D.new()
	mat_cg.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_cg.albedo_color = Color("#42352B") # Dusty ochre road
	colony_ground.material_override = mat_cg
	add_child(colony_ground)
	
	var cg_body = StaticBody3D.new()
	var cg_col = CollisionShape3D.new()
	var cg_shape = BoxShape3D.new()
	cg_shape.size = Vector3(100.0, 0.2, 80.0)
	cg_col.shape = cg_shape
	cg_body.position = Vector3(0, -0.09, 100.0)
	cg_body.add_child(cg_col)
	add_child(cg_body)
	
	# Thane Creek Mesh (x 60..110, z -50..50)
	if not creek_mesh:
		creek_mesh = MeshInstance3D.new()
		creek_mesh.name = "CreekMesh"
		var c_plane = PlaneMesh.new()
		c_plane.size = Vector2(50.0, 100.0)
		creek_mesh.mesh = c_plane
		creek_mesh.position = Vector3(85.0, 0.05, 0.0)
		
		var w_shader = preload("res://shaders/water.gdshader")
		var s_mat = ShaderMaterial.new()
		s_mat.shader = w_shader
		creek_mesh.material_override = s_mat
		add_child(creek_mesh)
		
	# Mangrove silhouettes at creek edges
	var mat_mangrove = StandardMaterial3D.new()
	mat_mangrove.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_mangrove.albedo_color = Color("#122314")
	for i in range(12):
		var tree = MeshInstance3D.new()
		var t_cone = CylinderMesh.new()
		t_cone.top_radius = 0.0
		t_cone.bottom_radius = 2.4
		t_cone.height = 5.0
		tree.mesh = t_cone
		tree.position = Vector3(62.0 + (i % 2) * 45.0, 2.5, -45.0 + i * 8.0)
		tree.material_override = mat_mangrove
		add_child(tree)
		
	# Outfall Canal (50, 0, -20) Sunken Channel
	var canal = MeshInstance3D.new()
	var canal_box = BoxMesh.new()
	canal_box.size = Vector3(25.0, 1.2, 3.5)
	canal.mesh = canal_box
	canal.position = Vector3(50.0, -0.5, -20.0)
	var mat_canal = StandardMaterial3D.new()
	mat_canal.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_canal.albedo_color = Color("#1C1E21")
	canal.material_override = mat_canal
	add_child(canal)
	
	# Canal Fume / Shimmer Particles
	var fumes = CPUParticles3D.new()
	fumes.name = "CanalFumes"
	fumes.amount = 25
	fumes.lifetime = 2.5
	fumes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	fumes.emission_box_extents = Vector3(10.0, 0.2, 1.5)
	fumes.direction = Vector3(0, 1, 0)
	fumes.spread = 15.0
	fumes.gravity = Vector3(0, 0.5, 0)
	fumes.initial_velocity_min = 0.5
	fumes.initial_velocity_max = 1.2
	fumes.color = Color(0.85, 0.8, 0.7, 0.35)
	fumes.position = Vector3(50.0, 0.2, -20.0)
	add_child(fumes)

func build_zones() -> void:
	build_gatehouse_and_billboards()
	build_rabale_colony()
	build_meter_substation()
	build_server_hall_a()
	build_cooling_towers()
	build_scada_hub()
	build_outfall_canal()
	build_audit_stage()

func build_gatehouse_and_billboards() -> void:
	# Gatehouse (0, 0, 50)
	var gh = MeshInstance3D.new()
	var gh_box = BoxMesh.new()
	gh_box.size = Vector3(4.0, 3.2, 5.0)
	gh.mesh = gh_box
	gh.position = Vector3(5.0, 1.6, 50.0)
	var mat_gh = StandardMaterial3D.new()
	mat_gh.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_gh.albedo_color = Color("#323B47")
	gh.material_override = mat_gh
	add_child(gh)
	
	# Boom Barrier
	var barrier = MeshInstance3D.new()
	var b_cyl = CylinderMesh.new()
	b_cyl.top_radius = 0.08
	b_cyl.bottom_radius = 0.08
	b_cyl.height = 6.0
	barrier.mesh = b_cyl
	barrier.rotation_degrees = Vector3(0, 0, 90)
	barrier.position = Vector3(0.0, 1.0, 50.0)
	var mat_bar = StandardMaterial3D.new()
	mat_bar.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_bar.albedo_color = Color("#D93829") # Red/white stripes
	barrier.material_override = mat_bar
	add_child(barrier)
	
	# Billboard near Gate 4
	var bb = create_billboard(
		Vector3(12.0, 3.5, 52.0),
		Vector3(8.0, 3.5, 0.4),
		"AETHERSCALE DATA CENTRE — RABALE, THANE\nWATER RECYCLING TARGET: 95% | ACTUAL: 41%",
		Color("#F0A500"),
		Vector3(0, 180, 0)
	)
	add_child(bb)

func build_rabale_colony() -> void:
	# 8 Chawl buildings (varied heights 6–14m)
	var chawl_positions = [
		Vector3(-25, 4.0, 85), Vector3(-25, 6.0, 105), Vector3(-25, 5.0, 120),
		Vector3(25, 5.5, 85), Vector3(25, 7.0, 105), Vector3(25, 4.5, 120),
		Vector3(-10, 5.0, 128), Vector3(10, 6.5, 128)
	]
	var mat_chawl = StandardMaterial3D.new()
	mat_chawl.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_chawl.albedo_color = Color("#6B5B4E")
	
	for i in range(chawl_positions.size()):
		var p = chawl_positions[i]
		var c = MeshInstance3D.new()
		var c_box = BoxMesh.new()
		var h = p.y * 2.0
		c_box.size = Vector3(12.0, h, 14.0)
		c.mesh = c_box
		c.position = Vector3(p.x, p.y, p.z)
		c.material_override = mat_chawl
		add_child(c)
		
		# Static collision for chawls
		var cb = StaticBody3D.new()
		var cc = CollisionShape3D.new()
		var cs = BoxShape3D.new()
		cs.size = c_box.size
		cc.shape = cs
		cb.position = c.position
		cb.add_child(cc)
		add_child(cb)
		
	# Water tanker queue at (-15, 0, 80)
	for i in range(3):
		var tanker = VehicleBuilderScript.create_water_tanker()
		tanker.position = Vector3(-15.0, 0.0, 75.0 + i * 8.0)
		add_child(tanker)
		
	# Sunita tai NPC interaction trigger at (-15, 0, 80)
	var sunita_area = InteractableAreaScript.new()
	sunita_area.prompt_text = "TALK TO SUNITA TAI"
	sunita_area.position = Vector3(-12.5, 0.0, 80.0)
	var col_s = CollisionShape3D.new()
	var sph_s = SphereShape3D.new()
	sph_s.radius = 2.5
	col_s.shape = sph_s
	sunita_area.add_child(col_s)
	sunita_area.interacted.connect(func(_p):
		GameState.trust += 5.0
		GameState.add_evidence_item("sunita_statement", "Sunita Tai Witness Statement: 6 Days Tap Water Deprivation")
		GameState.trigger_dialogue("SUNITA TAI", "We haven't had tap water in six days. The tanker comes once if we're lucky.")
		if AudioEngine: AudioEngine.play_sfx("evidence_collect")
	)
	add_child(sunita_area)
	
	# Billboard behind tanker queue
	var bb_colony = create_billboard(
		Vector3(-22.0, 2.5, 80.0),
		Vector3(6.0, 2.2, 0.3),
		"NMMC WATER ALLOCATION — THIS COLONY: 0L",
		Color("#D9534F"),
		Vector3(0, 90, 0)
	)
	add_child(bb_colony)
	
	# Flyer on colony wall: "6 DAYS WITHOUT TAP WATER — NMMC DO SOMETHING"
	var flyer = create_billboard(
		Vector3(-18.9, 1.8, 95.0),
		Vector3(1.8, 1.2, 0.05),
		"6 DAYS WITHOUT TAP WATER\nNMMC DO SOMETHING!",
		Color("#FFFFFF"),
		Vector3(0, 90, 0)
	)
	add_child(flyer)
	
	# Road graffiti: "DATA CENTRE TOOK OUR WATER"
	var graffiti = Label3D.new()
	graffiti.text = "DATA CENTRE TOOK OUR WATER"
	graffiti.font_size = 36
	graffiti.modulate = Color("#B83227")
	graffiti.position = Vector3(-4.0, 0.06, 75.0)
	graffiti.rotation_degrees = Vector3(-90, 0, 0)
	graffiti.pixel_size = 0.015
	add_child(graffiti)
	
	# Dry public tap: pole + spigot at (-10, 0, 90)
	var tap_pole = MeshInstance3D.new()
	var tp_cyl = CylinderMesh.new()
	tp_cyl.top_radius = 0.06
	tp_cyl.bottom_radius = 0.06
	tp_cyl.height = 1.2
	tap_pole.mesh = tp_cyl
	tap_pole.position = Vector3(-10.0, 0.6, 90.0)
	var mat_iron = StandardMaterial3D.new()
	mat_iron.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_iron.albedo_color = Color("#555A64")
	tap_pole.material_override = mat_iron
	add_child(tap_pole)
	
	# Tea stall at (5, 0, 85)
	var tea = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(3.5, 2.4, 3.0)
	tea.mesh = t_box
	tea.position = Vector3(5.0, 1.2, 85.0)
	var mat_tea = StandardMaterial3D.new()
	mat_tea.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_tea.albedo_color = Color("#3A5A40")
	tea.material_override = mat_tea
	add_child(tea)
	
	var rickshaw = VehicleBuilderScript.create_auto_rickshaw()
	rickshaw.position = Vector3(8.0, 0.0, 86.0)
	add_child(rickshaw)

func build_meter_substation() -> void:
	# Substation Building at (-28, 0, 44)
	var sub = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(8.0, 3.5, 8.0)
	sub.mesh = s_box
	sub.position = Vector3(-28.0, 1.75, 44.0)
	var mat_sub = StandardMaterial3D.new()
	mat_sub.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_sub.albedo_color = Color("#3B424D")
	sub.material_override = mat_sub
	add_child(sub)
	
	# Meter Cabinet interactable
	var cabinet_area = InteractableAreaScript.new()
	cabinet_area.name = "MeterCabinetArea"
	cabinet_area.prompt_text = "OPEN METER CABINET (HOLD 2s)"
	cabinet_area.hold_required = true
	cabinet_area.position = Vector3(-23.9, 1.2, 44.0)
	
	var col_c = CollisionShape3D.new()
	var box_c = BoxShape3D.new()
	box_c.size = Vector3(2.5, 2.0, 2.5)
	col_c.shape = box_c
	cabinet_area.add_child(col_c)
	
	# Cabinet visual box
	var cab_mesh = MeshInstance3D.new()
	var cm_box = BoxMesh.new()
	cm_box.size = Vector3(0.4, 1.4, 0.9)
	cab_mesh.mesh = cm_box
	var mat_cm = StandardMaterial3D.new()
	mat_cm.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_cm.albedo_color = Color("#85929E")
	cab_mesh.material_override = mat_cm
	cabinet_area.add_child(cab_mesh)
	
	cabinet_area.interacted.connect(func(_p):
		meter_cabinet_opened = true
		GameState.add_evidence_item("meter_discrepancy", "Meter Reading Gap: SCADA 5.8 L/s vs Meter 28.9 L/s")
		GameState.trigger_dialogue("MEERA", "SCADA shows 5.8 L/s. Meter reads 28.9 L/s. Gap: 23.1 L/s! Evidence documented.")
		if AudioEngine: AudioEngine.play_sfx("evidence_collect")
	)
	add_child(cabinet_area)
	
	# Sign on cabinet: "1 MLD potable = ~500 families/day"
	var cab_sign = Label3D.new()
	cab_sign.text = "1 MLD potable = ~500 families/day"
	cab_sign.font_size = 22
	cab_sign.modulate = Color("#F0A500")
	cab_sign.position = Vector3(-23.65, 2.0, 44.0)
	cab_sign.rotation_degrees = Vector3(0, 90, 0)
	cab_sign.pixel_size = 0.007
	add_child(cab_sign)
	
	# Hidden 1200mm Bypass Pipe behind substation (-32, 0, 44)
	bypass_pipe_mesh = MeshInstance3D.new()
	var p_cyl = CylinderMesh.new()
	p_cyl.top_radius = 0.6 # 1200mm diameter
	p_cyl.bottom_radius = 0.6
	p_cyl.height = 10.0
	bypass_pipe_mesh.mesh = p_cyl
	bypass_pipe_mesh.rotation_degrees = Vector3(90, 0, 0)
	bypass_pipe_mesh.position = Vector3(-33.0, 0.4, 44.0)
	var mat_pipe = StandardMaterial3D.new()
	mat_pipe.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_pipe.albedo_color = Color("#333A42")
	bypass_pipe_mesh.material_override = mat_pipe
	add_child(bypass_pipe_mesh)
	
	# Level 1 Decision Console near Substation (-28, 0, 40)
	var l1_console = InteractableAreaScript.new()
	l1_console.name = "Level1Console"
	l1_console.prompt_text = "ACCESS BYPASS VALVE CONSOLE"
	l1_console.position = Vector3(-27.0, 1.0, 40.0)
	var col_l1 = CollisionShape3D.new()
	var box_l1 = BoxShape3D.new()
	box_l1.size = Vector3(2.0, 2.0, 2.0)
	col_l1.shape = box_l1
	l1_console.add_child(col_l1)
	
	l1_console.interacted.connect(func(_p):
		var card_ui = get_tree().root.find_child("DecisionCardLayer", true, false)
		if card_ui:
			card_ui.open_card({
				"id": "LEVEL1_BYPASS",
				"title": "UNMETERED BYPASS DETECTED — 28.9 L/s",
				"options": [
					{
						"letter": "A",
						"text": "CLOSE IT NOW",
						"preview": "W↓↓↓ H↑↑↑ T↑ S↓ (90s Scramble Timer to save servers)"
					},
					{
						"letter": "B",
						"text": "THROTTLE COMPUTE 30%",
						"preview": "W↓ H↓ S↓↓ (No scramble, +15 Rohan Audit Pressure)"
					},
					{
						"letter": "C",
						"text": "LOG AND REPORT",
						"preview": "T↑↑ Evidence+1 Pressure↓10 (Airtight paper trail)"
					}
				]
			})
	)
	add_child(l1_console)

func build_server_hall_a() -> void:
	# Server Hall A (x -45..-15, z -45..-5)
	var hall = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(30.0, 6.0, 40.0)
	hall.mesh = h_box
	hall.position = Vector3(-30.0, 3.0, -25.0)
	var mat_hall = StandardMaterial3D.new()
	mat_hall.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_hall.albedo_color = Color("#1E242B")
	hall.material_override = mat_hall
	add_child(hall)
	
	# Hall Collision
	var hb = StaticBody3D.new()
	var hc = CollisionShape3D.new()
	var hs = BoxShape3D.new()
	hs.size = h_box.size
	hc.shape = hs
	hb.position = hall.position
	hb.add_child(hc)
	add_child(hb)
	
	# Red Emergency Flickering Lights inside Hall
	for i in range(3):
		var omni = OmniLight3D.new()
		omni.light_color = Color("#FF2211")
		omni.light_energy = 0.0 # Activates in Level 2
		omni.omni_range = 15.0
		omni.position = Vector3(-30.0 + (i - 1) * 8.0, 4.0, -25.0)
		red_emergency_lights.append(omni)
		add_child(omni)
		
	# In-world Posters on Server Hall wall
	var p1 = create_billboard(
		Vector3(-14.9, 2.5, -20.0),
		Vector3(0.1, 1.8, 2.4),
		"COOLING SYSTEM WATER USE: 2.5 MLD/DAY\nPOTABLE WATER USE INDEX — TARGET: BELOW 1.0 L/kWh",
		Color("#85C1E9"),
		Vector3(0, -90, 0)
	)
	add_child(p1)
	
	var p2 = create_billboard(
		Vector3(-14.9, 2.5, -30.0),
		Vector3(0.1, 1.8, 2.4),
		"PUE TARGET 1.15 | CURRENT PUE: 1.15",
		Color("#F0A500"),
		Vector3(0, -90, 0)
	)
	live_labels.append({"type": "PUE_POSTER", "label": p2.get_node("Label3D")})
	add_child(p2)
	
	# Pump Gallery: Three Valves V1, V2, V5 at entrance gallery (-16.0, 1.0, -22.0)
	var valve_names = ["V1", "V2", "V5"]
	var valve_pos = [Vector3(-16.0, 1.2, -22.0), Vector3(-16.0, 1.2, -25.0), Vector3(-16.0, 1.2, -28.0)]
	
	for i in range(3):
		var v_name = valve_names[i]
		var v_area = InteractableAreaScript.new()
		v_area.name = "ValveArea_" + v_name
		v_area.prompt_text = "TURN VALVE " + v_name
		v_area.position = valve_pos[i]
		
		var col_v = CollisionShape3D.new()
		var sph_v = SphereShape3D.new()
		sph_v.radius = 1.2
		col_v.shape = sph_v
		v_area.add_child(col_v)
		
		# Visual wheel
		var wheel = MeshInstance3D.new()
		var w_cyl = CylinderMesh.new()
		w_cyl.top_radius = 0.35
		w_cyl.bottom_radius = 0.35
		w_cyl.height = 0.08
		wheel.mesh = w_cyl
		wheel.rotation_degrees = Vector3(0, 0, 90)
		var mat_v = StandardMaterial3D.new()
		mat_v.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mat_v.albedo_color = Color("#D93829")
		wheel.material_override = mat_v
		v_area.add_child(wheel)
		
		v_area.interacted.connect(func(_p): handle_valve_turn(v_name))
		add_child(v_area)
		
	# Level 2 Decision Console at (-30, 0, -25)
	var l2_console = InteractableAreaScript.new()
	l2_console.name = "Level2Console"
	l2_console.prompt_text = "MANAGE JUNCTION TEMPERATURE"
	l2_console.position = Vector3(-20.0, 1.0, -25.0)
	var col_l2 = CollisionShape3D.new()
	var box_l2 = BoxShape3D.new()
	box_l2.size = Vector3(2.0, 2.0, 2.0)
	col_l2.shape = box_l2
	l2_console.add_child(col_l2)
	
	l2_console.interacted.connect(func(_p):
		var card_ui = get_tree().root.find_child("DecisionCardLayer", true, false)
		if card_ui:
			card_ui.open_card({
				"id": "LEVEL2_HEAT",
				"title": "Tj AT 84°C AND RISING",
				"options": [
					{
						"letter": "A",
						"text": "FLOOD TOWERS WITH MAKEUP WATER",
						"preview": "H↓↓↓ W↑↑↑ C↑ T↓↓ (+1.2MLD Draw, Creek goes dark)"
					},
					{
						"letter": "B",
						"text": "SHED 20% MORE COMPUTE LOAD",
						"preview": "H↓↓ S↓↓ W↓ (SLA Penalty, data preserved)"
					},
					{
						"letter": "C",
						"text": "BRING IN DRY BACKUP COOLERS",
						"preview": "H↓ P↑↑↑ W unchanged (PUE spikes, zero extra water)"
					}
				]
			})
	)
	add_child(l2_console)

func build_cooling_towers() -> void:
	# 4 Hyperboloid Cooling Towers at x=-5, 8, 21, 34 z=-35
	var tower_x = [-5.0, 8.0, 21.0, 34.0]
	for tx in tower_x:
		var tower = Node3D.new()
		tower.name = "CoolingTower"
		tower.position = Vector3(tx, 0, -35.0)
		
		# Hyperboloid mesh (Narrow center, wider top and base)
		# Lower base cylinder
		var base = MeshInstance3D.new()
		var b_cyl = CylinderMesh.new()
		b_cyl.top_radius = 4.2
		b_cyl.bottom_radius = 5.2
		b_cyl.height = 7.0
		base.mesh = b_cyl
		base.position = Vector3(0, 3.5, 0)
		var mat_t = StandardMaterial3D.new()
		mat_t.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mat_t.albedo_color = Color("#2A3142")
		base.material_override = mat_t
		tower.add_child(base)
		
		# Upper throat cylinder
		var top = MeshInstance3D.new()
		var t_cyl = CylinderMesh.new()
		t_cyl.top_radius = 4.8
		t_cyl.bottom_radius = 4.2
		t_cyl.height = 7.0
		top.mesh = t_cyl
		top.position = Vector3(0, 10.5, 0)
		top.material_override = mat_t
		tower.add_child(top)
		
		# Left-side highlight strip #3A4156
		var strip = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(0.6, 14.0, 0.4)
		strip.mesh = s_box
		strip.position = Vector3(-4.4, 7.0, 0)
		var mat_s = StandardMaterial3D.new()
		mat_s.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mat_s.albedo_color = Color("#3A4156")
		strip.material_override = mat_s
		tower.add_child(strip)
		
		# Steam particles from top
		var steam = CPUParticles3D.new()
		steam.amount = 25
		steam.lifetime = 4.0
		steam.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		steam.emission_sphere_radius = 3.5
		steam.direction = Vector3(0, 1, 0)
		steam.spread = 15.0
		steam.gravity = Vector3(0, 0.8, 0)
		steam.initial_velocity_min = 1.0
		steam.initial_velocity_max = 2.5
		steam.scale_amount_min = 1.5
		steam.scale_amount_max = 3.5
		steam.color = Color(0.94, 0.93, 0.91, 0.4)
		steam.position = Vector3(0, 14.0, 0)
		tower.add_child(steam)
		steam_emitters.append(steam)
		
		add_child(tower)
		
	# Sticker on cooling tower: "EVAPORATIVE COOLING USES 1–5L PER kWh"
	var sticker = create_billboard(
		Vector3(-5.0, 2.5, -29.6),
		Vector3(3.2, 1.2, 0.1),
		"EVAPORATIVE COOLING USES 1–5L PER kWh",
		Color("#F0A500"),
		Vector3(0, 180, 0)
	)
	add_child(sticker)

func build_scada_hub() -> void:
	# SCADA Hub at (20, 0, 10)
	var hub = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(12.0, 3.8, 10.0)
	hub.mesh = h_box
	hub.position = Vector3(20.0, 1.9, 10.0)
	var mat_hub = StandardMaterial3D.new()
	mat_hub.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_hub.albedo_color = Color("#2D3642")
	hub.material_override = mat_hub
	add_child(hub)
	
	# SCADA Hub Console (Level 4 Decision)
	var scada_console = InteractableAreaScript.new()
	scada_console.name = "SCADAHubConsole"
	scada_console.prompt_text = "ENGAGE SCADA REBUILD ARCHITECTURE"
	scada_console.position = Vector3(20.0, 1.0, 14.5)
	var col_sc = CollisionShape3D.new()
	var box_sc = BoxShape3D.new()
	box_sc.size = Vector3(3.0, 2.0, 2.0)
	col_sc.shape = box_sc
	scada_console.add_child(col_sc)
	
	scada_console.interacted.connect(func(_p):
		var card_ui = get_tree().root.find_child("DecisionCardLayer", true, false)
		if card_ui:
			card_ui.open_card({
				"id": "LEVEL4_REBUILD",
				"title": "COOLING SYSTEM RETROFIT WINDOW (BUDGET: " + str(GameState.budget) + " CR)",
				"options": [
					{
						"letter": "A",
						"text": "FULL DTC CONVERSION (Cost: 40 CR)",
						"preview": "W↓↓↓ P↓ H↓↓ (0.45 L/kWh, requires Evidence >= 3)",
						"min_evidence": 3,
						"cost_budget": 40
					},
					{
						"letter": "B",
						"text": "HYBRID WITH STP WATER (Cost: 20 CR)",
						"preview": "Potable Draw → 0 MLD, C↑ (Frees municipal water for Rabale)",
						"cost_budget": 20
					},
					{
						"letter": "C",
						"text": "OPTIMISE EXISTING (Cost: 10 CR)",
						"preview": "Preserves capital budget, modest efficiency gains",
						"cost_budget": 10
					}
				]
			})
	)
	add_child(scada_console)

func build_outfall_canal() -> void:
	# Blowdown valve at (40, 0, -20) (seized, needs force in Level 3)
	var valve_area = InteractableAreaScript.new()
	valve_area.name = "BlowdownValveArea"
	valve_area.prompt_text = "FORCE SEIZED BLOWDOWN VALVE"
	valve_area.position = Vector3(40.0, 1.0, -20.0)
	
	var col_bv = CollisionShape3D.new()
	var sph_bv = SphereShape3D.new()
	sph_bv.radius = 2.0
	col_bv.shape = sph_bv
	valve_area.add_child(col_bv)
	
	valve_area.interacted.connect(func(_p):
		if blowdown_valve_opened:
			# Open decision card
			var card_ui = get_tree().root.find_child("DecisionCardLayer", true, false)
			if card_ui:
				card_ui.open_card({
					"id": "LEVEL3_BLOWDOWN",
					"title": "BASIN TDS 2470PPM — OUTFALL RUNNING",
					"options": [
						{
							"letter": "A",
							"text": "EMERGENCY ZLD ACTIVATION (Cost: 20 CR)",
							"preview": "C↑↑↑ W↓ P↓↓ (Effluent → 0 MLD, 98% internal recovery)",
							"cost_budget": 20
						},
						{
							"letter": "B",
							"text": "DILUTE AND DISCHARGE (Cost: 5 CR)",
							"preview": "C↑ W↑↑ (Marginal DO improvement, non-compliant)",
							"cost_budget": 5
						},
						{
							"letter": "C",
							"text": "SEAL THE VALVE AND HOLD",
							"preview": "4-Minute Sump Timer (Must rebuild in Level 4 or Overflow Fail)"
						}
					]
				})
		else:
			# Mash mechanic
			blowdown_mash_count += 1
			if AudioEngine: AudioEngine.play_sfx("wrong_valve")
			if blowdown_mash_count >= 6:
				blowdown_valve_opened = true
				valve_area.prompt_text = "ACCESS BLOWDOWN VALVE CONSOLE"
				GameState.trigger_dialogue("AUDITOR", "Valve seized mechanism broken open! Console accessible.")
				if AudioEngine: AudioEngine.play_sfx("option_select")
			else:
				GameState.trigger_dialogue("AUDITOR", "Valve is seized! Tap [E] repeatedly to force it! (" + str(blowdown_mash_count) + "/6)")
	)
	add_child(valve_area)
	
	# Outfall warning sign
	var outfall_sign = create_billboard(
		Vector3(45.0, 2.0, -17.5),
		Vector3(3.2, 1.6, 0.1),
		"BLOWDOWN TDS: 2470 ppm | PERMISSIBLE: 2100 ppm",
		Color("#E06A3B"),
		Vector3(0, 0, 0)
	)
	live_labels.append({"type": "OUTFALL_SIGN", "label": outfall_sign.get_node("Label3D")})
	add_child(outfall_sign)
	
	# Creek monitoring board
	var creek_board = create_billboard(
		Vector3(58.0, 2.5, 0.0),
		Vector3(4.5, 2.2, 0.2),
		"THANE CREEK — FLAMINGO HABITAT (Phoenicopterus roseus)\nDISSOLVED OXYGEN MIN. 4mg/L | CURRENT READING: 2.2 mg/L",
		Color("#4FC3F7"),
		Vector3(0, -90, 0)
	)
	live_labels.append({"type": "CREEK_BOARD", "label": creek_board.get_node("Label3D")})
	add_child(creek_board)

func build_audit_stage() -> void:
	# Audit Stage at (0, 0, 58)
	var van = VehicleBuilderScript.create_mpcb_van()
	van.position = Vector3(0.0, 0.0, 58.0)
	add_child(van)
	
	var audit_area = InteractableAreaScript.new()
	audit_area.name = "AuditStageArea"
	audit_area.prompt_text = "CONFER WITH MPCB INSPECTOR DR. KULKARNI"
	audit_area.position = Vector3(2.5, 1.0, 58.0)
	
	var col_a = CollisionShape3D.new()
	var sph_a = SphereShape3D.new()
	sph_a.radius = 2.5
	col_a.shape = sph_a
	audit_area.add_child(col_a)
	
	audit_area.interacted.connect(func(_p): handle_audit_sequence())
	add_child(audit_area)

func build_field_notes() -> void:
	# Place 15 field notes around the world as readable clipboards/desks
	var note_locations = [
		Vector3(3.5, 1.2, 48.0),   # 1 Gatehouse
		Vector3(6.5, 1.0, 84.0),   # 2 Tea stall
		Vector3(42.0, 1.0, -18.0), # 3 Outfall canal
		Vector3(56.0, 1.2, -5.0),  # 4 Creek bank
		Vector3(-14.0, 1.0, 82.0), # 5 Tanker queue
		Vector3(-22.0, 1.2, 110.0),# 6 Colony chawl
		Vector3(30.0, 1.0, -32.0), # 7 Cooling tower basin
		Vector3(60.0, 1.2, 10.0),  # 8 Mangrove edge
		Vector3(-27.0, 1.2, 43.0), # 9 Meter substation
		Vector3(-18.0, 1.2, -22.0),# 10 Server Hall A
		Vector3(46.0, 1.0, -21.0), # 11 Outfall sign
		Vector3(2.0, 1.0, 52.0),   # 12 Gate 4
		Vector3(10.0, 1.0, -34.0), # 13 Tower 2
		Vector3(65.0, 1.2, -30.0), # 14 Estuary mudflat
		Vector3(-8.0, 1.0, 92.0)   # 15 Dry tap
	]
	
	for i in range(15):
		var n_area = InteractableAreaScript.new()
		n_area.prompt_text = "READ FIELD NOTE #" + str(i + 1)
		n_area.position = note_locations[i]
		
		var col_n = CollisionShape3D.new()
		var sph_n = SphereShape3D.new()
		sph_n.radius = 1.8
		col_n.shape = sph_n
		n_area.add_child(col_n)
		
		# Clipboard visual
		var board = MeshInstance3D.new()
		var b_box = BoxMesh.new()
		b_box.size = Vector3(0.4, 0.05, 0.5)
		board.mesh = b_box
		var mat_b = StandardMaterial3D.new()
		mat_b.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mat_b.albedo_color = Color("#C4A482")
		board.material_override = mat_b
		n_area.add_child(board)
		
		var note_idx = i
		n_area.interacted.connect(func(_p):
			var note = FieldNotesData.NOTES[note_idx]
			GameState.trigger_dialogue("FIELD NOTES", note["title"] + ": " + note["content"])
			if not GameState.field_notes_found.has(note["id"]):
				GameState.field_notes_found.append(note["id"])
				GameState.trust += 1.0
			if AudioEngine: AudioEngine.play_sfx("evidence_collect")
		)
		add_child(n_area)

func build_npcs() -> void:
	# Security Guard at Gate 4
	var guard = CharModelScript.new()
	guard.character_type = "GUARD"
	guard.position = Vector3(2.5, 0.0, 49.0)
	add_child(guard)
	
	# Sunita Tai at Tanker queue
	var sunita = CharModelScript.new()
	sunita.character_type = "SUNITA"
	sunita.position = Vector3(-12.5, 0.0, 80.0)
	add_child(sunita)
	
	# Rohan at SCADA Hub
	var rohan = CharModelScript.new()
	rohan.character_type = "ROHAN"
	rohan.position = Vector3(22.0, 0.0, 11.0)
	rohan.name = "RohanNPC"
	add_child(rohan)
	
	# Dr. Kulkarni at Audit Stage
	var kulkarni = CharModelScript.new()
	kulkarni.character_type = "KULKARNI"
	kulkarni.position = Vector3(2.0, 0.0, 58.0)
	kulkarni.name = "KulkarniNPC"
	add_child(kulkarni)
	
	# 3 Colony Pedestrians
	for i in range(3):
		var ped = CharModelScript.new()
		ped.character_type = "PEDESTRIAN"
		ped.position = Vector3(-5.0 + i * 5.0, 0.0, 95.0 + i * 8.0)
		add_child(ped)

func create_billboard(pos: Vector3, size: Vector3, text: String, text_color: Color, rot: Vector3) -> MeshInstance3D:
	var root = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	root.mesh = box
	root.position = pos
	root.rotation_degrees = rot
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat.albedo_color = Color("#181D24")
	root.material_override = mat
	
	var lbl = Label3D.new()
	lbl.name = "Label3D"
	lbl.text = text
	lbl.font_size = 28
	lbl.modulate = text_color
	lbl.outline_modulate = Color("#000000")
	lbl.outline_size = 3
	lbl.position = Vector3(0, 0, size.z * 0.55)
	lbl.pixel_size = 0.009
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.width = size.x * 110.0
	root.add_child(lbl)
	
	return root

func handle_valve_turn(v_name: String) -> void:
	if valve_solved:
		GameState.trigger_dialogue("AUDITOR", "Pump A valves already configured.")
		return
		
	valve_sequence.append(v_name)
	if AudioEngine: AudioEngine.play_sfx("option_select")
	
	# Correct order: open V2, then V5, then close V1
	if valve_sequence.size() == 1:
		if valve_sequence[0] != "V2":
			fail_valve_sequence()
	elif valve_sequence.size() == 2:
		if valve_sequence[1] != "V5":
			fail_valve_sequence()
	elif valve_sequence.size() == 3:
		if valve_sequence[2] == "V1":
			# Solved!
			valve_solved = true
			GameState.trigger_dialogue("MEERA", "Valve sequence correct! Flow diverted through secondary heat exchanger.")
			if AudioEngine: AudioEngine.play_sfx("level_complete")
		else:
			fail_valve_sequence()

func fail_valve_sequence() -> void:
	valve_sequence.clear()
	if AudioEngine: AudioEngine.play_sfx("wrong_valve")
	GameState.trigger_dialogue("SYSTEM", "PRESSURE MISMATCH! Valve sequence failed. Required: Open V2, Open V5, Close V1.")

func handle_audit_sequence() -> void:
	var state = GameState
	match audit_step:
		0:
			audit_step = 1
			state.trigger_dialogue("DR. KULKARNI", "MPCB Inspection underway. Question 1: What was the clandestine bypass flow rate from Municipal Line 4?")
		1:
			if state.evidence >= 1:
				audit_step = 2
				state.pressure = max(0.0, state.pressure - 10.0)
				state.trigger_dialogue("DR. KULKARNI", "Accurate. 28.9 L/s logged against municipal allocation. Question 2: What was the outfall dissolved oxygen reading?")
				if AudioEngine: AudioEngine.play_sfx("option_select")
			else:
				audit_step = 2
				state.pressure += 20.0
				state.trigger_dialogue("DR. KULKARNI", "Unsubstantiated claim. No audit records on bypass flow (+20 Audit Pressure). Question 2: What was the outfall dissolved oxygen reading?")
				if AudioEngine: AudioEngine.play_sfx("wrong_valve")
		2:
			if state.evidence >= 3:
				audit_step = 3
				state.pressure = max(0.0, state.pressure - 10.0)
				state.trigger_dialogue("DR. KULKARNI", "2.2 mg/L confirmed — severe breach of the 4.0 mg/L minimum threshold. Final Question: What cooling topology is currently operating?")
				if AudioEngine: AudioEngine.play_sfx("option_select")
			else:
				audit_step = 3
				state.pressure += 15.0
				state.trigger_dialogue("DR. KULKARNI", "No biological sample data provided (+15 Audit Pressure). Final Question: What cooling topology is currently operating?")
				if AudioEngine: AudioEngine.play_sfx("wrong_valve")
		3:
			audit_step = 4
			var sim = get_node_or_null("/root/Simulation")
			var topo = "HYBRID_EVAP"
			if sim: topo = sim.current_topology
			state.trigger_dialogue("DR. KULKARNI", "Current topology registered as: " + topo + ". Preparing final statutory determination.")
			if AudioEngine: AudioEngine.play_sfx("option_select")
			
			# Open Final Decision Card
			var card_ui = get_tree().root.find_child("DecisionCardLayer", true, false)
			if card_ui:
				card_ui.open_card({
					"id": "LEVEL5_FINAL",
					"title": "FINAL REGULATORY AUDIT DETERMINATION",
					"options": [
						{
							"letter": "A",
							"text": "FULL DISCLOSURE (Requires Evidence >= 4)",
							"preview": "Trust +20, SLA -10. Facility stays open. Best ending if HHI >= 65.",
							"min_evidence": 4
						},
						{
							"letter": "B",
							"text": "PARTIAL DISCLOSURE (Audit Pressure < 60)",
							"preview": "Facility survives. Creek environmental issue remains unresolved.",
							"max_pressure": 60
						},
						{
							"letter": "C",
							"text": "WHISTLEBLOW (Requires Evidence >= 5)",
							"preview": "Trust +30, SLA → 0. Complete public transparency. Creek protected.",
							"min_evidence": 5
						}
					]
				})

func update_live_world_readouts() -> void:
	var sim = get_node_or_null("/root/Simulation")
	if not sim:
		return
	for item in live_labels:
		var lbl: Label3D = item["label"]
		if not is_instance_valid(lbl):
			continue
		match item["type"]:
			"PUE_POSTER":
				lbl.text = "PUE TARGET 1.15 | CURRENT PUE: " + str(snappedf(sim.pue, 0.001))
			"OUTFALL_SIGN":
				lbl.text = "BLOWDOWN TDS: " + str(int(sim.basin_tds)) + " ppm | PERMISSIBLE: 2100 ppm"
			"CREEK_BOARD":
				lbl.text = "THANE CREEK — FLAMINGO HABITAT (Phoenicopterus roseus)\nDISSOLVED OXYGEN MIN. 4mg/L | CURRENT READING: " + str(snappedf(sim.creek_do, 0.1)) + " mg/L"

func trigger_world_transition(duration: float) -> void:
	apply_hhi_visuals(HHI.current_hhi, duration)

func apply_hhi_visuals(hhi_val: float, duration: float) -> void:
	var tier_data = HHI.get_tier_data()
	var sky_c: Color = tier_data["sky_color"]
	var fog_c: Color = tier_data["fog_color"]
	var creek_c: Color = tier_data["creek_color"]
	var fog_d: float = tier_data["fog_density"]
	var steam_amt: int = tier_data["steam_amount"]
	
	if duration <= 0.01:
		if world_env and world_env.environment:
			world_env.environment.background_color = sky_c
			world_env.environment.fog_light_color = fog_c
			world_env.environment.fog_density = fog_d
		if creek_mesh and creek_mesh.material_override is ShaderMaterial:
			creek_mesh.material_override.set_shader_parameter("water_color", creek_c)
		for s in steam_emitters:
			s.amount = max(1, steam_amt)
			s.emitting = (steam_amt > 0)
	else:
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if world_env and world_env.environment:
			tween.tween_property(world_env.environment, "background_color", sky_c, duration)
			tween.parallel().tween_property(world_env.environment, "fog_light_color", fog_c, duration)
			tween.parallel().tween_property(world_env.environment, "fog_density", fog_d, duration)
		if creek_mesh and creek_mesh.material_override is ShaderMaterial:
			tween.parallel().tween_method(func(c): creek_mesh.material_override.set_shader_parameter("water_color", c), creek_mesh.material_override.get_shader_parameter("water_color"), creek_c, duration)
		for s in steam_emitters:
			s.amount = max(1, steam_amt)
			s.emitting = (steam_amt > 0)

func update_level_flow() -> void:
	if not GameState:
		return
	# Level 2 emergency lights
	var is_l2 = (GameState.current_level == 2)
	for light in red_emergency_lights:
		light.light_energy = 2.5 if is_l2 else 0.0

func toggle_thermal_view(active: bool) -> void:
	if bypass_pipe_mesh and bypass_pipe_mesh.material_override:
		if active:
			bypass_pipe_mesh.material_override.albedo_color = Color("#FF6600")
		else:
			bypass_pipe_mesh.material_override.albedo_color = Color("#333A42")
