class_name ThemeKit
extends RefCounted

# Shared visual language: restrained serious sci-fi.
const BG_DEEP := Color(0.016, 0.028, 0.055)
const BG_PANEL := Color(0.035, 0.06, 0.105, 0.97)
const BORDER := Color(0.32, 0.58, 0.7, 0.5)
const ACCENT := Color(0.45, 0.85, 0.9)
const ACCENT_TEAL := Color(0.4, 0.92, 0.78)
const TEXT := Color(0.83, 0.89, 0.94)
const TEXT_DIM := Color(0.55, 0.64, 0.72)
const WARN := Color(1.0, 0.78, 0.35)
const DANGER := Color(1.0, 0.42, 0.38)
const GOOD := Color(0.5, 0.93, 0.7)

const RESOURCE_COLORS := {
	"food": Color(0.55, 0.85, 0.5),
	"energy": Color(1.0, 0.8, 0.4),
	"materials": Color(0.55, 0.7, 0.9),
	"medicine": Color(0.72, 0.9, 1.0),
	"morale": Color(0.78, 0.68, 0.96),
	"hull": Color(0.45, 0.85, 0.9),
	"readiness": Color(0.96, 0.62, 0.45),
}

const RESOURCE_TITLES := {
	"food": "Food",
	"energy": "Energy",
	"materials": "Materials",
	"medicine": "Medicine",
	"morale": "Morale",
	"hull": "Hull Integrity",
	"readiness": "Military Readiness",
}

static func resource_color(key: String) -> Color:
	return RESOURCE_COLORS.get(key, ACCENT)

static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 15
	# Button
	t.set_stylebox("normal", "Button", _box(Color(0.07, 0.12, 0.18, 0.95), BORDER, 1))
	t.set_stylebox("hover", "Button", _box(Color(0.1, 0.19, 0.27, 1.0), Color(0.5, 0.88, 0.95, 0.95), 1))
	t.set_stylebox("pressed", "Button", _box(Color(0.04, 0.09, 0.13, 1.0), ACCENT_TEAL, 1))
	t.set_stylebox("disabled", "Button", _box(Color(0.05, 0.07, 0.1, 0.55), Color(0.25, 0.3, 0.35, 0.4), 1))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", ACCENT_TEAL)
	t.set_color("font_disabled_color", "Button", Color(0.42, 0.47, 0.52))
	t.set_font_size("font_size", "Button", 15)
	# Panels
	t.set_stylebox("panel", "PanelContainer", _panel_box())
	t.set_stylebox("panel", "TooltipPanel", _box(Color(0.03, 0.05, 0.09, 0.98), Color(0.4, 0.7, 0.8, 0.7), 1, 6, 8.0))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_font_size("font_size", "TooltipLabel", 13)
	# Labels
	t.set_color("font_color", "Label", TEXT)
	t.set_font_size("font_size", "Label", 15)
	# LineEdit
	t.set_stylebox("normal", "LineEdit", _box(Color(0.05, 0.09, 0.14, 1.0), BORDER, 1))
	t.set_stylebox("focus", "LineEdit", _box(Color(0.06, 0.11, 0.16, 1.0), ACCENT, 1))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", Color(0.42, 0.5, 0.56))
	# OptionButton / CheckButton inherit Button type fallback in theme lookup.
	t.set_color("font_color", "OptionButton", TEXT)
	t.set_color("font_color", "CheckButton", TEXT)
	# Scroll/Sliders keep defaults; give HSlider grab highlights.
	t.set_stylebox("grab_area", "HSlider", _box(Color(0.2, 0.4, 0.5, 0.8), BORDER, 1, 2))
	t.set_stylebox("grab_area_highlight", "HSlider", _box(Color(0.35, 0.7, 0.8, 0.9), ACCENT, 1, 2))
	return t

static func _box(bg: Color, border: Color, width: int = 1, radius: int = 3, margin: float = 12.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left = width
	s.border_width_top = width
	s.border_width_right = width
	s.border_width_bottom = width
	s.border_color = border
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin * 0.7
	s.content_margin_bottom = margin * 0.7
	return s

static func _panel_box() -> StyleBoxFlat:
	var s := _box(BG_PANEL, BORDER, 1, 4, 16.0)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 10
	s.shadow_offset = Vector2(0, 3)
	return s

static func section(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", TEXT_DIM)
	l.add_theme_constant_override("letter_spacing", 1)
	return l

static func make_label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func chip(text: String, positive: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	var col: Color = GOOD if positive else DANGER
	l.add_theme_color_override("font_color", col)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col.r, col.g, col.b, 0.12)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(col.r, col.g, col.b, 0.55)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 6.0
	sb.content_margin_right = 6.0
	sb.content_margin_top = 2.0
	sb.content_margin_bottom = 2.0
	l.add_theme_stylebox_override("normal", sb)
	return l
