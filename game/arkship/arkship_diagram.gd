class_name ArkshipDiagram
extends Control

# Live side-view of Asteria. Each hull band is a district; the band fills
# with its governing resource level. Hover a band for district intel.
# Ship faces right (nose = Command).

const BAND_ORDER: Array = [
	{"id": "Hangars", "key": "readiness", "abbr": "HGR", "hint": "fighter readiness"},
	{"id": "Reactor", "key": "energy", "abbr": "RCT", "hint": "power output"},
	{"id": "Industry", "key": "materials", "abbr": "IND", "hint": "fabrication"},
	{"id": "Medical", "key": "medicine", "abbr": "MED", "hint": "casualty care"},
	{"id": "Agriculture", "key": "food", "abbr": "AGR", "hint": "food production"},
	{"id": "Habitation", "key": "morale", "abbr": "HAB", "hint": "civilian welfare"},
	{"id": "Command", "key": "readiness", "abbr": "CMD", "hint": "fleet coordination"},
]

const MAX_MATERIALS: float = 30000.0
const MAX_MEDICINE: float = 10000.0

var hull_frac: float = 1.0
var _levels: Array[float] = []
var _hover: int = -1
var _t: float = 0.0
var _population: int = 0

func _ready() -> void:
	custom_minimum_size = Vector2(300, 170)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_levels.resize(BAND_ORDER.size())
	for i in range(_levels.size()):
		_levels[i] = 0.7
	set_process(true)

func district_count() -> int:
	return BAND_ORDER.size()

func apply_state(state: CampaignState) -> void:
	if state == null:
		return
	_population = state.population
	hull_frac = clampf(float(state.resources.get("hull", 100.0)) / 100.0, 0.0, 1.0)
	for i in range(BAND_ORDER.size()):
		var key := String(BAND_ORDER[i]["key"])
		var raw: float = float(state.resources.get(key, 50.0))
		var norm: float
		match key:
			"materials":
				norm = raw / MAX_MATERIALS
			"medicine":
				norm = raw / MAX_MEDICINE
			_:
				norm = raw / 100.0
		_levels[i] = clampf(norm, 0.0, 1.0)
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	var m := get_local_mouse_position()
	var hovered := district_at(m.x) if (m.x >= 0.0 and m.y >= 0.0 and m.x <= size.x and m.y <= size.y) else -1
	if hovered != _hover:
		_hover = hovered
		if _hover >= 0:
			var b: Dictionary = BAND_ORDER[_hover]
			tooltip_text = "%s — %s\nDistrict fill: %d%% of nominal" % [String(b["id"]).to_upper(), String(b["hint"]), int(_levels[_hover] * 100.0)]
		else:
			tooltip_text = ""
	queue_redraw()

func _band_geometry() -> Rect2:
	return Rect2(14, 18, maxf(10.0, size.x - 28.0), maxf(30.0, size.y - 48.0))

func district_at(local_x: float) -> int:
	var g := _band_geometry()
	if local_x < g.position.x or local_x > g.position.x + g.size.x:
		return -1
	var band_w: float = g.size.x / float(BAND_ORDER.size())
	var idx := int(floor((local_x - g.position.x) / band_w))
	return clampi(idx, 0, BAND_ORDER.size() - 1)

# Hull half-height profile across normalized x (0 rear .. 1 nose).
func _top_y(x_norm: float, g: Rect2) -> float:
	var keys := [Vector2(0.0, 0.42), Vector2(0.12, 0.3), Vector2(0.35, 0.22), Vector2(0.7, 0.26), Vector2(0.92, 0.4), Vector2(1.0, 0.5)]
	return _profile(x_norm, keys, g)

func _bot_y(x_norm: float, g: Rect2) -> float:
	var keys := [Vector2(0.0, 0.58), Vector2(0.12, 0.7), Vector2(0.35, 0.78), Vector2(0.7, 0.74), Vector2(0.92, 0.6), Vector2(1.0, 0.5)]
	return _profile(x_norm, keys, g)

