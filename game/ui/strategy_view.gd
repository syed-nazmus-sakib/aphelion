extends Control

signal advance_requested
signal repair_requested
signal save_requested
signal menu_requested
signal course_requested(node_id: String, node_label: String)

const STAT_KEYS: Array[String] = ["food", "energy", "materials", "medicine", "morale", "hull", "readiness"]
const STAT_MAXES := {"materials": 30000.0, "medicine": 10000.0}
const STAT_SUFFIXES := {"materials": "", "medicine": ""}

var header_label: Label
var date_big: Label
var date_small: Label
var location_label: Label
var dest_label: Label
var alert_box: PanelContainer
var alert_label: Label
var pop_value_label: Label
var pop_delta_label: Label
var diagram: ArkshipDiagram
var stat_bars: Dictionary = {}
var star_map: StarMap
var intel_name: Label
var intel_kind: Label
var intel_blurb: Label
var intel_meta: Label
var plot_btn: Button
var objective_label: Label
var history_label: Label
var history_full: Label
var message_label: Label
var advance_btn: Button
var repair_btn: Button
var save_btn: Button
var history_overlay: Control
var toast_box: VBoxContainer

var _pop_target: float = 0.0
var _pop_display: float = 0.0
var _pop_flash: float = 0.0
var _pop_flash_text: String = ""
var _pop_flash_good: bool = true
var _has_pop: bool = false
var _prev_pop: int = -1
var _alert_t: float = 0.0
var _selected_node: String = ""
var _plotted_node: String = ""

func _ready() -> void:
	_build()

