extends Node

const MANIFEST_PATH := "res://data/art_asset_manifest.json"

var manifest := {}


func _ready() -> void:
	_load_manifest()


func _load_manifest() -> void:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_warning("Missing art asset manifest: " + MANIFEST_PATH)
		manifest = {}
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Invalid art asset manifest: " + MANIFEST_PATH)
		manifest = {}
		return
	manifest = parsed


func character_data(character_id: String) -> Dictionary:
	var characters: Dictionary = manifest.get("characters", {})
	return characters.get(character_id, characters.get("walker", {}))


func character_sheet(character_id: String, fallback: String) -> String:
	return str(character_data(character_id).get("sheet", fallback))


func character_frame_size(character_id: String) -> Vector2i:
	var data := character_data(character_id)
	var size: Array = data.get("frame_size", [64, 64])
	return Vector2i(int(size[0]), int(size[1]))


func character_side_facing(character_id: String) -> String:
	return str(character_data(character_id).get("side_facing", "right"))


func character_animation(character_id: String, animation_name: String) -> Dictionary:
	var animations: Dictionary = character_data(character_id).get("animations", {})
	if animations.has(animation_name):
		return animations[animation_name]
	if animation_name.ends_with("_left") or animation_name.ends_with("_right"):
		var side_name := animation_name.rsplit("_", true, 1)[0] + "_side"
		return animations.get(side_name, animations.get("idle_down", {}))
	return animations.get("idle_down", {})


func object_path(object_id: String, fallback: String) -> String:
	var objects: Dictionary = manifest.get("objects", {})
	var data: Dictionary = objects.get(object_id, {})
	return str(data.get("path", fallback))


func object_data(object_id: String) -> Dictionary:
	var objects: Dictionary = manifest.get("objects", {})
	return objects.get(object_id, {})


func tile_path(tile_id: String, fallback: String) -> String:
	var tiles: Dictionary = manifest.get("tiles", {})
	var data: Dictionary = tiles.get(tile_id, {})
	return str(data.get("path", fallback))


func icon_path(icon_id: String, fallback: String = "") -> String:
	var icons: Dictionary = manifest.get("ui_icons", {})
	var data: Dictionary = icons.get(icon_id, {})
	return str(data.get("path", fallback))
