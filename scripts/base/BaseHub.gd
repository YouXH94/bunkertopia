extends Node2D

const PlayerController := preload("res://scripts/entities/PlayerController.gd")
const InteractablePoint := preload("res://scripts/base/InteractablePoint.gd")
const TextureLoader := preload("res://scripts/core/TextureLoader.gd")
const GridBuildSystem := preload("res://scripts/systems/GridBuildSystem.gd")

var player: CharacterBody2D
var dirt_texture: Texture2D
var floor_texture: Texture2D
var field_texture: Texture2D
var grid_build_system


func _ready() -> void:
	dirt_texture = TextureLoader.load_texture("res://assets/art/tiles/dirt.png")
	floor_texture = TextureLoader.load_texture("res://assets/art/tiles/bunker_floor.png")
	field_texture = TextureLoader.load_texture("res://assets/art/tiles/field.png")
	_spawn_player()
	_build_base_layout()
	_setup_grid_building()
	_create_interactions()
	EventBus.announce_notice("白天行动：搜刮、研究、维护防线。夜晚前请确认炮塔、电力和食物。")


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
	_add_boundary_collisions()
	_add_solid_sprite("res://assets/art/objects/crash_plane.png", Vector2(230, 575), Vector2(2.0, 2.0), 1, Vector2(190, 78), Vector2(0, 12))
	_add_solid_sprite("res://assets/art/objects/bunker.png", Vector2(600, 300), Vector2(2.5, 2.5), 1, Vector2(210, 118), Vector2(0, 18))
	_add_solid_sprite("res://assets/art/objects/lab.png", Vector2(735, 320), Vector2(2.0, 2.0), 2, Vector2(130, 98), Vector2(0, 14))
	_add_solid_sprite("res://assets/art/objects/generator.png", Vector2(530, 480), Vector2(1.7, 1.7), 2, Vector2(78, 58), Vector2(0, 12))
	_add_solid_sprite("res://assets/art/objects/animal_pen.png", Vector2(375, 190), Vector2(1.7, 1.7), 1, Vector2(120, 78), Vector2(0, 14))
	_add_solid_sprite("res://assets/art/objects/city_gate.png", Vector2(1050, 445), Vector2(1.8, 1.8), 2, Vector2(78, 102), Vector2(0, 8))

	for pos in [Vector2(130, 300), Vector2(250, 300), Vector2(370, 300), Vector2(490, 155), Vector2(610, 155), Vector2(730, 155), Vector2(850, 155), Vector2(970, 300), Vector2(970, 420)]:
		_add_solid_sprite("res://assets/art/objects/wall_segment.png", pos, Vector2(1.4, 1.4), 3, Vector2(86, 36), Vector2(0, 10))

	for pos in [Vector2(875, 235), Vector2(875, 455), Vector2(455, 155)]:
		_add_solid_sprite("res://assets/art/objects/turret.png", pos, Vector2(1.6, 1.6), 4, Vector2(50, 54), Vector2(0, 8))

	for pos in [Vector2(160, 175), Vector2(220, 175), Vector2(280, 175), Vector2(160, 235), Vector2(220, 235), Vector2(280, 235)]:
		_add_solid_sprite("res://assets/art/objects/farm_plot.png", pos, Vector2(1.2, 1.2), 1, Vector2(46, 34), Vector2(0, 8))

	for pos in [Vector2(980, 155), Vector2(1080, 215), Vector2(1005, 340)]:
		_add_solid_sprite("res://assets/art/objects/ruined_building.png", pos, Vector2(1.6, 1.6), 1, Vector2(120, 118), Vector2(0, 18))


func _create_interactions() -> void:
	_add_interactable("E 打开实验室研究台", Vector2(735, 340), 62.0, Callable(self, "_open_research"))
	_add_interactable("E 查看储物箱与基地面板", Vector2(650, 410), 58.0, Callable(self, "_open_base_panel"))
	_add_interactable("E 打开建造模式", Vector2(610, 390), 62.0, Callable(self, "_open_build_panel"))
	_add_interactable("E 前往城市废墟搜刮", Vector2(1050, 445), 74.0, Callable(self, "_go_city"))
	_add_interactable("E 拉响夜间警报，开始防守", Vector2(875, 455), 62.0, Callable(self, "_go_night"))
	_add_interactable("E 维护发电机：燃料 -1 / 电力 +8", Vector2(530, 480), 54.0, Callable(self, "_prime_generator"))
	_add_interactable("E 抢修农田：水 -2 / 食物 +6", Vector2(220, 210), 86.0, Callable(self, "_tend_farm"))
	_add_interactable("E 照看畜舍：食物 -2 水 -1 / 蛋白 +8", Vector2(375, 190), 64.0, Callable(self, "_tend_animal_pen"))
	_add_interactable("E 给炮塔装填：弹药 -6 电力 -2", Vector2(875, 235), 62.0, Callable(self, "_load_turret"))
	_add_interactable("E 拆解坠机残骸", Vector2(230, 575), 82.0, Callable(self, "_salvage_crash"))


