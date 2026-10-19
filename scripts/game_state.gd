class_name GameStateManager
extends Node

signal state_updated
signal dialogue_triggered(speaker: String, text: String, color: Color)
signal evidence_added(count: int, title: String)
signal game_over_triggered(reason: String, subtext: String)
signal level_completed(level: int)
signal world_transition_started(duration: float)
signal context_hint_requested(text: String, duration: float)

signal screen_shake_requested(intensity: float, duration: float)
signal screen_flash_requested(flash_type: String)
signal particle_requested(particle_type: String, world_pos: Vector3)

func request_screen_shake(intensity: float, duration: float) -> void:
	emit_signal("screen_shake_requested", intensity, duration)

func request_screen_flash(flash_type: String) -> void:
	emit_signal("screen_flash_requested", flash_type)

func request_particle(particle_type: String, world_pos: Vector3 = Vector3.ZERO) -> void:
	emit_signal("particle_requested", particle_type, world_pos)

# Onboarding & Controls state
var controls_seen: bool = false
var shown_hints: Dictionary = {}

# Persistent State Variables
var sla: float = 100.0
var trust: float = 30.0
var evidence: int = 0:
	set(val):
		var prev = evidence
		evidence = clampi(val, 0, 6)
		budget = clampi(100 + (evidence * 5), 100, 130)
		if evidence > prev:
			emit_signal("evidence_added", evidence, "Evidence Documented")
			request_screen_shake(2.0, 0.15)
			request_screen_flash("evidence")
			request_particle("evidence_collect", Vector3.ZERO)
			if AudioEngine: AudioEngine.play_sfx("evidence_collect")
		emit_signal("state_updated")
var budget: int = 100
var pressure: float = 0.0:
	set(val):
		pressure = clampf(val, 0.0, 100.0)
		emit_signal("state_updated")
		if pressure >= 100.0:
			trigger_game_over("AUDIT SHUTDOWN", "REGULATORY AUDIT PRESSURE REACHED MAXIMUM")

# Specialist Data
var selected_specialist: String = "VOLT" # VOLT, ANANYA, TARA

const SPECIALISTS = {
	"VOLT": {
		"name": "KABIR 'VOLT' RAO",
		"role": "Senior Power Systems Engineer",
		"tool_name": "Thermal View",
		"tool_desc": "Highlights hot pipes, overheating components, and heat signatures",
		"upside": "Heat clock in Level 2 runs 20% slower",
		"downside": "Cannot collect water samples (no kit)",
		"accent": Color("#F0A500"),
		"stats": {"power": 80, "water": 30, "compliance": 50, "crisis": 70}
	},
	"ANANYA": {
		"name": "DR. ANANYA SEN",
		"role": "Environmental Compliance Officer",
		"tool_name": "Sample Kit",
		"tool_desc": "Reads TDS, temperature, and DO of water sources and pipes",
		"upside": "Water and creek evidence auto-tagged as verified",
		"downside": "Sprint speed is 10% slower",
		"accent": Color("#4A8F9E"),
		"stats": {"power": 20, "water": 90, "compliance": 80, "crisis": 50}
	},
	"TARA": {
		"name": "TARA 'ZERO' D'SOUZA",
		"role": "SCADA Specialist",
		"tool_name": "Remote Hack",
		"tool_desc": "Interact with consoles and read logs from up to 15m away",
		"upside": "Can access valve logs without physical proximity",
		"downside": "Each remote hack adds +5 Audit Pressure",
		"accent": Color("#4A7C59"),
		"stats": {"power": 40, "water": 80, "compliance": 60, "crisis": 40}
	}
}

# Level State
var current_level: int = 1
var in_game_clock: String = "16:30"
var level_name: String = "LEVEL 1 — METER 4"

const LEVEL_CONFIGS = {
	0: {"clock": "15:00", "name": "TUTORIAL — ONBOARDING"},
	1: {"clock": "16:30", "name": "LEVEL 1 — METER 4"},
	2: {"clock": "19:00", "name": "LEVEL 2 — EIGHTY-FIVE"},
	3: {"clock": "23:00", "name": "LEVEL 3 — BLOWDOWN"},
	4: {"clock": "03:00", "name": "LEVEL 4 — REBUILD"},
	5: {"clock": "06:05", "name": "LEVEL 5 — DAWN AUDIT"}
}

# Timers
var scramble_timer: float = 0.0
var scramble_active: bool = false

var sump_timer: float = 0.0
var sump_active: bool = false

var heat_clock_val: float = 71.5
var heat_clock_active: bool = false
var heat_fail_timer: float = 0.0

# Decisions Record
var decisions_history: Array = []
var evidence_collected: Dictionary = {}
var field_notes_found: Array = []
var is_game_over: bool = false

func _ready() -> void:
	init_input_map()
	reset_game()

