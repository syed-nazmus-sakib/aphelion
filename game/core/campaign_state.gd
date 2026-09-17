class_name CampaignState
extends RefCounted

const SCHEMA_VERSION: int = 1
const RESOURCE_KEYS: Array[String] = ["food", "energy", "materials", "medicine", "morale", "hull", "readiness"]
const RESOURCE_BOUNDS: Dictionary = {"food": Vector2(0.0, 100.0), "energy": Vector2(0.0, 100.0), "materials": Vector2(0.0, 1000000.0), "medicine": Vector2(0.0, 1000000.0), "morale": Vector2(0.0, 100.0), "hull": Vector2(0.0, 100.0), "readiness": Vector2(0.0, 100.0)}
const DEFAULT_RESOURCES: Dictionary = {"food": 82.0, "energy": 71.0, "materials": 18420.0, "medicine": 6241.0, "morale": 68.0, "hull": 100.0, "readiness": 77.0}
const STARTING_POPULATION: int = 450000
const STARTING_LOCATION: String = "Charon Staging"

var campaign_name: String = ""
var seed_value: int = 0
var day: int = 0
var population: int = STARTING_POPULATION
var resources: Dictionary = {}
var flags: Array = []
var history: Array = []
var location: String = STARTING_LOCATION
var active_event: String = ""
var pending_combat: bool = false
var last_result: Dictionary = {}
var rng_seed: int = 0
var rng_state: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

static func new_campaign(p_name: String, p_seed: int) -> CampaignState:
	var state: CampaignState = CampaignState.new()
	state.campaign_name = p_name
	state.seed_value = p_seed
	state.rng_seed = p_seed
	state._rng.seed = p_seed
	state.rng_state = state._rng.state
	for key in RESOURCE_KEYS:
		state.resources[key] = float(DEFAULT_RESOURCES[key])
	return state

func rng() -> RandomNumberGenerator:
	if _rng.seed != rng_seed or _rng.state != rng_state:
		_rng.seed = rng_seed
		_rng.state = rng_state
	return _rng

func advance_rng() -> int:
	var generator := rng()
	var value: int = generator.randi()
	rng_seed = generator.seed
	rng_state = generator.state
	return value

func roll_rng() -> float:
	var generator := rng()
	var value: float = generator.randf()
	rng_seed = generator.seed
	rng_state = generator.state
	return value

func clamp_resource(key: String, value: float) -> float:
	if not RESOURCE_BOUNDS.has(key):
		return value
	var bounds: Vector2 = RESOURCE_BOUNDS[key]
	return clampf(value, bounds.x, bounds.y)

func can_afford(costs: Dictionary) -> bool:
	for key in costs:
		if not resources.has(key):
			return false
		if not is_finite(float(costs[key])) or float(costs[key]) < 0.0 or float(resources[key]) < float(costs[key]):
			return false
	return true

func pay_costs(costs: Dictionary) -> bool:
	if not can_afford(costs):
		return false
	for key in costs:
		resources[key] = clamp_resource(key, float(resources[key]) - float(costs[key]))
	return true

func apply_gains(gains: Dictionary) -> void:
	for key in gains:
		if resources.has(key):
			resources[key] = clamp_resource(key, float(resources[key]) + float(gains[key]))

func record_history(entry: Dictionary) -> void:
	var record: Dictionary = {"day": day, "type": String(entry.get("type", "")), "label": String(entry.get("label", "")), "detail": String(entry.get("detail", ""))}
	history.append(record)

func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"campaign_name": campaign_name,
		"seed_value": seed_value,
		"rng_seed": str(rng_seed),
		"rng_state": str(rng_state),
		"day": day,
		"population": population,
		"resources": resources.duplicate(true),
		"flags": flags.duplicate(true),
		"history": history.duplicate(true),
		"location": location,
		"active_event": active_event,
		"pending_combat": pending_combat,
		"last_result": last_result.duplicate(true),
	}

