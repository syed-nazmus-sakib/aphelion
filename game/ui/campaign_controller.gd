extends Node

var combat_view: CombatView = null
var fade_layer: CanvasLayer = null
var fade_rect: ColorRect = null
var _fading: bool = false

func _ready() -> void:
	_build_fade()
	%MainMenu.new_requested.connect(_on_new_requested)
	%MainMenu.continue_requested.connect(_on_continue_requested)
	%MainMenu.settings_requested.connect(_on_settings_requested)
	%NewMigration.start_requested.connect(_on_new_start)
	%NewMigration.cancelled.connect(_on_new_cancelled)
	%SettingsPanel.closed.connect(_on_settings_closed)
	%Opening.opening_finished.connect(_on_opening_finished, CONNECT_ONE_SHOT)
	%StrategyView.advance_requested.connect(_on_advance)
	%StrategyView.repair_requested.connect(_on_repair)
	%StrategyView.save_requested.connect(_on_save)
	%StrategyView.menu_requested.connect(_on_menu)
	%StrategyView.course_requested.connect(_on_course)
	%EventPanel.choice_made.connect(_on_choice)
	%CombatBrief.launch_requested.connect(_on_launch)
	%CombatBrief.dismissed.connect(_on_brief_dismissed)
	_show_menu()

func _build_fade() -> void:
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0.008, 0.014, 0.03)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_rect.modulate.a = 0.0
	fade_layer.add_child(fade_rect)

func _switch(action: Callable) -> void:
	# Headless tests skip the visual transition; windows get a cinematic fade.
	if DisplayServer.get_name() == "headless" or _fading:
		action.call()
		return
	_fading = true
	fade_rect.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, 0.22)
	tw.tween_callback(action)
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func() -> void: _fading = false)

func _toast(text: String, kind: String = "info") -> void:
	if Campaign.state != null:
		%StrategyView.show_toast(text, kind)

func _show_menu() -> void:
	%MainMenu.visible = true
	%MainMenu.refresh()
	%Opening.visible = false
	%StrategyView.visible = false
	%EventPanel.visible = false
	%CombatBrief.visible = false
	%NewMigration.visible = false
	%SettingsPanel.visible = false
	_clear_combat()

# --- menu flows ---

func _on_new_requested() -> void:
	%NewMigration.open()

func _on_new_cancelled() -> void:
	%NewMigration.visible = false

func _on_new_start(campaign_name: String, seed_value: int, difficulty: int) -> void:
	Campaign.new_campaign(campaign_name, seed_value)
	_apply_difficulty(difficulty)
	SaveManager.save(Campaign.state)
	%NewMigration.visible = false
	%MainMenu.visible = false
	%StrategyView.visible = false
	# replay opening each new migration: reconnect one-shot
	if not %Opening.opening_finished.is_connected(_on_opening_finished):
		%Opening.opening_finished.connect(_on_opening_finished, CONNECT_ONE_SHOT)
	_switch(func() -> void:
		%Opening.play())

func _apply_difficulty(difficulty: int) -> void:
	if Campaign.state == null:
		return
	match difficulty:
		1: # story
			Campaign.state.apply_gains({"morale": 5.0, "food": 5.0})
			Campaign.state.record_history({"type": "setup", "label": "Story margins", "detail": "Steadier starting morale."})
		2: # harsh
			Campaign.state.apply_gains({"morale": -5.0, "food": -10.0})
			Campaign.state.record_history({"type": "setup", "label": "Harsh margins", "detail": "Thinner starting reserves."})
		_:
			pass

func _on_continue_requested() -> void:
	if not Campaign.continue_campaign():
		return
	_switch(func() -> void:
		%MainMenu.visible = false
		%Opening.visible = false
		%StrategyView.visible = true
		_refresh()
		_toast("Migration resumed at %s." % TimeSystem.date_label(Campaign.state.day), "ok"))

func _on_settings_requested() -> void:
	%SettingsPanel.open()

func _on_settings_closed() -> void:
	%SettingsPanel.visible = false

func _on_opening_finished() -> void:
	_switch(func() -> void:
		%Opening.visible = false
		%StrategyView.visible = true
		_refresh()
		_toast("Fleet Command is yours. The migration begins.", "ok"))

# --- strategy flows ---

func _on_advance() -> void:
	if Campaign.state == null:
		return
	var day_before: int = Campaign.state.day
	var pop_before: int = Campaign.state.population
	TimeSystem.advance(Campaign.state, 30)
	SaveManager.save(Campaign.state)
	_refresh()
	var days: int = Campaign.state.day - day_before
	var pop_delta: int = Campaign.state.population - pop_before
	if Campaign.state.active_event != "":
		_toast("Advance halted — a decision waits (%d days elapsed)." % maxi(days, 0), "warn")
	elif days > 0:
		_toast("Advanced %d days · %s · population %+d" % [days, CampaignDate.from_total_days(Campaign.state.day).short_label(), pop_delta], "info")

