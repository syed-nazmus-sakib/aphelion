class_name PopulationSystem
extends RefCounted

static func change_population(state: CampaignState, delta: int) -> int:
	state.population = maxi(0, state.population + delta)
	return state.population

static func apply_casualties(state: CampaignState, casualties: int) -> int:
	return change_population(state, -maxi(0, casualties))

static func daily_tick(state: CampaignState) -> void:
	var births: int = int(round(state.population * 0.00004))
	var deaths: int = int(round(state.population * 0.000025))
	change_population(state, births - deaths)
	ResourceSystem.add(state, "food", -0.12)
	ResourceSystem.add(state, "energy", 0.08)
	ResourceSystem.add(state, "materials", 8.0)
	if state.resources.food <= 0.0:
		var losses: int = maxi(1, int(state.population * 0.0002))
		apply_casualties(state, losses)
		ResourceSystem.add(state, "morale", -0.5)
		HistorySystem.record(state, "shortage", "Food reserves exhausted", "%d people lost to prolonged shortages." % losses)
