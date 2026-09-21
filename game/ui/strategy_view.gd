extends Control

signal advance_requested
signal repair_requested
signal save_requested
signal menu_requested

var header_label: Label
var location_label: Label
var stats_label: Label
var districts_label: Label
var objective_label: Label
var history_label: Label
var message_label: Label
var star_map: StarMap
var advance_btn: Button
var repair_btn: Button
var save_btn: Button
var history_overlay: Control
var history_full: Label

const DISTRICTS: Array = [
	{"id": "Command", "hint": "coordination"},
	{"id": "Habitation", "hint": "morale"},
	{"id": "Agriculture", "hint": "food"},
	{"id": "Industry", "hint": "materials"},
	{"id": "Medical", "hint": "medicine"},
	{"id": "Reactor", "hint": "energy"},
	{"id": "Hangars", "hint": "readiness"},
]

func _ready() -> void:
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.035, 0.07)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 28
	root.offset_right = -28
	root.offset_top = 16
	root.offset_bottom = -16
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	# top bar
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	root.add_child(top)
	header_label = Label.new()
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_label.add_theme_font_size_override("font_size", 24)
	header_label.add_theme_color_override("font_color", Color(0.8, 0.9, 0.95))
	top.add_child(header_label)
	location_label = Label.new()
	location_label.add_theme_font_size_override("font_size", 15)
	location_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	top.add_child(location_label)
	# main row
	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 16)
	root.add_child(main)
	# left: fleet summary
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(300, 0)
	left.add_theme_constant_override("separation", 8)
	main.add_child(left)
	left.add_child(_section("ASTERIA — ARKSHIP SUMMARY"))
	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 16)
	left.add_child(stats_label)
	left.add_child(_section("DISTRICTS (CONCEPTUAL)"))
	districts_label = Label.new()
	districts_label.add_theme_font_size_override("font_size", 14)
	districts_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.88))
	left.add_child(districts_label)
	# center: star map
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 8)
	main.add_child(center)
	center.add_child(_section("STRATEGIC REGION — CHARON REACH"))
	star_map = StarMap.new()
	star_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(star_map)
	var legend := Label.new()
	legend.text = "Teal ring: fleet holding · Blue: next transition · Red: hostile return · Gold: salvage/ice"
	legend.add_theme_font_size_override("font_size", 12)
	legend.add_theme_color_override("font_color", Color(0.55, 0.62, 0.7))
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(legend)
	# right: objective + history
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(330, 0)
	right.add_theme_constant_override("separation", 8)
	main.add_child(right)
	right.add_child(_section("OBJECTIVE"))
	objective_label = Label.new()
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.add_theme_font_size_override("font_size", 16)
	objective_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.55))
	right.add_child(objective_label)
	right.add_child(_section("FLEET LOG (RECENT)"))
	history_label = Label.new()
	history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	history_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history_label.add_theme_font_size_override("font_size", 13)
	history_label.add_theme_color_override("font_color", Color(0.68, 0.76, 0.84))
	right.add_child(history_label)
	# bottom bar
	var bottom := VBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	root.add_child(bottom)
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 10)
	bottom.add_child(nav)
	var fleet_btn := _btn(nav, "FLEET", false)
	fleet_btn.tooltip_text = "Fleet overview is part of this dashboard in the vertical slice."
	var asteria_btn := _btn(nav, "ASTERIA", false)
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
	message_label = Label.new()
	message_label.add_theme_font_size_override("font_size", 13)
	message_label.add_theme_color_override("font_color", Color(0.6, 0.72, 0.85))
	bottom.add_child(message_label)
	# history overlay (hidden)
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
	var ht := Label.new()
	ht.text = "FLEET HISTORY"
	ht.add_theme_font_size_override("font_size", 22)
	hvb.add_child(ht)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 300)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hvb.add_child(scroll)
	history_full = Label.new()
	history_full.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	history_full.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(history_full)
	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.pressed.connect(_toggle_history.bind(false))
	hvb.add_child(close_btn)

func _section(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color(0.5, 0.65, 0.78))
	return l

func _btn(parent: Container, text: String, disabled: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.disabled = disabled
	if disabled:
		b.tooltip_text = "Locked in the vertical slice."
	parent.add_child(b)
	return b

func _toggle_history(open: bool) -> void:
	history_overlay.visible = open

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
	header_label.text = "%s — %s" % [state.campaign_name, TimeSystem.date_label(state.day)]
	location_label.text = "%s · seed %d" % [state.location, state.seed_value]
	stats_label.text = "\n".join([
		"Population      %d souls" % state.population,
		"Food            %.0f%%" % float(state.resources.food),
		"Energy          %.0f%%" % float(state.resources.energy),
		"Materials       %d" % int(state.resources.materials),
		"Medicine        %d" % int(state.resources.medicine),
		"Morale          %.0f" % float(state.resources.morale),
		"Hull Integrity  %.0f%%" % float(state.resources.hull),
		"Military Read.  %.0f%%" % float(state.resources.readiness),
	])
	districts_label.text = _districts_text(state)
	var objective: String = "Advance the migration. Watch supplies, then push toward Galene Drift."
	if state.pending_combat:
		objective = "HOSTILE CONTACT closing. Open the alert and launch the interceptor."
	elif state.active_event != "":
		objective = "Decision required. Open the event log — the ship is waiting."
	elif float(state.resources.hull) < 40.0:
		objective = "Hull critical. Repair before advancing or risk losing compartments."
	elif float(state.resources.food) < 25.0:
		objective = "Food reserves low. Every day costs lives — resolve the shortage."
	objective_label.text = objective
	history_label.text = _recent_history(state, 5)
	history_full.text = _recent_history(state, 60)
	if history_full.text.is_empty():
		history_full.text = "No entries yet. History begins with your first decision."
	var blocked: bool = state.pending_combat or state.active_event != ""
	advance_btn.disabled = blocked or state.population <= 0 or float(state.resources.hull) <= 0.0
	var missing: float = 100.0 - float(state.resources.hull)
	repair_btn.disabled = blocked or missing <= 0.0 or float(state.resources.materials) < 100.0
	message_label.text = "Each number is people. A damaged farm is twenty thousand children eating less this winter."
	star_map.queue_redraw()

func _districts_text(state: CampaignState) -> String:
	var lines: Array[String] = []
	for d in DISTRICTS:
		var key := _district_key(String(d["id"]))
		var val := float(state.resources.get(key, 50.0))
		var bar := _bar(val)
		lines.append("%-11s %s %3.0f" % [String(d["id"]), bar, val])
	return "\n".join(lines)

func _district_key(district: String) -> String:
	match district:
		"Command":
			return "readiness"
		"Habitation":
			return "morale"
		"Agriculture":
			return "food"
		"Industry":
			return "materials"
		"Medical":
			return "medicine"
		"Reactor":
			return "energy"
		"Hangars":
			return "readiness"
	return "morale"

func _bar(v: float) -> String:
	# materials/medicine are absolute; normalize for bar display
	var n: float = v
	if v > 100.0:
		n = 100.0 if v > 1000.0 else v / 10.0
	n = clampf(n, 0.0, 100.0)
	var filled: int = int(n / 10.0)
	var s := "["
	for i in range(10):
		s += "#" if i < filled else "-"
	return s + "]"
