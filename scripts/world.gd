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

# Lighting rigs
var floodlights: Array = []
var street_lamps: Array = []
var rack_lights: Array = []
var red_emergency_lights: Array = []
var strobe_timer: float = 0.0
var rack_blink_timer: float = 0.0
var level5_sunrise_timer: float = 0.0

# Live Label3Ds to update every second
var live_labels: Array = []
var steam_emitters: Array = []

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
var heat_shimmer_mesh: MeshInstance3D
var canal_fumes: CPUParticles3D
var rain_particles: CPUParticles3D

func _ready() -> void:
	build_lighting_rigs()
	build_weather_systems()
	build_environment_geometry()
	build_zones()
	build_field_notes()
	build_npcs()
	setup_signals()
	apply_hhi_visuals(HHI.current_hhi, 0.0) # instant initial
	update_level_flow()
	
	_disable_building_shadows(self)
	
	# Start clock/labels update timer
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(update_live_world_readouts)
	add_child(timer)
	timer.start()
	update_live_world_readouts()

func _disable_building_shadows(node: Node) -> void:
	if node is MeshInstance3D and not (node.get_parent() is CharModelScript or node.owner is CharModelScript):
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in node.get_children():
		if not (c is CharModelScript):
			_disable_building_shadows(c)

func build_weather_systems() -> void:
	# Rain weather layer for Levels 3 & 4 (300 particles, falling downward, reacts to HHI)
	rain_particles = CPUParticles3D.new()
	rain_particles.name = "RainParticles"
	rain_particles.amount = 300
	rain_particles.lifetime = 1.4
	rain_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain_particles.emission_box_extents = Vector3(40.0, 1.0, 40.0)
	rain_particles.position = Vector3(0.0, 24.0, 0.0)
	rain_particles.direction = Vector3(0, -1, 0)
	rain_particles.spread = 4.0
	rain_particles.gravity = Vector3(0, -32.0, 0)
	rain_particles.initial_velocity_min = 18.0
	rain_particles.initial_velocity_max = 24.0
	rain_particles.visibility_aabb = AABB(Vector3(-50, -30, -50), Vector3(100, 60, 100))
	
	var drop_mesh = BoxMesh.new()
	drop_mesh.size = Vector3(0.02, 0.35, 0.02)
	var mat_drop = StandardMaterial3D.new()
	mat_drop.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_drop.albedo_color = Color(0.8, 0.9, 1.0, 0.5)
	mat_drop.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_mesh.material = mat_drop
	rain_particles.mesh = drop_mesh
	
	rain_particles.emitting = false
	add_child(rain_particles)

func _process(delta: float) -> void:
	# Server hall rack lights blinking (1s alternation red/green)
	rack_blink_timer += delta
	if rack_blink_timer >= 1.0:
		rack_blink_timer = 0.0
		for idx in range(rack_lights.size()):
			var rl: OmniLight3D = rack_lights[idx]
			if is_instance_valid(rl):
				rl.light_color = Color("#44FF44") if (idx % 2 == 0) else Color("#FF4444")
				
	# Emergency strobe in Level 2
	if GameState and GameState.current_level == 2:
		strobe_timer += delta
		var energy_val = 0.3 + 0.9 * (sin(strobe_timer * TAU / 0.8) * 0.5 + 0.5)
		for el in red_emergency_lights:
			if is_instance_valid(el):
				el.light_energy = energy_val
				
	# Level 5 sunrise lerp
	if GameState and GameState.current_level == 5 and level5_sunrise_timer < 90.0:
		level5_sunrise_timer += delta
		var t = clamp(level5_sunrise_timer / 90.0, 0.0, 1.0)
		var c1 = Color("#FF4010")
		var c2 = Color("#FFB347")
		var c3 = Color("#87CEEB")
		var cur_sun_color: Color
		if t < 0.5:
			cur_sun_color = c1.lerp(c2, t * 2.0)
		else:
			cur_sun_color = c2.lerp(c3, (t - 0.5) * 2.0)
		if sun_light:
			sun_light.light_color = cur_sun_color
			sun_light.rotation_degrees = Vector3(-10.0 + t * 45.0, 90.0, 0.0) # Rises from east

	# Heat shimmer in Level 2 within 8m of hot pipes
	if heat_shimmer_mesh:
		var p_node = get_node_or_null("Player")
		if GameState and GameState.current_level == 2 and p_node and p_node.global_position.distance_to(Vector3(-16.0, 1.5, -25.0)) <= 8.0:
			heat_shimmer_mesh.visible = true
		else:
			heat_shimmer_mesh.visible = false

	# Rain particle reaction to HHI
	if rain_particles and rain_particles.emitting:
		var target_amt = int(clamp(300.0 * (1.0 - HHI.current_hhi / 110.0), 60.0, 300.0))
		rain_particles.amount = target_amt

func setup_signals() -> void:
	if GameState:
		GameState.world_transition_started.connect(trigger_world_transition)
		GameState.state_updated.connect(update_level_flow)

