extends Control

signal launch_requested
signal dismissed

var info_label: Label
var launch_btn: Button
var scope: SensorScope = null
var _t: float = 0.0
var _tween: Tween = null

func _ready() -> void:
	visible = false
	info_label = $Panel/VBox/Info
	launch_btn = $Panel/VBox/Buttons/LaunchButton
	launch_btn.pressed.connect(func() -> void: launch_requested.emit())
	$Panel/VBox/Buttons/CloseButton.pressed.connect(func() -> void: dismissed.emit())
	scope = SensorScope.new()
	scope.custom_minimum_size = Vector2(260, 130)
	var vbox := $Panel/VBox
	vbox.add_child(scope)
	vbox.move_child(scope, 2)
	set_process(true)

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
	modulate.a = 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.2)

func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	# urgent pulse on the launch button
	if launch_btn != null and not launch_btn.disabled:
		var pulse: float = 0.85 + 0.15 * sin(_t * 6.0)
		launch_btn.modulate = Color(1, pulse, pulse * 0.9)
