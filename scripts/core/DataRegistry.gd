extends Node

var data := {}


func _ready() -> void:
	var file := FileAccess.open("res://data/gameplay.json", FileAccess.READ)
	if file == null:
		push_error("Missing gameplay data: res://data/gameplay.json")
		data = {}
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("gameplay.json is not a dictionary.")
		data = {}
		return

	data = parsed


func get_research_projects() -> Array:
	return data.get("research_projects", [])


func get_research_project(project_id: String) -> Dictionary:
	for project in get_research_projects():
		if project.get("id", "") == project_id:
			return project
	return {}


func get_build_options() -> Array:
	return data.get("build_options", [])


func get_city_containers() -> Array:
	return data.get("city_containers", [])


func get_zombies() -> Array:
	return data.get("zombies", [])


func get_zombie(zombie_id: String) -> Dictionary:
	for zombie in get_zombies():
		if zombie.get("id", "") == zombie_id:
			return zombie
	return {}


func get_event(event_id: String) -> Dictionary:
	return data.get("events", {}).get(event_id, {})
