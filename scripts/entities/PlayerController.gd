extends CharacterBody2D

const TextureLoader := preload("res://scripts/core/TextureLoader.gd")

@export var speed := 185.0
@export var attack_range := 54.0
@export var firearm_range := 260.0

var current_interactable: Node = null
var sprite: Sprite2D
var frame_size := Vector2i(64, 64)
var animation_time := 0.0
var animation_name := "idle_down"
var facing := "down"
var attack_anim_timer := 0.0
var attack_cooldown := 0.0
var attack_flash := 0.0
var attack_target := Vector2.ZERO


func _ready() -> void:
	_setup_input()
	name = "Player"
	collision_layer = 1
	collision_mask = 1

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24, 30)
	shape.shape = rect
	shape.position = Vector2(0, 8)
	add_child(shape)

	sprite = Sprite2D.new()
	var sheet_path := ArtRegistry.character_sheet("scientist", "res://assets/art/characters/scientist.png")
	sprite.texture = TextureLoader.load_texture(sheet_path)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0, -12)
	if sheet_path.ends_with("_sheet.png"):
		frame_size = ArtRegistry.character_frame_size("scientist")
		sprite.region_enabled = true
		sprite.region_rect = Rect2(Vector2.ZERO, Vector2(frame_size.x, frame_size.y))
	add_child(sprite)


func _physics_process(_delta: float) -> void:
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	velocity = input_vector.normalized() * speed
	move_and_slide()

	_update_facing(input_vector)
	attack_cooldown = max(0.0, attack_cooldown - _delta)
	attack_anim_timer = max(0.0, attack_anim_timer - _delta)
	attack_flash = max(0.0, attack_flash - _delta)
	_update_animation(_delta, input_vector.length() > 0.05)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_interactable != null:
		current_interactable.interact(self)
	elif event.is_action_pressed("attack"):
		_try_attack()


func set_interactable(interactable: Node) -> void:
	current_interactable = interactable
	if interactable == null:
		EventBus.set_prompt("")
	else:
		EventBus.set_prompt(interactable.prompt)


func _setup_input() -> void:
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("interact", [KEY_E])
	_add_key_action("attack", [KEY_SPACE])


func _add_key_action(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)


func _try_attack() -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = 0.36
	attack_anim_timer = 0.24
	animation_time = 0.0

	var closest := _find_zombie(attack_range)
	if closest != null:
		closest.take_damage(9)
		attack_target = to_local(closest.global_position)
		attack_flash = 0.10
		AudioManager.play_sfx("hit")
		return

	closest = _find_zombie(firearm_range)
	if closest != null and int(GameState.resources.get("ammo", 0)) > 0:
		GameState.apply_resource_delta({"ammo": -1}, "player_fire")
		closest.take_damage(14)
		attack_target = to_local(closest.global_position)
		attack_flash = 0.09
		AudioManager.play_sfx("gun")
		return

	attack_target = Vector2(-42 if sprite.flip_h else 42, 0)
	attack_flash = 0.06


func _update_facing(input_vector: Vector2) -> void:
	if input_vector.length() <= 0.05:
		return
	if abs(input_vector.x) > abs(input_vector.y):
		facing = "side"
		_apply_side_flip(input_vector.x)
	elif input_vector.y < 0:
		facing = "up"
		sprite.flip_h = false
	else:
		facing = "down"
		sprite.flip_h = false


func _apply_side_flip(horizontal: float) -> void:
	var source_facing := ArtRegistry.character_side_facing("scientist")
	if source_facing == "left":
		sprite.flip_h = horizontal > 0
	else:
		sprite.flip_h = horizontal < 0


func _update_animation(delta: float, moving: bool) -> void:
	animation_time += delta
	var state := "idle"
	if attack_anim_timer > 0.0:
		state = "attack"
	elif moving:
		state = "walk"
	_set_animation(state + "_" + facing)


func _set_animation(next_name: String) -> void:
	if not sprite.region_enabled:
		return
	if animation_name != next_name:
		animation_name = next_name
		animation_time = 0.0
	var anim := ArtRegistry.character_animation("scientist", animation_name)
	if anim.is_empty():
		return
	var frames: int = max(1, int(anim.get("frames", 1)))
	var fps: float = max(1.0, float(anim.get("fps", 1)))
	var frame: int = int(animation_time * fps) % frames
	var row: int = int(anim.get("row", 0))
	sprite.region_rect = Rect2(Vector2(frame * frame_size.x, row * frame_size.y), Vector2(frame_size.x, frame_size.y))


func _find_zombie(max_distance: float) -> Node2D:
	var best: Node2D = null
	var best_distance := max_distance
	for zombie in get_tree().get_nodes_in_group("zombies"):
		if zombie == null or not is_instance_valid(zombie):
			continue
		var distance := global_position.distance_to(zombie.global_position)
		if distance <= best_distance:
			best_distance = distance
			best = zombie
	return best


func _draw() -> void:
	if attack_flash > 0.0:
		draw_line(Vector2.ZERO, attack_target, Color(1.0, 0.86, 0.46, 0.95), 3.0)
