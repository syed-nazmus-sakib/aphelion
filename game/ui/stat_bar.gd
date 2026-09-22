class_name StatBar
extends Control

# Animated horizontal gauge: eases toward target, flashes deltas, pulses
# when critically low.

var title: String = ""
var max_value: float = 100.0
var suffix: String = "%"
var color: Color = ThemeKit.ACCENT

var display_value: float = 0.0
var target_value: float = 0.0

var _has_target: bool = false
var _flash: float = 0.0
var _flash_text: String = ""
var _flash_positive: bool = true
var _t: float = 0.0

func setup(p_title: String, p_color: Color, p_max: float = 100.0, p_suffix: String = "%") -> StatBar:
	title = p_title
	color = p_color
	max_value = maxf(0.001, p_max)
	suffix = p_suffix
	custom_minimum_size = Vector2(0, 34)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	return self

func set_target(v: float) -> void:
	var clamped := clampf(v, 0.0, max_value)
	if not _has_target:
		display_value = clamped
	elif not is_equal_approx(clamped, target_value):
		var d: float = clamped - target_value
		if absf(d) >= 0.5:
			_flash = 1.5
			_flash_positive = d > 0.0
			var unit: String = suffix
			_flash_text = ("+%.0f%s" % [absf(d), unit]) if d > 0.0 else ("-%.0f%s" % [absf(d), unit])
	target_value = clamped
	_has_target = true

func reset_display(v: float) -> void:
	target_value = clampf(v, 0.0, max_value)
	display_value = target_value
	_has_target = true
	_flash = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(0, 34)
	set_process(true)

func _process(delta: float) -> void:
	_t += delta
	if absf(display_value - target_value) > 0.05:
		display_value += (target_value - display_value) * minf(1.0, delta * 6.0)
		if absf(display_value - target_value) <= 0.05:
			display_value = target_value
	else:
		display_value = target_value
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta)
	queue_redraw()

func ratio() -> float:
	return clampf(display_value / max_value, 0.0, 1.0)

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 8.0:
		return
	var font := ThemeDB.fallback_font
	# title + value row
	draw_string(font, Vector2(0, 12), title, HORIZONTAL_ALIGNMENT_LEFT, w * 0.6, 13, ThemeKit.TEXT_DIM)
	var value_text: String
	if suffix == "%":
		value_text = "%d%%" % int(round(display_value))
	else:
		value_text = "%d" % int(round(display_value))
	var value_size: Vector2 = font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	var vx: float = w - value_size.x
	draw_string(font, Vector2(vx, 12), value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
	# delta flash after value
	if _flash > 0.0 and _flash_text != "":
		var a: float = minf(1.0, _flash * 1.6)
		var dcol: Color = ThemeKit.GOOD if _flash_positive else ThemeKit.DANGER
		draw_string(font, Vector2(vx - 6.0 - font.get_string_size(_flash_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x, 12), _flash_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(dcol.r, dcol.g, dcol.b, a))
	# track
	var track := Rect2(0, 17, w, 11)
	var low: bool = ratio() < 0.25
	var pulse: float = 0.5 + 0.5 * sin(_t * 4.0)
	var fill_col := color
	if low:
		fill_col = color.lerp(ThemeKit.DANGER, 0.65)
	draw_rect(track, Color(0.07, 0.11, 0.15, 0.95))
	var fill_w: float = track.size.x * ratio()
	if fill_w > 0.5:
		draw_rect(Rect2(track.position, Vector2(fill_w, track.size.y)), fill_col)
		# sheen
		draw_rect(Rect2(Vector2(track.position.x, track.position.y), Vector2(fill_w, 2.0)), Color(1, 1, 1, 0.18))
	var border_col := Color(0.3, 0.45, 0.55, 0.45)
	if low:
		border_col = Color(ThemeKit.DANGER.r, ThemeKit.DANGER.g, ThemeKit.DANGER.b, 0.4 + 0.5 * pulse)
	draw_rect(track, border_col, false, 1.0)
