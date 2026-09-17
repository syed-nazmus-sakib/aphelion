class_name EventSystem
extends RefCounted

const EVENTS_PATH: String = "res://content/events.json"

var events: Dictionary = {}

func _init() -> void:
	_load_events()

func _load_events() -> void:
	events = {}
	if not FileAccess.file_exists(EVENTS_PATH):
		return
	var file: FileAccess = FileAccess.open(EVENTS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("events"):
		return
	var raw_events = parsed["events"]
	if typeof(raw_events) != TYPE_ARRAY:
		return
	for entry in raw_events:
		var event: Dictionary = _normalize_event(entry)
		if not event.is_empty():
			events[event["id"]] = event

func _normalize_event(entry) -> Dictionary:
	if typeof(entry) != TYPE_DICTIONARY:
		return {}
	if typeof(entry.get("id", null)) != TYPE_STRING or String(entry["id"]).is_empty():
		return {}
	if typeof(entry.get("title", null)) != TYPE_STRING or typeof(entry.get("body", null)) != TYPE_STRING:
		return {}
	var choices: Array = []
	var raw_choices = entry.get("choices", [])
	if typeof(raw_choices) != TYPE_ARRAY or raw_choices.is_empty():
		return {}
	for raw_choice in raw_choices:
		if typeof(raw_choice) != TYPE_DICTIONARY:
			return {}
		if typeof(raw_choice.get("label", null)) != TYPE_STRING:
			return {}
		var choice: Dictionary = {
			"label": String(raw_choice["label"]),
			"description": String(raw_choice.get("description", "")),
			"effects": {},
		}
		var raw_effects = raw_choice.get("effects", {})
		if typeof(raw_effects) == TYPE_DICTIONARY:
			for key in raw_effects:
				choice["effects"][String(key)] = float(raw_effects[key])
		if raw_choice.has("delayed_effects"):
			var raw_delayed = raw_choice["delayed_effects"]
			if typeof(raw_delayed) == TYPE_DICTIONARY:
				choice["delayed_effects"] = {}
				for key in raw_delayed:
					choice["delayed_effects"][String(key)] = float(raw_delayed[key])
			choice["delay_days"] = maxi(1, int(raw_choice.get("delay_days", 1)))
		choices.append(choice)
	return {
		"id": String(entry["id"]),
		"title": String(entry["title"]),
		"body": String(entry["body"]),
		"day": maxi(0, int(entry.get("day", 0))),
		"requires_flag": String(entry.get("requires_flag", "")),
		"requires_last_result_casualties": bool(entry.get("requires_last_result_casualties", false)),
		"day_offset_from_trigger": maxi(0, int(entry.get("day_offset_from_trigger", 0))),
		"sets_pending_combat": bool(entry.get("sets_pending_combat", false)),
		"choices": choices,
	}

func available(state: CampaignState) -> Dictionary:
	if state == null:
		return {}
	if state.pending_combat or state.active_event != "":
		return {}
	for id in events:
		var event: Dictionary = events[id]
		if state.flags.has("event_done:%s" % id):
			continue
		if event.get("requires_last_result_casualties", false) and int(state.last_result.get("casualties", 0)) <= 0:
			continue
		var due_day: int = int(event.get("day", 0))
		if event.get("requires_flag", "") != "":
			var trigger: int = _flag_day(state, event["requires_flag"])
			if trigger < 0:
				continue
			due_day = trigger + int(event.get("day_offset_from_trigger", 0))
		if state.day < due_day:
			continue
		return event
	return {}

func _flag_day(state: CampaignState, flag: String) -> int:
	for entry in state.history:
		if String(entry.get("type", "")) == "flag" and String(entry.get("label", "")) == flag:
			return int(entry.get("day", 0))
	return -1

func choose(state: CampaignState, event_id: String, choice_index: int) -> bool:
	if state == null:
		return false
	if not events.has(event_id):
		return false
	var event: Dictionary = events[event_id]
	if state.active_event != event_id and available(state).get("id", "") != event_id:
		return false
	var choices: Array = event.get("choices", [])
	if choice_index < 0 or choice_index >= choices.size():
		return false
	if state.flags.has("event_done:%s" % event_id):
		return false
	var choice: Dictionary = choices[choice_index]
	var costs: Dictionary = {}
	for key in choice.effects:
		if key in ["energy", "materials", "medicine"] and float(choice.effects[key]) < 0.0:
			costs[key] = -float(choice.effects[key])
	if not state.can_afford(costs):
		return false
	state.apply_gains(choice.get("effects", {}))
	if choice.has("delayed_effects"):
		state.flags.append("delay:%s:%d:%s" % [event_id, state.day + int(choice.get("delay_days", 1)), JSON.stringify(choice["delayed_effects"])])
	if event.get("sets_pending_combat", false):
		state.pending_combat = true
	state.flags.append("event_done:%s" % event_id)
	state.active_event = ""
	state.record_history({"type": "event", "label": event["title"], "detail": String(choice.get("label", ""))})
	return true