func _build() -> void:
	var bg := SpaceBackground.new()
	bg.name = "Background"
	add_child(bg)
	var root := VBoxContainer.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 22
	root.offset_right = -22
	root.offset_top = 12
	root.offset_bottom = -12
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	# --- top bar ---
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	root.add_child(top)
	var top_left := VBoxContainer.new()
	top_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_left.add_theme_constant_override("separation", 0)
	top.add_child(top_left)
	header_label = ThemeKit.make_label("APHELION", 24, Color(0.9, 0.95, 1.0))
	top_left.add_child(header_label)
	var date_row := HBoxContainer.new()
	date_row.add_theme_constant_override("separation", 12)
	top_left.add_child(date_row)
	date_big = ThemeKit.make_label("Y0 M01 D01", 16, ThemeKit.ACCENT_TEAL)
	date_row.add_child(date_big)
	date_small = ThemeKit.make_label("", 13, ThemeKit.TEXT_DIM)
	date_row.add_child(date_small)
	var top_right := VBoxContainer.new()
	top_right.add_theme_constant_override("separation", 0)
	top_right.alignment = BoxContainer.ALIGNMENT_END
	top.add_child(top_right)
	location_label = ThemeKit.make_label("Charon Staging", 15, ThemeKit.TEXT)
	location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_right.add_child(location_label)
	dest_label = ThemeKit.make_label("DEST: —", 13, ThemeKit.TEXT_DIM)
	dest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_right.add_child(dest_label)

	# --- alert strip ---
	alert_box = PanelContainer.new()
	alert_box.visible = false
	root.add_child(alert_box)
	var alert_sb := StyleBoxFlat.new()
	alert_sb.bg_color = Color(1.0, 0.3, 0.25, 0.14)
	alert_sb.border_width_left = 3
	alert_sb.border_width_top = 1
	alert_sb.border_width_right = 1
	alert_sb.border_width_bottom = 1
	alert_sb.border_color = ThemeKit.DANGER
	alert_sb.content_margin_left = 10.0
	alert_sb.content_margin_right = 10.0
	alert_sb.content_margin_top = 4.0
	alert_sb.content_margin_bottom = 4.0
	alert_box.add_theme_stylebox_override("panel", alert_sb)
	alert_label = ThemeKit.make_label("", 14, Color(1.0, 0.75, 0.7))
	alert_box.add_child(alert_label)

	# --- main row ---
	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 14)
	root.add_child(main)

	# left: Asteria
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(318, 0)
	left.add_theme_constant_override("separation", 6)
	main.add_child(left)
	left.add_child(ThemeKit.section("ASTERIA — ARKSHIP"))
	diagram = ArkshipDiagram.new()
	diagram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	diagram.custom_minimum_size = Vector2(310, 176)
	left.add_child(diagram)
	var pop_row := HBoxContainer.new()
	pop_row.add_theme_constant_override("separation", 10)
	left.add_child(pop_row)
	var pop_vb := VBoxContainer.new()
	pop_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pop_vb.add_theme_constant_override("separation", 0)
	pop_row.add_child(pop_vb)
	pop_vb.add_child(ThemeKit.section("POPULATION"))
	pop_value_label = ThemeKit.make_label("450,000", 30, Color(0.92, 0.96, 1.0))
	pop_vb.add_child(pop_value_label)
	pop_delta_label = ThemeKit.make_label("", 14, ThemeKit.TEXT_DIM)
	pop_delta_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	pop_row.add_child(pop_delta_label)
	for key in STAT_KEYS:
		var bar := StatBar.new()
		bar.setup(String(ThemeKit.RESOURCE_TITLES.get(key, key)), ThemeKit.resource_color(key),
			float(STAT_MAXES.get(key, 100.0)), String(STAT_SUFFIXES.get(key, "%")))
		left.add_child(bar)
		stat_bars[key] = bar

	# center: star map + intel
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 6)
	main.add_child(center)
	center.add_child(ThemeKit.section("STRATEGIC REGION — CHARON REACH"))
	star_map = StarMap.new()
	star_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(star_map)
	star_map.node_selected.connect(_on_node_selected)
	var intel := PanelContainer.new()
	intel.custom_minimum_size = Vector2(0, 118)
	center.add_child(intel)
	var intel_vb := VBoxContainer.new()
	intel_vb.add_theme_constant_override("separation", 4)
	intel.add_child(intel_vb)
	var intel_head := HBoxContainer.new()
	intel_head.add_theme_constant_override("separation", 10)
	intel_vb.add_child(intel_head)
	intel_name = ThemeKit.make_label("Select a contact", 17, Color(0.9, 0.95, 1.0))
	intel_head.add_child(intel_name)
	intel_kind = ThemeKit.make_label("", 12, ThemeKit.TEXT_DIM)
	intel_head.add_child(intel_kind)
	intel_blurb = ThemeKit.make_label("Click a system on the map to inspect threat, salvage and transit estimates.", 13, ThemeKit.TEXT_DIM)
	intel_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intel_blurb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	intel_vb.add_child(intel_blurb)
	intel_meta = ThemeKit.make_label("", 13, ThemeKit.TEXT)
	intel_vb.add_child(intel_meta)
	var intel_actions := HBoxContainer.new()
	intel_actions.add_theme_constant_override("separation", 10)
	intel_vb.add_child(intel_actions)
	plot_btn = Button.new()
	plot_btn.text = "PLOT COURSE"
	plot_btn.disabled = true
	plot_btn.pressed.connect(_on_plot_pressed)
	intel_actions.add_child(plot_btn)
	var legend := ThemeKit.make_label("Teal ring: fleet · Blue: next transition · Red: hostile return · Gold: salvage/ice", 12, ThemeKit.TEXT_DIM)
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(legend)

	# right: objective + log
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(292, 0)
	right.add_theme_constant_override("separation", 8)
	main.add_child(right)
	var obj_panel := PanelContainer.new()
	right.add_child(obj_panel)
	var obj_vb := VBoxContainer.new()
	obj_vb.add_theme_constant_override("separation", 4)
	obj_panel.add_child(obj_vb)
	obj_vb.add_child(ThemeKit.section("OBJECTIVE"))
	objective_label = ThemeKit.make_label("", 15, Color(0.95, 0.88, 0.6))
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	obj_vb.add_child(objective_label)
	right.add_child(ThemeKit.section("FLEET LOG (RECENT)"))
	history_label = ThemeKit.make_label("", 13, Color(0.68, 0.76, 0.84))
	history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	history_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(history_label)

	# --- bottom bar ---
	var bottom := VBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	root.add_child(bottom)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 10)
	bottom.add_child(nav)
	var fleet_btn := _btn(nav, "FLEET", true)
	fleet_btn.tooltip_text = "Fleet overview is part of this dashboard in the vertical slice."
	var asteria_btn := _btn(nav, "ASTERIA", true)
	asteria_btn.tooltip_text = "You are viewing Asteria."
	var research_btn := _btn(nav, "RESEARCH", true)
	research_btn.tooltip_text = "Locked in the vertical slice — research choices arrive via events."
	var history_btn := _btn(nav, "HISTORY", false)
	history_btn.pressed.connect(_toggle_history.bind(true))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(spacer)
	advance_btn = _btn(nav, "ADVANCE 30 DAYS", false)
	advance_btn.pressed.connect(func() -> void: advance_requested.emit())
	repair_btn = _btn(nav, "REPAIR HULL", false)
	repair_btn.tooltip_text = "Spend 100 materials per hull point (max 10 per action)."
	repair_btn.pressed.connect(func() -> void: repair_requested.emit())
	save_btn = _btn(nav, "SAVE", false)
	save_btn.pressed.connect(func() -> void: save_requested.emit())
	var menu_btn := _btn(nav, "MENU", false)
	menu_btn.pressed.connect(func() -> void: menu_requested.emit())
	message_label = ThemeKit.make_label("Each number is people. A damaged farm is twenty thousand children eating less this winter.", 13, ThemeKit.TEXT_DIM)
	bottom.add_child(message_label)

	# --- toasts (top-center overlay) ---
	var toast_layer := Control.new()
	toast_layer.name = "ToastLayer"
	toast_layer.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toast_layer.offset_left = 430.0
	toast_layer.offset_right = -430.0
	toast_layer.offset_top = 14.0
	toast_layer.offset_bottom = 300.0
	toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_layer)
	toast_box = VBoxContainer.new()
	toast_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toast_box.add_theme_constant_override("separation", 6)
	toast_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	toast_layer.add_child(toast_box)

	# --- history overlay (hidden) ---
	history_overlay = Control.new()
	history_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	history_overlay.visible = false
	add_child(history_overlay)
	var hdim := ColorRect.new()
	hdim.set_anchors_preset(Control.PRESET_FULL_RECT)
	hdim.color = Color(0, 0, 0, 0.6)
	history_overlay.add_child(hdim)
	var hcenter := CenterContainer.new()
	hcenter.set_anchors_preset(Control.PRESET_FULL_RECT)
	history_overlay.add_child(hcenter)
	var hpanel := PanelContainer.new()
	hpanel.custom_minimum_size = Vector2(640, 420)
	hcenter.add_child(hpanel)
	var hvb := VBoxContainer.new()
	hvb.add_theme_constant_override("separation", 10)
	hpanel.add_child(hvb)
	var ht := ThemeKit.make_label("FLEET HISTORY", 22, Color(0.9, 0.95, 1.0))
	hvb.add_child(ht)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 300)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hvb.add_child(scroll)
	history_full = ThemeKit.make_label("", 13, ThemeKit.TEXT)
	history_full.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	history_full.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(history_full)
	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.pressed.connect(_toggle_history.bind(false))
	hvb.add_child(close_btn)

