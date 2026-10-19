class_name AudioEngineAutoload
extends Node

# Real-time DSP procedural audio synthesis via AudioStreamGenerator
# Zero external audio files

var is_muted: bool = false
var audio_started: bool = false
var master_volume: float = 0.7
var bgm_duck_factor: float = 1.0
var bgm_duck_timer: float = 0.0

var bgm_player: AudioStreamPlayer
var bgm_playback: AudioStreamGeneratorPlayback
var sfx_player: AudioStreamPlayer
var sfx_playback: AudioStreamGeneratorPlayback

var current_bgm_mode: String = "TITLE"
var bgm_time: float = 0.0
var active_sfx: Array = []

# Random night bark timer (30-90s)
var dog_bark_timer: float = 35.0

# Player location tracking for positional reactive layers
var player_pos: Vector3 = Vector3(0, 0, 50)
var is_inside_server_hall: bool = false
var is_near_creek: bool = false
var is_near_colony: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_audio_players()

func setup_audio_players() -> void:
	var bgm_stream = AudioStreamGenerator.new()
	bgm_stream.mix_rate = 22050
	bgm_stream.buffer_length = 0.15
	
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = bgm_stream
	bgm_player.volume_db = -3.0
	add_child(bgm_player)
	
	var sfx_stream = AudioStreamGenerator.new()
	sfx_stream.mix_rate = 22050
	sfx_stream.buffer_length = 0.15
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = sfx_stream
	sfx_player.volume_db = -1.0
	add_child(sfx_player)
	
	bgm_player.play()
	bgm_playback = bgm_player.get_stream_playback()
	
	sfx_player.play()
	sfx_playback = sfx_player.get_stream_playback()
	
	audio_started = true

func _input(event: InputEvent) -> void:
	if not audio_started:
		if event is InputEventKey or event is InputEventMouseButton:
			audio_started = true

func toggle_mute() -> bool:
	is_muted = !is_muted
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), is_muted)
	return is_muted

func set_bgm_level(level: int) -> void:
	match level:
		0, 1: current_bgm_mode = "LEVEL1"
		2: current_bgm_mode = "LEVEL2"
		3: current_bgm_mode = "LEVEL3"
		4: current_bgm_mode = "LEVEL4"
		5: current_bgm_mode = "LEVEL5"
		_: current_bgm_mode = "TITLE"

func duck_bgm(factor: float = 0.4, duration: float = 0.5) -> void:
	bgm_duck_factor = factor
	bgm_duck_timer = duration

func _process(delta: float) -> void:
	if is_muted or not audio_started:
		return
		
	# BGM Ducking decay
	if bgm_duck_timer > 0.0:
		bgm_duck_timer -= delta
		if bgm_duck_timer <= 0.0:
			bgm_duck_factor = 1.0
			
	# Update player location context
	update_player_context()
	
	# Random dog bark in night levels (3, 4)
	var state = get_node_or_null("/root/GameState")
	if state and (state.current_level == 3 or state.current_level == 4):
		dog_bark_timer -= delta
		if dog_bark_timer <= 0.0:
			dog_bark_timer = randf_range(30.0, 90.0)
			play_sfx("dog_bark")
			
	bgm_time += delta
	generate_bgm_samples()
	generate_sfx_samples(delta)

func update_player_context() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_pos = players[0].global_position
		# Inside Server Hall A: x -45..-15, z -45..-5
		is_inside_server_hall = (player_pos.x >= -46.0 and player_pos.x <= -14.0 and player_pos.z >= -46.0 and player_pos.z <= -4.0)
		# Near Creek: x > 55
		is_near_creek = (player_pos.x > 54.0)
		# Near Colony: z > 68
		is_near_colony = (player_pos.z > 68.0)