func build_lighting_rigs() -> void:
	# Level 1 Directional Sun baseline
	if sun_light:
		sun_light.light_color = Color("#FFC87A")
		sun_light.light_energy = 1.1
		sun_light.rotation_degrees = Vector3(-35, 20, 0)
		sun_light.shadow_enabled = true
		sun_light.shadow_blur = 0.0
		
	# 4 Corner Floodlights at compound fence corners (Level 2)
	var corner_coords = [
		Vector3(-50, 8, -50), Vector3(50, 8, -50),
		Vector3(-50, 8, 50), Vector3(50, 8, 50)
	]
	for cp in corner_coords:
		var fl = SpotLight3D.new()
		fl.light_color = Color("#FFE0A0")
		fl.spot_range = 30.0
		fl.spot_angle = 40.0
		fl.light_energy = 0.0 # Activated in Level 2
		fl.position = cp
		var target_look = Vector3(0, 0, 0)
		add_child(fl)
		fl.look_at(target_look, Vector3.UP)
		floodlights.append(fl)
		
	# Street Lamps every 20m along roads (Levels 3 & 4)
	var lamp_z_coords = [50.0, 70.0, 90.0, 110.0, 130.0]
	for z_pos in lamp_z_coords:
		for x_pos in [-12.0, 12.0]:
			var lamp_pole = MeshInstance3D.new()
			var p_cyl = CylinderMesh.new()
			p_cyl.top_radius = 0.08
			p_cyl.bottom_radius = 0.1
			p_cyl.height = 5.0
			lamp_pole.mesh = p_cyl
			lamp_pole.position = Vector3(x_pos, 2.5, z_pos)
			var mat_pole = StandardMaterial3D.new()
			mat_pole.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
			mat_pole.albedo_color = Color("#30343D")
			lamp_pole.material_override = mat_pole
			add_child(lamp_pole)
			
			var omni = OmniLight3D.new()
			omni.light_color = Color("#FFA020")
			omni.omni_range = 12.0
			omni.light_energy = 0.0 # Activated in Level 3/4
			omni.position = Vector3(x_pos, 4.8, z_pos)
			add_child(omni)
			street_lamps.append(omni)

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
		
	# Creek Mud Banks (0.5m raised terrain edge on each side: dark mud #3A2A1A)
	for bank_x in [59.5, 110.5]:
		var bank = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(2.5, 0.6, 100.0)
		bank.mesh = b_mesh
		bank.position = Vector3(bank_x, 0.25, 0.0)
		var mat_bank = StandardMaterial3D.new()
		mat_bank.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mat_bank.albedo_color = Color("#3A2A1A")
		bank.material_override = mat_bank
		add_child(bank)
		
		var bank_body = StaticBody3D.new()
		var bank_col = CollisionShape3D.new()
		var bank_shape = BoxShape3D.new()
		bank_shape.size = b_mesh.size
		bank_col.shape = bank_shape
		bank_body.position = bank.position
		bank_body.add_child(bank_col)
		add_child(bank_body)
		
	# 20 Mangrove silhouettes at creek edges (varied heights 3–8m)
	var mat_mangrove = StandardMaterial3D.new()
	mat_mangrove.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_mangrove.albedo_color = Color("#122314")
	for i in range(20):
		var tree = MeshInstance3D.new()
		var t_cone = CylinderMesh.new()
		var m_height = 3.0 + (i % 6) * 1.0 # 3.0 to 8.0m
		t_cone.top_radius = 0.0
		t_cone.bottom_radius = 1.4 + (i % 4) * 0.3
		t_cone.height = m_height
		tree.mesh = t_cone
		var side_x = 61.5 if (i % 2 == 0) else 108.5
		tree.position = Vector3(side_x, m_height * 0.5, -48.0 + i * 5.0)
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
	
	# Canal Fume / Shimmer Particles (pale yellow-brown #C8B060, 3m spread, rises slowly)
	var fumes = CPUParticles3D.new()
	fumes.name = "CanalFumes"
	fumes.amount = 25
	fumes.lifetime = 6.0
	fumes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	fumes.emission_box_extents = Vector3(3.0, 0.2, 1.5)
	fumes.direction = Vector3(0, 1, 0)
	fumes.spread = 20.0
	fumes.gravity = Vector3(0, 0.4, 0)
	fumes.initial_velocity_min = 0.4
	fumes.initial_velocity_max = 0.8
	fumes.color = Color("#C8B0604D") # Low opacity 0.3
	fumes.position = Vector3(50.0, 0.2, -20.0)
	canal_fumes = fumes
	add_child(fumes)

