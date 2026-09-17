extends Control

signal advance_requested

func _ready() -> void:
	$AdvanceButton.pressed.connect(func() -> void: advance_requested.emit())

func refresh(state: CampaignState) -> void:
	$Header.text = "%s — %s" % [state.campaign_name, TimeSystem.date_label(state.day)]
	$Stats.text = "\n".join([
		"Population      %d" % state.population,
		"Food            %.0f%%" % state.resources.food,
		"Energy          %.0f%%" % state.resources.energy,
		"Materials       %d" % int(state.resources.materials),
		"Medicine        %d" % int(state.resources.medicine),
		"Morale          %.0f" % state.resources.morale,
		"Hull Integrity  %.0f%%" % state.resources.hull,
		"Readiness       %.0f%%" % state.resources.readiness,
	])
	var objective: String = "Advance the migration."
	if state.pending_combat:
		objective = "Hostile contact! Open the event log."
	elif state.active_event != "":
		objective = "Decisions required. Open the event log."
	$Objective.text = objective
