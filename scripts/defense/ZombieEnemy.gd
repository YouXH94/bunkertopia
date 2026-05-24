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
var frame_size := Vector2i(64, 64)
var animation_time := 0.0
var animation_name := "walk_down"
var facing := "down"
var hit_anim_timer := 0.0
var attack_anim_timer := 0.0


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
	var fallback := "res://assets/art/characters/zombie_walker.png"
	if zombie_id == "runner":
		fallback = "res://assets/art/characters/zombie_runner.png"
	elif zombie_id == "brute":
		fallback = "res://assets/art/characters/zombie_brute.png"
	var sheet_path := ArtRegistry.character_sheet(zombie_id, fallback)
	sprite.texture = TextureLoader.load_texture(sheet_path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0, -12)
	if sheet_path.ends_with("_sheet.png"):
		frame_size = ArtRegistry.character_frame_size(zombie_id)
		sprite.region_enabled = true
		sprite.region_rect = Rect2(Vector2.ZERO, Vector2(frame_size.x, frame_size.y))
	add_child(sprite)
	target_wall = _nearest_wall()


func _physics_process(delta: float) -> void:
	if health <= 0:
		return
	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			slow_multiplier = 1.0
	hit_anim_timer = max(0.0, hit_anim_timer - delta)
	attack_anim_timer = max(0.0, attack_anim_timer - delta)

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
		_update_facing(velocity)
		_update_animation(delta, true)
	else:
		velocity = Vector2.ZERO
		attack_cooldown -= delta
		_update_animation(delta, false)
		if attack_cooldown <= 0.0:
			attack_anim_timer = 0.22
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
	hit_anim_timer = 0.14
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
		_update_facing(velocity)
		_update_animation(delta, true)
		return
	if path_index < path_points.size() - 1:
		path_index += 1
		return
	velocity = Vector2.ZERO
	attack_cooldown -= delta
	_update_animation(delta, false)
	if attack_cooldown <= 0.0:
		attack_anim_timer = 0.22
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


func _update_facing(move_vector: Vector2) -> void:
	if move_vector.length() <= 0.05:
		return
	if abs(move_vector.x) > abs(move_vector.y):
		facing = "side"
		sprite.flip_h = move_vector.x < 0
	elif move_vector.y < 0:
		facing = "up"
	else:
		facing = "down"


func _update_animation(delta: float, moving: bool) -> void:
	animation_time += delta
	var state := "idle"
	if hit_anim_timer > 0.0:
		state = "hit"
	elif attack_anim_timer > 0.0:
		state = "attack"
	elif moving:
		state = "walk"
	var direction := facing
	if state == "hit":
		direction = "down"
	_set_animation(state + "_" + direction)


func _set_animation(next_name: String) -> void:
	if not sprite.region_enabled:
		return
	if animation_name != next_name:
		animation_name = next_name
		animation_time = 0.0
	var anim := ArtRegistry.character_animation(zombie_id, animation_name)
	if anim.is_empty():
		return
	var frames: int = max(1, int(anim.get("frames", 1)))
	var fps: float = max(1.0, float(anim.get("fps", 1)))
	var frame: int = int(animation_time * fps) % frames
	var row: int = int(anim.get("row", 0))
	sprite.region_rect = Rect2(Vector2(frame * frame_size.x, row * frame_size.y), Vector2(frame_size.x, frame_size.y))
