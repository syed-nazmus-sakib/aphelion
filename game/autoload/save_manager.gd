extends Node

const SAVE_FILE: String = "migrations/save_1.json"

func save_path() -> String:
	return OS.get_user_data_dir() + "/" + SAVE_FILE

func has_save() -> bool:
	return FileAccess.file_exists(save_path())

func save(state: CampaignState) -> Error:
	return SaveSystem.save_campaign(state, save_path())

func load_state() -> CampaignState:
	return SaveSystem.load_campaign(save_path())