func _btn(parent: Container, text: String, disabled: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = disabled
	parent.add_child(b)
	return b

func _toggle_history(open: bool) -> void:
	history_overlay.visible = open

# --- intel ---

func _on_node_selected(node_id: String) -> void:
	_selected_node = node_id
	update_intel(node_id)

func update_intel(node_id: String) -> void:
	var n := StarMap.node_by_id(node_id)
	if n.is_empty():
		intel_name.text = "Select a contact"
		intel_kind.text = ""
		intel_blurb.text = "Click a system on the map to inspect threat, salvage and transit estimates."
		intel_meta.text = ""
		plot_btn.disabled = true
		plot_btn.text = "PLOT COURSE"
		return
	var kind := String(n["kind"])
	intel_name.text = String(n["label"])
	var kind_text := ""
	match kind:
		"current":
			kind_text = "FLEET HOLDING"
		"next":
			kind_text = "NEXT TRANSITION"
		"danger":
			kind_text = "HOSTILE RETURN"
		"resource":
			kind_text = "SALVAGE / ICE"
	if node_id == star_map.fleet_node_id:
		kind_text = "FLEET HOLDING"
	intel_kind.text = kind_text
	intel_kind.add_theme_color_override("font_color", _kind_color(kind, node_id))
	intel_blurb.text = String(n["blurb"])
	var threat: int = int(n["threat"])
	var pips := ""
	for i in range(3):
		pips += "#" if i < threat else "-"
	intel_meta.text = "THREAT [%s]   SALVAGE: %s   TRANSIT: %dd" % [pips, String(n["resource"]), int(n["travel_days"])]
	var is_fleet: bool = node_id == star_map.fleet_node_id
	plot_btn.disabled = is_fleet or node_id == _plotted_node
	plot_btn.text = "ALREADY PLOTTED" if (not is_fleet and node_id == _plotted_node) else "PLOT COURSE"

func _kind_color(kind: String, node_id: String) -> Color:
	if node_id == star_map.fleet_node_id:
		return Color(0.55, 0.95, 0.8)
	match kind:
		"next":
			return Color(0.55, 0.8, 1.0)
		"danger":
			return ThemeKit.DANGER
		"resource":
			return ThemeKit.WARN
	return ThemeKit.TEXT_DIM

func _on_plot_pressed() -> void:
	if _selected_node.is_empty():
		return
	course_requested.emit(_selected_node, StarMap.label_for(_selected_node))

# --- toasts ---

func show_toast(text: String, kind: String = "info") -> void:
	if not is_inside_tree():
		return
	while toast_box.get_child_count() >= 4:
		var oldest: Node = toast_box.get_child(0)
		toast_box.remove_child(oldest)
		oldest.queue_free()
	var col := ThemeKit.ACCENT
	match kind:
		"ok":
			col = ThemeKit.GOOD
		"warn":
			col = ThemeKit.WARN
		"danger":
			col = ThemeKit.DANGER
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.05, 0.09, 0.95)
	sb.border_width_left = 3
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = col
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 6
	panel.add_theme_stylebox_override("panel", sb)
	var lbl := ThemeKit.make_label(text, 13, Color(col.r, col.g, col.b, 0.95))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(300, 0)
	panel.add_child(lbl)
	panel.modulate.a = 0.0
	toast_box.add_child(panel)
	var tw := panel.create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.2)
	tw.tween_interval(3.4)
	tw.tween_property(panel, "modulate:a", 0.0, 0.45)
	tw.tween_callback(panel.queue_free)