func _profile(x_norm: float, keys: Array, g: Rect2) -> float:
	var xn := clampf(x_norm, 0.0, 1.0)
	for i in range(keys.size() - 1):
		var a: Vector2 = keys[i]
		var b: Vector2 = keys[i + 1]
		if xn >= a.x and xn <= b.x:
			var t: float = (xn - a.x) / maxf(0.0001, b.x - a.x)
			var f: float = lerpf(a.y, b.y, t)
			return g.position.y + f * g.size.y
	return g.position.y + float(keys[keys.size() - 1].y) * g.size.y

func _draw() -> void:
	var g := _band_geometry()
	if g.size.x < 8.0:
		return
	var band_w: float = g.size.x / float(BAND_ORDER.size())
	var font := ThemeDB.fallback_font
	# backing grid
	for i in range(6):
		var gx: float = g.position.x + g.size.x * i / 5.0
		draw_line(Vector2(gx, g.position.y - 6), Vector2(gx, g.position.y + g.size.y + 6), Color(0.2, 0.3, 0.4, 0.15), 1.0)
	# bands
	for i in range(BAND_ORDER.size()):
		var x0: float = g.position.x + band_w * i
		var x1: float = x0 + band_w
		var n0a := (x0 - g.position.x) / g.size.x
		var n0b := (x1 - g.position.x) / g.size.x
		var top0 := _top_y(n0a, g)
		var top1 := _top_y(n0b, g)
		var bot0 := _bot_y(n0a, g)
		var bot1 := _bot_y(n0b, g)
		# hull background inside band
		draw_colored_polygon(PackedVector2Array([
			Vector2(x0, top0), Vector2(x1, top1), Vector2(x1, bot1), Vector2(x0, bot0)]),
			Color(0.08, 0.13, 0.19, 0.95))
		# fill level
		var lvl: float = _levels[i]
		var key := String(BAND_ORDER[i]["key"])
		var col := ThemeKit.resource_color(key)
		var yf0: float = bot0 - (bot0 - top0) * lvl
		var yf1: float = bot1 - (bot1 - top1) * lvl
		if lvl > 0.01:
			var fill_col := col
			if lvl < 0.25:
				var pulse: float = 0.5 + 0.5 * sin(_t * 4.0)
				fill_col = col.lerp(ThemeKit.DANGER, 0.55 + 0.2 * pulse)
			draw_colored_polygon(PackedVector2Array([
				Vector2(x0, yf0), Vector2(x1, yf1), Vector2(x1, bot1), Vector2(x0, bot0)]),
				Color(fill_col.r, fill_col.g, fill_col.b, 0.85))
			# surface line
			draw_line(Vector2(x0, yf0), Vector2(x1, yf1), Color(1, 1, 1, 0.35), 1.5)
		# hover highlight
		if i == _hover:
			draw_colored_polygon(PackedVector2Array([
				Vector2(x0, top0), Vector2(x1, top1), Vector2(x1, bot1), Vector2(x0, bot0)]),
				Color(1, 1, 1, 0.08))
			draw_polyline(PackedVector2Array([
				Vector2(x0, top0), Vector2(x1, top1), Vector2(x1, bot1), Vector2(x0, bot0), Vector2(x0, top0)]),
				Color(col.r, col.g, col.b, 0.9), 1.5)
		# windows row
		for wi in range(3):
			var wx: float = lerpf(x0, x1, 0.25 + 0.25 * wi)
			var wt: float = _top_y((wx - g.position.x) / g.size.x, g)
			var twinkle: float = 0.4 + 0.6 * (0.5 + 0.5 * sin(_t * 2.0 + i * 1.7 + wi))
			draw_circle(Vector2(wx, wt + 7.0), 1.8, Color(0.95, 0.95, 0.85, 0.35 + 0.5 * twinkle * lvl))
		# abbr label under hull
		var abbr: String = String(BAND_ORDER[i]["abbr"])
		var abbr_w: float = font.get_string_size(abbr, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		draw_string(font, Vector2((x0 + x1) * 0.5 - abbr_w * 0.5, g.position.y + g.size.y + 16), abbr, HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
			Color(col.r, col.g, col.b, 0.5 + 0.5 * lvl))
		# separator
		if i > 0:
			draw_line(Vector2(x0, top0), Vector2(x0, bot0), Color(0.4, 0.6, 0.7, 0.3), 1.0)
	# outline (hull color by integrity)
	var outline := ThemeKit.resource_color("hull")
	if hull_frac < 0.5:
		outline = outline.lerp(ThemeKit.DANGER, 0.6)
	elif hull_frac < 0.8:
		outline = outline.lerp(ThemeKit.WARN, 0.35)
	var top_pts := PackedVector2Array()
	var bot_pts := PackedVector2Array()
	for i in range(25):
		var xn: float = float(i) / 24.0
		var x: float = g.position.x + xn * g.size.x
		top_pts.append(Vector2(x, _top_y(xn, g)))
		bot_pts.append(Vector2(x, _bot_y(xn, g)))
	draw_polyline(top_pts, Color(outline.r, outline.g, outline.b, 0.95), 2.0)
	draw_polyline(bot_pts, Color(outline.r, outline.g, outline.b, 0.95), 2.0)
	draw_line(top_pts[0], bot_pts[0], Color(outline.r, outline.g, outline.b, 0.95), 2.0)
	draw_line(top_pts[top_pts.size() - 1], bot_pts[bot_pts.size() - 1], Color(outline.r, outline.g, outline.b, 0.95), 2.0)
	# damage gashes
	if hull_frac < 0.995:
		var gashes := clampi(int(ceil((1.0 - hull_frac) * 5.0)), 1, 4)
		for gi in range(gashes):
			var gx_n: float = [0.28, 0.48, 0.66, 0.82][gi % 4]
			var gx: float = g.position.x + gx_n * g.size.x
			var gtop := _top_y(gx_n, g)
			var gbot := _bot_y(gx_n, g)
			var gy: float = lerpf(gtop, gbot, 0.35 + 0.2 * sin(gi * 2.1))
			var jag := PackedVector2Array([
				Vector2(gx - 6, gy - 4), Vector2(gx - 1, gy + 2), Vector2(gx + 3, gy - 3), Vector2(gx + 8, gy + 4)])
			draw_polyline(jag, Color(1.0, 0.4, 0.3, 0.9), 2.0)
			var smoke: float = 0.35 + 0.3 * sin(_t * 3.0 + gi)
			draw_circle(Vector2(gx + 2, gy - 7), 4.0, Color(0.5, 0.5, 0.5, smoke * 0.4))
	# engine plume (rear, left)
	var rear_top := _top_y(0.0, g)
	var rear_bot := _bot_y(0.0, g)
	var mid := (rear_top + rear_bot) * 0.5
	for pi in range(3):
		var flick: float = 0.5 + 0.5 * sin(_t * (9.0 + pi * 3.0) + pi)
		var length: float = (10.0 + 8.0 * flick) + pi * 6.0
		var alpha: float = (0.5 - 0.12 * pi) * (0.7 + 0.3 * flick)
		var plume := PackedVector2Array([
			Vector2(g.position.x, rear_top + 4 + pi * 3),
			Vector2(g.position.x - length, mid - 2 + pi * 2),
			Vector2(g.position.x, rear_bot - 4 - pi * 3)])
		draw_colored_polygon(plume, Color(0.35, 0.75, 1.0, alpha))
	# nose light
	var nose := Vector2(g.position.x + g.size.x, _top_y(1.0, g) + (g.position.y + g.size.y - _top_y(1.0, g)) * 0.5)
	var blink: float = 0.5 + 0.5 * sin(_t * 2.4)
	draw_circle(nose, 2.5, Color(1.0, 0.85, 0.5, 0.4 + 0.6 * blink))
	# labels
	draw_string(font, Vector2(0, 11), "ASTERIA — HULL %d%%" % int(round(hull_frac * 100.0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
		Color(outline.r, outline.g, outline.b, 0.95))
