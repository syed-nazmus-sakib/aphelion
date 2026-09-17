class_name HistorySystem
extends RefCounted

static func record(state: CampaignState, type: String, label: String, detail: String) -> void:
	if state != null:
		state.record_history({"type": type, "label": label, "detail": detail})

static func add_delayed(state: CampaignState, effect_id: String, due_day: int, payload: Dictionary) -> void:
	if state == null:
		return
	state.flags.append("delay:%s:%d:%s" % [effect_id, due_day, JSON.stringify(payload)])

static func due_delayed(state: CampaignState) -> Array:
	var due: Array = []
	if state == null:
		return due
	for i in range(state.flags.size() - 1, -1, -1):
		var entry: String = String(state.flags[i])
		if entry.begins_with("delay:"):
			var parts := entry.split(":", false, 3)
			if parts.size() >= 4 and int(parts[2]) <= state.day:
				var parsed: Variant = JSON.parse_string(parts[3])
				var payload: Dictionary = parsed if typeof(parsed) == TYPE_DICTIONARY else {}
				due.append({"effect_id": parts[1], "due_day": int(parts[2]), "payload": payload})
				state.flags.remove_at(i)
	return due

static func has_flag(state: CampaignState, flag: String) -> bool:
	return state != null and state.flags.has(flag)

static func add_flag(state: CampaignState, flag: String) -> void:
	if state != null and not state.flags.has(flag):
		state.flags.append(flag)
