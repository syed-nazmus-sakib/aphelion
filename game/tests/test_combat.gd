extends SceneTree

func check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)

var failures: int = 0

func _initialize() -> void:
	var arena := CombatArena.new()
	arena.setup(100.0, 60.0, 11)
	var holder: Array = [null]
	arena.finished.connect(func(r: CombatResult) -> void: holder[0] = r)
	root.add_child(arena)
	var movement: Vector2 = Vector2.ZERO
	for frame in range(60 * 240):
		movement = Vector2(sin(frame * 0.05) * 0.9, 0.0)
		var firing: bool = true
		arena.step(1.0 / 60.0, movement, firing, false)
		if arena.paused:
			arena.paused = false
		if holder[0] != null:
			break
	var result: CombatResult = holder[0] as CombatResult
	if result == null:
		printerr("FAIL: combat never concluded in simulated four minutes")
		failures += 1
	else:
		check(result.kills > 0, "enemies destroyed: %d" % result.kills)
		check(result.hull_damage >= 0.0 and result.hull_damage < 100.0, "hull damage sane: %.1f" % result.hull_damage)
		check(result.casualties >= 0 and result.salvage >= 0, "casualties/salvage sane")
		print("RESULT: victory=%s kills=%d hull_dmg=%.1f casualties=%d salvage=%d" % [result.victory, result.kills, result.hull_damage, result.casualties, result.salvage])
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)
