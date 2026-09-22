extends SceneTree

var failures: int = 0

func check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: %s" % label)
	else:
		failures += 1
		printerr("FAIL: %s" % label)

func _initialize() -> void:
	# global theme resource wired into project settings
	check(ResourceLoader.exists("res://ui/migration_theme.tres"), "theme resource exists")
	check(ProjectSettings.get_setting("gui/theme/custom", "") == "res://ui/migration_theme.tres", "project theme set")

	# StatBar eases + flashes deltas
	var bar := StatBar.new()
	bar.setup("Food", Color.GREEN)
	root.add_child(bar)
	bar.set_target(80.0)
	for i in range(180):
		await process_frame
		if absf(bar.display_value - 80.0) < 1.0:
			break
	check(absf(bar.display_value - 80.0) < 1.0, "stat bar eases to target (%.1f)" % bar.display_value)
	bar.set_target(60.0)
	check(bar._flash > 0.0, "stat bar flashes on change")
	bar.queue_free()

	# SpaceBackground + SensorScope boot
	var bg := SpaceBackground.new()
	root.add_child(bg)
	await process_frame
	check(bg._stars.size() > 200, "space background seeded")
	bg.queue_free()
	var scope := SensorScope.new()
	root.add_child(scope)
	await process_frame
	check(scope._blips.size() > 0, "sensor scope seeded")
	scope.queue_free()

	# StarMap click selection
	var map := StarMap.new()
	root.add_child(map)
	await process_frame
	map.size = Vector2(520, 360)
	var got := [""]
	map.node_selected.connect(func(id: String) -> void: got[0] = id)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = map.node_pos("charon", map.size)
	map._gui_input(click)
	check(got[0] == "charon", "star map click emits selection")
	check(map.selected_id == "charon", "star map selection stored")
	check(StarMap.label_for("galene") == "Galene Drift", "node label lookup")
	check(StarMap.id_for_location("Hollow Signal") == "hollow", "location maps to node id")
	map.queue_free()

	# ArkshipDiagram hit-testing + state
	var diagram := ArkshipDiagram.new()
	root.add_child(diagram)
	await process_frame
	diagram.apply_state(CampaignState.new_campaign("T", 1))
	check(diagram.district_count() == 7, "seven districts")
	var g := diagram._band_geometry()
	var mid_x: float = g.position.x + g.size.x * 0.5
	check(diagram.district_at(mid_x) >= 0, "district hit-test inside hull")
	check(diagram.district_at(-50.0) == -1, "district miss outside hull")
	diagram.queue_free()

	# plot course mechanics
	var st := CampaignState.new_campaign("Course", 3)
	check(FleetSystem.plot_course(st, "galene", "Galene Drift"), "plot course accepts new destination")
	check(FleetSystem.course_node(st) == "galene", "course flag readable")
	check(st.flags.has("course:galene"), "course flag stored")
	check(not FleetSystem.plot_course(st, "charon", "Charon Staging"), "cannot plot current holding")
	check(not FleetSystem.plot_course(st, "galene", "Galene Drift"), "no duplicate plot")
	check(FleetSystem.plot_course(st, "thresh", "Thresher Cache"), "course can be changed")
	check(not st.flags.has("course:galene"), "old course replaced")
	var course_count := 0
	for f in st.flags:
		if String(f).begins_with("course:"):
			course_count += 1
	check(course_count == 1, "exactly one course flag")
	# course survives save roundtrip
	var roundtrip := CampaignState.from_dict(JSON.parse_string(JSON.stringify(st.to_dict())))
	check(roundtrip != null and FleetSystem.course_node(roundtrip) == "thresh", "course persists through save")

	# Strategy view integration
	var sv: Control = load("res://scenes/strategy_view.tscn").instantiate()
	root.add_child(sv)
	await process_frame
	await process_frame
	sv.refresh(st)
	await process_frame
	check(sv.stat_bars.size() == 7, "seven stat bars built")
	check(sv.star_map != null, "star map present")
	check(sv.diagram != null, "arkship diagram present")
	check(sv.objective_label.text != "", "objective populated")
	check(sv.date_big.text.contains("Y"), "date badge populated")
	check(sv.dest_label.text.contains("Thresher"), "destination shows plotted course")
	sv.star_map.select_node("galene")
	check(sv._selected_node == "galene", "intel follows map selection")
	check(sv.intel_name.text == "Galene Drift", "intel shows node label")
	check(not sv.plot_btn.disabled, "plot enabled for non-fleet node")
	var emitted := [""]
	sv.course_requested.connect(func(id: String, _lbl: String) -> void: emitted[0] = id)
	sv.plot_btn.pressed.emit()
	check(emitted[0] == "galene", "plot button emits course_requested")
	sv.star_map.select_node("charon")
	check(sv.plot_btn.disabled, "plot disabled for fleet holding")
	sv.show_toast("Test toast", "ok")
	await process_frame
	check(sv.toast_box.get_child_count() == 1, "toast queued")
	sv._toggle_history(true)
	await process_frame
	var vp := root.get_visible_rect()
	var close_found := false
	for b in sv.find_children("*", "Button", true, false):
		if (b as Button).text == "CLOSE" and (b as Control).is_visible_in_tree() and vp.encloses((b as Control).get_global_rect()):
			close_found = true
	check(close_found, "history CLOSE on screen")
	sv.queue_free()

	# Event panel: chips, affordability, keyboard
	var ep: Control = load("res://scenes/event_panel.tscn").instantiate()
	root.add_child(ep)
	await process_frame
	var events := EventSystem.new()
	var hydro: Dictionary = events.events["hydroponics_failure"]
	ep.present(hydro, st)
	await process_frame
	check(ep.visible, "event panel visible")
	check(ep.choice_buttons.size() == 3, "three choice buttons")
	var chip_count := 0
	for row in ep.choice_rows:
		chip_count += (row.get_child(1) as HBoxContainer).get_child_count()
	check(chip_count >= 8, "effect chips rendered (%d)" % chip_count)
	st.resources["energy"] = 10.0
	ep.present(hydro, st)
	await process_frame
	check(ep.choice_buttons[0].disabled, "unaffordable choice disabled")
	check(not ep.choice_buttons[1].disabled, "affordable choice enabled")
	var picked := [-1]
	ep.choice_made.connect(func(_id: String, i: int) -> void: picked[0] = i)
	var key := InputEventKey.new()
	key.keycode = KEY_2
	key.pressed = true
	ep._unhandled_input(key)
	check(picked[0] == 1, "keyboard 1-3 picks choice")
	ep.queue_free()

	# Main menu still wired
	var menu: PackedScene = load("res://scenes/main_menu.tscn")
	check(menu != null, "main menu scene present")
	var m: Control = menu.instantiate()
	root.add_child(m)
	await process_frame
	check(m.get_node_or_null("Stars") != null, "menu has animated starfield")
	check(m.get_node_or_null("Panel/StartButton") != null, "menu buttons intact")
	m.queue_free()

	# Opening typewriter boots
	var opening: PackedScene = load("res://scenes/opening.tscn")
	var op: Control = opening.instantiate()
	root.add_child(op)
	op.play()
	await process_frame
	await process_frame
	check(op.visible, "opening plays")
	op.queue_free()

	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)
