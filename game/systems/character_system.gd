class_name CharacterSystem
extends RefCounted

static func add_character(state: CampaignState, name: String, role: String) -> void:
	if state == null or name.is_empty():
		return
	for character in state.flags:
		if typeof(character) == TYPE_STRING and character.begins_with("character:"):
			var parts := character.split(":", false)
			if parts.size() >= 2 and parts[1] == name:
				return
	state.flags.append("character:%s:%s" % [name, role])

static func remove_character(state: CampaignState, name: String) -> bool:
	if state == null:
		return false
	for i in range(state.flags.size() - 1, -1, -1):
		var entry: String = String(state.flags[i])
		if entry.begins_with("character:"):
			var parts := entry.split(":", false)
			if parts.size() >= 2 and parts[1] == name:
				state.flags.remove_at(i)
				return true
	return false

static func list_characters(state: CampaignState) -> Array:
	var people: Array = []
	if state == null:
		return people
	for entry in state.flags:
		var text: String = String(entry)
		if text.begins_with("character:"):
			var parts := text.split(":", false)
			if parts.size() >= 3:
				people.append({"name": parts[1], "role": parts[2]})
	return people

static func has_character(state: CampaignState, name: String) -> bool:
	if state == null:
		return false
	for entry in state.flags:
		var text: String = String(entry)
		if text.begins_with("character:") and text.split(":", false).size() >= 2 and text.split(":", false)[1] == name:
			return true
	return false
