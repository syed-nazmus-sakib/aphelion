class_name FleetSystem
extends RefCounted

const REPAIR_COST_PER_HULL: float = 100.0
const MAX_REPAIR_HULL: float = 10.0

static func apply_combat_result(state: CampaignState, result: CombatResult) -> bool:
	if state == null or result == null:
		return false
	if not state.pending_combat:
		return false
	if state.flags.has("encounter_resolved"):
		return false
	state.flags.append("encounter_resolved")
	state.record_history({"type": "flag", "label": "encounter_resolved", "detail": ""})
	state.pending_combat = false
	state.resources["hull"] = state.clamp_resource("hull", float(state.resources.get("hull", 0.0)) - result.hull_damage)
	var lost: int = maxi(0, result.casualties)
	state.population = maxi(0, state.population - lost)
	state.resources["materials"] = state.clamp_resource("materials", float(state.resources.get("materials", 0.0)) + float(result.salvage))
	state.last_result = result.to_dict()
	var label: String = "Victory" if result.victory else "Defeat"
	state.record_history({"type": "combat", "label": label, "detail": "hull -%.1f casualties %d kills %d salvage %d" % [result.hull_damage, result.casualties, result.kills, result.salvage]})
	return true

static func repair(state: CampaignState) -> bool:
	if state == null or state.pending_combat or state.active_event != "":
		return false
	var hull: float = float(state.resources.get("hull", 0.0))
	var missing: float = 100.0 - hull
	if missing <= 0.0:
		return false
	var points: float = minf(minf(missing, MAX_REPAIR_HULL), float(state.resources.get("materials", 0.0)) / REPAIR_COST_PER_HULL)
	if points <= 0.0:
		return false
	var cost: float = points * REPAIR_COST_PER_HULL
	state.resources["materials"] = state.clamp_resource("materials", float(state.resources["materials"]) - cost)
	state.resources["hull"] = state.clamp_resource("hull", hull + points)
	state.record_history({"type": "repair", "label": "Hull repaired", "detail": "+%.1f hull for %d materials" % [points, int(cost)]})
	return true
