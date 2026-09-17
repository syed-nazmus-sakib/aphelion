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
	if start == null:
		printerr("FAIL: StartButton missing")
		quit(1)
		return
	var pressed := [false]
	menu.campaign_started.connect(func() -> void: pressed[0] = true)
	start.pressed.emit()
	await process_frame
	if pressed[0]:
		print("PASS: menu boots and start button works")
		quit(0)
	else:
		printerr("FAIL: start button did not fire signal")
		quit(1)