func _add_sprite(texture_path: String, pos: Vector2, scale_value: Vector2, z: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = TextureLoader.load_texture(texture_path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = pos
	sprite.scale = scale_value
	sprite.z_index = z
	add_child(sprite)
	return sprite


func _add_solid_sprite(texture_path: String, pos: Vector2, scale_value: Vector2, z: int, collision_size: Vector2, collision_offset: Vector2 = Vector2.ZERO) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	body.z_index = z
	add_child(body)

	var sprite := Sprite2D.new()
	sprite.texture = TextureLoader.load_texture(texture_path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = scale_value
	sprite.z_index = z
	body.add_child(sprite)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = collision_size
	shape.position = collision_offset
	shape.shape = rect
	body.add_child(shape)
	return body


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


func _setup_grid_building() -> void:
	if GameState.placed_buildings.is_empty():
		GameState.reset_new_game()
	grid_build_system = GridBuildSystem.new()
	grid_build_system.z_index = 7
	add_child(grid_build_system)


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


func _open_build_panel(_actor: Node) -> void:
	EventBus.build_panel_requested.emit()


func _go_city(_actor: Node) -> void:
	SceneRouter.go_city()


func _go_night(_actor: Node) -> void:
	SceneRouter.go_night()


func _prime_generator(_actor: Node) -> void:
	if GameState.spend({"fuel": 1}, "generator"):
		GameState.add_power(8)
		GameState.mark_tutorial_flag("maintained_generator")
		EventBus.announce_notice("发电机恢复稳定输出。")
		AudioManager.play_sfx("generator")
	else:
		EventBus.announce_notice("燃料不足，发电机只能低速运转。")
		AudioManager.play_sfx("fail")


func _tend_farm(_actor: Node) -> void:
	var today_key := "farm_day_" + str(GameState.day)
	if bool(GameState.tutorial_flags.get(today_key, false)):
		EventBus.announce_notice("农田今天已经抢修过，再翻土只会把霉味翻出来。")
		return
	if not GameState.spend({"water": 2}, "farm"):
		EventBus.announce_notice("净水不足，农田只能继续干裂。")
		AudioManager.play_sfx("fail")
		return
	GameState.mark_tutorial_flag(today_key)
	GameState.mark_tutorial_flag("used_farm")
	GameState.apply_resource_delta({"food": 6}, "farm_yield")
	GameState.apply_body_delta({"vitamins": 3, "sanity": 1})
	EventBus.announce_notice("农田产出一批苦到诚实的蔬菜。")
	AudioManager.play_sfx("pickup")


func _tend_animal_pen(_actor: Node) -> void:
	var today_key := "animal_day_" + str(GameState.day)
	if bool(GameState.tutorial_flags.get(today_key, false)):
		EventBus.announce_notice("畜舍今天已经处理过，里面的幸存者都需要安静。")
		return
	if not GameState.spend({"food": 2, "water": 1}, "animal_pen"):
		EventBus.announce_notice("饲料或净水不足，畜舍无法维持产出。")
		AudioManager.play_sfx("fail")
		return
	GameState.mark_tutorial_flag(today_key)
	GameState.mark_tutorial_flag("used_animal_pen")
	GameState.apply_body_delta({"protein": 8, "sanity": 2})
	EventBus.announce_notice("畜舍提供了热蛋白餐。味道不提，活着就行。")
	AudioManager.play_sfx("pickup")


func _load_turret(_actor: Node) -> void:
	if not GameState.spend({"ammo": 6, "power": 2}, "turret_load"):
		EventBus.announce_notice("炮塔装填失败：弹药或电力不足。")
		AudioManager.play_sfx("fail")
		return
	GameState.turret_ready = true
	GameState.mark_tutorial_flag("loaded_turret")
	EventBus.announce_notice("炮塔就绪。它现在比大多数人更可靠。")
	AudioManager.play_sfx("turret")


func _salvage_crash(_actor: Node) -> void:
	if bool(GameState.tutorial_flags.get("crash_salvaged", false)):
		EventBus.announce_notice("坠机残骸已经被拆到只剩糟糕回忆。")
		return
	GameState.mark_tutorial_flag("crash_salvaged")
	GameState.apply_resource_delta({"parts": 8, "fuel": 1, "samples": 1}, "crash_salvage")
	GameState.apply_body_delta({"infection": 2, "calories": -2})
	EventBus.announce_event("坠机残骸", "你从扭曲的航空铝和冷冻箱里拆出还能用的零件、燃料和一份污染样本。\n\n获得：零件 +8，燃料 +1，样本 +1\n感染风险 +2")
	AudioManager.play_sfx("pickup")
