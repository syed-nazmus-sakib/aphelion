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

const HOLD_AFTER_LINE: float = 0.9
const TYPE_CHARS_PER_SEC: float = 34.0

var line_index: int = -1
var elapsed: float = 0.0
var done: bool = false
var label: Label
var hint: Label
var stars: Array[Vector2] = []
var star_depth: Array[float] = []

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
	for i in range(180):
		stars.append(Vector2(rng.randf() * 1280.0, rng.randf() * 800.0))
		star_depth.append(rng.randf_range(0.3, 1.0))

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
	label.visible_characters = 0
	label.visible = false
	set_process(true)

func _process(delta: float) -> void:
	if not visible or done:
		return
	elapsed += delta
	# kick off the first line after a brief beat
	if line_index < 0:
		if elapsed > 0.35:
			_advance_line()
		queue_redraw()
		return
	# typewriter reveal for the current line
	if line_index >= 0 and line_index < LINES.size():
		var full := LINES[line_index]
		var chars := mini(full.length(), int(elapsed * TYPE_CHARS_PER_SEC))
		label.visible_characters = chars
		label.visible = full != ""
		# advance once fully typed plus a hold
		if chars >= full.length() and elapsed * TYPE_CHARS_PER_SEC >= full.length() and elapsed >= (float(full.length()) / TYPE_CHARS_PER_SEC) + HOLD_AFTER_LINE:
			_advance_line()
	queue_redraw()

func _advance_line() -> void:
	# if still typing, complete the line instantly
	if line_index >= 0 and line_index < LINES.size() and label.visible_characters < LINES[line_index].length():
		elapsed = float(LINES[line_index].length()) / TYPE_CHARS_PER_SEC + HOLD_AFTER_LINE
		label.visible_characters = LINES[line_index].length()
		return
	line_index += 1
	if line_index >= LINES.size():
		_finish()
		return
	elapsed = 0.0
	label.text = LINES[line_index]
	label.visible_characters = 0
	label.visible = LINES[line_index] != ""
	# the final two lines get a longer, heavier presentation
	if line_index >= 5:
		label.add_theme_font_size_override("font_size", 34)
		label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	else:
		label.add_theme_font_size_override("font_size", 30)
		label.add_theme_color_override("font_color", Color(0.8, 0.9, 0.95))

func _finish() -> void:
	if done:
		return
	done = true
	set_process(false)
	opening_finished.emit()

func _progress() -> float:
	return clampf(float(maxi(0, line_index)) / float(LINES.size()), 0.0, 1.0)

func _draw() -> void:
	var r := get_rect().size
	draw_rect(Rect2(Vector2.ZERO, r), Color(0.01, 0.02, 0.045))
	var cx: float = r.x * 0.5
	var progress := _progress()
	# star streaks grow as the fleet accelerates
	for i in range(stars.size()):
		var depth: float = star_depth[i]
		var s := stars[i]
		var streak: float = 1.0 + progress * 26.0 * depth
		var col := Color(0.7, 0.8, 0.92, 0.35 + 0.45 * depth)
		if streak > 3.0:
			draw_line(s, s + Vector2(streak * 0.6, -streak * 0.35), col, 1.2)
		else:
			draw_circle(s, 1.2 + depth * 0.6, col)
	# Earth: large arc at bottom-left receding as lines progress
	var earth_pos := Vector2(cx - 420.0 + progress * 160.0, r.y + 260.0 - progress * 200.0)
	# atmosphere glow rings
	draw_circle(earth_pos, 358.0, Color(0.3, 0.6, 0.9, 0.06))
	draw_circle(earth_pos, 348.0, Color(0.25, 0.5, 0.8, 0.08))
	draw_circle(earth_pos, 340.0, Color(0.14, 0.32, 0.52))
	# subtle band shading
	draw_circle(earth_pos + Vector2(-60, -80), 300.0, Color(0.18, 0.38, 0.58, 0.5))
	draw_circle(earth_pos + Vector2(-140, 40), 240.0, Color(0.1, 0.24, 0.4, 0.5))
	draw_arc(earth_pos, 340.0, 0.0, TAU, 72, Color(0.5, 0.8, 1.0, 0.75), 2.5)
	draw_arc(earth_pos, 344.0, PI * 0.9, PI * 1.7, 36, Color(0.55, 0.85, 1.0, 0.35), 4.0)
	# night lights (few dots on dark side, fading as we leave)
	for i in range(30):
		var a: float = 3.6 + i * 0.075
		var p := earth_pos + Vector2(cos(a), sin(a)) * (326.0 + sin(i * 3.1) * 6.0)
		draw_circle(p, 2.0, Color(1.0, 0.85, 0.5, 0.55 * (1.0 - progress)))
	# debris streaks falling through the atmosphere
	for i in range(5):
		var dt: float = fposmod(progress * 2.0 + i * 0.37, 1.0)
		var da: float = 4.1 + i * 0.22
		var dp := earth_pos + Vector2(cos(da), sin(da)) * 350.0
		var dvel := Vector2(cos(da + 1.2), sin(da + 1.2)) * (30.0 + i * 8.0)
		draw_line(dp + dvel * dt * 0.4, dp + dvel * dt * 0.4 + dvel * 0.35, Color(1.0, 0.6, 0.3, 0.5 * (1.0 - progress)), 1.5)
	# six arkships departing with engine trails
	for i in range(6):
		var t: float = clampf(progress * 1.5 - i * 0.04, 0.0, 1.0)
		var p := Vector2(cx - 220.0 + i * 72.0 + t * 300.0, r.y * 0.58 - t * 220.0 + sin(i * 2.1) * 14.0)
		var dir := Vector2(0.7, -0.7).normalized()
		# trail
		for k in range(4):
			var tl: float = 14.0 + k * 10.0 + t * 16.0
			var alpha: float = 0.35 - k * 0.07
			draw_line(p - dir * 4.0, p - dir * (4.0 + tl), Color(0.4, 0.8, 1.0, maxf(0.0, alpha)), 3.0 - k * 0.5)
		# hull: elongated wedge
		var side := Vector2(-dir.y, dir.x)
		var nose := p + dir * 11.0
		var tail := p - dir * 8.0
		var hull := PackedVector2Array([
			nose, tail + side * 5.0, tail - side * 5.0])
		draw_colored_polygon(hull, Color(0.8, 0.9, 0.96, 0.95))
		draw_polyline(hull + PackedVector2Array([hull[0]]), Color(0.4, 0.6, 0.75, 0.9), 1.2)
		# engine glow at tail
		var flick: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 90.0 + i)
		draw_circle(tail, 3.5 + 1.5 * flick, Color(0.5, 0.85, 1.0, 0.5 + 0.3 * flick))