# --- refresh ---

func _recent_history(state: CampaignState, max_entries: int) -> String:
	if state == null or state.history.is_empty():
		return ""
	var lines: Array[String] = []
	var start: int = maxi(0, state.history.size() - max_entries)
	for i in range(start, state.history.size()):
		var e: Dictionary = state.history[i]
		var day_label: String = TimeSystem.date_label(int(e.get("day", 0)))
		lines.append("%s — %s: %s" % [day_label, String(e.get("label", "")), String(e.get("detail", ""))])
	return "\n".join(lines)

func refresh(state: CampaignState) -> void:
	if state == null:
		return
	header_label.text = state.campaign_name
	date_big.text = CampaignDate.from_total_days(state.day).short_label()
	date_small.text = TimeSystem.date_label(state.day)
	location_label.text = "%s · seed %d" % [state.location, state.seed_value]
	var course := FleetSystem.course_node(state)
	_plotted_node = course
	dest_label.text = ("DEST: %s" % StarMap.label_for(course)) if course != "" else "DEST: —"
	star_map.set_fleet_location(state.location)
	star_map.set_course(course)
	diagram.apply_state(state)
	for key in STAT_KEYS:
		var bar: StatBar = stat_bars[key]
		bar.set_target(float(state.resources.get(key, 0.0)))
	_pop_target = float(state.population)
	if not _has_pop:
		# first paint: let the counter ease up from zero
		_has_pop = true
	if _prev_pop >= 0 and state.population != _prev_pop:
		var pop_delta: int = state.population - _prev_pop
		_pop_flash = 1.6
		_pop_flash_good = pop_delta > 0
		_pop_flash_text = "%+d" % pop_delta
	_prev_pop = state.population

	var objective: String = "Advance the migration. Watch supplies, then push toward Galene Drift."
	if state.pending_combat:
		objective = "HOSTILE CONTACT closing. Open the alert and launch the interceptor."
	elif state.active_event != "":
		objective = "Decision required. The ship is waiting for your order."
	elif float(state.resources.hull) < 40.0:
		objective = "Hull critical. Repair before advancing or risk losing compartments."
	elif float(state.resources.food) < 25.0:
		objective = "Food reserves low. Every day costs lives — resolve the shortage."
	objective_label.text = objective

	# alert strip
	if state.pending_combat:
		alert_box.visible = true
		alert_label.text = "!! HOSTILE CONTACT — combat imminent. Launch from the alert panel."
		alert_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.65))
	elif state.active_event != "":
		alert_box.visible = true
		alert_label.text = "DECISION REQUIRED — Asteria waits for Fleet Command."
		alert_label.add_theme_color_override("font_color", ThemeKit.WARN)
	else:
		alert_box.visible = false

	history_label.text = _recent_history(state, 6)
	history_full.text = _recent_history(state, 60)
	if history_full.text.is_empty():
		history_full.text = "No entries yet. History begins with your first decision."
	var blocked: bool = state.pending_combat or state.active_event != ""
	advance_btn.disabled = blocked or state.population <= 0 or float(state.resources.hull) <= 0.0
	var missing: float = 100.0 - float(state.resources.hull)
	repair_btn.disabled = blocked or missing <= 0.0 or float(state.resources.materials) < 100.0
	if _selected_node != "":
		update_intel(_selected_node)
	star_map.queue_redraw()

