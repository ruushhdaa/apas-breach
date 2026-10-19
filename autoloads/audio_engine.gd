class_name AudioEngineAutoload
extends Node

# Audio Engine synthesizing all sound in real-time via AudioStreamGenerator
# Zero external audio files

var is_muted: bool = false
var audio_started: bool = false
var master_volume: float = 0.7

var bgm_player: AudioStreamPlayer
var bgm_playback: AudioStreamGeneratorPlayback
var sfx_player: AudioStreamPlayer
var sfx_playback: AudioStreamGeneratorPlayback

var current_bgm_mode: String = "TITLE"
var bgm_time: float = 0.0
var sfx_queue: Array = []
var active_sfx: Array = []

# Footstep timing
var footstep_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_audio_players()

func setup_audio_players() -> void:
	# BGM Generator
	var bgm_stream = AudioStreamGenerator.new()
	bgm_stream.mix_rate = 22050
	bgm_stream.buffer_length = 0.15
	
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = bgm_stream
	bgm_player.volume_db = -4.0
	add_child(bgm_player)
	
	# SFX Generator
	var sfx_stream = AudioStreamGenerator.new()
	sfx_stream.mix_rate = 22050
	sfx_stream.buffer_length = 0.15
	
	sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = sfx_stream
	sfx_player.volume_db = -2.0
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
		0: current_bgm_mode = "LEVEL1"
		1: current_bgm_mode = "LEVEL1"
		2: current_bgm_mode = "LEVEL2"
		3: current_bgm_mode = "LEVEL3"
		4: current_bgm_mode = "LEVEL4"
		5: current_bgm_mode = "LEVEL5"
		_: current_bgm_mode = "TITLE"

func _process(delta: float) -> void:
	if is_muted or not audio_started:
		return
		
	bgm_time += delta
	generate_bgm_samples()
	generate_sfx_samples(delta)

# BGM Waveform generation
func generate_bgm_samples() -> void:
	if not bgm_playback:
		return
		
	var frames_to_fill = bgm_playback.get_frames_available()
	if frames_to_fill <= 0:
		return
		
	var dt = 1.0 / 22050.0
	var sim = get_node_or_null("/root/Simulation")
	var hhi_node = get_node_or_null("/root/HHI")
	var hhi_val = 38.0
	if hhi_node:
		hhi_val = hhi_node.current_hhi
		
	for i in range(frames_to_fill):
		bgm_time += dt
		var sample: float = 0.0
		
		match current_bgm_mode:
			"TITLE":
				# Slow pad: four-note chord (C2=65.4, E2=82.4, G2=98.0, B2=123.5) + 40Hz sub + noise
				var s1 = sin(TAU * 65.4 * bgm_time) * 0.12
				var s2 = sin(TAU * 82.4 * bgm_time * 1.002) * 0.10
				var s3 = sin(TAU * 98.0 * bgm_time * 0.998) * 0.10
				var s4 = sin(TAU * 123.5 * bgm_time) * 0.08
				var sub = sin(TAU * 40.0 * bgm_time) * 0.15
				var n = (randf() * 2.0 - 1.0) * 0.03 * (0.5 + 0.5 * sin(TAU * 0.2 * bgm_time))
				sample = (s1 + s2 + s3 + s4 + sub + n) * 0.4
				
			"LEVEL1":
				# 60Hz sine drone + 0.1Hz LFO sweep + occasional ping
				var lfo = 0.5 + 0.5 * sin(TAU * 0.1 * bgm_time)
				var drone = sin(TAU * 60.0 * bgm_time) * 0.3 * lfo
				var sub = sin(TAU * 30.0 * bgm_time) * 0.15
				sample = (drone + sub) * 0.6
				
			"LEVEL2":
				# Minor third tension (220Hz + 261Hz) + 0.8Hz LFO + staccato 110Hz pulse every 1.2s
				var lfo = 0.5 + 0.5 * sin(TAU * 0.8 * bgm_time)
				var m3 = (sin(TAU * 220.0 * bgm_time) + sin(TAU * 261.0 * bgm_time)) * 0.15 * lfo
				var pulse_phase = fmod(bgm_time, 1.2)
				var pulse = 0.0
				if pulse_phase < 0.15:
					pulse = sin(TAU * 110.0 * bgm_time) * (1.0 - pulse_phase / 0.15) * 0.25
				sample = (m3 + pulse) * 0.6
				
			"LEVEL3":
				# Sub pulse 55Hz every 0.5s + distorted saw 180Hz + shimmer 2200Hz
				var pulse_phase = fmod(bgm_time, 0.5)
				var sub_pulse = sin(TAU * 55.0 * bgm_time) * (1.0 - pulse_phase / 0.5) * 0.25
				var saw_val = fmod(bgm_time * 180.0, 1.0) * 2.0 - 1.0
				var saw_distorted = clamp(saw_val * 2.0, -0.15, 0.15)
				var shimmer = sin(TAU * 2200.0 * bgm_time) * 0.03
				sample = (sub_pulse + saw_distorted + shimmer) * 0.6
				
			"LEVEL4":
				# Sparse: 432Hz sine every 4s (2s sound, 2s silence) + 30Hz sub
				var cycle = fmod(bgm_time, 4.0)
				var tone = 0.0
				if cycle < 2.0:
					var env = sin(PI * (cycle / 2.0))
					tone = sin(TAU * 432.0 * bgm_time) * env * 0.15
				var sub = sin(TAU * 30.0 * bgm_time) * 0.05
				sample = (tone + sub) * 0.5
				
			"LEVEL5":
				if hhi_val >= 85.0:
					# Open major chord C4(261.6), E4(329.6), G4(392.0) with 4Hz tremolo
					var trem = 0.8 + 0.2 * sin(TAU * 4.0 * bgm_time)
					var c = (sin(TAU * 261.6 * bgm_time) + sin(TAU * 329.6 * bgm_time) + sin(TAU * 392.0 * bgm_time)) * 0.12 * trem
					sample = c * 0.7
				elif hhi_val >= 65.0:
					var trem = 0.8 + 0.2 * sin(TAU * 2.0 * bgm_time)
					var c = (sin(TAU * 260.0 * bgm_time) + sin(TAU * 327.0 * bgm_time) + sin(TAU * 390.0 * bgm_time)) * 0.12 * trem
					sample = c * 0.7
				else:
					# Minor arpeggio C3(130.8), Bb2(116.5), Ab2(103.8), G2(98.0)
					var step_idx = int(fmod(bgm_time / 3.0, 4.0))
					var freqs = [130.8, 116.5, 103.8, 98.0]
					var f = freqs[step_idx]
					var env = 1.0 - (fmod(bgm_time, 3.0) / 3.0)
					sample = sin(TAU * f * bgm_time) * env * 0.25
					
		# Layer ambient HHI texture
		if hhi_val >= 85.0:
			sample += (randf() * 2.0 - 1.0) * 0.02 # water noise
		elif hhi_val < 25.0:
			# 880Hz klaxon pulse
			if fmod(bgm_time, 1.0) < 0.3:
				sample += sin(TAU * 880.0 * bgm_time) * 0.15
				
		sample = clamp(sample * master_volume, -0.9, 0.9)
		bgm_playback.push_frame(Vector2(sample, sample))