# BGM Waveform generation with multi-layer reactive DSP
func generate_bgm_samples() -> void:
	if not bgm_playback:
		return
		
	var frames_to_fill = bgm_playback.get_frames_available()
	if frames_to_fill <= 0:
		return
		
	var dt = 1.0 / 22050.0
	var sim = get_node_or_null("/root/Simulation")
	var state = get_node_or_null("/root/GameState")
	var hhi_node = get_node_or_null("/root/HHI")
	var hhi_val = 38.0
	if hhi_node:
		hhi_val = hhi_node.current_hhi
		
	for i in range(frames_to_fill):
		bgm_time += dt
		var sample: float = 0.0
		
		# --- BASE LEVEL LAYERS ---
		match current_bgm_mode:
			"TITLE":
				# Slow ambient chord (C2, E2, G2, B2) + 40Hz sub + gentle noise
				var s1 = sin(TAU * 65.4 * bgm_time) * 0.12
				var s2 = sin(TAU * 82.4 * bgm_time * 1.002) * 0.10
				var s3 = sin(TAU * 98.0 * bgm_time * 0.998) * 0.10
				var s4 = sin(TAU * 123.5 * bgm_time) * 0.08
				var sub = sin(TAU * 40.0 * bgm_time) * 0.15
				sample = (s1 + s2 + s3 + s4 + sub) * 0.5
				
			"LEVEL1":
				# 60Hz drone + industrial hiss (filtered noise)
				var drone = sin(TAU * 60.0 * bgm_time) * 0.22
				var sub = sin(TAU * 30.0 * bgm_time) * 0.12
				var hiss = (randf() * 2.0 - 1.0) * 0.035 * (0.6 + 0.4 * sin(TAU * 0.5 * bgm_time))
				sample = (drone + sub + hiss) * 0.55
				
			"LEVEL2":
				# Minor chord swell (A minor: A2=110Hz, C3=130.8Hz, E3=164.8Hz)
				var swell = 0.5 + 0.5 * sin(TAU * 0.3 * bgm_time)
				var a2 = sin(TAU * 110.0 * bgm_time) * 0.15
				var c3 = sin(TAU * 130.8 * bgm_time) * 0.12
				var e3 = sin(TAU * 164.8 * bgm_time) * 0.12
				sample = (a2 + c3 + e3) * swell * 0.55
				
			"LEVEL3":
				# Low sub pulse 55Hz + eerie shimmer 2200Hz
				var pulse_env = max(0.0, sin(TAU * 1.0 * bgm_time))
				var sub55 = sin(TAU * 55.0 * bgm_time) * 0.25 * pulse_env
				var shimmer = sin(TAU * 2200.0 * bgm_time) * 0.028 * (0.7 + 0.3 * sin(TAU * 3.0 * bgm_time))
				sample = (sub55 + shimmer) * 0.55
				
			"LEVEL4":
				# Near silence, 432Hz tone every 4s (2s sound, 2s silence)
				var cycle = fmod(bgm_time, 4.0)
				var tone = 0.0
				if cycle < 2.0:
					var env = sin(PI * (cycle / 2.0))
					tone = sin(TAU * 432.0 * bgm_time) * env * 0.14
				var sub = sin(TAU * 35.0 * bgm_time) * 0.04
				sample = (tone + sub) * 0.45
				
			"LEVEL5":
				# Sunrise arpeggio
				if hhi_val >= 85.0:
					var trem = 0.8 + 0.2 * sin(TAU * 4.0 * bgm_time)
					var c = (sin(TAU * 261.6 * bgm_time) + sin(TAU * 329.6 * bgm_time) + sin(TAU * 392.0 * bgm_time)) * 0.12 * trem
					sample = c * 0.65
				elif hhi_val >= 65.0:
					var trem = 0.8 + 0.2 * sin(TAU * 2.0 * bgm_time)
					var c = (sin(TAU * 260.0 * bgm_time) + sin(TAU * 327.0 * bgm_time) + sin(TAU * 390.0 * bgm_time)) * 0.12 * trem
					sample = c * 0.65
				else:
					var step_idx = int(fmod(bgm_time / 2.0, 4.0))
					var freqs = [130.8, 116.5, 103.8, 98.0]
					var f = freqs[step_idx]
					var env = 1.0 - (fmod(bgm_time, 2.0) / 2.0)
					sample = sin(TAU * f * bgm_time) * env * 0.22
		
		# --- REACTIVE LAYERS ADDED ON TOP ---
		
		# 1. HHI drops below 50: +180Hz alarm tone pulse every 3s
		if hhi_val < 50.0:
			var alarm_phase = fmod(bgm_time, 3.0)
			if alarm_phase < 0.25:
				var alarm_env = sin(PI * (alarm_phase / 0.25))
				sample += sin(TAU * 180.0 * bgm_time) * alarm_env * 0.12
				
		# 2. Scramble timer active: +440Hz rapid pulse every 0.5s
		if state and state.scramble_active:
			var scr_phase = fmod(bgm_time, 0.5)
			if scr_phase < 0.15:
				var scr_env = 1.0 - (scr_phase / 0.15)
				sample += sin(TAU * 440.0 * bgm_time) * scr_env * 0.15
				
		# 3. Sump timer active: +220Hz slow pulse every 2s
		if state and state.sump_active:
			var sump_phase = fmod(bgm_time, 2.0)
			if sump_phase < 0.3:
				var sump_env = 1.0 - (sump_phase / 0.3)
				sample += sin(TAU * 220.0 * bgm_time) * sump_env * 0.14
				
		# 4. Inside Server Hall A: continuous fan whirr 800Hz bandpass
		if is_inside_server_hall:
			var fan_mod = sin(TAU * 28.0 * bgm_time) * 0.3 + 0.7
			var fan_whirr = sin(TAU * 800.0 * bgm_time) * 0.08 * fan_mod
			sample += fan_whirr
			
		# 5. Near creek: water noise bandpass 200–600Hz
		if is_near_creek:
			var water_noise = (randf() * 2.0 - 1.0) * 0.05 * (0.8 + 0.2 * sin(TAU * 4.0 * bgm_time))
			sample += water_noise
			
		# 6. Near colony: ambient crowd murmur (stacked sine waves 180–220Hz, 8 voices)
		if is_near_colony:
			var murmur = 0.0
			for v in range(8):
				var freq = 180.0 + v * 5.2
				murmur += sin(TAU * freq * bgm_time + v * 0.7) * 0.008
			sample += murmur
			
		# 7. Rain in Level 3 and 4: white noise bandpass 400–1200Hz, volume 0.15 (reacts to HHI)
		if state and (state.current_level == 3 or state.current_level == 4):
			var rain_intensity = clamp(1.0 - (hhi_val / 100.0) * 0.65, 0.2, 1.0)
			# Bandpass approximation with shaped white noise
			var rain_sample = (randf() * 2.0 - 1.0) * (sin(TAU * 800.0 * bgm_time) * 0.5 + 0.5)
			sample += rain_sample * 0.15 * rain_intensity
			
		# Apply master volume and ducking factor
		sample = clamp(sample * master_volume * bgm_duck_factor, -0.9, 0.9)
		bgm_playback.push_frame(Vector2(sample, sample))