static func _is_int(value) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT and is_finite(value) and value == floor(value) and absf(value) <= 9007199254740991.0
static func _validate_resource_payload(payload: Dictionary) -> bool:
	for key in RESOURCE_KEYS:
		if not payload.has(key):
			return false
		var raw = payload[key]
		if typeof(raw) != TYPE_FLOAT and typeof(raw) != TYPE_INT:
			return false
		var bounds: Vector2 = RESOURCE_BOUNDS[key]
		if not is_finite(float(raw)) or float(raw) < bounds.x or float(raw) > bounds.y:
			return false
	return true

static func clamp_resource_static(value: float, key: String) -> float:
	if not RESOURCE_BOUNDS.has(key):
		return value
	var bounds: Vector2 = RESOURCE_BOUNDS[key]
	return clampf(value, bounds.x, bounds.y)

static func from_dict(data: Dictionary) -> CampaignState:
	if data == null or data.is_empty():
		return null
	if not _is_int(data.get("schema_version")) or data["schema_version"] != SCHEMA_VERSION:
		return null
	if typeof(data.get("campaign_name", null)) != TYPE_STRING:
		return null
	if not _is_int(data.get("seed_value", null)):
		return null
	if typeof(data.get("rng_seed")) != TYPE_STRING or not data["rng_seed"].is_valid_int():
		return null
	if typeof(data.get("rng_state")) != TYPE_STRING or not data["rng_state"].is_valid_int():
		return null
	if not _is_int(data.get("day", null)):
		return null
	if not _is_int(data.get("population", null)):
		return null
	if data["day"] < 0 or data["population"] < 0:
		return null
	if typeof(data.get("resources", null)) != TYPE_DICTIONARY:
		return null
	if not _validate_resource_payload(data["resources"]):
		return null
	if typeof(data.get("flags", null)) != TYPE_ARRAY:
		return null
	for flag in data["flags"]:
		if typeof(flag) != TYPE_STRING:
			return null
	if typeof(data.get("history", null)) != TYPE_ARRAY:
		return null
	for entry in data["history"]:
		if typeof(entry) != TYPE_DICTIONARY:
			return null
		if not _is_int(entry.get("day", null)) or typeof(entry.get("type", null)) != TYPE_STRING or typeof(entry.get("label", null)) != TYPE_STRING or typeof(entry.get("detail", null)) != TYPE_STRING:
			return null
	if typeof(data.get("location", null)) != TYPE_STRING:
		return null
	if typeof(data.get("active_event", null)) != TYPE_STRING:
		return null
	if typeof(data.get("pending_combat", null)) != TYPE_BOOL:
		return null
	if typeof(data.get("last_result", null)) != TYPE_DICTIONARY:
		return null
	if not data["last_result"].is_empty() and CombatResult.from_dict(data["last_result"]) == null:
		return null
	var state: CampaignState = CampaignState.new()
	state.campaign_name = String(data["campaign_name"])
	state.seed_value = int(data["seed_value"])
	state.rng_seed = int(data["rng_seed"])
	state.rng_state = int(data["rng_state"])
	state.day = int(data["day"])
	state.population = int(data["population"])
	state.resources = {}
	for key in RESOURCE_KEYS:
		state.resources[key] = CampaignState.clamp_resource_static(float(data["resources"][key]), key)
	state.flags = []
	for flag in data["flags"]:
		state.flags.append(String(flag))
	state.history = []
	for entry in data["history"]:
		state.history.append({
			"day": int(entry["day"]),
			"type": String(entry["type"]),
			"label": String(entry["label"]),
			"detail": String(entry["detail"]),
		})
	state.location = String(data["location"])
	state.active_event = String(data["active_event"])
	state.pending_combat = bool(data["pending_combat"])
	if not data["last_result"].is_empty():
		state.last_result = CombatResult.from_dict(data["last_result"]).to_dict()
	return state
