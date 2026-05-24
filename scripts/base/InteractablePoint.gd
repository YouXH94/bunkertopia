extends Area2D

const TextureLoader := preload("res://scripts/core/TextureLoader.gd")

signal interacted(actor)

@export var prompt := "E 交互"
@export var radius := 48.0
@export var cooldown := 0.6

var callback: Callable
var marker: Sprite2D
var cooldown_remaining := 0.0
var enabled := true


func _ready() -> void:
	monitoring = true
	collision_layer = 0
	collision_mask = 1

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	cooldown_remaining = max(0.0, cooldown_remaining - delta)


func set_marker(texture_path: String, offset: Vector2 = Vector2.ZERO) -> void:
	marker = Sprite2D.new()
	marker.texture = TextureLoader.load_texture(texture_path)
	marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	marker.position = offset
	add_child(marker)


func interact(actor: Node) -> void:
	if not can_interact():
		return
	start_cooldown()
	if callback.is_valid():
		callback.call(actor)
	else:
		interacted.emit(actor)


func can_interact() -> bool:
	return enabled and cooldown_remaining <= 0.0


func start_cooldown() -> void:
	cooldown_remaining = cooldown
	_pulse_marker()


func set_enabled(value: bool) -> void:
	enabled = value
	modulate = Color.WHITE if enabled else Color(0.45, 0.45, 0.45, 1.0)


func _pulse_marker() -> void:
	if marker == null:
		return
	marker.modulate = Color(1.0, 0.86, 0.55, 1.0)
	var tween := create_tween()
	tween.tween_property(marker, "modulate", Color.WHITE, 0.16)


func _on_body_entered(body: Node) -> void:
	if body.has_method("set_interactable"):
		body.set_interactable(self)


func _on_body_exited(body: Node) -> void:
	if body.has_method("set_interactable") and body.current_interactable == self:
		body.set_interactable(null)
