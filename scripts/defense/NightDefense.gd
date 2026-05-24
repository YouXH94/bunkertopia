extends Node2D

const PlayerController := preload("res://scripts/entities/PlayerController.gd")
const DefenseBuilding := preload("res://scripts/build/DefenseBuilding.gd")
const PathGridSystem := preload("res://scripts/systems/PathGridSystem.gd")
const WaveDirector := preload("res://scripts/systems/WaveDirector.gd")
const ThreatDirector := preload("res://scripts/systems/ThreatDirector.gd")
const ZombieEnemy := preload("res://scripts/defense/ZombieEnemy.gd")

var player: CharacterBody2D
var building_nodes := {}
var spawn_timer: Timer
var spawn_queue := []
var spawn_cells: Array[Vector2i] = []
var spawned := 0
var ended := false
var rng := RandomNumberGenerator.new()
var turret_cooldowns := {}
var trap_cooldowns := {}


func _ready() -> void:
	rng.randomize()
	GameState.start_night()
	GameState.night_stats["building_destroyed"] = []
	GameState.night_stats["farm_loss"] = 0
	GameState.night_stats["animal_loss"] = 0
	GameState.night_stats["ammo_waste"] = 0
	_build_open_base()
	_spawn_player()
	spawn_cells = ThreatDirector.get_spawn_cells()
	spawn_queue = WaveDirector.build_wave()
	_start_wave()
	AudioManager.play_sfx("alarm")
	EventBus.announce_event("尸潮来袭", "威胁从多个方向靠近。\n\n" + ThreatDirector.threat_summary())


func _draw() -> void:
	for x in range(PathGridSystem.COLS):
		for y in range(PathGridSystem.ROWS):
			var pos := PathGridSystem.ORIGIN + Vector2(x * PathGridSystem.CELL_SIZE, y * PathGridSystem.CELL_SIZE)
			draw_rect(Rect2(pos, Vector2(PathGridSystem.CELL_SIZE, PathGridSystem.CELL_SIZE)), Color(0.12, 0.16, 0.14, 0.13), false, 1.0)
	for spawn in spawn_cells:
		draw_circle(PathGridSystem.grid_to_world(spawn), 30, Color(0.95, 0.13, 0.08, 0.30))
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0.02, 0.03, 0.05, 0.22))


func _process(delta: float) -> void:
	if ended:
		return
	_apply_defense_systems(delta)
	if GameState.failed:
		ended = true
		return
	if spawned >= spawn_queue.size() and get_tree().get_nodes_in_group("zombies").is_empty():
		_finish_night()


func _build_open_base() -> void:
	queue_redraw()
	_add_boundary_collisions()
	for entry in GameState.placed_buildings:
		var building := DefenseBuilding.new()
		building.setup(entry)
		building.destroyed.connect(_on_building_destroyed)
		add_child(building)
		building_nodes[building.uid] = building


func _spawn_player() -> void:
	player = PlayerController.new()
	player.position = PathGridSystem.grid_to_world(PathGridSystem.bunker_cell(GameState.placed_buildings)) + Vector2(40, 0)
	player.speed = 160.0
	add_child(player)
	var camera := Camera2D.new()
	camera.enabled = true
	camera.position = Vector2(640, 360)
	add_child(camera)


func _start_wave() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 0.72
	spawn_timer.timeout.connect(_spawn_zombie)
	add_child(spawn_timer)
	spawn_timer.start()


func _spawn_zombie() -> void:
	if spawned >= spawn_queue.size():
		spawn_timer.stop()
		return
	var data: Dictionary = spawn_queue[spawned]
	var spawn_cell := spawn_cells[rng.randi_range(0, spawn_cells.size() - 1)]
	var target_node: Node = _pick_target_building(data)
	var target_cell: Vector2i = target_node.grid if target_node != null else PathGridSystem.bunker_cell(GameState.placed_buildings)
	var path: Array[Vector2] = PathGridSystem.find_path(spawn_cell, target_cell, GameState.placed_buildings)
	if path.is_empty():
		target_node = _node_for_entry(PathGridSystem.nearest_blocker(spawn_cell, GameState.placed_buildings))
		if target_node != null:
			path = [PathGridSystem.grid_to_world(spawn_cell), target_node.center_world()]
	var zombie := ZombieEnemy.new()
	zombie.position = PathGridSystem.grid_to_world(spawn_cell)
	zombie.setup_dynamic(data, path, target_node)
	zombie.z_index = 8
	add_child(zombie)
	spawned += 1


func _pick_target_building(zombie_data: Dictionary):
	var priorities: Array = zombie_data.get("target_priority", ["bunker_core"])
	for priority in priorities:
		var fallback_match = null
		for uid in building_nodes.keys():
			var building: Node = building_nodes[uid]
			if building.health <= 0:
				continue
			if str(priority) == "turret" and building.building_id.contains("turret"):
				return building
			if building.building_id == str(priority):
				return building
			if fallback_match == null and building.building_id == "bunker_core":
				fallback_match = building
		if fallback_match != null and str(priority) == "bunker_core":
			return fallback_match
	return _node_for_entry({"uid": _bunker_uid()})


