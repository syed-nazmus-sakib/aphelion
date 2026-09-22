extends Control

# Distant arkship convoy crossing behind the main menu. Sits between the
# starfield and the menu panel so it isn't painted over.

var _t: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(true)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var r := size
	var y: float = r.y * 0.22
	for i in range(6):
		var t: float = fposmod(_t * 0.012 + i * 0.16, 1.3) - 0.15
		var x: float = t * (r.x + 200.0) - 100.0
		var p := Vector2(x, y + sin(i * 1.7 + _t * 0.3) * 8.0 + i * 14.0)
		var alpha: float = clampf(1.45 - t, 0.3, 0.75)
		# hull
		var hull := PackedVector2Array([
			p + Vector2(-20, -4), p + Vector2(14, -4), p + Vector2(23, 0),
			p + Vector2(14, 4), p + Vector2(-20, 4)])
		draw_colored_polygon(hull, Color(0.6, 0.75, 0.85, alpha))
		draw_polyline(hull + PackedVector2Array([hull[0]]), Color(0.7, 0.9, 1.0, alpha * 0.7), 1.0)
		# engine glow
		var glow: float = 0.5 + 0.5 * sin(_t * 6.0 + i)
		draw_circle(p + Vector2(-22, 0), 3.5 + 1.5 * glow, Color(0.4, 0.8, 1.0, alpha * (0.4 + 0.4 * glow)))
		draw_line(p + Vector2(-22, 0), p + Vector2(-46.0 - 8.0 * glow, 0), Color(0.35, 0.7, 1.0, alpha * 0.3), 2.0)