func _on_repair() -> void:
	if Campaign.state == null:
		return
	if FleetSystem.repair(Campaign.state):
		SaveManager.save(Campaign.state)
		_refresh()
		_toast("Hull crews report: integrity now %.0f%%." % float(Campaign.state.resources.hull), "ok")
	else:
		%StrategyView.message_label.text = "Repairs impossible — no materials or no damage to patch."

func _on_save() -> void:
	if Campaign.state == null:
		return
	SaveManager.save(Campaign.state)
	%StrategyView.message_label.text = "Migration saved. History will remember."
	_toast("Migration saved.", "ok")

func _on_menu() -> void:
	if Campaign.state != null:
		SaveManager.save(Campaign.state)
	_switch(_show_menu)

func _on_course(node_id: String, node_label: String) -> void:
	if Campaign.state == null:
		return
	if FleetSystem.plot_course(Campaign.state, node_id, node_label):
		SaveManager.save(Campaign.state)
		_refresh()
		_toast("Course plotted: %s." % node_label, "info")
	else:
		_toast("Course unchanged — already holding or already plotted there.", "warn")

func _on_choice(event_id: String, index: int) -> void:
	if Campaign.state == null:
		return
	var events := EventSystem.new()
	var title := ""
	var chosen_label := ""
	if events.events.has(event_id):
		title = String(events.events[event_id].get("title", ""))
		var choices: Array = events.events[event_id].get("choices", [])
		if index >= 0 and index < choices.size():
			chosen_label = String(choices[index].get("label", ""))
	if not events.choose(Campaign.state, event_id, index):
		%StrategyView.message_label.text = "Cannot take that action — reserves too low."
		_refresh()
		return
	SaveManager.save(Campaign.state)
	_refresh()
	var toast_text := ("%s — %s" % [title, chosen_label]) if chosen_label != "" else "Decision recorded."
	_toast(toast_text, "warn" if Campaign.state.pending_combat else "info")
	if Campaign.state.pending_combat:
		_toast("Hostile contact armed — combat imminent.", "danger")

func _on_brief_dismissed() -> void:
	%CombatBrief.visible = false

# --- combat flow ---

func _on_launch() -> void:
	if Campaign.state == null or not Campaign.state.pending_combat:
		return
	%EventPanel.visible = false
	%CombatBrief.visible = false
	%StrategyView.visible = false
	_switch(func() -> void:
		var scene: PackedScene = load("res://scenes/combat.tscn")
		combat_view = scene.instantiate() as CombatView
		%CombatHolder.add_child(combat_view)
		combat_view.setup(
			float(Campaign.state.resources.hull),
			float(Campaign.state.resources.readiness),
			Campaign.state.seed_value + Campaign.state.day)
		combat_view.combat_finished.connect(_on_combat_finished, CONNECT_ONE_SHOT))

func _on_combat_finished(result: CombatResult) -> void:
	if Campaign.state != null and result != null:
		FleetSystem.apply_combat_result(Campaign.state, result)
		SaveManager.save(Campaign.state)
	_clear_combat()
	_switch(func() -> void:
		%StrategyView.visible = true
		_refresh()
		if result != null:
			var kind := "ok" if result.victory else "danger"
			var headline := "Victory" if result.victory else "Defeat"
			_toast("%s — hull -%.1f, casualties %d, salvage %d." % [headline, result.hull_damage, result.casualties, result.salvage], kind)
		_check_game_over())

func _clear_combat() -> void:
	if combat_view != null and is_instance_valid(combat_view):
		combat_view.queue_free()
	combat_view = null
	for child in %CombatHolder.get_children():
		child.queue_free()

func _check_game_over() -> void:
	if Campaign.state == null:
		return
	if float(Campaign.state.resources.hull) <= 0.0 or Campaign.state.population <= 0:
		Campaign.state.record_history({"type": "gameover", "label": "Arkship lost", "detail": "Asteria could no longer sustain life."})
		SaveManager.save(Campaign.state)
		%StrategyView.message_label.text = "ASTERIA IS LOST. The migration ends here — start a new journey from the menu."
		_toast("ASTERIA IS LOST.", "danger")

# --- refresh ---

func _refresh() -> void:
	if Campaign.state == null:
		_show_menu()
		return
	%StrategyView.refresh(Campaign.state)
	_present_event_if_any()
	%CombatBrief.present(Campaign.state)

func _present_event_if_any() -> void:
	var state: CampaignState = Campaign.state
	if state == null:
		return
	if combat_view != null:
		return
	# active event takes precedence (set by TimeSystem)
	if state.active_event != "":
		var events := EventSystem.new()
		if events.events.has(state.active_event):
			if not %EventPanel.visible:
				%EventPanel.present(events.events[state.active_event], state)
			return
	# otherwise check for newly due event
	if not state.pending_combat:
		var events2 := EventSystem.new()
		var due: Dictionary = events2.available(state)
		if not due.is_empty():
			state.active_event = String(due["id"])
			SaveManager.save(state)
			%EventPanel.present(due, state)
