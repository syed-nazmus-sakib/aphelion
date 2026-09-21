extends Control

signal new_requested
signal continue_requested
signal settings_requested

var status_label: Label
var continue_btn: Button

func _ready() -> void:
	$Panel/StartButton.pressed.connect(func() -> void: new_requested.emit())
	continue_btn = $Panel/ContinueButton
	continue_btn.pressed.connect(func() -> void: continue_requested.emit())
	$Panel/SettingsButton.disabled = false
	$Panel/SettingsButton.pressed.connect(func() -> void: settings_requested.emit())
	$Panel/QuitButton.pressed.connect(get_tree().quit)
	refresh()

func refresh() -> void:
	status_label = $Panel/StatusLabel
	if SaveManager.has_save():
		continue_btn.disabled = false
		status_label.text = "Saved migration found. Continue the journey."
	else:
		continue_btn.disabled = true
		status_label.text = "No saved migration. Begin a new journey."