func _add_building_details(building_node: Node3D, size: Vector3, has_ac: bool, has_tank: bool, has_dish: bool) -> void:
	# Roof edge: 0.3m parapet overhang
	var parapet = MeshInstance3D.new()
	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(size.x + 0.6, 0.4, size.z + 0.6)
	parapet.mesh = p_mesh
	parapet.position = Vector3(0, (size.y * 0.5) + 0.2, 0)
	var mat_p = StandardMaterial3D.new()
	mat_p.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_p.albedo_color = Color("#1C2028")
	parapet.material_override = mat_p
	building_node.add_child(parapet)
	
	# Window indentations: thin inset quads
	var mat_win = StandardMaterial3D.new()
	mat_win.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_win.albedo_color = Color("#0E1218")
	
	for w_side in [-1.0, 1.0]:
		var win = MeshInstance3D.new()
		var win_mesh = QuadMesh.new()
		win_mesh.size = Vector2(size.x * 0.6, size.y * 0.4)
		win.mesh = win_mesh
		win.position = Vector3(0, 0, (size.z * 0.5 + 0.02) * w_side)
		if w_side < 0: win.rotation_degrees = Vector3(0, 180, 0)
		win.material_override = mat_win
		building_node.add_child(win)
		
	# Extruded Doorframe
	var frame = MeshInstance3D.new()
	var f_mesh = BoxMesh.new()
	f_mesh.size = Vector3(1.8, 2.6, 0.15)
	frame.mesh = f_mesh
	frame.position = Vector3(0, -size.y * 0.5 + 1.3, size.z * 0.5 + 0.08)
	var mat_frame = StandardMaterial3D.new()
	mat_frame.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_frame.albedo_color = Color("#15171D")
	frame.material_override = mat_frame
	building_node.add_child(frame)
	
	# Distinguishing props
	if has_ac:
		var ac = MeshInstance3D.new()
		var ac_box = BoxMesh.new()
		ac_box.size = Vector3(1.4, 0.9, 0.7)
		ac.mesh = ac_box
		ac.position = Vector3(size.x * 0.25, -size.y * 0.2, size.z * 0.5 + 0.35)
		var mat_ac = StandardMaterial3D.new()
		mat_ac.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mat_ac.albedo_color = Color("#8C969E")
		ac.material_override = mat_ac
		building_node.add_child(ac)
		
	if has_tank:
		var tank = MeshInstance3D.new()
		var t_cyl = CylinderMesh.new()
		t_cyl.top_radius = 1.0
		t_cyl.bottom_radius = 1.0
		t_cyl.height = 1.8
		tank.mesh = t_cyl
		tank.position = Vector3(-size.x * 0.25, (size.y * 0.5) + 1.1, 0)
		var mat_tank = StandardMaterial3D.new()
		mat_tank.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mat_tank.albedo_color = Color("#111A24")
		tank.material_override = mat_tank
		building_node.add_child(tank)
		
	if has_dish:
		var dish = MeshInstance3D.new()
		var d_torus = TorusMesh.new()
		d_torus.inner_radius = 0.5
		d_torus.outer_radius = 0.8
		dish.mesh = d_torus
		dish.position = Vector3(size.x * 0.2, (size.y * 0.5) + 0.8, -size.z * 0.2)
		dish.rotation_degrees = Vector3(30, 45, 0)
		var mat_dish = StandardMaterial3D.new()
		mat_dish.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mat_dish.albedo_color = Color("#A0A4A8")
		dish.material_override = mat_dish
		building_node.add_child(dish)

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
	var gh = Node3D.new()
	gh.position = Vector3(5.0, 1.6, 50.0)
	var gh_mesh = MeshInstance3D.new()
	var gh_box = BoxMesh.new()
	gh_box.size = Vector3(4.0, 3.2, 5.0)
	gh_mesh.mesh = gh_box
	var mat_gh = StandardMaterial3D.new()
	mat_gh.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_gh.albedo_color = Color("#323B47")
	gh_mesh.material_override = mat_gh
	gh.add_child(gh_mesh)
	_add_building_details(gh, gh_box.size, true, false, true)
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
	# 8 Chawls: Each different height AND footprint
	var chawl_data = [
		{"pos": Vector3(-25, 4.0, 85),  "size": Vector3(12.0, 8.0, 14.0), "ac": true, "tank": false, "dish": true},
		{"pos": Vector3(-26, 6.0, 105), "size": Vector3(15.0, 12.0, 10.0), "ac": false, "tank": true, "dish": true},
		{"pos": Vector3(-24, 5.0, 122), "size": Vector3(10.0, 10.0, 18.0), "ac": true, "tank": true, "dish": false},
		{"pos": Vector3(25, 5.5, 85),   "size": Vector3(14.0, 11.0, 12.0), "ac": true, "tank": false, "dish": false},
		{"pos": Vector3(26, 7.0, 105),  "size": Vector3(11.0, 14.0, 15.0), "ac": false, "tank": true, "dish": true},
		{"pos": Vector3(25, 4.5, 122),  "size": Vector3(16.0, 9.0, 13.0),  "ac": true, "tank": true, "dish": true},
		{"pos": Vector3(-10, 5.0, 132), "size": Vector3(18.0, 10.0, 11.0), "ac": false, "tank": true, "dish": false},
		{"pos": Vector3(12, 6.5, 132),  "size": Vector3(13.0, 13.0, 16.0), "ac": true, "tank": false, "dish": true}
	]
	
	var mat_chawl = StandardMaterial3D.new()
	mat_chawl.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_chawl.albedo_color = Color("#6B5B4E")
	
	for cd in chawl_data:
		var c_node = Node3D.new()
		c_node.position = cd["pos"]
		
		var c_mesh_inst = MeshInstance3D.new()
		var c_box = BoxMesh.new()
		c_box.size = cd["size"]
		c_mesh_inst.mesh = c_box
		c_mesh_inst.material_override = mat_chawl
		c_node.add_child(c_mesh_inst)
		_add_building_details(c_node, cd["size"], cd["ac"], cd["tank"], cd["dish"])
		add_child(c_node)
		
		# Static collision for chawls
		var cb = StaticBody3D.new()
		var cc = CollisionShape3D.new()
		var cs = BoxShape3D.new()
		cs.size = cd["size"]
		cc.shape = cs
		cb.position = cd["pos"]
		cb.add_child(cc)
		add_child(cb)
		
	# Laundry lines between buildings (thin wire + cloth flags)
	var line_mesh = CylinderMesh.new()
	line_mesh.top_radius = 0.015
	line_mesh.bottom_radius = 0.015
	line_mesh.height = 14.0
	
	var laundry_line = MeshInstance3D.new()
	laundry_line.mesh = line_mesh
	laundry_line.rotation_degrees = Vector3(0, 0, 90)
	laundry_line.position = Vector3(0, 4.0, 105.0)
	var mat_wire = StandardMaterial3D.new()
	mat_wire.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_wire.albedo_color = Color("#222222")
	laundry_line.material_override = mat_wire
	add_child(laundry_line)
	
	# Cloth flags hanging on laundry line
	var flag_colors = [Color("#E63946"), Color("#F1FAEE"), Color("#A8DADC"), Color("#457B9D"), Color("#E9C46A")]
	for fi in range(6):
		var flag = MeshInstance3D.new()
		var f_mesh = QuadMesh.new()
		f_mesh.size = Vector2(0.9, 1.2)
		flag.mesh = f_mesh
		flag.position = Vector3(-5.0 + fi * 2.0, 3.3, 105.0)
		var mat_flag = StandardMaterial3D.new()
		mat_flag.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mat_flag.albedo_color = flag_colors[fi % flag_colors.size()]
		flag.material_override = mat_flag
		add_child(flag)
		
	# Water tanker queue at (-15, 0, 80) — 5 tankers total (2 more added)
	for i in range(5):
		var tanker = VehicleBuilderScript.create_water_tanker()
		tanker.position = Vector3(-15.0, 0.0, 68.0 + i * 8.5)
		add_child(tanker)
		
	# Line of people waiting at tap
	for pi in range(3):
		var tap_ped = CharModelScript.new()
		tap_ped.character_type = "PEDESTRIAN"
		tap_ped.position = Vector3(-10.0, 0.0, 87.0 - pi * 1.4)
		add_child(tap_ped)
		
	# Sunita tai NPC interaction trigger at (-12.5, 0, 80)
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
	
	# Political poster on chawl wall (flat textured quad)
	var pol_poster = MeshInstance3D.new()
	var p_quad = QuadMesh.new()
	p_quad.size = Vector2(2.2, 3.0)
	pol_poster.mesh = p_quad
	pol_poster.position = Vector3(-18.9, 3.0, 88.0)
	pol_poster.rotation_degrees = Vector3(0, 90, 0)
	var mat_pp = StandardMaterial3D.new()
	mat_pp.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_pp.albedo_color = Color("#C0392B")
	pol_poster.material_override = mat_pp
	add_child(pol_poster)
	
	# Flyer on colony wall: "6 DAYS WITHOUT TAP WATER — NMMC DO SOMETHING"
	var flyer = create_billboard(
		Vector3(-18.9, 1.8, 95.0),
		Vector3(1.8, 1.2, 0.05),
		"6 DAYS WITHOUT TAP WATER\nNMMC DO SOMETHING!",
		Color("#FFFFFF"),
		Vector3(0, 90, 0)
	)
	add_child(flyer)
	
	# Road graffiti: "DATA CENTRE TOOK OUR WATER" (legible)
	var graffiti = Label3D.new()
	graffiti.text = "DATA CENTRE TOOK OUR WATER"
	graffiti.font_size = 48
	graffiti.modulate = Color("#B83227")
	graffiti.outline_modulate = Color("#000000")
	graffiti.outline_size = 4
	graffiti.position = Vector3(-4.0, 0.06, 75.0)
	graffiti.rotation_degrees = Vector3(-90, 0, 0)
	graffiti.pixel_size = 0.016
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
	var sub_node = Node3D.new()
	sub_node.position = Vector3(-28.0, 1.75, 44.0)
	var sub = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(8.0, 3.5, 8.0)
	sub.mesh = s_box
	var mat_sub = StandardMaterial3D.new()
	mat_sub.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_sub.albedo_color = Color("#3B424D")
	sub.material_override = mat_sub
	sub_node.add_child(sub)
	_add_building_details(sub_node, s_box.size, true, true, false)
	add_child(sub_node)
	
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
				"situation_type": "pipe",
				"title": "UNMETERED BYPASS DETECTED — 28.9 L/s",
				"subline": "BYPASS FLOW: 28.9 L/s | MUNICIPAL SUPPLY: 14%",
				"options": [
					{
						"letter": "A",
						"text": "CLOSE IT NOW",
						"desc": "Shut down the unmetered bypass immediately to stop municipal draw.",
						"tradeoff": "Saves municipal water but risks starving tower basins and heating servers.",
						"preview": "W↓↓↓ H↑↑↑ T↑ S↓"
					},
					{
						"letter": "B",
						"text": "THROTTLE COMPUTE 30%",
						"desc": "Shed load to reduce cooling demand while maintaining safe operation.",
						"tradeoff": "Cuts water use and heat generation but damages client service level agreements.",
						"preview": "W↓ H↓ S↓↓"
					},
					{
						"letter": "C",
						"text": "LOG AND REPORT",
						"desc": "Preserve airtight documentation for the MPCB audit before taking physical action.",
						"tradeoff": "Builds compliance evidence and community trust, but water continues flowing.",
						"preview": "T↑↑ Evidence+1 Pressure↓10"
					}
				]
			})
	)
	add_child(l1_console)