# Dialogue Character Speech Voice Synthesizer
func play_dialogue_char(speaker: String) -> void:
	if is_muted: return
	var sp = speaker.to_upper()
	var sfx_obj = {"name": "dialogue_char", "time": 0.0, "duration": 0.05, "freq": 440.0, "type": "sine"}
	
	if sp.contains("MEERA"):
		sfx_obj["freq"] = 440.0
		sfx_obj["duration"] = 0.050 # 50ms warm clear
		sfx_obj["type"] = "sine"
	elif sp.contains("ROHAN"):
		sfx_obj["freq"] = 180.0
		sfx_obj["duration"] = 0.060 # 60ms overdrive
		sfx_obj["type"] = "overdrive"
	elif sp.contains("SUNITA"):
		sfx_obj["freq"] = 320.0
		sfx_obj["duration"] = 0.040 # 40ms tremolo
		sfx_obj["type"] = "tremolo"
	elif sp.contains("KULKARNI"):
		sfx_obj["freq"] = 280.0
		sfx_obj["duration"] = 0.070 # 70ms authoritative
		sfx_obj["type"] = "sine"
	elif sp.contains("VOLT"):
		sfx_obj["freq"] = 380.0
		sfx_obj["duration"] = 0.055 # 55ms
		sfx_obj["type"] = "sine"
	elif sp.contains("ANANYA"):
		sfx_obj["freq"] = 420.0
		sfx_obj["duration"] = 0.050 # 50ms clear
		sfx_obj["type"] = "sine"
	elif sp.contains("TARA"):
		sfx_obj["freq"] = 360.0
		sfx_obj["duration"] = 0.045 # 45ms slightly nervous
		sfx_obj["type"] = "tremolo"
	else:
		sfx_obj["freq"] = 400.0
		sfx_obj["duration"] = 0.050
		sfx_obj["type"] = "sine"
		
	active_sfx.append(sfx_obj)

