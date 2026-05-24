extends Node2D

const PlayerController := preload("res://scripts/entities/PlayerController.gd")
const InteractablePoint := preload("res://scripts/base/InteractablePoint.gd")
const TextureLoader := preload("res://scripts/core/TextureLoader.gd")

var player: CharacterBody2D
var dirt_texture: Texture2D
var floor_texture: Texture2D
var field_texture: Texture2D


func _ready() -> void:
	dirt_texture = TextureLoader.load_texture("res://assets/art/tiles/dirt.png")
	floor_texture = TextureLoader.load_texture("res://assets/art/tiles/bunker_floor.png")
	field_texture = TextureLoader.load_texture("res://assets/art/tiles/field.png")
	_spawn_player()
	_build_base_layout()
	_create_interactions()
	EventBus.announce_notice("白天行动：搜刮、研究、维护防线，按 N 可直接测试夜晚尸潮。")


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0.11, 0.12, 0.09))
	for x in range(0, 1280, 64):
		for y in range(0, 720, 64):
			if dirt_texture != null:
				draw_texture(dirt_texture, Vector2(x, y))

	draw_rect(Rect2(420, 190, 450, 310), Color(0.18, 0.15, 0.11))
	for x in range(430, 850, 64):
		for y in range(200, 490, 64):
			if floor_texture != null:
				draw_texture(floor_texture, Vector2(x, y))

	for x in range(150, 340, 48):
		for y in range(160, 285, 48):
			if field_texture != null:
				draw_texture(field_texture, Vector2(x, y))

	draw_rect(Rect2(70, 540, 380, 90), Color(0.16, 0.16, 0.15))
	draw_rect(Rect2(900, 100, 260, 420), Color(0.10, 0.10, 0.10))


func _spawn_player() -> void:
	player = PlayerController.new()
	player.position = Vector2(610, 390)
	add_child(player)

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position = Vector2(640, 360)
	camera.zoom = Vector2(1.0, 1.0)
	add_child(camera)


func _build_base_layout() -> void:
	queue_redraw()
	_add_sprite("res://assets/art/objects/crash_plane.png", Vector2(230, 575), Vector2(2.0, 2.0), 1)
	_add_sprite("res://assets/art/objects/bunker.png", Vector2(600, 300), Vector2(2.5, 2.5), 1)
	_add_sprite("res://assets/art/objects/lab.png", Vector2(735, 320), Vector2(2.0, 2.0), 2)
	_add_sprite("res://assets/art/objects/generator.png", Vector2(530, 480), Vector2(1.7, 1.7), 2)
	_add_sprite("res://assets/art/objects/animal_pen.png", Vector2(375, 190), Vector2(1.7, 1.7), 1)
	_add_sprite("res://assets/art/objects/city_gate.png", Vector2(1050, 445), Vector2(1.8, 1.8), 2)

	for pos in [Vector2(130, 300), Vector2(250, 300), Vector2(370, 300), Vector2(490, 155), Vector2(610, 155), Vector2(730, 155), Vector2(850, 155), Vector2(970, 300), Vector2(970, 420)]:
		_add_sprite("res://assets/art/objects/wall_segment.png", pos, Vector2(1.4, 1.4), 3)

	for pos in [Vector2(875, 235), Vector2(875, 455), Vector2(455, 155)]:
		_add_sprite("res://assets/art/objects/turret.png", pos, Vector2(1.6, 1.6), 4)

	for pos in [Vector2(160, 175), Vector2(220, 175), Vector2(280, 175), Vector2(160, 235), Vector2(220, 235), Vector2(280, 235)]:
		_add_sprite("res://assets/art/objects/farm_plot.png", pos, Vector2(1.2, 1.2), 1)

	for pos in [Vector2(980, 155), Vector2(1080, 215), Vector2(1005, 340)]:
		_add_sprite("res://assets/art/objects/ruined_building.png", pos, Vector2(1.6, 1.6), 1)


func _create_interactions() -> void:
	_add_interactable("E 打开实验室研究台", Vector2(735, 340), 62.0, Callable(self, "_open_research"))
	_add_interactable("E 查看基地与建造信息", Vector2(520, 480), 60.0, Callable(self, "_open_base_panel"))
	_add_interactable("E 前往城市废墟搜刮", Vector2(1050, 445), 74.0, Callable(self, "_go_city"))
	_add_interactable("E 启动夜晚防守模拟", Vector2(875, 455), 62.0, Callable(self, "_go_night"))
	_add_interactable("E 维护发电机：燃料 -1 / 电力 +8", Vector2(530, 480), 54.0, Callable(self, "_prime_generator"))


func _add_sprite(texture_path: String, pos: Vector2, scale_value: Vector2, z: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = TextureLoader.load_texture(texture_path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = pos
	sprite.scale = scale_value
	sprite.z_index = z
	add_child(sprite)
	return sprite


func _add_interactable(prompt: String, pos: Vector2, radius: float, callback: Callable) -> InteractablePoint:
	var point := InteractablePoint.new()
	point.prompt = prompt
	point.radius = radius
	point.position = pos
	point.callback = callback
	add_child(point)
	return point


func _open_research(_actor: Node) -> void:
	EventBus.research_panel_requested.emit()


func _open_base_panel(_actor: Node) -> void:
	EventBus.base_panel_requested.emit()


func _go_city(_actor: Node) -> void:
	SceneRouter.go_city()


func _go_night(_actor: Node) -> void:
	SceneRouter.go_night()


func _prime_generator(_actor: Node) -> void:
	if GameState.spend({"fuel": 1}, "generator"):
		GameState.add_power(8)
		EventBus.announce_notice("发电机恢复稳定输出。")
	else:
		EventBus.announce_notice("燃料不足，发电机只能低速运转。")
