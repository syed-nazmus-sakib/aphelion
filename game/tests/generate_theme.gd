extends SceneTree

# One-shot generator: rebuilds res://ui/migration_theme.tres from ThemeKit.
# Run: tools/godot/godot --headless --path game --script res://tests/generate_theme.gd

func _initialize() -> void:
	var theme := ThemeKit.build_theme()
	var err := ResourceSaver.save(theme, "res://ui/migration_theme.tres")
	if err != OK:
		printerr("FAIL: could not save theme (error %d)" % err)
		quit(1)
		return
	print("SAVED: res://ui/migration_theme.tres")
	quit(0)
