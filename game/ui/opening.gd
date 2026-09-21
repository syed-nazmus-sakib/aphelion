extends Control

signal opening_finished

const LINES: Array[String] = [
	"EXODUS YEAR 0",
	"ARKSHIPS: 6",
	"HUMAN POPULATION: 2,700,000",
	"ESTIMATED JOURNEY: 550 YEARS",
	"",
	"You will not reach the destination.",
	"Your descendants might.",
]

var line_index: int = -1
var elapsed: float = 0.0
var done: bool = false
var label: Label
var hint: Label
var stars: Array[Vector2] = []

func _ready() -> void:
	label = $Lines
	hint = Label.new()
	hint.text = "Click or press Esc to continue"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.55, 0.62, 0.7))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.offset_top = -40.0
	add_child(hint)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in range(160):
		stars.append(Vector2(rng.randf() * 1280.0, rng.randf() * 800.0))

func _unhandled_input(event: InputEvent) -> void:
	if not visible or done:
		return
	if event.is_action_pressed("ui_cancel"):
		_finish()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		_advance_line()
		get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_advance_line()

func play() -> void:
	visible = true
	done = false
	line_index = -1
	elapsed = 0.0
	label.text = ""
	set_process(true)

func _process(delta: float) -> void:
	if not visible or done:
		return
	elapsed += delta
	# auto-advance every 1.6s
	if elapsed > 1.6:
		elapsed = 0.0
		_advance_line()
	queue_redraw()

func _advance_line() -> void:
	elapsed = 0.0
	line_index += 1
	if line_index >= LINES.size():
		_finish()
		return
	label.text = LINES[line_index]
	label.visible = LINES[line_index] != ""

func _finish() -> void:
	if done:
		return
	done = true
	set_process(false)
	opening_finished.emit()

func _draw() -> void:
	var r := get_rect().size
	var cx: float = r.x * 0.5
	# Earth: large arc at bottom-left receding as lines progress
	var progress: float = clampf(float(maxi(0, line_index)) / float(LINES.size()), 0.0, 1.0)
	var earth_pos := Vector2(cx - 420.0 + progress * 120.0, r.y + 260.0 - progress * 160.0)
	draw_circle(earth_pos, 340.0, Color(0.15, 0.35, 0.55))
	draw_circle(earth_pos, 340.0, Color(0.1, 0.2, 0.35, 0.0))
	draw_arc(earth_pos, 340.0, 0.0, TAU, 64, Color(0.5, 0.8, 1.0, 0.7), 3.0)
	# night lights (few dots on dark side)
	for i in range(24):
		var a: float = 3.6 + i * 0.09
		var p := earth_pos + Vector2(cos(a), sin(a)) * 330.0
		draw_circle(p, 2.0, Color(1.0, 0.85, 0.5, 0.5 * (1.0 - progress)))
	for s in stars:
		draw_circle(s, 1.4, Color(0.7, 0.8, 0.92, 0.7))
	# six arkships departing: small wedges moving up-right
	for i in range(6):
		var t: float = clampf(progress * 1.4 - i * 0.04, 0.0, 1.0)
		var p := Vector2(cx - 200.0 + i * 70.0 + t * 260.0, r.y * 0.62 - t * 180.0 + sin(i * 2.1) * 12.0)
		var pts := PackedVector2Array([p + Vector2(0, -10), p + Vector2(-7, 8), p + Vector2(7, 8)])
		draw_colored_polygon(pts, Color(0.75, 0.88, 0.94, 0.9))
		# engine glow
		draw_circle(p + Vector2(0, 12), 4.0 + t * 2.0, Color(0.4, 0.8, 1.0, 0.5))