# Footstep Synthesizer with indoor surface variation
func play_footstep(is_sprint: bool, is_inside: bool = false) -> void:
	if is_muted: return
	var foot_obj = {
		"name": "footstep",
		"time": 0.0,
		"duration": 0.08, # 80ms
		"is_inside": is_inside,
		"is_sprint": is_sprint
	}
	active_sfx.append(foot_obj)

# General Synthesized SFX Queue and Dispatcher
func play_sfx(sfx_name: String) -> void:
	if is_muted:
		return
	var sfx_obj = {"name": sfx_name, "time": 0.0, "duration": 0.5}
	match sfx_name:
		"decision_open": sfx_obj["duration"] = 0.24 # 880->660->440Hz, 80ms each
		"option_hover": sfx_obj["duration"] = 0.02  # 1200Hz, 20ms click
		"option_select": sfx_obj["duration"] = 0.20 # 660->880Hz sweep 200ms
		"confirm_decision": sfx_obj["duration"] = 0.30 # major chord hit C5 E5 G5 simultaneous 300ms
		"wrong_valve": sfx_obj["duration"] = 0.40   # 200->80Hz, 400ms slight distortion
		"correct_valve": sfx_obj["duration"] = 0.45 # 440->660->880Hz 150ms each in sequence
		"level_complete": sfx_obj["duration"] = 0.45# C5 E5 G5 arpeggio 150ms per note
		"game_over": sfx_obj["duration"] = 0.80     # C3 descending to G2 800ms
		"evidence_collect":
			sfx_obj["duration"] = 0.30 # 300->600Hz chirp 300ms
			duck_bgm(0.4, 0.5)         # volume duck BGM
		"beat_complete": sfx_obj["duration"] = 0.15 # 300->600Hz chirp shorter 150ms
		"interact_prompt": sfx_obj["duration"] = 0.03 # 1000Hz subtle click 30ms
		"ui_back": sfx_obj["duration"] = 0.15       # 440->330Hz sweep 150ms
		"menu_confirm": sfx_obj["duration"] = 0.20  # 660->880Hz 200ms
		"screen_transition": sfx_obj["duration"] = 0.10 # white noise burst 100ms
		"dog_bark": sfx_obj["duration"] = 0.080     # 440Hz drop 300->180Hz 80ms
		_: sfx_obj["duration"] = 0.1
		
	active_sfx.append(sfx_obj)

