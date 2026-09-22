extends Control

signal choice_made(event_id: String, index: int)
signal dismissed

const MAX_VISIBLE_CHOICES: int = 3

var title_label: Label
var body_label: Label
var choices_box: VBoxContainer
var choice_rows: Array[VBoxContainer] = []
var choice_buttons: Array[Button] = []
var _state: CampaignState = null
var _tween: Tween = null
var _event_id: String = ""

func _ready() -> void:
	visible = false
	title_label = $Center/Panel/VBox/Title
	body_label = $Center/Panel/VBox/Body
	choices_box = $Center/Panel/VBox/Choices

func present(event: Dictionary, state: CampaignState = null) -> void:
	_event_id = String(event.get("id", ""))
	title_label.text = String(event.get("title", ""))
	body_label.text = String(event.get("body", ""))
	_state = state
	var choices: Array = event.get("choices", [])
	_rebuild_choices(choices)
	visible = true
	modulate.a = 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, 0.22)

func _rebuild_choices(choices: Array) -> void:
	for child in choices_box.get_children():
		choices_box.remove_child(child)
		child.queue_free()
	choice_rows.clear()
	choice_buttons.clear()
	for i in range(mini(choices.size(), MAX_VISIBLE_CHOICES)):
		var c: Dictionary = choices[i]
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		choices_box.add_child(row)
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 54)
		var label_text: String = String(c.get("label", ""))
		var desc: String = String(c.get("description", ""))
		button.text = "%d · %s" % [i + 1, label_text]
		if not desc.is_empty():
			button.text += "\n    %s" % desc
		button.tooltip_text = _effects_line(c)
		if _state != null and not _can_afford(c):
			button.disabled = true
			button.tooltip_text = "Insufficient reserves.\n" + button.tooltip_text
		button.pressed.connect(_on_choice.bind(i))
		row.add_child(button)
		choice_buttons.append(button)
		choice_rows.append(row)
		var chips := HBoxContainer.new()
		chips.add_theme_constant_override("separation", 6)
		row.add_child(chips)
		var fx: Dictionary = c.get("effects", {})
		for key in fx:
			var v: float = float(fx[key])
			var unit: String = "%" if key in ["food", "energy", "morale", "hull", "readiness"] else ""
			var sign_char: String = "+" if v >= 0.0 else "-"
			var chip := ThemeKit.chip("%s %s%.0f%s" % [String(key), sign_char, absf(v), unit], v > 0.0)
			chips.add_child(chip)
		if c.has("delayed_effects"):
			var delayed: Dictionary = c["delayed_effects"]
			var parts: Array[String] = []
			for dkey in delayed:
				parts.append("%s %+.0f" % [String(dkey), float(delayed[dkey])])
			chips.add_child(ThemeKit.chip("later: %s" % ", ".join(parts), true))

func _can_afford(choice: Dictionary) -> bool:
	if _state == null:
		return true
	var fx: Dictionary = choice.get("effects", {})
	for key in fx:
		if key in ["energy", "materials", "medicine"] and float(fx[key]) < 0.0:
			if float(_state.resources.get(key, 0.0)) < -float(fx[key]):
				return false
	return true

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
	if _event_id.is_empty():
		return
	choice_made.emit(_event_id, index)
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		# Events require a decision; Esc does not dismiss, it nudges.
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var code: Key = event.keycode
		if code >= KEY_1 and code <= KEY_3:
			var idx: int = int(code - KEY_1)
			if idx < choice_buttons.size() and not choice_buttons[idx].disabled:
				_on_choice(idx)
				get_viewport().set_input_as_handled()
