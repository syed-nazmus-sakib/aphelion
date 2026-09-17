extends SceneTree

var failures: int = 0

func check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)

func _initialize() -> void:
	var state := CampaignState.new_campaign("Test migration", 42)
	check(state.population == 450000, "Asteria population")
	var baseline: Dictionary = state.to_dict()
	var restored := CampaignState.from_dict(JSON.parse_string(JSON.stringify(baseline)))
	check(restored != null, "JSON save roundtrip")
	check(restored.to_dict() == baseline, "roundtrip preserves campaign")
	check(CampaignState.from_dict({"schema_version": 999}) == null, "schema version rejected")
	var corrupt: Variant = JSON.parse_string(JSON.stringify(baseline))
	corrupt.population = -5
	check(CampaignState.from_dict(corrupt) == null, "negative population rejected")
	var bad_seed: Variant = JSON.parse_string(JSON.stringify(baseline))
	bad_seed.rng_seed = 42
	check(CampaignState.from_dict(bad_seed) == null, "rng seed type rejected")
	var path: String = OS.get_environment("HOME") + "/.local_share/godot/app_userdata/The Last Migration/test_save.json"
	check(SaveSystem.save_campaign(state, path) == OK, "atomic save")
	var loaded := SaveSystem.load_campaign(path)
	check(loaded != null and loaded.to_dict() == baseline, "save load roundtrip")
	var second := CampaignState.new_campaign("Second", 42)
	check(second.advance_rng() == state.advance_rng(), "seeded rng deterministic")
	quit(1 if failures > 0 else 0)