# Synthesized SFX Queue and Dispatcher
func play_sfx(sfx_name: String) -> void:
	if is_muted:
		return
	var sfx_obj = {"name": sfx_name, "time": 0.0, "duration": 0.5}
	match sfx_name:
		"decision_open": sfx_obj["duration"] = 0.24 # 880->660->440Hz, 80ms each
		"option_hover": sfx_obj["duration"] = 0.02  # 1200Hz, 20ms
		"option_select": sfx_obj["duration"] = 0.20 # 660->880Hz sweep, 200ms
		"wrong_valve": sfx_obj["duration"] = 0.40   # 200->80Hz, 400ms
		"level_complete": sfx_obj["duration"] = 0.45# C5 E5 G5, 150ms each
		"game_over": sfx_obj["duration"] = 0.80     # C3->G2 descending, 800ms
		"evidence_collect": sfx_obj["duration"] = 0.30 # 300->600Hz chirp
		"interact_prompt": sfx_obj["duration"] = 0.03 # 1000Hz click
		"rohan_dialogue": sfx_obj["duration"] = 0.06  # 180Hz, distorted
		"meera_dialogue": sfx_obj["duration"] = 0.06  # 440Hz warm
		"walk_footstep": sfx_obj["duration"] = 0.08   # 40Hz thud
		"sprint_footstep": sfx_obj["duration"] = 0.08 # 40Hz thud
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
				"decision_open":
					# 880 -> 660 -> 440 (80ms each)
					var freq = 880.0
					if t > 0.16: freq = 440.0
					elif t > 0.08: freq = 660.0
					s = sin(TAU * freq * t) * (1.0 - (t / dur)) * 0.4
					
				"option_hover":
					s = sin(TAU * 1200.0 * t) * 0.25
					
				"option_select":
					var sweep_f = lerp(660.0, 880.0, t / dur)
					s = sin(TAU * sweep_f * t) * (1.0 - (t / dur)) * 0.4
					
				"wrong_valve":
					var sweep_f = lerp(200.0, 80.0, t / dur)
					var raw = sin(TAU * sweep_f * t) * 1.5
					s = clamp(raw, -0.4, 0.4) * (1.0 - (t / dur))
					
				"level_complete":
					var freq = 523.25 # C5
					if t > 0.30: freq = 783.99 # G5
					elif t > 0.15: freq = 659.25 # E5
					var sub_t = fmod(t, 0.15)
					s = sin(TAU * freq * t) * (1.0 - (sub_t / 0.15)) * 0.4
					
				"game_over":
					var sweep_f = lerp(130.8, 98.0, t / dur)
					s = sin(TAU * sweep_f * t) * (1.0 - (t / dur)) * 0.5
					
				"evidence_collect":
					var sweep_f = lerp(300.0, 600.0, t / dur)
					s = sin(TAU * sweep_f * t) * (1.0 - (t / dur)) * 0.4
					
				"interact_prompt":
					s = sin(TAU * 1000.0 * t) * (1.0 - (t / dur)) * 0.2
					
				"rohan_dialogue":
					var raw = sin(TAU * 180.0 * t) * 2.0
					s = clamp(raw, -0.3, 0.3) * (1.0 - (t / dur))
					
				"meera_dialogue":
					s = sin(TAU * 440.0 * t) * (1.0 - (t / dur)) * 0.3
					
				"walk_footstep", "sprint_footstep":
					s = sin(TAU * 40.0 * t) * (1.0 - (t / dur)) * 0.35
					
			total_sample += s
			if t >= dur:
				to_remove.append(sfx)
				
		for r in to_remove:
			active_sfx.erase(r)
			
		total_sample = clamp(total_sample * master_volume, -0.9, 0.9)
		sfx_playback.push_frame(Vector2(total_sample, total_sample))
