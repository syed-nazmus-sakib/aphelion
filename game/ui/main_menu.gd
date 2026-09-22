extends Control

signal new_requested
signal continue_requested
signal settings_requested

const CONVOY_SCRIPT := preload("res://ui/menu_convoy.gd")

var status_label: Label
var continue_btn: Button
var title_label: Label
var _t: float = 0.0

func _ready() -> void:
	$Panel/StartButton.pressed.connect(func() -> void: new_requested.emit())
	continue_btn = $Panel/ContinueButton
	continue_btn.pressed.connect(func() -> void: continue_requested.emit())
	$Panel/SettingsButton.disabled = false
	$Panel/SettingsButton.pressed.connect(func() -> void: settings_requested.emit())
	$Panel/QuitButton.pressed.connect(get_tree().quit)
	title_label = $Panel/Title
	# convoy must sit above the starfield child but below the panel
	var convoy: Control = CONVOY_SCRIPT.new()
	convoy.name = "Convoy"
	add_child(convoy)
	move_child(convoy, 2)
	set_process(true)
	refresh()

func refresh() -> void:
	status_label = $Panel/StatusLabel
	if SaveManager.has_save():
		continue_btn.disabled = false
		status_label.text = "Saved migration found. Continue the journey."
	else:
		continue_btn.disabled = true
		status_label.text = "No saved migration. Begin a new journey."

func _process(delta: float) -> void:
	_t += delta
	if title_label != null:
		var pulse: float = 0.88 + 0.12 * sin(_t * 1.4)
		title_label.modulate = Color(1, 1, 1, pulse)
