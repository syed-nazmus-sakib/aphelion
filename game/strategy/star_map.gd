class_name StarMap
extends Control

# Tiny strategic region for the vertical slice:
# current location, next destination, danger, resource opportunity.
const NODES: Array = [
	{"id": "charon", "label": "Charon Staging", "kind": "current", "pos": Vector2(0.22, 0.62)},
	{"id": "galene", "label": "Galene Drift", "kind": "next", "pos": Vector2(0.52, 0.42)},
	{"id": "hollow", "label": "Hollow Signal", "kind": "danger", "pos": Vector2(0.72, 0.68)},
	{"id": "thresh", "label": "Thresher Cache", "kind": "resource", "pos": Vector2(0.45, 0.78)},
]
const LINKS: Array = [
	["charon", "galene"],
	["charon", "thresh"],
	["galene", "hollow"],
]

func _ready() -> void:
	custom_minimum_size = Vector2(520, 380)
	mouse_filter = MOUSE_FILTER_IGNORE

func _draw() -> void:
	var r := get_rect().size
	# background panel
	draw_rect(Rect2(Vector2.ZERO, r), Color(0.03, 0.05, 0.1))
	draw_rect(Rect2(Vector2.ZERO, r), Color(0.3, 0.45, 0.6, 0.35), false, 1.0)
	# faint grid
	var gx: float = 0.0
	while gx < r.x:
		draw_line(Vector2(gx, 0), Vector2(gx, r.y), Color(0.2, 0.3, 0.45, 0.18), 1.0)
		gx += 52.0
	var gy: float = 0.0
	while gy < r.y:
		draw_line(Vector2(0, gy), Vector2(r.x, gy), Color(0.2, 0.3, 0.45, 0.15), 1.0)
		gy += 52.0
	# links
	for link in LINKS:
		var a := _node_pos(String(link[0]), r)
		var b := _node_pos(String(link[1]), r)
		var danger: bool = String(link[1]) == "hollow" or String(link[0]) == "hollow"
		draw_dashed_line(a, b, Color(0.9, 0.4, 0.35, 0.6) if danger else Color(0.4, 0.7, 0.85, 0.55), 2.0, 8.0)
	# nodes
	for n in NODES:
		var p := Vector2(float(n["pos"].x) * r.x, float(n["pos"].y) * r.y)
		var kind := String(n["kind"])
		var col := Color(0.6, 0.8, 0.9)
		var rad := 10.0
		match kind:
			"current":
				col = Color(0.55, 0.95, 0.8)
				rad = 13.0
			"next":
				col = Color(0.55, 0.8, 1.0)
			"danger":
				col = Color(1.0, 0.42, 0.38)
			"resource":
				col = Color(1.0, 0.82, 0.4)
		# glow
		draw_circle(p, rad + 7.0, Color(col, 0.18))
		draw_circle(p, rad, col.darkened(0.35))
		draw_arc(p, rad, 0.0, TAU, 24, col, 2.0)
		if kind == "current":
			# fleet marker: small triangle + pulse
			var pulse: float = 4.0 + 2.0 * sin(Time.get_ticks_msec() / 400.0)
			draw_arc(p, rad + pulse + 6.0, 0.0, TAU, 28, Color(col, 0.5), 1.5)
		draw_string(ThemeDB.fallback_font, p + Vector2(16, 5), String(n["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.82, 0.88, 0.94))
		var sub := ""
		match kind:
			"current":
				sub = "FLEET HOLDING"
			"next":
				sub = "NEXT TRANSITION"
			"danger":
				sub = "HOSTILE RETURN"
			"resource":
				sub = "SALVAGE / ICE"
		draw_string(ThemeDB.fallback_font, p + Vector2(16, 21), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.55, 0.62, 0.7))

func _node_pos(node_id: String, r: Vector2) -> Vector2:
	for n in NODES:
		if String(n["id"]) == node_id:
			return Vector2(float(n["pos"].x) * r.x, float(n["pos"].y) * r.y)
	return Vector2.ZERO
