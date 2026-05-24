extends Node

signal scene_change_requested(scene_key)

var current_scene_key := "base"


func go_base() -> void:
	request_scene("base")


func go_city() -> void:
	request_scene("city")


func go_night() -> void:
	request_scene("night")


func request_scene(scene_key: String) -> void:
	current_scene_key = scene_key
	scene_change_requested.emit(scene_key)
