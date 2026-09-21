extends Control

signal choice_made(event_id: String, index: int)
signal dismissed

var title_label: Label
var body_label: Label
var buttons: Array[Button] = []
var current_effects: Array = []

func _ready() -> void:
	visible = false
	title_label = $Panel/VBox/Title
	body_label = $Panel/VBox/Body
	for i in range(3):
		var button: Button = get_node("Panel/VBox/Choice%d" % i)
		buttons.append(button)
		button.pressed.connect(_on_choice.bind(i))

func present(event: Dictionary) -> void:
	title_label.text = String(event.get("title", ""))
	body_label.text = String(event.get("body", ""))
	var choices: Array = event.get("choices", [])
	current_effects = choices
	for i in range(buttons.size()):
		var button: Button = buttons[i]
		button.visible = i < choices.size()
		if i < choices.size():
			var c: Dictionary = choices[i]
			var label_text: String = String(c.get("label", ""))
			var desc: String = String(c.get("description", ""))
			if not desc.is_empty():
				button.text = "%s\n%s" % [label_text, desc]
			else:
				button.text = label_text
			button.tooltip_text = _effects_line(c)
	set_meta("event_id", String(event.get("id", "")))
	visible = true

func _effects_line(choice: Dictionary) -> String:
	var fx: Dictionary = choice.get("effects", {})
	if fx.is_empty():
		return String(choice.get("description", ""))
	var parts: Array[String] = []
	for k in fx:
		var v: float = float(fx[k])
		var sign_str: String = "+" if v >= 0.0 else ""
		parts.append("%s %s%.1f" % [String(k), sign_str, v])
	return "%s\n[%s]" % [String(choice.get("description", "")), ", ".join(parts)]

func _on_choice(index: int) -> void:
	choice_made.emit(get_meta("event_id"), index)
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		# Events require a decision; Esc does not dismiss, it nudges.
		get_viewport().set_input_as_handled()
