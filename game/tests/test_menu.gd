extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/main_menu.tscn")
	if scene == null:
		printerr("FAIL: main menu scene missing")
		quit(1)
		return
	var menu: Control = scene.instantiate()
	root.add_child(menu)
	await process_frame
	var start: Button = menu.get_node("Panel/StartButton")
	var cont: Button = menu.get_node("Panel/ContinueButton")
	var settings: Button = menu.get_node("Panel/SettingsButton")
	var quit_btn: Button = menu.get_node("Panel/QuitButton")
	if start == null or cont == null or settings == null or quit_btn == null:
		printerr("FAIL: menu buttons missing")
		quit(1)
		return
	if settings.disabled:
		printerr("FAIL: settings button should be enabled")
		quit(1)
		return
	var pressed := [false]
	menu.new_requested.connect(func() -> void: pressed[0] = true)
	start.pressed.emit()
	await process_frame
	if not pressed[0]:
		printerr("FAIL: start button did not fire new_requested")
		quit(1)
		return
	# main scene boot check
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	if main_scene == null:
		printerr("FAIL: main.tscn missing")
		quit(1)
		return
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	for path in ["MainMenu", "Opening", "StrategyView", "EventPanel", "CombatBrief", "NewMigration", "SettingsPanel", "CombatHolder"]:
		if main.get_node_or_null(path) == null:
			printerr("FAIL: Main missing %s" % path)
			quit(1)
			return
	var combat_scene: PackedScene = load("res://scenes/combat.tscn")
	if combat_scene == null:
		printerr("FAIL: combat.tscn missing")
		quit(1)
		return
	print("PASS: menu boots, signals work, main + combat scenes present")
	quit(0)
