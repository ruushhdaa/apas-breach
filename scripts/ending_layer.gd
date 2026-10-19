class_name EndingLayerController
extends CanvasLayer

@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var outcome_title: Label = $CenterContainer/PanelContainer/VBox/OutcomeTitle
@onready var narrative_text: Label = $CenterContainer/PanelContainer/VBox/NarrativeText
@onready var score_label: Label = $CenterContainer/PanelContainer/VBox/ScoreLabel
@onready var stats_label: Label = $CenterContainer/PanelContainer/VBox/StatsLabel
@onready var summary_label: Label = $CenterContainer/PanelContainer/VBox/SummaryLabel
@onready var restart_button: Button = $CenterContainer/PanelContainer/VBox/HBoxButtons/RestartButton
@onready var credits_button: Button = $CenterContainer/PanelContainer/VBox/HBoxButtons/CreditsButton

func _ready() -> void:
	visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	credits_button.pressed.connect(_on_credits_pressed)

func display_ending(tier: String, score: float, hhi: float, _final_option: String) -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	outcome_title.text = "OUTCOME: " + tier
	
	match tier:
		"RESTORED":
			outcome_title.modulate = Color("#44DD66")
			narrative_text.text = "The creek is blue. The colony has water.\nThe facility is running clean.\nYou did something real tonight."
		"STRAINED":
			outcome_title.modulate = Color("#E0A020")
			narrative_text.text = "The numbers are better. Not good.\nThe creek will recover. Eventually."
		"BREACH":
			outcome_title.modulate = Color("#F06030")
			narrative_text.text = "The facility passed the audit. The creek didn't.\nThe tankers are still queuing."
		_: # COLLAPSE
			outcome_title.modulate = Color("#DD3322")
			narrative_text.text = "The facility is offline. The creek is black.\nThe colony is still waiting."
			
	score_label.text = "FINAL COMPOSITE SCORE: %.1f / 100\nFINAL HHI: %.1f (%s)" % [score, hhi, tier]
	
	var sim = get_node_or_null("/root/Simulation")
	var p_mld = 2.50
	var pue_v = 1.15
	var tj_v = 71.5
	var creek_v = 35.0
	if sim:
		p_mld = sim.potable_mld
		pue_v = sim.pue
		tj_v = sim.tj
		creek_v = sim.creek_health_pct
		
	stats_label.text = "Potable Draw: %.2f MLD | PUE: %.3f | Silicon Tj: %.1f °C | Creek Health: %.0f%%\nCommunity Trust: %.0f | Audit Pressure: %.0f | Evidence Collected: %d/6" % [
		p_mld, pue_v, tj_v, creek_v, GameState.trust, GameState.pressure, GameState.evidence
	]
	
	var summary_str = "Decisions Executed: "
	for item in GameState.decisions_history:
		summary_str += "[%s: %s] " % [item["card"].replace("LEVEL", "L"), item["option"]]
	summary_label.text = summary_str

func _on_restart_pressed() -> void:
	GameState.reset_game()
	get_tree().change_scene_to_file("res://scenes/dispatch_screen.tscn")

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/credits.tscn")
