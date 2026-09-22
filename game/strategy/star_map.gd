class_name StarMap
extends Control

signal node_selected(node_id: String)

# Tiny strategic region for the vertical slice:
# current location, next destination, danger, resource opportunity.
# Animated (radar sweep, traffic, twinkle) and clickable (node intel).

const NODES: Array = [
	{
		"id": "charon", "label": "Charon Staging", "kind": "current", "pos": Vector2(0.22, 0.62),
		"blurb": "Fleet holding pattern. Inner-system debris still crosses the approach lanes.",
		"threat": 0, "resource": "Refinery spares", "travel_days": 0,
	},
	{
		"id": "galene", "label": "Galene Drift", "kind": "next", "pos": Vector2(0.52, 0.42),
		"blurb": "Ice-rich drift. The planned next transition corridor runs through it.",
		"threat": 1, "resource": "Water ice", "travel_days": 45,
	},
	{
		"id": "hollow", "label": "Hollow Signal", "kind": "danger", "pos": Vector2(0.72, 0.68),
		"blurb": "An automated distress loop repeats on an empty beacon. Something shut that station down.",
		"threat": 3, "resource": "Unknown", "travel_days": 70,
	},
	{
		"id": "thresh", "label": "Thresher Cache", "kind": "resource", "pos": Vector2(0.45, 0.78),
		"blurb": "Derelict cargo rig. Cutters could strip usable alloys if the approach holds.",
		"threat": 1, "resource": "Alloys / salvage", "travel_days": 30,
	},
]
const LINKS: Array = [
	["charon", "galene"],
	["charon", "thresh"],
	["galene", "hollow"],
]

var selected_id: String = ""
var fleet_node_id: String = "charon"
var course_node_id: String = ""
var _hover_id: String = ""
var _t: float = 0.0
var _bg_stars: Array = []

static func label_for(node_id: String) -> String:
	for n in NODES:
		if String(n["id"]) == node_id:
			return String(n["label"])
	return ""

static func node_by_id(node_id: String) -> Dictionary:
	for n in NODES:
		if String(n["id"]) == node_id:
			return n
	return {}

static func id_for_location(location_label: String) -> String:
	for n in NODES:
		if String(n["label"]) == location_label:
			return String(n["id"])
	return "charon"

func _ready() -> void:
	custom_minimum_size = Vector2(520, 340)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	_bg_stars.clear()
	for i in range(90):
		_bg_stars.append({"u": rng.randf(), "v": rng.randf(), "s": rng.randf_range(0.6, 1.6), "phase": rng.randf() * TAU})
	set_process(true)

func set_fleet_location(location_label: String) -> void:
	fleet_node_id = id_for_location(location_label)
	queue_redraw()

func set_course(node_id: String) -> void:
	course_node_id = node_id
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func node_pos(node_id: String, r: Vector2) -> Vector2:
	for n in NODES:
		if String(n["id"]) == node_id:
			return Vector2(float(n["pos"].x) * r.x, float(n["pos"].y) * r.y)
	return Vector2.ZERO

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hit := _node_at(event.position)
		if hit != "":
			_select(hit)
			accept_event()
	elif event is InputEventMouseMotion:
		var h := _node_at(event.position)
		if h != _hover_id:
			_hover_id = h
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if h != "" else Control.CURSOR_ARROW

func _node_at(local: Vector2) -> String:
	var r := size
	var best := ""
	var best_d := 30.0
	for n in NODES:
		var p := Vector2(float(n["pos"].x) * r.x, float(n["pos"].y) * r.y)
		var d := p.distance_to(local)
		if d < best_d:
			best_d = d
			best = String(n["id"])
	return best

func _select(node_id: String) -> void:
	selected_id = node_id
	node_selected.emit(node_id)

func select_node(node_id: String) -> void:
	# programmatic selection (tests / controller) — emits as well
	_select(node_id)

