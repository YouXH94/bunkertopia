extends Node2D

const PlayerController := preload("res://scripts/entities/PlayerController.gd")
const InteractablePoint := preload("res://scripts/base/InteractablePoint.gd")
const SearchContainer := preload("res://scripts/city/SearchContainer.gd")
const TextureLoader := preload("res://scripts/core/TextureLoader.gd")

var road_texture: Texture2D
var ground_texture: Texture2D
var player: CharacterBody2D


func _ready() -> void:
	road_texture = TextureLoader.load_texture("res://assets/art/tiles/cracked_road.png")
	ground_texture = TextureLoader.load_texture("res://assets/art/tiles/dark_ground.png")
	_spawn_player()
	_build_city()
	_create_search_points()
	EventBus.announce_notice("城市探索：靠近箱柜按 E 搜刮，感染风险会累积。")


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0.07, 0.08, 0.08))
	for x in range(0, 1280, 64):
		for y in range(0, 720, 64):
			if ground_texture != null:
				draw_texture(ground_texture, Vector2(x, y))
	for x in range(0, 1280, 64):
		for y in range(275, 455, 64):
			if road_texture != null:
				draw_texture(road_texture, Vector2(x, y))
	for y in range(0, 720, 64):
		if road_texture != null:
			draw_texture(road_texture, Vector2(610, y))


func _spawn_player() -> void:
	player = PlayerController.new()
	player.position = Vector2(100, 620)
	add_child(player)

	var camera := Camera2D.new()
	camera.enabled = true
	camera.position = Vector2(640, 360)
	add_child(camera)


func _build_city() -> void:
	queue_redraw()
	for pos in [Vector2(160, 165), Vector2(360, 145), Vector2(840, 155), Vector2(1060, 180), Vector2(260, 520), Vector2(970, 535)]:
		_add_sprite("res://assets/art/objects/ruined_building.png", pos, Vector2(2.0, 2.0), 1)

	for pos in [Vector2(520, 340), Vector2(740, 315), Vector2(1110, 410)]:
		_add_sprite("res://assets/art/objects/rubble.png", pos, Vector2(1.7, 1.7), 2)

	for pos in [Vector2(330, 365), Vector2(890, 365)]:
		_add_sprite("res://assets/art/objects/wrecked_car.png", pos, Vector2(1.7, 1.7), 2)

	_add_sprite("res://assets/art/objects/crash_plane.png", Vector2(1110, 610), Vector2(1.55, 1.55), 1)
	_add_sprite("res://assets/art/objects/city_gate.png", Vector2(90, 635), Vector2(1.5, 1.5), 3)


func _create_search_points() -> void:
	var positions := [
		Vector2(170, 205),
		Vector2(340, 360),
		Vector2(1110, 605),
		Vector2(880, 365),
		Vector2(260, 520),
		Vector2(735, 315)
	]
	var containers := DataRegistry.get_city_containers()
	for i in range(min(positions.size(), containers.size())):
		var search := SearchContainer.new()
		search.setup(containers[i])
		search.position = positions[i]
		search.radius = 50.0
		search.set_marker("res://assets/art/objects/container.png", Vector2.ZERO)
		add_child(search)

	var exit := InteractablePoint.new()
	exit.prompt = "E 撤回地堡"
	exit.radius = 58.0
	exit.position = Vector2(90, 635)
	exit.callback = Callable(self, "_return_to_base")
	add_child(exit)


func _add_sprite(texture_path: String, pos: Vector2, scale_value: Vector2, z: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = TextureLoader.load_texture(texture_path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = pos
	sprite.scale = scale_value
	sprite.z_index = z
	add_child(sprite)
	return sprite


func _return_to_base(_actor: Node) -> void:
	SceneRouter.go_base()
