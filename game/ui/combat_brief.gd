extends Control

signal launch_requested
signal dismissed

func _ready() -> void:
	visible = false
	$Panel/VBox/Buttons/LaunchButton.pressed.connect(func() -> void: launch_requested.emit())
	$Panel/VBox/Buttons/CloseButton.pressed.connect(func() -> void: dismissed.emit())

func present(state: CampaignState) -> void:
	var lines: Array[String] = []
	if state.pending_combat:
		lines.append("Hostile contact closing. Launch interceptor.")
	lines.append("Last engagement:")
	lines.append(str(state.last_result))
	$Panel/VBox/Info.text = "\n".join(lines)
	$Panel/VBox/Buttons/LaunchButton.visible = state.pending_combat
	visible = true
