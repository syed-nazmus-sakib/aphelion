class_name CombatResult
extends RefCounted

var victory: bool = false
var hull_damage: float = 0.0
var casualties: int = 0
var kills: int = 0
var salvage: int = 0

func _init(p_victory: bool = false, p_hull_damage: float = 0.0, p_casualties: int = 0, p_kills: int = 0, p_salvage: int = 0) -> void:
	victory = p_victory
	hull_damage = maxf(0.0, p_hull_damage)
	casualties = maxi(0, p_casualties)
	kills = maxi(0, p_kills)
	salvage = maxi(0, p_salvage)

func to_dict() -> Dictionary:
	return {"victory": victory, "hull_damage": hull_damage, "casualties": casualties, "kills": kills, "salvage": salvage}

static func from_dict(data: Dictionary) -> CombatResult:
	if not (data.has("victory") and data.has("hull_damage") and data.has("casualties") and data.has("kills") and data.has("salvage")):
		return null
	var hull_ok: bool = typeof(data["hull_damage"]) == TYPE_FLOAT or typeof(data["hull_damage"]) == TYPE_INT
	var count_ok: bool = typeof(data["casualties"]) == TYPE_INT or typeof(data["casualties"]) == TYPE_FLOAT
	var kills_ok: bool = typeof(data["kills"]) == TYPE_INT or typeof(data["kills"]) == TYPE_FLOAT
	var salvage_ok: bool = typeof(data["salvage"]) == TYPE_INT or typeof(data["salvage"]) == TYPE_FLOAT
	if typeof(data["victory"]) != TYPE_BOOL or not hull_ok or not count_ok or not kills_ok or not salvage_ok:
		return null
	return CombatResult.new(data["victory"], float(data["hull_damage"]), int(data["casualties"]), int(data["kills"]), int(data["salvage"]))