func _process(delta: float) -> void:
	# population number easing
	if absf(_pop_display - _pop_target) > 0.5:
		_pop_display += (_pop_target - _pop_display) * minf(1.0, delta * 3.5)
		if absf(_pop_display - _pop_target) <= 0.5:
			_pop_display = _pop_target
		if pop_value_label != null:
			pop_value_label.text = "%d" % int(round(_pop_display))
	elif pop_value_label != null and pop_value_label.text != "%d" % int(round(_pop_target)):
		_pop_display = _pop_target
		pop_value_label.text = "%d" % int(round(_pop_display))
	if _pop_flash > 0.0:
		_pop_flash = maxf(0.0, _pop_flash - delta)
		if pop_delta_label != null:
			if _pop_flash > 0.0 and _pop_flash_text != "":
				var col: Color = ThemeKit.GOOD if _pop_flash_good else ThemeKit.DANGER
				pop_delta_label.text = _pop_flash_text
				pop_delta_label.add_theme_color_override("font_color", Color(col.r, col.g, col.b, minf(1.0, _pop_flash * 1.5)))
			else:
				pop_delta_label.text = ""
	# alert pulse
	_alert_t += delta
	if alert_box != null and alert_box.visible:
		var pulse: float = 0.72 + 0.28 * sin(_alert_t * 5.0)
		alert_box.modulate.a = pulse
