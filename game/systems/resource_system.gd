class_name ResourceSystem
extends RefCounted

static func get_resource(state: CampaignState, key: String) -> float:
	if state == null or not state.resources.has(key):
		return 0.0
	return float(state.resources[key])

static func set_resource(state: CampaignState, key: String, value: float) -> float:
	if state == null or not state.resources.has(key):
		return 0.0
	state.resources[key] = state.clamp_resource(key, value)
	return float(state.resources[key])

static func add(state: CampaignState, key: String, delta: float) -> float:
	if state == null or not state.resources.has(key):
		return 0.0
	return set_resource(state, key, get_resource(state, key) + delta)

static func can_afford(state: CampaignState, costs: Dictionary) -> bool:
	return state != null and state.can_afford(costs)

static func spend(state: CampaignState, costs: Dictionary) -> bool:
	return state != null and state.pay_costs(costs)

static func produce(state: CampaignState, gains: Dictionary) -> void:
	if state != null:
		state.apply_gains(gains)