func _draw() -> void:
	var r := size
	if r.x < 8.0 or r.y < 8.0:
		return
	# background panel
	draw_rect(Rect2(Vector2.ZERO, r), Color(0.025, 0.045, 0.085))
	# faint grid
	var gx: float = 0.0
	while gx < r.x:
		draw_line(Vector2(gx, 0), Vector2(gx, r.y), Color(0.2, 0.3, 0.45, 0.16), 1.0)
		gx += 52.0
	var gy: float = 0.0
	while gy < r.y:
		draw_line(Vector2(0, gy), Vector2(r.x, gy), Color(0.2, 0.3, 0.45, 0.13), 1.0)
		gy += 52.0
	# drifting background stars
	for st in _bg_stars:
		var u: float = fposmod(float(st["u"]) + _t * 0.0015, 1.0)
		var p := Vector2(u * r.x, float(st["v"]) * r.y)
		var tw: float = 0.5 + 0.5 * sin(_t * 1.5 + float(st["phase"]))
		draw_circle(p, float(st["s"]), Color(0.7, 0.8, 0.95, 0.2 + 0.35 * tw))
	# links with marching dashes
	for link in LINKS:
		var a := node_pos(String(link[0]), r)
		var b := node_pos(String(link[1]), r)
		var danger: bool = String(link[1]) == "hollow" or String(link[0]) == "hollow"
		var col := Color(0.9, 0.4, 0.35, 0.55) if danger else Color(0.4, 0.7, 0.85, 0.5)
		_marching_line(a, b, col, 10.0, 7.0, _t * 22.0)
	# plotted course highlight
	if course_node_id != "" and course_node_id != fleet_node_id:
		var ca := node_pos(fleet_node_id, r)
		var cb := node_pos(course_node_id, r)
		_marching_line(ca, cb, Color(ThemeKit.ACCENT_TEAL.r, ThemeKit.ACCENT_TEAL.g, ThemeKit.ACCENT_TEAL.b, 0.85), 14.0, 5.0, -_t * 40.0)
	# traffic dots along links
	for li in range(LINKS.size()):
		var link: Array = LINKS[li]
		var a2 := node_pos(String(link[0]), r)
		var b2 := node_pos(String(link[1]), r)
		for k in range(2):
			var tt: float = fposmod(_t * 0.09 + float(li) * 0.31 + k * 0.5, 1.0)
			var p2 := a2.lerp(b2, tt)
			var dir := (b2 - a2).normalized()
			var perp := Vector2(-dir.y, dir.x)
			draw_colored_polygon(PackedVector2Array([
				p2 + dir * 5.0, p2 - dir * 3.0 + perp * 2.5, p2 - dir * 3.0 - perp * 2.5]),
				Color(0.7, 0.9, 1.0, 0.65))
	# radar sweep from fleet node
	var origin := node_pos(fleet_node_id, r)
	var sweep: float = _t * 0.9
	var reach: float = minf(r.x, r.y) * 0.55
	for i in range(10):
		var a0: float = sweep - 0.9 * (i + 1) / 10.0
		var a1: float = sweep - 0.9 * i / 10.0
		var alpha: float = 0.10 * (1.0 - i / 10.0)
		var p0 := origin + Vector2(cos(a0), sin(a0)) * reach
		var p1 := origin + Vector2(cos(a1), sin(a1)) * reach
		draw_colored_polygon(PackedVector2Array([origin, p0, p1]), Color(0.4, 0.95, 0.85, alpha))
	draw_line(origin, origin + Vector2(cos(sweep), sin(sweep)) * reach, Color(0.45, 0.95, 0.85, 0.35), 1.5)
	# nodes
	for n in NODES:
		var id := String(n["id"])
		var p3 := Vector2(float(n["pos"].x) * r.x, float(n["pos"].y) * r.y)
		var kind := String(n["kind"])
		# fleet overrides "current" style on its node
		var is_fleet: bool = id == fleet_node_id
		var is_sel: bool = id == selected_id
		var is_hover: bool = id == _hover_id
		var is_course: bool = id == course_node_id
		var col2 := Color(0.6, 0.8, 0.9)
		var rad := 10.0
		if is_fleet:
			col2 = Color(0.55, 0.95, 0.8)
			rad = 13.0
		else:
			match kind:
				"next":
					col2 = Color(0.55, 0.8, 1.0)
				"danger":
					col2 = Color(1.0, 0.42, 0.38)
				"resource":
					col2 = Color(1.0, 0.82, 0.4)
		if is_hover and not is_fleet:
			rad += 2.0
		# glow
		draw_circle(p3, rad + 7.0, Color(col2, 0.16))
		draw_circle(p3, rad, col2.darkened(0.35))
		draw_arc(p3, rad, 0.0, TAU, 24, col2, 2.0)
		if is_fleet:
			var pulse: float = 4.0 + 2.0 * sin(_t * 3.0)
			draw_arc(p3, rad + pulse + 6.0, 0.0, TAU, 28, Color(col2, 0.45), 1.5)
			# tiny fleet triangle
			var tri := PackedVector2Array([p3 + Vector2(0, -6), p3 + Vector2(-5, 5), p3 + Vector2(5, 5)])
			draw_colored_polygon(tri, Color(0.9, 1.0, 0.98, 0.9))
		if is_course and not is_fleet:
			var cpulse: float = 2.0 + 1.5 * sin(_t * 5.0)
			draw_arc(p3, rad + 6.0 + cpulse, 0.0, TAU, 24, Color(ThemeKit.ACCENT_TEAL, 0.7), 1.5)
		if is_sel:
			var sr: float = rad + 12.0
			draw_arc(p3, sr, 0.0, TAU, 32, Color(1, 1, 1, 0.85), 1.5)
			for corner in range(4):
				var ca2: float = TAU * corner / 4.0 + PI * 0.25
				var cp := p3 + Vector2(cos(ca2), sin(ca2)) * (sr + 3.0)
				draw_circle(cp, 2.0, Color(1, 1, 1, 0.9))
		var font := ThemeDB.fallback_font
		var name_col := Color(0.9, 0.95, 1.0) if (is_sel or is_fleet) else Color(0.82, 0.88, 0.94)
		draw_string(font, p3 + Vector2(16, 5), String(n["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, name_col)
		var sub := ""
		if is_fleet:
			sub = "FLEET HOLDING"
		else:
			match kind:
				"next":
					sub = "NEXT TRANSITION"
				"danger":
					sub = "HOSTILE RETURN"
				"resource":
					sub = "SALVAGE / ICE"
		if is_course and not is_fleet:
			sub += " · PLOTTED"
		draw_string(font, p3 + Vector2(16, 21), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.55, 0.62, 0.7))
	# border
	draw_rect(Rect2(Vector2.ZERO, r), Color(0.3, 0.5, 0.65, 0.4), false, 1.0)

func _marching_line(a: Vector2, b: Vector2, col: Color, dash: float, gap: float, offset: float) -> void:
	var vec := b - a
	var length := vec.length()
	if length < 1.0:
		return
	var dir := vec / length
	var period := dash + gap
	var pos := fposmod(offset, period) - period
	while pos < length:
		var seg_end: float = minf(length, pos + dash)
		if seg_end > maxf(0.0, pos):
			draw_line(a + dir * maxf(0.0, pos), a + dir * seg_end, col, 1.6)
		pos += period
