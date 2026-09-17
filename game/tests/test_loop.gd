extends SceneTree

var failures: int = 0

func check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)

func _initialize() -> void:
	var state := CampaignState.new_campaign("Loop test", 7)
	var events := EventSystem.new()
	var combat_seen: bool = false
	var memorial_seen: bool = false
	for step in range(60):
		TimeSystem.advance(state, 30)
		while true:
			var event: Dictionary = events.available(state)
			if event.is_empty():
				if state.active_event != "":
					state.active_event = ""
					continue
				break
			if event.id == "first_contact":
				combat_seen = true
				var before: int = state.population
				events.choose(state, event.id, 0)
				var result := CombatResult.new(true, 18.0, 42, 31, 260)
				check(FleetSystem.apply_combat_result(state, result), "combat result applied")
				check(state.population == before - 42, "casualties applied")
				check(state.resources.hull == 82.0, "hull damage applied")
			elif event.id == "memorial_service":
				memorial_seen = true
				events.choose(state, event.id, 0)
			else:
				events.choose(state, event.id, 0)
		if state.pending_combat:
			state.pending_combat = false
		if memorial_seen and combat_seen:
			break
	check(combat_seen, "combat encounter reached")
	check(memorial_seen, "memorial triggered after casualties")
	check(state.history.size() >= 5, "history accumulated")
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)
