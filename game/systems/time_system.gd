class_name TimeSystem
extends RefCounted

static func can_advance(state: CampaignState) -> bool:
	return state != null and not state.pending_combat and state.active_event == "" and state.resources.hull > 0.0 and state.population > 0

static func advance(state: CampaignState, days: int) -> bool:
	if days <= 0 or not can_advance(state):
		return false
	var events := EventSystem.new()
	for tick in range(mini(days, 360)):
		var event: Dictionary = events.available(state)
		if not event.is_empty():
			state.active_event = event.id
			return true
		state.day += 1
		PopulationSystem.daily_tick(state)
		for delayed in HistorySystem.due_delayed(state):
			state.apply_gains(delayed.payload)
			HistorySystem.record(state, "delayed", "Deferred consequences", delayed.effect_id)
		if not can_advance(state):
			break
	var due: Dictionary = events.available(state)
	if not due.is_empty():
		state.active_event = due.id
	return true

static func date_label(day: int) -> String:
	return CampaignDate.from_total_days(day).label()
