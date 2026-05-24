extends CharacterBody2D

const TextureLoader := preload("res://scripts/core/TextureLoader.gd")

@export var speed := 185.0

var current_interactable: Node = null
var sprite: Sprite2D


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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_interactable != null:
		current_interactable.interact(self)


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


func _add_key_action(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)
