extends CharacterBody2D

const TextureLoader := preload("res://scripts/core/TextureLoader.gd")

@export var speed := 185.0
@export var attack_range := 54.0
@export var firearm_range := 260.0

var current_interactable: Node = null
var sprite: Sprite2D
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
	sprite.texture = TextureLoader.load_texture("res://assets/art/characters/scientist.png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0, -10)
	add_child(sprite)


func _physics_process(_delta: float) -> void:
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	velocity = input_vector.normalized() * speed
	move_and_slide()

	if input_vector.x != 0:
		sprite.flip_h = input_vector.x < 0
	attack_cooldown = max(0.0, attack_cooldown - _delta)
	attack_flash = max(0.0, attack_flash - _delta)
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
