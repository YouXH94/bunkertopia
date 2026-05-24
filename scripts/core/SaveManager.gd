extends Node

const SAVE_PATH := "user://bunkertopia_demo_save.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(scene_key: String = "base") -> bool:
	if GameState.failed or GameState.demo_completed:
		return false

	var data := GameState.to_save_dict()
	data["scene_key"] = scene_key if scene_key != "night" else "base"

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Unable to write save file: " + SAVE_PATH)
		return false

	file.store_string(JSON.stringify(data, "\t"))
	return true


func load_game() -> Dictionary:
	if not has_save():
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Unable to read save file: " + SAVE_PATH)
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Save file is corrupt. Starting a fresh run is recommended.")
		return {}

	GameState.load_from_save_dict(parsed)
	return parsed


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