func init_input_map() -> void:
	var actions = {
		"move_forward": [KEY_W, KEY_UP],
		"move_backward": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"sprint": [KEY_SHIFT],
		"interact": [KEY_E],
		"tool_action": [KEY_Q],
		"hint": [KEY_H],
		"toggle_map": [KEY_M],
		"dev_panel": [KEY_F1],
		"pause_menu": [KEY_ESCAPE],
		"skip_action": [KEY_SPACE]
	}
	for act in actions:
		if not InputMap.has_action(act):
			InputMap.add_action(act)
		for key in actions[act]:
			var ev = InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(act, ev)

func reset_game() -> void:
	sla = 100.0
	trust = 30.0
	evidence = 0
	budget = 100
	pressure = 0.0
	current_level = 1
	scramble_active = false
	scramble_timer = 0.0
	sump_active = false
	sump_timer = 0.0
	heat_clock_active = false
	heat_fail_timer = 0.0
	is_game_over = false
	decisions_history.clear()
	evidence_collected.clear()
	set_level(1)

func set_level(lvl: int) -> void:
	current_level = lvl
	if LEVEL_CONFIGS.has(lvl):
		in_game_clock = LEVEL_CONFIGS[lvl]["clock"]
		level_name = LEVEL_CONFIGS[lvl]["name"]
	emit_signal("state_updated")

func _process(delta: float) -> void:
	if is_game_over:
		return
		
	# Scramble Timer (Level 1 bypass closed)
	if scramble_active:
		scramble_timer -= delta
		if scramble_timer <= 0.0:
			scramble_active = false
			request_screen_shake(15.0, 1.0)
			request_screen_flash("damage")
			trigger_game_over("TOWER STARVATION", "COOLING SYSTEM COLLAPSE — SILICON OVERHEATED")
			
	# Sump Timer (Level 3 option C)
	if sump_active:
		sump_timer -= delta
		if sump_timer <= 0.0:
			sump_active = false
			request_screen_shake(12.0, 0.8)
			request_screen_flash("damage")
			trigger_game_over("SUMP OVERFLOW", "EFFLUENT RETENTION CAPACITY BREACHED")
			
	# Heat clock (Level 2)
	if heat_clock_active:
		var sim = get_node_or_null("/root/Simulation")
		var rate = 1.2
		if selected_specialist == "VOLT":
			rate *= 0.8 # 20% slower
		heat_clock_val += delta * rate
		if sim:
			sim.tj = heat_clock_val
			
		if heat_clock_val >= 90.0:
			heat_fail_timer += delta
			if heat_fail_timer >= 20.0:
				trigger_game_over("SILICON MELTDOWN", "FACILITY OFFLINE — CRITICAL THERMAL EVENT")
		else:
			heat_fail_timer = 0.0

func trigger_game_over(reason: String, subtext: String) -> void:
	if is_game_over:
		return
	is_game_over = true
	request_screen_shake(12.0, 0.8)
	request_screen_flash("damage")
	if AudioEngine: AudioEngine.play_sfx("game_over")
	emit_signal("game_over_triggered", reason, subtext)

func add_evidence_item(id: String, title: String) -> void:
	if not evidence_collected.has(id):
		evidence_collected[id] = true
		evidence += 1

func trigger_dialogue(speaker: String, text: String) -> void:
	var color = Color("#4A8F9E") # Meera teal
	if speaker.to_upper().contains("ROHAN"):
		color = Color("#D9534F") # Rohan red-orange
	elif speaker.to_upper().contains("KULKARNI"):
		color = Color("#F0A500") # Inspector amber
	elif speaker.to_upper().contains("SUNITA"):
		color = Color("#88C0D0") # Sunita tai soft blue
	emit_signal("dialogue_triggered", speaker, text, color)

func start_world_transition(duration: float = 6.0) -> void:
	emit_signal("world_transition_started", duration)

const SAVE_PATH = "user://savegame.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var data = {
		"level": current_level,
		"specialist": selected_specialist,
		"sla": sla,
		"trust": trust,
		"evidence": evidence,
		"budget": budget,
		"pressure": pressure,
		"field_notes": field_notes_found
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_game() -> bool:
	if not has_save():
		return false
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(content) == OK and json.data is Dictionary:
		var d = json.data
		current_level = d.get("level", 1)
		selected_specialist = d.get("specialist", "VOLT")
		sla = d.get("sla", 100.0)
		trust = d.get("trust", 30.0)
		evidence = d.get("evidence", 0)
		budget = d.get("budget", 100)
		pressure = d.get("pressure", 0.0)
		field_notes_found = d.get("field_notes", [])
		emit_signal("state_updated")
		return true
	return false

func trigger_context_hint(hint_id: String, text: String, duration: float = 3.0) -> void:
	if shown_hints.has(hint_id):
		return
	shown_hints[hint_id] = true
	emit_signal("context_hint_requested", text, duration)

