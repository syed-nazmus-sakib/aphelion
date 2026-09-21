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
	# modal dialogs must be fully on-screen (regression: manual
	# PRESET_CENTER + position math pushed them to bottom-right)
	var vp: Rect2 = root.get_visible_rect()
	var nm: Control = main.get_node("NewMigration")
	nm.open()
	await process_frame
	await process_frame
	if not _button_on_screen(nm, "BEGIN EXODUS", vp):
		printerr("FAIL: BEGIN EXODUS not on screen")
		quit(1)
		return
	var started := [false]
	nm.start_requested.connect(func(_n: String, _s: int, _d: int) -> void: started[0] = true)
	_press_button(nm, "BEGIN EXODUS")
	await process_frame
	if not started[0]:
		printerr("FAIL: BEGIN EXODUS did not emit start_requested")
		quit(1)
		return
	var sp: Control = main.get_node("SettingsPanel")
	sp.open()
	await process_frame
	await process_frame
	if not _button_on_screen(sp, "BACK", vp):
		printerr("FAIL: settings BACK not on screen")
		quit(1)
		return
	# history overlay inside strategy view
	var sv: Control = main.get_node("StrategyView")
	sv.visible = true
	sv.refresh(CampaignState.new_campaign("Layout", 99))
	await process_frame
	sv._toggle_history(true)
	await process_frame
	if not _button_on_screen(sv, "CLOSE", vp):
		printerr("FAIL: history CLOSE not on screen")
		quit(1)
		return
	# combat end panel
	var cv: Node2D = combat_scene.instantiate()
	root.add_child(cv)
	await process_frame
	await process_frame
	cv._on_arena_finished(CombatResult.new(true, 5.0, 10, 20, 100))
	await process_frame
	if not _button_on_screen(cv, "RETURN TO FLEET", vp):
		printerr("FAIL: RETURN TO FLEET not on screen")
		quit(1)
		return
	print("PASS: menu boots, signals work, main + combat scenes present")
	print("PASS: all modal dialogs centered on screen")
	quit(0)

func _button_on_screen(node: Node, text: String, vp: Rect2) -> bool:
	for b in node.find_children("*", "Button", true, false):
		if (b as Button).text == text:
			var r: Rect2 = (b as Control).get_global_rect()
			if (b as Control).is_visible_in_tree() and vp.encloses(r):
				return true
	return false

func _press_button(node: Node, text: String) -> void:
	for b in node.find_children("*", "Button", true, false):
		if (b as Button).text == text:
			(b as Button).pressed.emit()
			return
