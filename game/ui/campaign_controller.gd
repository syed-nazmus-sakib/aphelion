extends Node

var state: CampaignState = null

func _ready() -> void:
	%MainMenu.campaign_started.connect(_on_new_migration)
	%EventPanel.choice_made.connect(_on_choice)
	%EventPanel.dismissed.connect(_refresh)
	%StrategyView.advance_requested.connect(_on_advance)
	%StrategyView.visible = false
	%CombatBrief.launch_requested.connect(_on_launch)
	%CombatBrief.dismissed.connect(_refresh)
	%CombatBrief.visible = false

func _on_new_migration() -> void:
	Campaign.new_campaign("Asteria Prime", randi())
	%MainMenu.visible = false
	%Opening.opening_finished.connect(_show_strategy, CONNECT_ONE_SHOT)
	%Opening.visible = true

func _show_strategy() -> void:
	%Opening.visible = false
	%StrategyView.visible = true
	_refresh()

func _show_strategy_direct() -> void:
	%MainMenu.visible = false
	%Opening.visible = false
	%StrategyView.visible = true
	_refresh()

func _refresh() -> void:
	%StrategyView.refresh(Campaign.state)
	var event := EventSystem.new().available(Campaign.state)
	if not event.is_empty() and not %EventPanel.visible:
		%EventPanel.set_meta("event_id", event.id)
		%EventPanel.present(event)
	%CombatBrief.present(Campaign.state)

func _on_advance() -> void:
	TimeSystem.advance(Campaign.state, 30)
	SaveManager.save(Campaign.state)
	_refresh()

func _on_choice(event_id: String, index: int) -> void:
	var events := EventSystem.new()
	events.choose(Campaign.state, event_id, index)
	SaveManager.save(Campaign.state)
	_refresh()

func _on_launch() -> void:
	print("launch combat placeholder")
