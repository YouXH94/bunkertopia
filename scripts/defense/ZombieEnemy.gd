extends CharacterBody2D

const TextureLoader := preload("res://scripts/core/TextureLoader.gd")

signal died(enemy)

var zombie_id := "walker"
var health := 22
var speed := 38.0
var damage := 4
var reward_samples := 1
var walls := []
var base_position := Vector2.ZERO
var target_wall: Node2D = null
var attack_cooldown := 0.0
var sprite: Sprite2D


func setup(data: Dictionary, wall_segments: Array, bunker_position: Vector2) -> void:
	zombie_id = str(data.get("id", "walker"))
	health = int(data.get("health", 22))
	speed = float(data.get("speed", 38))
	damage = int(data.get("damage", 4))
	reward_samples = int(data.get("reward_samples", 1))
	walls = wall_segments
	base_position = bunker_position


func _ready() -> void:
	add_to_group("zombies")
	collision_layer = 2
	collision_mask = 0

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

	if target_wall == null or not is_instance_valid(target_wall) or not target_wall.is_blocking():
		target_wall = _nearest_wall()

	var target := base_position
	if target_wall != null and target_wall.is_blocking():
		target = target_wall.global_position

	var distance := global_position.distance_to(target)
	if distance > 28:
		velocity = (target - global_position).normalized() * speed
		move_and_slide()
		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0
	else:
		velocity = Vector2.ZERO
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			_attack_target()
			attack_cooldown = 0.85


func take_damage(amount: int) -> void:
	health -= amount
	modulate = Color(1.0, 0.72, 0.72, 1.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.08)
	if health <= 0:
		GameState.record_kill()
		died.emit(self)
		queue_free()


func _attack_target() -> void:
	if target_wall != null and is_instance_valid(target_wall) and target_wall.is_blocking():
		target_wall.apply_damage(damage)
	else:
		GameState.record_base_damage(damage)


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
