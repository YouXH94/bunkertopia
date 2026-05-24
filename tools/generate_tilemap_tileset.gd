extends SceneTree

const TILESET_PATH := "res://assets/art/tiles/bunkertopia_tileset.tres"
const TILE_SIZE := Vector2i(64, 64)

const TILE_ASSET_DIRS := [
	"res://assets/art/tiles/generated",
	"res://assets/art/objects/generated",
]

const PRIORITY_TILE_ASSETS := [
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
	{"id": "lab_floor", "path": "res://assets/art/tiles/generated/lab_floor.png"},
	{"id": "lab_floor_cable", "path": "res://assets/art/tiles/generated/lab_floor_cable.png"},
	{"id": "lab_floor_grate", "path": "res://assets/art/tiles/generated/lab_floor_grate.png"},
	{"id": "bunker_bed", "path": "res://assets/art/objects/generated/bunker_bed.png"},
	{"id": "bunker_entrance", "path": "res://assets/art/objects/generated/bunker_entrance.png"},
	{"id": "lab_desk", "path": "res://assets/art/objects/generated/lab_desk.png"},
	{"id": "lab_wall_panel", "path": "res://assets/art/objects/generated/lab_wall_panel.png"},
	{"id": "lab_wall_pipes", "path": "res://assets/art/objects/generated/lab_wall_pipes.png"},
	{"id": "lab_wall_warning", "path": "res://assets/art/objects/generated/lab_wall_warning.png"},
	{"id": "metal_chair", "path": "res://assets/art/objects/generated/metal_chair.png"},
	{"id": "metal_shelf", "path": "res://assets/art/objects/generated/metal_shelf.png"},
	{"id": "rusty_locker", "path": "res://assets/art/objects/generated/rusty_locker.png"},
	{"id": "rusty_table", "path": "res://assets/art/objects/generated/rusty_table.png"},
	{"id": "supercomputer", "path": "res://assets/art/objects/generated/supercomputer.png"},
	{"id": "supercomputer_screen_frame_00", "path": "res://assets/art/objects/generated/supercomputer_screen_frame_00.png"},
	{"id": "supercomputer_screen_frame_01", "path": "res://assets/art/objects/generated/supercomputer_screen_frame_01.png"},
	{"id": "supercomputer_screen_frame_02", "path": "res://assets/art/objects/generated/supercomputer_screen_frame_02.png"},
	{"id": "supercomputer_screen_frame_03", "path": "res://assets/art/objects/generated/supercomputer_screen_frame_03.png"},
	{"id": "supercomputer_screen_frame_04", "path": "res://assets/art/objects/generated/supercomputer_screen_frame_04.png"},
	{"id": "supercomputer_screen_frame_05", "path": "res://assets/art/objects/generated/supercomputer_screen_frame_05.png"},
	{"id": "supercomputer_screen_frame_06", "path": "res://assets/art/objects/generated/supercomputer_screen_frame_06.png"},
	{"id": "supercomputer_screen_frame_07", "path": "res://assets/art/objects/generated/supercomputer_screen_frame_07.png"},
]

const ATLAS_TILE_ASSETS := [
	{"id": "stone_road_atlas", "path": "res://assets/art/tiles/generated/stone_road_atlas.png", "tile_size": [64, 64], "columns": 4, "rows": 4},
	{"id": "mountain_atlas", "path": "res://assets/art/tiles/generated/mountain_atlas.png", "tile_size": [64, 64], "columns": 4, "rows": 4},
	{"id": "nature_atlas", "path": "res://assets/art/tiles/generated/nature_atlas.png", "tile_size": [64, 64], "columns": 5, "rows": 4},
]


func _init() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = TILE_SIZE
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)

	var tile_assets := _collect_tile_assets()
	for i in range(tile_assets.size()):
		var asset: Dictionary = tile_assets[i]
		var texture := load(str(asset["path"]))
		if texture == null:
			push_warning("Missing tile asset: " + str(asset["path"]))
			continue
		var source := TileSetAtlasSource.new()
		source.resource_name = str(asset["id"])
		source.texture = texture
		source.texture_region_size = _texture_region_size(asset, texture)
		_create_tiles(source, asset, texture)
		tile_set.add_source(source, i)

	var error := ResourceSaver.save(tile_set, TILESET_PATH)
	if error != OK:
		push_error("Failed to save TileSet: " + error_string(error))
	else:
		print("Saved TileSet with %d sources: %s" % [tile_assets.size(), TILESET_PATH])
	quit(error)


func _collect_tile_assets() -> Array:
	var assets: Array = PRIORITY_TILE_ASSETS.duplicate(true)
	assets.append_array(ATLAS_TILE_ASSETS.duplicate(true))
	var seen := {}
	for asset in assets:
		seen[str(asset["path"])] = true
	for dir_path in TILE_ASSET_DIRS:
		var dir := DirAccess.open(dir_path)
		if dir == null:
			push_warning("Missing tile asset directory: " + dir_path)
			continue
		var file_names := dir.get_files()
		file_names.sort()
		for file_name in file_names:
			if not file_name.ends_with(".png"):
				continue
			var asset_path: String = dir_path.path_join(file_name)
			if bool(seen.get(asset_path, false)):
				continue
			var asset_id := file_name.get_basename()
			assets.append({
				"id": asset_id,
				"path": asset_path,
			})
	return assets


func _texture_region_size(asset: Dictionary, texture: Texture2D) -> Vector2i:
	if asset.has("tile_size"):
		var size: Array = asset["tile_size"]
		return Vector2i(int(size[0]), int(size[1]))
	var texture_size := texture.get_size()
	return Vector2i(int(texture_size.x), int(texture_size.y))


func _create_tiles(source: TileSetAtlasSource, asset: Dictionary, texture: Texture2D) -> void:
	if not asset.has("tile_size"):
		source.create_tile(Vector2i.ZERO)
		return
	var tile_size: Vector2i = _texture_region_size(asset, texture)
	var texture_size := texture.get_size()
	var columns := int(asset.get("columns", int(texture_size.x) / tile_size.x))
	var rows := int(asset.get("rows", int(texture_size.y) / tile_size.y))
	for y in range(rows):
		for x in range(columns):
			source.create_tile(Vector2i(x, y))
