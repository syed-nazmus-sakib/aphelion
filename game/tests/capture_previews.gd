extends SceneTree

# Windowed preview capture — drives key screens and saves PNGs to logs/previews.
# Run (NOT headless): tools/godot/godot --path game --script res://tests/capture_previews.gd

const OUT_DIR: String = "res://../logs/previews"
var shot_index: int = 0

func _initialize() -> void:
	var dir_path := ProjectSettings.globalize_path(OUT_DIR)
	DirAccess.make_dir_recursive_absolute(dir_path)
	print("OUT: ", dir_path)

	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await _settle()

	await _shot(main, "01_menu")

	# new migration dialog
	var nm: Control = main.get_node("NewMigration")
	nm.open()
	await _settle(8)
	await _shot(main, "02_new_migration")
	nm.visible = false

	# opening mid-sequence
	var op: Control = main.get_node("Opening")
	op.play()
	for i in range(45):
		await process_frame
	await _shot(main, "03_opening")

	# strategy: fresh campaign
	var state := CampaignState.new_campaign("Asteria Prime", 41789)
	FleetSystem.plot_course(state, "galene", "Galene Drift")
	var sv: Control = main.get_node("StrategyView")
	op.visible = false
	main.get_node("MainMenu").visible = false
	sv.visible = true
	sv.refresh(state)
	await _settle(20)
	sv.star_map.select_node("hollow")
	sv.show_toast("Advanced 30 days · Y0 M01 D30", "info")
	sv.show_toast("Hydroponics Fault — Emergency sterilization", "warn")
	await _settle(40)
	await _shot(main, "04_strategy")

	# event panel with chips
	var ep: Control = main.get_node("EventPanel")
	var events := EventSystem.new()
	ep.present(events.events["hydroponics_failure"], state)
	await _settle(20)
	await _shot(main, "05_event")
	ep.visible = false

	# combat brief with sensor scope
	state.pending_combat = true
	var brief: Control = main.get_node("CombatBrief")
	brief.present(state)
	await _settle(30)
	await _shot(main, "06_combat_brief")
	brief.visible = false

	# history overlay
	state.record_history({"type": "event", "label": "Hydroponics Fault", "detail": "Emergency sterilization"})
	state.record_history({"type": "combat", "label": "Victory", "detail": "hull -12.0 casualties 38 kills 24 salvage 210"})
	sv.refresh(state)
	sv._toggle_history(true)
	await _settle(15)
	await _shot(main, "07_history")
	sv._toggle_history(false)

	# combat itself
	var combat_scene: PackedScene = load("res://scenes/combat.tscn")
	var cv: Node = combat_scene.instantiate()
	sv.visible = false
	main.get_node("CombatHolder").add_child(cv)
	(cv as CombatView).setup(94.0, 77.0, 41789 + 30)
	for i in range(60 * 5):
		await process_frame
	await _shot(main, "08_combat")

	print("DONE: %d screenshots" % shot_index)
	quit(0)

func _settle(frames: int = 12) -> void:
	for i in range(frames):
		await process_frame
	await RenderingServer.frame_post_draw

func _shot(main: Node, name: String) -> void:
	shot_index += 1
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path: String = ProjectSettings.globalize_path(OUT_DIR) + "/" + name + ".png"
	var err := img.save_png(path)
	if err != OK:
		printerr("SHOT FAIL: %s (%d)" % [name, err])
	else:
		print("SHOT: %s (%dx%d)" % [name, img.get_width(), img.get_height()])
