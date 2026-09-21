extends Control

signal launch_requested
signal dismissed

var info_label: Label
var launch_btn: Button

func _ready() -> void:
	visible = false
	info_label = $Panel/VBox/Info
	launch_btn = $Panel/VBox/Buttons/LaunchButton
	launch_btn.pressed.connect(func() -> void: launch_requested.emit())
	$Panel/VBox/Buttons/CloseButton.pressed.connect(func() -> void: dismissed.emit())

func present(state: CampaignState) -> void:
	if state == null or not state.pending_combat:
		visible = false
		return
	var lines: Array[String] = []
	lines.append("Long-range sensors hold a hard return on an intercept vector.")
	lines.append("The contact mirrors every course change Asteria makes.")
	lines.append("")
	lines.append("Readiness %.0f%% · Hull %.0f%% · Population %d" % [
		float(state.resources.readiness), float(state.resources.hull), state.population])
	lines.append("")
	lines.append("If they reach the hull, compartments burn. Launch the interceptor.")
	info_label.text = "\n".join(lines)
	launch_btn.visible = true
	visible = true
