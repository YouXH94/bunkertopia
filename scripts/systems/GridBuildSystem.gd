extends Node2D

const DefenseBuilding := preload("res://scripts/build/DefenseBuilding.gd")
const PathGridSystem := preload("res://scripts/systems/PathGridSystem.gd")

var build_mode := false
var selected_id := "barricade"
var tool := "place"
var overlay := "none"
var preview_cell := Vector2i.ZERO
var can_place_preview := false
var building_nodes := {}


func _ready() -> void:
	EventBus.build_mode_changed.connect(_set_build_mode)
	EventBus.build_selection_changed.connect(func(id): selected_id = str(id); queue_redraw())
	EventBus.build_tool_changed.connect(func(new_tool): tool = str(new_tool); queue_redraw())
	EventBus.build_overlay_changed.connect(func(new_overlay): overlay = str(new_overlay); queue_redraw())
	refresh_from_state()


func refresh_from_state() -> void:
	for child in get_children():
		child.queue_free()
	building_nodes.clear()
	for entry in GameState.placed_buildings:
		_spawn_building(entry)
	queue_redraw()


func _process(_delta: float) -> void:
	if not build_mode:
		return
	preview_cell = PathGridSystem.world_to_grid(get_global_mouse_position())
	can_place_preview = _can_place(selected_id, preview_cell)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not build_mode:
		return
	if event.is_action_pressed("interact") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		if tool == "place":
			_try_place()
		elif tool == "demolish":
			_try_demolish()
		elif tool == "repair":
			_try_repair()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		EventBus.build_mode_changed.emit(false)


func _set_build_mode(enabled: bool) -> void:
	build_mode = enabled
	visible = true
	queue_redraw()


func _try_place() -> void:
	if not can_place_preview:
		EventBus.build_feedback.emit("此处不可放置：占格、地图边界或封死全部路径。", true)
		AudioManager.play_sfx("fail")
		return
	var entry := GameState.add_building(selected_id, preview_cell)
	if entry.is_empty():
		EventBus.build_feedback.emit("资源不足，无法建造。", true)
		AudioManager.play_sfx("fail")
		return
	_spawn_building(entry)
	EventBus.build_feedback.emit("已建造：" + str(DataRegistry.get_defense_building(selected_id).get("name", selected_id)), false)
	AudioManager.play_sfx("pickup")
	queue_redraw()


func _try_demolish() -> void:
	var building: Node = _building_at(preview_cell)
	if building == null:
		return
	if GameState.remove_building(building.uid):
		building.queue_free()
		building_nodes.erase(building.uid)
		EventBus.build_feedback.emit("建筑已拆除，回收材料留给战后清点。", false)
		AudioManager.play_sfx("door")
	else:
		EventBus.build_feedback.emit("核心设施不能拆除。", true)
		AudioManager.play_sfx("fail")


func _try_repair() -> void:
	var building: Node = _building_at(preview_cell)
	if building == null:
		return
	if building.repair_full():
		EventBus.build_feedback.emit("维修完成：" + str(building.data.get("name", building.building_id)), false)
		AudioManager.play_sfx("pickup")
	else:
		EventBus.build_feedback.emit("维修材料不足。", true)
		AudioManager.play_sfx("fail")


func _spawn_building(entry: Dictionary):
	var node := DefenseBuilding.new()
	node.setup(entry)
	add_child(node)
	building_nodes[node.uid] = node
	return node


func _building_at(cell: Vector2i):
	for uid in building_nodes.keys():
		var building = building_nodes[uid]
		if PathGridSystem.building_cells({"id": building.building_id, "grid": [building.grid.x, building.grid.y]}, building.data).has(cell):
			return building
	return null


func _can_place(building_id: String, cell: Vector2i) -> bool:
	var data := DataRegistry.get_defense_building(building_id)
	if data.is_empty():
		return false
	for used_cell in PathGridSystem.building_cells({"id": building_id, "grid": [cell.x, cell.y]}, data):
		if not PathGridSystem.in_bounds(used_cell):
			return false
		if _building_at(used_cell) != null:
			return false
	var simulated := GameState.placed_buildings.duplicate(true)
	simulated.append({"uid": -999, "id": building_id, "grid": [cell.x, cell.y], "health": int(data.get("max_health", 1))})
	if bool(data.get("blocks_path", false)) and not PathGridSystem.has_any_entry_path(simulated):
		return false
	return true


func _draw() -> void:
	if build_mode:
		for x in range(PathGridSystem.COLS):
			for y in range(PathGridSystem.ROWS):
				var pos := PathGridSystem.ORIGIN + Vector2(x * PathGridSystem.CELL_SIZE, y * PathGridSystem.CELL_SIZE)
				draw_rect(Rect2(pos, Vector2(PathGridSystem.CELL_SIZE, PathGridSystem.CELL_SIZE)), Color(0.25, 0.35, 0.28, 0.22), false, 1.0)
		var data := DataRegistry.get_defense_building(selected_id)
		var size: Array = data.get("size", [1, 1])
		var color := Color(0.20, 0.85, 0.35, 0.36) if can_place_preview else Color(0.95, 0.20, 0.14, 0.36)
		draw_rect(Rect2(PathGridSystem.ORIGIN + Vector2(preview_cell.x, preview_cell.y) * PathGridSystem.CELL_SIZE, Vector2(int(size[0]), int(size[1])) * PathGridSystem.CELL_SIZE), color, true)
	if overlay == "power":
		_draw_power_overlay()
	elif overlay == "threat":
		_draw_threat_overlay()


func _draw_power_overlay() -> void:
	for uid in building_nodes.keys():
		var building = building_nodes[uid]
		var need := int(building.data.get("power_need", 0))
		var generation := int(building.data.get("power_generation", 0))
		var storage := int(building.data.get("power_storage", 0))
		if need > 0 or generation > 0 or storage > 0:
			var color := Color(0.25, 0.65, 1.0, 0.28) if PowerSystem.building_is_powered(building.building_id) else Color(1.0, 0.20, 0.14, 0.28)
			draw_circle(building.center_world(), 64 + int(building.data.get("grid_range", 0)) * 22, color)


func _draw_threat_overlay() -> void:
	var spawns := PathGridSystem.spawn_cells_for_pressure(GameState.base_footprint, GameState.base_noise, GameState.base_smell, GameState.base_light)
	for spawn in spawns:
		var pos := PathGridSystem.grid_to_world(spawn)
		draw_circle(pos, 34, Color(0.95, 0.12, 0.08, 0.45))
		draw_line(pos, PathGridSystem.grid_to_world(PathGridSystem.bunker_cell(GameState.placed_buildings)), Color(0.95, 0.18, 0.12, 0.28), 2.0)
