extends Node

var state: CampaignState = null

func new_campaign(campaign_name: String, seed_value: int) -> void:
	state = CampaignState.new_campaign(campaign_name, seed_value)
	SaveManager.save(state)

func continue_campaign() -> bool:
	state = SaveManager.load_state()
	return state != null

func has_active() -> bool:
	return state != null
