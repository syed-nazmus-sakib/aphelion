extends Control

signal campaign_started

func _ready() -> void:
	$Panel/StartButton.pressed.connect(_on_start)
	$Panel/ContinueButton.pressed.connect(_on_continue)
	$Panel/QuitButton.pressed.connect(get_tree().quit)

func _on_start() -> void:
	campaign_started.emit()

func _on_continue() -> void:
	var loaded := SaveSystem.load_campaign(SaveManager.save_path())
	if loaded == null:
		$Panel/StatusLabel.text = "No saved migration found."
		return
	campaign_started.emit()
