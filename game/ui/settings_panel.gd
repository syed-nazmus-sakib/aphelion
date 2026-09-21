extends Control

signal closed

var volume_slider: HSlider
var mute_check: CheckButton
var status_label: Label

func _ready() -> void:
	visible = false
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.7)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)
	var title := Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 26)
	vb.add_child(title)
	var vl := Label.new()
	vl.text = "Master volume"
	vb.add_child(vl)
	volume_slider = HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 100.0
	volume_slider.step = 1.0
	volume_slider.value = 80.0
	volume_slider.value_changed.connect(_on_volume)
	vb.add_child(volume_slider)
	mute_check = CheckButton.new()
	mute_check.text = "Mute all audio"
	mute_check.toggled.connect(_on_mute)
	vb.add_child(mute_check)
	status_label = Label.new()
	status_label.text = "Audio placeholders: no shipped tracks in the vertical slice."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(0.6, 0.68, 0.76))
	vb.add_child(status_label)
	var back := Button.new()
	back.text = "BACK"
	back.pressed.connect(func() -> void: closed.emit())
	vb.add_child(back)

func open() -> void:
	visible = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		closed.emit()
		get_viewport().set_input_as_handled()

func _on_volume(v: float) -> void:
	var db: float = linear_to_db(clampf(v / 100.0, 0.001, 1.0))
	AudioServer.set_bus_volume_db(0, db)
	AudioServer.set_bus_mute(0, false)
	mute_check.set_pressed_no_signal(false)

func _on_mute(muted: bool) -> void:
	AudioServer.set_bus_mute(0, muted)