func generate_sfx_samples(delta: float) -> void:
	if not sfx_playback or active_sfx.is_empty():
		return
		
	var frames_to_fill = sfx_playback.get_frames_available()
	if frames_to_fill <= 0:
		return
		
	var dt = 1.0 / 22050.0
	
	for i in range(frames_to_fill):
		var total_sample: float = 0.0
		var to_remove: Array = []
		
		for sfx in active_sfx:
			sfx["time"] += dt
			var t: float = sfx["time"]
			var dur: float = sfx["duration"]
			var s: float = 0.0
			
			match sfx["name"]:
				"dialogue_char":
					var f = sfx.get("freq", 440.0)
					var type = sfx.get("type", "sine")
					var env = 1.0 - (t / dur)
					if type == "overdrive":
						var raw = sin(TAU * f * t) * 2.5
						s = clamp(raw, -0.3, 0.3) * env
					elif type == "tremolo":
						var trem = 0.6 + 0.4 * sin(TAU * 25.0 * t)
						s = sin(TAU * f * t) * trem * env * 0.3
					else:
						s = sin(TAU * f * t) * env * 0.3
						
				"footstep":
					var env = 1.0 - (t / dur)
					var thud = sin(TAU * 40.0 * t) * env * 0.35 # 40Hz thud
					if sfx.get("is_inside", false):
						var click = sin(TAU * 600.0 * t) * env * 0.15 # 600Hz click
						thud += click
					s = thud
					
				"dog_bark":
					# 440Hz drop 300->180Hz over 80ms
					var bark_f = lerp(300.0, 180.0, t / dur)
					var env = 1.0 - (t / dur)
					s = sin(TAU * bark_f * t) * env * 0.3
					
				"decision_open":
					# 880 -> 660 -> 440 (80ms each)
					var freq = 880.0
					if t > 0.16: freq = 440.0
					elif t > 0.08: freq = 660.0
					s = sin(TAU * freq * t) * (1.0 - (t / dur)) * 0.4
					
				"option_hover":
					# 1200Hz 20ms click sound
					s = sin(TAU * 1200.0 * t) * 0.25
					
				"option_select":
					# 660 -> 880Hz sweep 200ms
					var sweep_f = lerp(660.0, 880.0, t / dur)
					s = sin(TAU * sweep_f * t) * (1.0 - (t / dur)) * 0.4
					
				"confirm_decision":
					# Major chord hit C5 E5 G5 simultaneous 300ms
					var env = 1.0 - (t / dur)
					s = (sin(TAU * 523.25 * t) + sin(TAU * 659.25 * t) + sin(TAU * 783.99 * t)) * 0.15 * env
					
				"wrong_valve":
					# Jarring 200 -> 80Hz 400ms error tone
					var sweep_f = lerp(200.0, 80.0, t / dur)
					var raw = sin(TAU * sweep_f * t) * 2.2
					s = clamp(raw, -0.45, 0.45) * (1.0 - (t / dur))
					
				"correct_valve":
					# 440 -> 660 -> 880Hz, 150ms each
					var freq = 440.0
					if t > 0.30: freq = 880.0
					elif t > 0.15: freq = 660.0
					var sub_t = fmod(t, 0.15)
					s = sin(TAU * freq * t) * (1.0 - (sub_t / 0.15)) * 0.4
					
				"level_complete":
					var freq = 523.25 # C5
					if t > 0.30: freq = 783.99 # G5
					elif t > 0.15: freq = 659.25 # E5
					var sub_t = fmod(t, 0.15)
					s = sin(TAU * freq * t) * (1.0 - (sub_t / 0.15)) * 0.4
					
				"game_over":
					# C3 (130.8) descending to G2 (98.0) 800ms
					var sweep_f = lerp(130.8, 98.0, t / dur)
					s = sin(TAU * sweep_f * t) * (1.0 - (t / dur)) * 0.5
					
				"evidence_collect":
					# Bright 300 -> 600Hz chirp
					var sweep_f = lerp(300.0, 600.0, t / dur)
					s = sin(TAU * sweep_f * t) * (1.0 - (t / dur)) * 0.4
					
				"beat_complete":
					# Shorter 300 -> 600Hz chirp 150ms
					var sweep_f = lerp(300.0, 600.0, t / dur)
					s = sin(TAU * sweep_f * t) * (1.0 - (t / dur)) * 0.4
					
				"interact_prompt":
					s = sin(TAU * 1000.0 * t) * (1.0 - (t / dur)) * 0.2
					
				"ui_back":
					# 440 -> 330Hz sweep 150ms
					var sweep_f = lerp(440.0, 330.0, t / dur)
					s = sin(TAU * sweep_f * t) * (1.0 - (t / dur)) * 0.35
					
				"menu_confirm":
					# 660 -> 880Hz 200ms sweep
					var sweep_f = lerp(660.0, 880.0, t / dur)
					s = sin(TAU * sweep_f * t) * (1.0 - (t / dur)) * 0.4
					
				"screen_transition":
					# White noise burst 100ms fading
					s = (randf() * 2.0 - 1.0) * (1.0 - (t / dur)) * 0.25
					
			total_sample += s
			if t >= dur:
				to_remove.append(sfx)
				
		for r in to_remove:
			active_sfx.erase(r)
			
		total_sample = clamp(total_sample * master_volume, -0.9, 0.9)
		sfx_playback.push_frame(Vector2(total_sample, total_sample))
