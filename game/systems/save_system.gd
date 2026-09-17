class_name SaveSystem
extends RefCounted

static func save_campaign(state: CampaignState, path: String) -> Error:
	if state == null or path.is_empty() or CampaignState.from_dict(state.to_dict()) == null:
		return ERR_INVALID_DATA
	var parent: String = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(parent):
		var error: Error = DirAccess.make_dir_recursive_absolute(parent)
		if error != OK:
			return error
	var temporary: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(state.to_dict(), "\t"))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK:
		return error
	if load_campaign(temporary) == null:
		return ERR_FILE_CORRUPT
	return DirAccess.rename_absolute(temporary, path)

static func load_campaign(path: String) -> CampaignState:
	if not FileAccess.file_exists(path):
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return null
	return CampaignState.from_dict(parsed)