func build_server_hall_a() -> void:
	# Server Hall A (x -45..-15, z -45..-5)
	var hall_node = Node3D.new()
	hall_node.position = Vector3(-30.0, 3.0, -25.0)
	var hall = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(30.0, 6.0, 40.0)
	hall.mesh = h_box
	var mat_hall = StandardMaterial3D.new()
	mat_hall.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_hall.albedo_color = Color("#1E242B")
	hall.material_override = mat_hall
	hall_node.add_child(hall)
	_add_building_details(hall_node, h_box.size, true, true, true)
	add_child(hall_node)
	
	# Raised floor tiles (grid pattern shader)
	var floor_mesh = MeshInstance3D.new()
	var f_plane = PlaneMesh.new()
	f_plane.size = Vector2(28.0, 38.0)
	floor_mesh.mesh = f_plane
	floor_mesh.position = Vector3(-30.0, 0.05, -25.0)
	var s_floor = ShaderMaterial.new()
	s_floor.shader = preload("res://shaders/raised_floor.gdshader")
	floor_mesh.material_override = s_floor
	add_child(floor_mesh)
	
	# 6 Rack Rows of server racks with blinking front lights
	for row in range(6):
		var row_z = -40.0 + row * 6.0
		var rack = MeshInstance3D.new()
		var r_box = BoxMesh.new()
		r_box.size = Vector3(20.0, 3.2, 1.2)
		rack.mesh = r_box
		rack.position = Vector3(-30.0, 1.6, row_z)
		var mat_rack = StandardMaterial3D.new()
		mat_rack.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mat_rack.albedo_color = Color("#11151A")
		rack.material_override = mat_rack
		add_child(rack)
		
		# Blinking front panel light
		var omni_rack = OmniLight3D.new()
		omni_rack.light_color = Color("#44FF44") if (row % 2 == 0) else Color("#FF4444")
		omni_rack.omni_range = 3.0
		omni_rack.light_energy = 0.8
		omni_rack.position = Vector3(-30.0, 2.0, row_z + 0.7)
		add_child(omni_rack)
		rack_lights.append(omni_rack)
		
	# Overhead cable trays: horizontal cylinder grids
	for cy in range(3):
		var tray = MeshInstance3D.new()
		var t_cyl = CylinderMesh.new()
		t_cyl.top_radius = 0.04
		t_cyl.bottom_radius = 0.04
		t_cyl.height = 36.0
		tray.mesh = t_cyl
		tray.rotation_degrees = Vector3(90, 0, 0)
		tray.position = Vector3(-35.0 + cy * 5.0, 4.8, -25.0)
		var mat_tray = StandardMaterial3D.new()
		mat_tray.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mat_tray.albedo_color = Color("#8C969E")
		tray.material_override = mat_tray
		add_child(tray)
	
	# Hall Collision
	var hb = StaticBody3D.new()
	var hc = CollisionShape3D.new()
	var hs = BoxShape3D.new()
	hs.size = h_box.size
	hc.shape = hs
	hb.position = hall_node.position
	hb.add_child(hc)
	add_child(hb)
	
	# Red Emergency Flickering Lights inside Hall (Level 2 strobing)
	for i in range(4):
		var omni = OmniLight3D.new()
		omni.light_color = Color("#FF2211")
		omni.light_energy = 0.0 # Activates in Level 2
		omni.omni_range = 16.0
		omni.position = Vector3(-35.0 + i * 5.0, 4.2, -25.0)
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
	
	# Heat Shimmer Mesh near hot pipes (-16, 1.5, -25)
	heat_shimmer_mesh = MeshInstance3D.new()
	heat_shimmer_mesh.name = "HeatShimmer"
	var hs_quad = QuadMesh.new()
	hs_quad.size = Vector2(8.0, 4.0)
	heat_shimmer_mesh.mesh = hs_quad
	heat_shimmer_mesh.position = Vector3(-16.0, 1.5, -25.0)
	heat_shimmer_mesh.rotation_degrees = Vector3(0, 90, 0)
	var hs_mat = ShaderMaterial.new()
	hs_mat.shader = preload("res://shaders/heat_shimmer.gdshader")
	heat_shimmer_mesh.material_override = hs_mat
	heat_shimmer_mesh.visible = false
	add_child(heat_shimmer_mesh)

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
		
	# Level 2 Decision Console at (-20, 1, -25)
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
				"situation_type": "flame",
				"title": "Tj AT 84°C AND RISING",
				"subline": "JUNCTION TEMP: 84.0°C | TRIP LIMIT: 90.0°C",
				"options": [
					{
						"letter": "A",
						"text": "FLOOD TOWERS WITH MAKEUP WATER",
						"desc": "Over-saturate evaporative towers with emergency municipal makeup water.",
						"tradeoff": "Cools chips rapidly but consumes massive drinking water and pollutes creek.",
						"preview": "H↓↓↓ W↑↑↑ C↑ T↓↓"
					},
					{
						"letter": "B",
						"text": "SHED 20% MORE COMPUTE LOAD",
						"desc": "Drop batch computing queues and hold critical workloads domestically.",
						"tradeoff": "Reduces thermal rise cleanly without extra water, but incurs severe SLA penalty.",
						"preview": "H↓↓ S↓↓ W↓"
					},
					{
						"letter": "C",
						"text": "BRING IN DRY BACKUP COOLERS",
						"desc": "Spin up emergency high-power fan air chillers without consuming water.",
						"tradeoff": "Keeps silicon operational without water, but spikes electrical power and PUE.",
						"preview": "H↓ P↑↑↑ W unchanged"
					}
				]
			})
	)
	add_child(l2_console)

