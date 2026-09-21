extends Control

signal start_requested(campaign_name: String, seed_value: int, difficulty: int)
signal cancelled

var name_edit: LineEdit
var seed_edit: LineEdit
var difficulty_btn: OptionButton

func _ready() -> void:
	visible = false
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.7)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(390, 200)
	panel.custom_minimum_size = Vector2(500, 0)
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	var title := Label.new()
	title.text = "NEW MIGRATION"
	title.add_theme_font_size_override("font_size", 26)
	vb.add_child(title)
	var info := Label.new()
	info.text = "One arkship. One region. Five centuries of consequence begin here."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(info)
	vb.add_child(_row("Expedition name:", _make_name()))
	vb.add_child(_row("Seed (blank = random):", _make_seed()))
	difficulty_btn = OptionButton.new()
	difficulty_btn.add_item("Standard — as balanced", 0)
	difficulty_btn.add_item("Story — steadier morale", 1)
	difficulty_btn.add_item("Harsh — thinner margins", 2)
	vb.add_child(_row("Difficulty:", difficulty_btn))
	var reroll := Button.new()
	reroll.text = "REROLL SEED"
	reroll.pressed.connect(func() -> void: seed_edit.text = str(randi()))
	vb.add_child(reroll)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	vb.add_child(hb)
	var start := Button.new()
	start.text = "BEGIN EXODUS"
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start.pressed.connect(_on_start)
	hb.add_child(start)
	var cancel := Button.new()
	cancel.text = "CANCEL"
	cancel.pressed.connect(func() -> void: cancelled.emit())
	hb.add_child(cancel)

func _row(label_text: String, control: Control) -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	var l := Label.new()
	l.text = label_text
	vb.add_child(l)
	vb.add_child(control)
	return vb

func _make_name() -> LineEdit:
	name_edit = LineEdit.new()
	name_edit.text = "Asteria Prime"
	name_edit.max_length = 40
	return name_edit

func _make_seed() -> LineEdit:
	seed_edit = LineEdit.new()
	seed_edit.text = str(randi())
	seed_edit.placeholder_text = "e.g. 41789"
	return seed_edit

func open() -> void:
	name_edit.text = "Asteria Prime"
	seed_edit.text = str(randi())
	difficulty_btn.selected = 0
	visible = true
	name_edit.grab_focus()

func _on_start() -> void:
	var cname: String = name_edit.text.strip_edges()
	if cname.is_empty():
		cname = "Asteria Prime"
	var seed_value: int = int(Time.get_ticks_usec() % 1000000)
	if not seed_edit.text.strip_edges().is_empty() and seed_edit.text.strip_edges().is_valid_int():
		seed_value = int(seed_edit.text.strip_edges())
	start_requested.emit(cname, seed_value, difficulty_btn.selected)
