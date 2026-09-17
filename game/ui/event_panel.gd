extends Control

signal choice_made(event_id: String, index: int)
signal dismissed

func _ready() -> void:
	visible = false
	for i in range(3):
		var button: Button = get_node("Panel/VBox/Choice%d" % i)
		button.pressed.connect(_on_choice.bind(i))

func present(event: Dictionary) -> void:
	$Panel/VBox/Title.text = String(event.get("title", ""))
	$Panel/VBox/Body.text = String(event.get("body", ""))
	var choices: Array = event.get("choices", [])
	for i in range(3):
		var button: Button = get_node("Panel/VBox/Choice%d" % i)
		button.visible = i < choices.size()
		if i < choices.size():
			button.text = String(choices[i].get("label", ""))
	visible = true

func _on_choice(index: int) -> void:
	choice_made.emit(get_meta("event_id"), index)
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		dismissed.emit()
