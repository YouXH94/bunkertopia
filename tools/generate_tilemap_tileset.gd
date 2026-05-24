extends SceneTree

const TILESET_PATH := "res://assets/art/tiles/bunkertopia_tileset.tres"
const TILE_SIZE := Vector2i(64, 64)

const TILE_ASSETS := [
	{"id": "dirt", "path": "res://assets/art/tiles/generated/dirt.png"},
	{"id": "bunker_floor", "path": "res://assets/art/tiles/generated/bunker_floor.png"},
	{"id": "field", "path": "res://assets/art/tiles/generated/field.png"},
	{"id": "cracked_road", "path": "res://assets/art/tiles/generated/cracked_road.png"},
	{"id": "dark_ground", "path": "res://assets/art/tiles/generated/dark_ground.png"},
	{"id": "night_ground", "path": "res://assets/art/tiles/generated/night_ground.png"},
	{"id": "animal_pen", "path": "res://assets/art/objects/generated/animal_pen.png"},
	{"id": "barricade", "path": "res://assets/art/objects/generated/barricade.png"},
	{"id": "basic_turret", "path": "res://assets/art/objects/generated/basic_turret.png"},
	{"id": "battery", "path": "res://assets/art/objects/generated/battery.png"},
	{"id": "bunker_core", "path": "res://assets/art/objects/generated/bunker_core.png"},
	{"id": "container", "path": "res://assets/art/objects/generated/container.png"},
	{"id": "crash_plane", "path": "res://assets/art/objects/generated/crash_plane.png"},
	{"id": "farm_plot", "path": "res://assets/art/objects/generated/farm_plot.png"},
	{"id": "flame_trap", "path": "res://assets/art/objects/generated/flame_trap.png"},
	{"id": "furnace", "path": "res://assets/art/objects/generated/furnace.png"},
	{"id": "gate", "path": "res://assets/art/objects/generated/gate.png"},
	{"id": "generator", "path": "res://assets/art/objects/generated/generator.png"},
	{"id": "lab_station", "path": "res://assets/art/objects/generated/lab_station.png"},
	{"id": "power_pole", "path": "res://assets/art/objects/generated/power_pole.png"},
	{"id": "rubble", "path": "res://assets/art/objects/generated/rubble.png"},
	{"id": "ruined_building", "path": "res://assets/art/objects/generated/ruined_building.png"},
	{"id": "scrap_wall", "path": "res://assets/art/objects/generated/scrap_wall.png"},
	{"id": "shotgun_turret", "path": "res://assets/art/objects/generated/shotgun_turret.png"},
	{"id": "spike_trap", "path": "res://assets/art/objects/generated/spike_trap.png"},
	{"id": "spotlight", "path": "res://assets/art/objects/generated/spotlight.png"},
	{"id": "wire_fence", "path": "res://assets/art/objects/generated/wire_fence.png"},
	{"id": "workbench", "path": "res://assets/art/objects/generated/workbench.png"},
	{"id": "wrecked_car", "path": "res://assets/art/objects/generated/wrecked_car.png"},
]


func _init() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = TILE_SIZE
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)

	for i in range(TILE_ASSETS.size()):
		var asset: Dictionary = TILE_ASSETS[i]
		var texture := load(str(asset["path"]))
		if texture == null:
			push_warning("Missing tile asset: " + str(asset["path"]))
			continue
		var source := TileSetAtlasSource.new()
		source.resource_name = str(asset["id"])
		source.texture = texture
		source.texture_region_size = texture.get_size()
		source.create_tile(Vector2i.ZERO)
		tile_set.add_source(source, i)

	var error := ResourceSaver.save(tile_set, TILESET_PATH)
	if error != OK:
		push_error("Failed to save TileSet: " + error_string(error))
	else:
		print("Saved TileSet with %d sources: %s" % [TILE_ASSETS.size(), TILESET_PATH])
	quit(error)
