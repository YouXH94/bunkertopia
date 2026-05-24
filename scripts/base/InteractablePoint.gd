extends Area2D

const TextureLoader := preload("res://scripts/core/TextureLoader.gd")

signal interacted(actor)

@export var prompt := "E 交互"
@export var radius := 48.0

var callback: Callable
var marker: Sprite2D


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


func set_marker(texture_path: String, offset: Vector2 = Vector2.ZERO) -> void:
	marker = Sprite2D.new()
	marker.texture = TextureLoader.load_texture(texture_path)
	marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	marker.position = offset
	add_child(marker)


func interact(actor: Node) -> void:
	if callback.is_valid():
		callback.call(actor)
	else:
		interacted.emit(actor)


func _on_body_entered(body: Node) -> void:
	if body.has_method("set_interactable"):
		body.set_interactable(self)


func _on_body_exited(body: Node) -> void:
	if body.has_method("set_interactable") and body.current_interactable == self:
		body.set_interactable(null)
