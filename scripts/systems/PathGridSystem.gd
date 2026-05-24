extends RefCounted

const CELL_SIZE := 48
const ORIGIN := Vector2(40, 40)
const COLS := 25
const ROWS := 14


static func grid_to_world(cell: Vector2i) -> Vector2:
	return ORIGIN + Vector2(cell.x * CELL_SIZE + CELL_SIZE / 2, cell.y * CELL_SIZE + CELL_SIZE / 2)


static func world_to_grid(pos: Vector2) -> Vector2i:
	var local := pos - ORIGIN
	return Vector2i(floori(local.x / CELL_SIZE), floori(local.y / CELL_SIZE))


static func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < COLS and cell.y < ROWS


static func building_cells(entry: Dictionary, data: Dictionary = {}) -> Array[Vector2i]:
	if data.is_empty():
		data = DataRegistry.get_defense_building(str(entry.get("id", "")))
	var size: Array = data.get("size", [1, 1])
	var origin := Vector2i(int(entry.get("grid", [0, 0])[0]), int(entry.get("grid", [0, 0])[1]))
	var cells: Array[Vector2i] = []
	for x in range(int(size[0])):
		for y in range(int(size[1])):
			cells.append(origin + Vector2i(x, y))
	return cells


static func blocked_cells(buildings: Array, extra: Dictionary = {}) -> Dictionary:
	var blocked := {}
	for building in buildings:
		var entry: Dictionary = building
		if int(entry.get("health", 1)) <= 0:
			continue
		var data := DataRegistry.get_defense_building(str(entry.get("id", "")))
		if not bool(data.get("blocks_path", false)):
			continue
		for cell in building_cells(entry, data):
			blocked[cell] = int(entry.get("uid", -1))
	for cell in extra.keys():
		blocked[cell] = extra[cell]
	return blocked


static func find_path(start: Vector2i, goal: Vector2i, buildings: Array, extra_blocked: Dictionary = {}) -> Array[Vector2]:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0, 0, COLS, ROWS)
	grid.cell_size = Vector2i(1, 1)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()

	var blocked := blocked_cells(buildings, extra_blocked)
	for cell in blocked.keys():
		if cell != start and cell != goal and in_bounds(cell):
			grid.set_point_solid(cell, true)

	if not in_bounds(start) or not in_bounds(goal):
		return []
	var ids := grid.get_id_path(start, goal)
	var points: Array[Vector2] = []
	for cell in ids:
		points.append(grid_to_world(cell))
	return points


static func has_any_entry_path(buildings: Array, extra_blocked: Dictionary = {}) -> bool:
	var goal := bunker_cell(buildings)
	for entry in spawn_cells_for_pressure(0, 0, 0, 0):
		if find_path(entry, goal, buildings, extra_blocked).size() > 0:
			return true
	return false


static func bunker_cell(buildings: Array) -> Vector2i:
	for building in buildings:
		if str(building.get("id", "")) == "bunker_core":
			var grid: Array = building.get("grid", [12, 7])
			return Vector2i(int(grid[0]), int(grid[1]))
	return Vector2i(12, 7)


static func spawn_cells_for_pressure(footprint: int, noise: int, smell: int, light: int) -> Array[Vector2i]:
	var spawns: Array[Vector2i] = [Vector2i(COLS - 1, 6), Vector2i(0, 6)]
	if footprint >= 8 or noise >= 7:
		spawns.append(Vector2i(12, 0))
	if footprint >= 12 or smell >= 8:
		spawns.append(Vector2i(12, ROWS - 1))
	if light >= 10:
		spawns.append(Vector2i(COLS - 1, 2))
	return spawns


static func nearest_blocker(start: Vector2i, buildings: Array) -> Dictionary:
	var best := {}
	var best_distance := 999999.0
	for building in buildings:
		var data := DataRegistry.get_defense_building(str(building.get("id", "")))
		if not bool(data.get("blocks_path", false)) or int(building.get("health", 0)) <= 0:
			continue
		for cell in building_cells(building, data):
			var distance := Vector2(start).distance_to(Vector2(cell))
			if distance < best_distance:
				best_distance = distance
				best = building
	return best
