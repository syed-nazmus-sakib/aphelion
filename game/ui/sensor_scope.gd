class_name SensorScope
extends Control

# Small animated radar scope: rotating sweep, converging hostile blips.

var _t: float = 0.0
var _blips: Array = []

func _ready() -> void:
	custom_minimum_size = Vector2(240, 140)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	_blips.clear()
	for i in range(4):
		_blips.append({
			"angle": rng.randf() * TAU,
			"dist": rng.randf_range(0.55, 0.95),
			"speed": rng.randf_range(0.05, 0.12),
			"hostile": i < 3,
		})
	set_process(true)

func _process(delta: float) -> void:
	_t += delta
	for b in _blips:
		b["dist"] = maxf(0.18, float(b["dist"]) - float(b["speed"]) * delta * 0.35)
		b["angle"] = float(b["angle"]) + delta * 0.15
	queue_redraw()

func _draw() -> void:
	var c := size * 0.5
	var r: float = minf(size.x, size.y) * 0.46
	if r < 4.0:
		return
	draw_circle(c, r + 2.0, Color(0.03, 0.07, 0.1, 0.9))
	draw_circle(c, r, Color(0.04, 0.1, 0.12, 0.95))
	for i in range(1, 4):
		draw_arc(c, r * i / 3.0, 0.0, TAU, 40, Color(0.3, 0.7, 0.7, 0.25), 1.0)
	draw_line(c - Vector2(r, 0), c + Vector2(r, 0), Color(0.3, 0.7, 0.7, 0.18), 1.0)
	draw_line(c - Vector2(0, r), c + Vector2(0, r), Color(0.3, 0.7, 0.7, 0.18), 1.0)
	# sweep
	var ang: float = _t * 1.6
	var segs := 14
	for i in range(segs):
		var a0: float = ang - TAU * (i + 1) / segs
		var a1: float = ang - TAU * i / segs
		var alpha: float = 0.35 * (1.0 - float(i) / float(segs))
		var p0 := c + Vector2(cos(a0), sin(a0)) * r
		var p1 := c + Vector2(cos(a1), sin(a1)) * r
		# angle-ordered wedge: center → lower angle → higher angle
		draw_colored_polygon(PackedVector2Array([c, p0, p1]), Color(0.35, 0.9, 0.8, alpha * 0.35))
	draw_line(c, c + Vector2(cos(ang), sin(ang)) * r, Color(0.5, 0.95, 0.85, 0.7), 1.5)
	# blips
	for b in _blips:
		var sweep_d: float = absf(wrapf(float(b["angle"]) - ang, -PI, PI))
		var lit: float = clampf(1.0 - sweep_d / 1.2, 0.25, 1.0)
		var bp := c + Vector2(cos(float(b["angle"])), sin(float(b["angle"]))) * r * float(b["dist"])
		if b["hostile"]:
			draw_circle(bp, 3.5, Color(1.0, 0.45, 0.4, lit))
			draw_arc(bp, 6.0, 0.0, TAU, 12, Color(1.0, 0.5, 0.4, lit * 0.6), 1.0)
		else:
			draw_circle(bp, 3.0, Color(0.5, 0.9, 1.0, lit))
	# center fleet pip
	draw_circle(c, 3.0, ThemeKit.ACCENT_TEAL)
	draw_arc(c, 6.0 + 1.5 * sin(_t * 3.0), 0.0, TAU, 16, Color(ThemeKit.ACCENT_TEAL.r, ThemeKit.ACCENT_TEAL.g, ThemeKit.ACCENT_TEAL.b, 0.5), 1.0)
	draw_arc(c, r, 0.0, TAU, 48, Color(0.4, 0.8, 0.85, 0.6), 1.5)
