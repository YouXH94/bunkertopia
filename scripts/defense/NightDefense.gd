extends Node2D

const WallSegment := preload("res://scripts/defense/WallSegment.gd")
const Turret := preload("res://scripts/defense/Turret.gd")
const ZombieEnemy := preload("res://scripts/defense/ZombieEnemy.gd")
const TextureLoader := preload("res://scripts/core/TextureLoader.gd")

var ground_texture: Texture2D
var walls := []
var spawn_timer: Timer
var spawned := 0
var wave_total := 18
var ended := false
var rng := RandomNumberGenerator.new()
var bunker_position := Vector2(170, 360)


func _ready() -> void:
	rng.randomize()
	ground_texture = TextureLoader.load_texture("res://assets/art/tiles/night_ground.png")
	GameState.start_night()
	wave_total = 12 + int(GameState.day / 2)
	_build_defense_line()
	_start_wave()
	var event_data := DataRegistry.get_event("horde")
	EventBus.announce_event(event_data.get("title", "尸潮来袭"), event_data.get("body", "夜晚开始。"))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0.025, 0.035, 0.050))
	for x in range(0, 1280, 64):
		for y in range(0, 720, 64):
			if ground_texture != null:
				draw_texture(ground_texture, Vector2(x, y))
	draw_rect(Rect2(80, 165, 210, 390), Color(0.075, 0.070, 0.065))
	draw_rect(Rect2(355, 110, 24, 500), Color(0.14, 0.12, 0.10))
	draw_rect(Rect2(1040, 40, 210, 620), Color(0.04, 0.045, 0.05))


func _process(_delta: float) -> void:
	if ended:
		return
	if GameState.base_integrity <= 0:
		GameState.add_loss("地堡门被攻破")
		_finish_night()
	elif spawned >= wave_total and get_tree().get_nodes_in_group("zombies").is_empty():
		if GameState.wall_integrity < 35:
			GameState.add_loss("外墙需要大修")
		_finish_night()


func _build_defense_line() -> void:
	queue_redraw()
	_add_sprite("res://assets/art/objects/bunker.png", bunker_position, Vector2(2.2, 2.2), 1)
	_add_sprite("res://assets/art/objects/generator.png", Vector2(210, 525), Vector2(1.45, 1.45), 2)

	for y in [155, 245, 335, 425, 515]:
		var wall := WallSegment.new()
		wall.position = Vector2(360, y)
		add_child(wall)
		walls.append(wall)

	for pos in [Vector2(290, 215), Vector2(285, 365), Vector2(290, 505)]:
		var turret := Turret.new()
		turret.position = pos
		turret.z_index = 4
		add_child(turret)


func _start_wave() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 0.8
	spawn_timer.timeout.connect(_spawn_zombie)
	add_child(spawn_timer)
	spawn_timer.start()


func _spawn_zombie() -> void:
	if spawned >= wave_total:
		spawn_timer.stop()
		return

	var zombie_data := _pick_zombie_data()
	var zombie := ZombieEnemy.new()
	var y := rng.randi_range(80, 640)
	zombie.position = Vector2(rng.randi_range(1120, 1240), y)
	zombie.setup(zombie_data, walls, bunker_position)
	zombie.z_index = 5
	add_child(zombie)
	spawned += 1


func _pick_zombie_data() -> Dictionary:
	var zombies := DataRegistry.get_zombies()
	if zombies.is_empty():
		return {}
	var roll := rng.randi_range(0, 99)
	if roll > 86 and zombies.size() >= 3:
		return zombies[2]
	if roll > 64 and zombies.size() >= 2:
		return zombies[1]
	return zombies[0]


func _finish_night() -> void:
	ended = true
	if spawn_timer != null:
		spawn_timer.stop()
	for zombie in get_tree().get_nodes_in_group("zombies"):
		if is_instance_valid(zombie):
			zombie.queue_free()
	var report: Dictionary = GameState.finish_night()
	EventBus.report_requested.emit(report)


func _add_sprite(texture_path: String, pos: Vector2, scale_value: Vector2, z: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = TextureLoader.load_texture(texture_path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = pos
	sprite.scale = scale_value
	sprite.z_index = z
	add_child(sprite)
	return sprite