func _build_hyperboloid_tower(r_min: float = 3.0, r_top: float = 5.0, H: float = 20.0, lat_segs: int = 16, lon_segs: int = 20) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(lat_segs):
		var h0 = (float(i) / float(lat_segs)) * H
		var h1 = (float(i + 1) / float(lat_segs)) * H
		var r0 = r_min + (r_top - r_min) * (pow((h0 / H - 0.5), 2.0) / 0.25)
		var r1 = r_min + (r_top - r_min) * (pow((h1 / H - 0.5), 2.0) / 0.25)
		
		var v0 = float(i) / float(lat_segs)
		var v1 = float(i + 1) / float(lat_segs)
		
		for j in range(lon_segs):
			var theta0 = (float(j) / float(lon_segs)) * TAU
			var theta1 = (float(j + 1) / float(lon_segs)) * TAU
			var u0 = float(j) / float(lon_segs)
			var u1 = float(j + 1) / float(lon_segs)
			
			var p00 = Vector3(r0 * cos(theta0), h0, r0 * sin(theta0))
			var p01 = Vector3(r0 * cos(theta1), h0, r0 * sin(theta1))
			var p10 = Vector3(r1 * cos(theta0), h1, r1 * sin(theta0))
			var p11 = Vector3(r1 * cos(theta1), h1, r1 * sin(theta1))
			
			var n00 = Vector3(cos(theta0), -(h0 / H - 0.5) * 0.4, sin(theta0)).normalized()
			var n01 = Vector3(cos(theta1), -(h0 / H - 0.5) * 0.4, sin(theta1)).normalized()
			var n10 = Vector3(cos(theta0), -(h1 / H - 0.5) * 0.4, sin(theta0)).normalized()
			var n11 = Vector3(cos(theta1), -(h1 / H - 0.5) * 0.4, sin(theta1)).normalized()
			
			st.set_uv(Vector2(u0, v0)); st.set_normal(n00); st.add_vertex(p00)
			st.set_uv(Vector2(u0, v1)); st.set_normal(n10); st.add_vertex(p10)
			st.set_uv(Vector2(u1, v1)); st.set_normal(n11); st.add_vertex(p11)
			
			st.set_uv(Vector2(u0, v0)); st.set_normal(n00); st.add_vertex(p00)
			st.set_uv(Vector2(u1, v1)); st.set_normal(n11); st.add_vertex(p11)
			st.set_uv(Vector2(u1, v0)); st.set_normal(n01); st.add_vertex(p01)
			
	return st.commit()

