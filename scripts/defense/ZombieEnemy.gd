extends CharacterBody2D

const TextureLoader := preload("res://scripts/core/TextureLoader.gd")

signal died(enemy)

var zombie_id := "walker"
var health := 22
var speed := 38.0
var damage := 4
var reward_samples := 1
var building_damage := 4
var armor := 0.0
var fire_weakness := 1.0
var pierce_weakness := 1.0
var walls := []
var base_position := Vector2.ZERO
var target_wall: Node2D = null
var path_points: Array[Vector2] = []
var path_index := 0
var target_building: Node = null
var attack_cooldown := 0.0
var slow_multiplier := 1.0
var slow_timer := 0.0
var sprite: Sprite2D


func setup(data: Dictionary, wall_segments: Array, bunker_position: Vector2) -> void:
	zombie_id = str(data.get("id", "walker"))
	health = int(data.get("health", 22))
	speed = float(data.get("speed", 38))
	damage = int(data.get("damage", 4))
	building_damage = int(data.get("building_damage", damage))
	reward_samples = int(data.get("reward_samples", 1))
	armor = float(data.get("armor", 0.0))
	fire_weakness = float(data.get("fire_weakness", 1.0))
	pierce_weakness = float(data.get("pierce_weakness", 1.0))
	walls = wall_segments
	base_position = bunker_position


func setup_dynamic(data: Dictionary, path: Array, target: Node) -> void:
	setup(data, [], Vector2.ZERO)
	path_points.clear()
	for point in path:
		path_points.append(point)
	path_index = 0
	target_building = target


func _ready() -> void:
	add_to_group("zombies")
	collision_layer = 2
	collision_mask = 1

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(22, 28)
	shape.shape = rect
	add_child(shape)

	sprite = Sprite2D.new()
	if zombie_id == "runner":
		sprite.texture = TextureLoader.load_texture("res://assets/art/characters/zombie_runner.png")
	elif zombie_id == "brute":
		sprite.texture = TextureLoader.load_texture("res://assets/art/characters/zombie_brute.png")
	else:
		sprite.texture = TextureLoader.load_texture("res://assets/art/characters/zombie_walker.png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0, -8)
	add_child(sprite)
	target_wall = _nearest_wall()


func _physics_process(delta: float) -> void:
	if health <= 0:
		return
	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			slow_multiplier = 1.0

	if not path_points.is_empty():
		_follow_dynamic_path(delta)
		return

	if target_wall == null or not is_instance_valid(target_wall) or not target_wall.is_blocking():
		target_wall = _nearest_wall()

	var target := base_position
	if target_wall != null and target_wall.is_blocking():
		target = target_wall.global_position

	var distance := global_position.distance_to(target)
	if distance > 42:
		velocity = (target - global_position).normalized() * speed * slow_multiplier
		move_and_slide()
		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0
	else:
		velocity = Vector2.ZERO
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			_attack_target()
			attack_cooldown = 0.85


func take_damage(amount: int, damage_type: String = "normal") -> void:
	var final_amount := amount
	if damage_type == "fire":
		final_amount = int(amount * fire_weakness)
	elif damage_type == "pierce":
		final_amount = int(amount * pierce_weakness)
	else:
		final_amount = int(amount * (1.0 - armor))
	final_amount = max(1, final_amount)
	health -= final_amount
	modulate = Color(1.0, 0.72, 0.72, 1.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.08)
	if health <= 0:
		AudioManager.play_sfx("zombie")
		GameState.record_kill()
		died.emit(self)
		queue_free()


func _attack_target() -> void:
	if target_wall != null and is_instance_valid(target_wall) and target_wall.is_blocking():
		target_wall.apply_damage(building_damage)
	else:
		GameState.record_base_damage(damage)
	AudioManager.play_sfx("damage")


func _follow_dynamic_path(delta: float) -> void:
	if target_building != null and (not is_instance_valid(target_building) or target_building.health <= 0):
		GameState.record_base_damage(damage)
		queue_free()
		return
	var target := path_points[min(path_index, path_points.size() - 1)]
	var distance := global_position.distance_to(target)
	if distance > 16:
		velocity = (target - global_position).normalized() * speed * slow_multiplier
		move_and_slide()
		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0
		return
	if path_index < path_points.size() - 1:
		path_index += 1
		return
	velocity = Vector2.ZERO
	attack_cooldown -= delta
	if attack_cooldown <= 0.0:
		if target_building != null and is_instance_valid(target_building):
			target_building.apply_damage(building_damage)
		else:
			GameState.record_base_damage(damage)
		attack_cooldown = 0.85


func apply_slow(multiplier: float, duration: float) -> void:
	slow_multiplier = min(slow_multiplier, multiplier)
	slow_timer = max(slow_timer, duration)


func _nearest_wall() -> Node2D:
	var best: Node2D = null
	var best_distance := 100000.0
	for wall in walls:
		if wall == null or not is_instance_valid(wall) or not wall.is_blocking():
			continue
		var distance := global_position.distance_to(wall.global_position)
		if distance < best_distance:
			best_distance = distance
			best = wall
	return best
