class_name SpaceBackground
extends Control

# Layered, slowly drifting starfield + soft nebula. Seeded in normalized
# coordinates so it survives any viewport size.

var drift_scale: float = 1.0
var _t: float = 0.0
var _stars: Array = []
var _nebula: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	seed_field(11)
	set_process(true)

func seed_field(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_stars.clear()
	_nebula.clear()
	for i in range(230):
		_stars.append({"u": rng.randf(), "v": rng.randf(), "layer": 0, "s": rng.randf_range(0.7, 1.3), "phase": rng.randf() * TAU, "spd": rng.randf_range(0.0008, 0.002)})
	for i in range(80):
		_stars.append({"u": rng.randf(), "v": rng.randf(), "layer": 1, "s": rng.randf_range(0.9, 1.5), "phase": rng.randf() * TAU, "spd": rng.randf_range(0.002, 0.004)})
	for i in range(24):
		_stars.append({"u": rng.randf(), "v": rng.randf(), "layer": 2, "s": rng.randf_range(1.2, 2.0), "phase": rng.randf() * TAU, "spd": rng.randf_range(0.004, 0.007)})
	var neb_colors := [
		Color(0.1, 0.18, 0.32, 0.07),
		Color(0.08, 0.24, 0.26, 0.06),
		Color(0.16, 0.12, 0.3, 0.055),
		Color(0.06, 0.14, 0.24, 0.07),
	]
	for i in range(4):
		_nebula.append({
			"u": rng.randf(), "v": rng.randf(),
			"r": rng.randf_range(0.22, 0.42),
			"color": neb_colors[i % neb_colors.size()],
		})

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var sz := size
	if sz.x < 2.0 or sz.y < 2.0:
		return
	draw_rect(Rect2(Vector2.ZERO, sz), ThemeKit.BG_DEEP)
	for n in _nebula:
		var c: Color = n["color"]
		var ctr := Vector2(float(n["u"]) * sz.x, float(n["v"]) * sz.y)
		var base_r := float(n["r"]) * minf(sz.x, sz.y)
		for ring in range(5):
			var shrink := 1.0 - float(ring) * 0.17
			var alpha_scale := 0.28 + float(ring) * 0.12
			draw_circle(ctr, base_r * shrink, Color(c.r, c.g, c.b, c.a * alpha_scale))
	for st in _stars:
		var layer: int = st["layer"]
		var spd: float = float(st["spd"]) * drift_scale
		var u: float = fposmod(float(st["u"]) + _t * spd, 1.0)
		var v: float = fposmod(float(st["v"]) + _t * spd * 0.35, 1.0)
		var p := Vector2(u * sz.x, v * sz.y)
		var twinkle: float = 0.55 + 0.45 * sin(_t * 1.7 + float(st["phase"]))
		var radius: float = float(st["s"]) * (0.9 + 0.35 * layer)
		var alpha: float = (0.35 + 0.25 * layer) * twinkle
		var col := Color(0.75, 0.85, 0.98, alpha)
		if layer == 2:
			col = Color(0.9, 0.95, 1.0, minf(1.0, alpha + 0.25))
		draw_circle(p, radius, col)
		if layer == 2 and twinkle > 0.85:
			var arm: float = 4.0 + 2.0 * twinkle
			draw_line(p - Vector2(arm, 0), p + Vector2(arm, 0), Color(col.r, col.g, col.b, col.a * 0.5), 1.0)
			draw_line(p - Vector2(0, arm), p + Vector2(0, arm), Color(col.r, col.g, col.b, col.a * 0.5), 1.0)