func build_cooling_towers() -> void:
	# 4 Parametric Hyperboloid Cooling Towers at x=-5, 8, 21, 34 z=-35
	var tower_x = [-5.0, 8.0, 21.0, 34.0]
	var hyp_mesh = _build_hyperboloid_tower(3.0, 5.0, 20.0, 16, 20)
	var tower_shader = preload("res://shaders/cooling_tower_streaks.gdshader")
	var mat_tower = ShaderMaterial.new()
	mat_tower.shader = tower_shader
	
	for tx in tower_x:
		var tower = Node3D.new()
		tower.name = "CoolingTower"
		tower.position = Vector3(tx, 0, -35.0)
		
		var t_mesh_inst = MeshInstance3D.new()
		t_mesh_inst.mesh = hyp_mesh
		t_mesh_inst.material_override = mat_tower
		tower.add_child(t_mesh_inst)
		
		# Tower Collision
		var tb = StaticBody3D.new()
		var tc = CollisionShape3D.new()
		var t_cyl_shape = CylinderShape3D.new()
		t_cyl_shape.radius = 4.2
		t_cyl_shape.height = 20.0
		tc.shape = t_cyl_shape
		tb.position = Vector3(0, 10.0, 0)
		tb.add_child(tc)
		tower.add_child(tb)
		
		# Dual Steam Particles: Inner plume (fast white) + Outer drift (slow cream)
		var inner_steam = CPUParticles3D.new()
		inner_steam.amount = 12
		inner_steam.lifetime = 3.0
		inner_steam.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		inner_steam.emission_sphere_radius = 2.0
		inner_steam.direction = Vector3(0, 1, 0)
		inner_steam.spread = 10.0
		inner_steam.gravity = Vector3(0, 1.2, 0)
		inner_steam.initial_velocity_min = 2.0
		inner_steam.initial_velocity_max = 3.5
		inner_steam.color = Color("#F0F0F0")
		inner_steam.position = Vector3(0, 20.0, 0)
		inner_steam.visibility_aabb = AABB(Vector3(-10, -5, -10), Vector3(20, 30, 20))
		tower.add_child(inner_steam)
		steam_emitters.append(inner_steam)
		
		var outer_steam = CPUParticles3D.new()
		outer_steam.amount = 8
		outer_steam.lifetime = 8.0
		outer_steam.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		outer_steam.emission_sphere_radius = 3.5
		outer_steam.direction = Vector3(0.2, 1, 0.1)
		outer_steam.spread = 22.0
		outer_steam.gravity = Vector3(0.2, 0.5, 0)
		outer_steam.initial_velocity_min = 0.8
		outer_steam.initial_velocity_max = 1.6
		outer_steam.scale_amount_min = 2.0
		outer_steam.scale_amount_max = 4.5
		outer_steam.color = Color(0.94, 0.93, 0.88, 0.4)
		outer_steam.position = Vector3(0, 20.0, 0)
		outer_steam.visibility_aabb = AABB(Vector3(-15, -5, -15), Vector3(30, 35, 30))
		tower.add_child(outer_steam)
		steam_emitters.append(outer_steam)
		
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
	var hub_node = Node3D.new()
	hub_node.position = Vector3(20.0, 1.9, 10.0)
	var hub = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(12.0, 3.8, 10.0)
	hub.mesh = h_box
	var mat_hub = StandardMaterial3D.new()
	mat_hub.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat_hub.albedo_color = Color("#2D3642")
	hub.material_override = mat_hub
	hub_node.add_child(hub)
	_add_building_details(hub_node, h_box.size, true, false, true)
	add_child(hub_node)
	
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
				"situation_type": "pipe",
				"title": "COOLING SYSTEM RETROFIT WINDOW (BUDGET: " + str(GameState.budget) + " CR)",
				"subline": "TOPOLOGY: " + str(Simulation.current_topology) + " | BUDGET: " + str(GameState.budget) + " CR",
				"options": [
					{
						"letter": "A",
						"text": "FULL DTC CONVERSION (Cost: 40 CR)",
						"desc": "Switch completely to Direct-to-Chip liquid cooling topology.",
						"tradeoff": "Dramatically cuts potable water and heat, but expends major budget and requires permits.",
						"preview": "W↓↓↓ P↓ H↓↓ (Requires Evidence >= 3)",
						"min_evidence": 3,
						"cost_budget": 40
					},
					{
						"letter": "B",
						"text": "HYBRID WITH STP WATER (Cost: 20 CR)",
						"desc": "Retrofit cooling towers to use treated sewage water instead of municipal potable.",
						"tradeoff": "Completely eliminates potable drinking water draw, returning water to community.",
						"preview": "Potable Draw → 0 MLD, C↑",
						"cost_budget": 20
					},
					{
						"letter": "C",
						"text": "OPTIMISE EXISTING (Cost: 10 CR)",
						"desc": "Calibrate current hybrid evaporative loop with tight software throttles.",
						"tradeoff": "Preserves capital reserves, but offers only modest reductions in water draw.",
						"preview": "Small efficiency gain, preserves Budget",
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
					"situation_type": "drop",
					"title": "BASIN TDS 2470PPM — OUTFALL RUNNING",
					"subline": "EFFLUENT TDS: 2470 ppm | CREEK DO: 2.2 mg/L",
					"options": [
						{
							"letter": "A",
							"text": "EMERGENCY ZLD ACTIVATION (Cost: 20 CR)",
							"desc": "Engage Zero Liquid Discharge train to eliminate all effluent discharge.",
							"tradeoff": "Instantly saves the creek and recovers 98% water, but consumes power and budget.",
							"preview": "C↑↑↑ W↓ P↓↓ (Effluent → 0 MLD)",
							"cost_budget": 20
						},
						{
							"letter": "B",
							"text": "DILUTE AND DISCHARGE (Cost: 5 CR)",
							"desc": "Mix municipal water into blowdown stream to artificially mask TDS readings.",
							"tradeoff": "Produces lower TDS on paper, but dumps equal chemical mass and wastes clean water.",
							"preview": "C↑ W↑↑ (Non-compliant, +20 Pressure)",
							"cost_budget": 5
						},
						{
							"letter": "C",
							"text": "SEAL THE VALVE AND HOLD",
							"desc": "Lock down outfall discharge and route toxic blowdown into retention sump.",
							"tradeoff": "Immediate creek protection, but starts a 4-minute Sump Timer that must be fixed.",
							"preview": "4-Minute Sump Timer (Must solve in L4)"
						}
					]
				})
		else:
			# Mash mechanic
			blowdown_mash_count += 1
			if AudioEngine: AudioEngine.play_sfx("wrong_valve")
			if blowdown_mash_count >= 10: # Spec specifies Mash E 10 times
				blowdown_valve_opened = true
				valve_area.prompt_text = "ACCESS BLOWDOWN VALVE CONSOLE"
				GameState.trigger_dialogue("AUDITOR", "Valve seized mechanism broken open! Console accessible.")
				if AudioEngine: AudioEngine.play_sfx("option_select")
			else:
				GameState.trigger_dialogue("AUDITOR", "Valve is seized! Tap [E] repeatedly to force it! (" + str(blowdown_mash_count) + "/10)")
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
	lbl.visibility_range_end = 80.0
	lbl.visibility_range_end_margin = 15.0
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
					"situation_type": "lock",
					"title": "FINAL REGULATORY AUDIT DETERMINATION",
					"subline": "FINAL HHI: " + str(int(HHI.current_hhi)) + " | EVIDENCE: " + str(state.evidence) + "/6",
					"options": [
						{
							"letter": "A",
							"text": "FULL DISCLOSURE (Requires Evidence >= 4)",
							"desc": "Present comprehensive verified logs across bypass flow, creek DO, and cooling topology.",
							"tradeoff": "Maximum community trust and compliance rating; modest SLA fine; keeps facility open.",
							"preview": "Trust +20, SLA -10. Facility stays open.",
							"min_evidence": 4
						},
						{
							"letter": "B",
							"text": "PARTIAL DISCLOSURE (Audit Pressure < 60)",
							"desc": "Concede municipal meter gaps while omitting creek discharge severity.",
							"tradeoff": "Facility survives with minimal penalties, but leaves creek ecology damaged.",
							"preview": "Facility survives. Creek issue unresolved.",
							"max_pressure": 60
						},
						{
							"letter": "C",
							"text": "WHISTLEBLOW (Requires Evidence >= 5)",
							"desc": "Hand entire evidentiary dossier over to the public press and state regulator.",
							"tradeoff": "Facility faces total statutory shutdown, ensuring ultimate environmental justice.",
							"preview": "Trust +30, SLA → 0. Total transparency.",
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
	var lvl = GameState.current_level
	
	# LEVEL-SPECIFIC LIGHTING OVERHAUL:
	match lvl:
		1:
			# Level 1 (16:30): warm directional #FFC87A, energy 1.1, rotation (-35, 20, 0)
			if sun_light:
				sun_light.visible = true
				sun_light.light_color = Color("#FFC87A")
				sun_light.light_energy = 1.1
				sun_light.rotation_degrees = Vector3(-35, 20, 0)
			if world_env and world_env.environment:
				world_env.environment.ambient_light_energy = 0.4
				world_env.environment.ambient_light_color = Color("#2A3A4A")
			for fl in floodlights: fl.light_energy = 0.0
			for sl in street_lamps: sl.light_energy = 0.0
			for el in red_emergency_lights: el.light_energy = 0.0
			if rain_particles: rain_particles.emitting = false
			if canal_fumes: canal_fumes.emitting = false
		2:
			# Level 2 (19:00): sun to -10 degrees (near horizon), color #FF6030, 4 floodlights at fence corners
			if sun_light:
				sun_light.visible = true
				sun_light.light_color = Color("#FF6030")
				sun_light.light_energy = 0.8
				sun_light.rotation_degrees = Vector3(-10, 20, 0)
			for fl in floodlights: fl.light_energy = 1.5
			for sl in street_lamps: sl.light_energy = 0.0
			if rain_particles: rain_particles.emitting = false
			if canal_fumes: canal_fumes.emitting = false
		3:
			# Level 3 (23:00): sun off, moon = weak directional #8090B0, energy 0.15; street lamps every 20m along roads #FFA020, range 12, energy 0.6
			if sun_light:
				sun_light.visible = true
				sun_light.light_color = Color("#8090B0")
				sun_light.light_energy = 0.15
				sun_light.rotation_degrees = Vector3(-65, 45, 0)
			for fl in floodlights: fl.light_energy = 0.5
			for sl in street_lamps: sl.light_energy = 0.6
			for el in red_emergency_lights: el.light_energy = 0.0
			if rain_particles: rain_particles.emitting = true
			if canal_fumes: canal_fumes.emitting = true
		4:
			# Level 4 (03:00): same as Level 3, fewer lights, more shadow pools
			if sun_light:
				sun_light.visible = true
				sun_light.light_color = Color("#8090B0")
				sun_light.light_energy = 0.12
				sun_light.rotation_degrees = Vector3(-75, 45, 0)
			for fl in floodlights: fl.light_energy = 0.2
			for idx in range(street_lamps.size()):
				street_lamps[idx].light_energy = 0.4 if (idx % 2 == 0) else 0.0
			for el in red_emergency_lights: el.light_energy = 0.0
			if rain_particles: rain_particles.emitting = true
			if canal_fumes: canal_fumes.emitting = false
		5:
			# Level 5 (06:05): sun rises from east, lerp from #FF4010 to #FFB347 to #87CEEB over 90 seconds
			level5_sunrise_timer = 0.0
			if sun_light:
				sun_light.visible = true
				sun_light.light_color = Color("#FF4010")
				sun_light.light_energy = 0.9
				sun_light.rotation_degrees = Vector3(-10, 90, 0)
			for fl in floodlights: fl.light_energy = 0.0
			for sl in street_lamps: sl.light_energy = 0.2
			for el in red_emergency_lights: el.light_energy = 0.0
			if rain_particles: rain_particles.emitting = false
			if canal_fumes: canal_fumes.emitting = false

func toggle_thermal_view(active: bool) -> void:
	if bypass_pipe_mesh and bypass_pipe_mesh.material_override:
		if active:
			bypass_pipe_mesh.material_override.albedo_color = Color("#FF6600")
		else:
			bypass_pipe_mesh.material_override.albedo_color = Color("#333A42")