func _bunker_uid() -> int:
	for entry in GameState.placed_buildings:
		if str(entry.get("id", "")) == "bunker_core":
			return int(entry.get("uid", -1))
	return -1


func _node_for_entry(entry: Dictionary):
	if entry.is_empty():
		return null
	return building_nodes.get(int(entry.get("uid", -1)), null)


func _apply_defense_systems(delta: float) -> void:
	for uid in building_nodes.keys():
		var building: Node = building_nodes[uid]
		if building.health <= 0:
			continue
		if building.building_id in ["basic_turret", "shotgun_turret"]:
			_update_turret(building, delta)
		elif building.building_id in ["spike_trap", "flame_trap", "wire_fence"]:
			_update_trap(building, delta)


func _update_turret(building, delta: float) -> void:
	turret_cooldowns[building.uid] = max(0.0, float(turret_cooldowns.get(building.uid, 0.0)) - delta)
	if float(turret_cooldowns[building.uid]) > 0.0:
		return
	if not PowerSystem.building_is_powered(building.building_id):
		return
	var ammo_use := int(building.data.get("ammo_use", 1))
	if int(GameState.resources.get("ammo", 0)) < ammo_use:
		return
	var target := _nearest_zombie(building.center_world(), float(building.data.get("range", 220)))
	if target == null:
		return
	GameState.apply_resource_delta({"ammo": -ammo_use, "power": -int(building.data.get("power_need", 0))}, "turret_fire")
	if target.zombie_id == "crawler":
		GameState.night_stats["ammo_waste"] = int(GameState.night_stats.get("ammo_waste", 0)) + ammo_use
	if building.building_id == "shotgun_turret":
		for zombie in get_tree().get_nodes_in_group("zombies"):
			if building.center_world().distance_to(zombie.global_position) <= float(building.data.get("range", 145)) + float(building.data.get("splash", 72)):
				zombie.take_damage(int(building.data.get("damage", 9)), "normal")
	else:
		target.take_damage(int(building.data.get("damage", 12)), "normal")
	AudioManager.play_sfx("turret")
	turret_cooldowns[building.uid] = 0.55 if building.building_id == "basic_turret" else 0.95


func _update_trap(building, delta: float) -> void:
	trap_cooldowns[building.uid] = max(0.0, float(trap_cooldowns.get(building.uid, 0.0)) - delta)
	if float(trap_cooldowns[building.uid]) > 0.0:
		return
	if building.building_id != "spike_trap" and not PowerSystem.building_is_powered(building.building_id):
		return
	for zombie in get_tree().get_nodes_in_group("zombies"):
		if PathGridSystem.world_to_grid(zombie.global_position) == building.grid:
			var damage_type := str(building.data.get("damage_type", "electric"))
			var damage := int(building.data.get("trap_damage", building.data.get("electric_damage", 5)))
			zombie.take_damage(damage, damage_type)
			if building.building_id == "wire_fence":
				zombie.apply_slow(float(building.data.get("slow", 0.5)), 0.55)
			if building.building_id == "flame_trap":
				if int(GameState.resources.get("fuel", 0)) <= 0:
					return
				GameState.apply_resource_delta({"fuel": -1}, "flame_trap")
			building.apply_damage(3)
			trap_cooldowns[building.uid] = 0.75
			return


func _nearest_zombie(origin: Vector2, radius: float) -> Node2D:
	var best: Node2D = null
	var best_distance := radius
	for zombie in get_tree().get_nodes_in_group("zombies"):
		var distance := origin.distance_to(zombie.global_position)
		if distance <= best_distance:
			best_distance = distance
			best = zombie
	return best


func _on_building_destroyed(building) -> void:
	var destroyed: Array = GameState.night_stats.get("building_destroyed", [])
	destroyed.append(str(building.data.get("name", building.building_id)))
	GameState.night_stats["building_destroyed"] = destroyed
	if building.building_id == "farm_plot":
		GameState.night_stats["farm_loss"] = int(GameState.night_stats.get("farm_loss", 0)) + 1
		GameState.apply_resource_delta({"food": -4}, "farm_destroyed")
	elif building.building_id == "animal_pen":
		GameState.night_stats["animal_loss"] = int(GameState.night_stats.get("animal_loss", 0)) + 1
		GameState.apply_body_delta({"protein": -6, "sanity": -4})
	elif building.building_id == "bunker_core":
		GameState.record_base_damage(999)


func _finish_night() -> void:
	ended = true
	if spawn_timer != null:
		spawn_timer.stop()
	for zombie in get_tree().get_nodes_in_group("zombies"):
		if is_instance_valid(zombie):
			zombie.queue_free()
	var report: Dictionary = GameState.finish_night()
	report["weak_path_hint"] = ThreatDirector.weak_path_hint(report)
	EventBus.report_requested.emit(report)


func _add_solid_rect(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)


func _add_boundary_collisions() -> void:
	_add_solid_rect(Vector2(640, -18), Vector2(1280, 36))
	_add_solid_rect(Vector2(640, 738), Vector2(1280, 36))
	_add_solid_rect(Vector2(-18, 360), Vector2(36, 720))
	_add_solid_rect(Vector2(1298, 360), Vector2(36, 720))
