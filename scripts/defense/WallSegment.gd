extends StaticBody2D

const TextureLoader := preload("res://scripts/core/TextureLoader.gd")

signal destroyed(segment)

@export var max_health := 100
var health := 100
var sprite: Sprite2D
var collision_shape: CollisionShape2D


func _ready() -> void:
	health = max_health
	collision_layer = 1
	collision_mask = 0
	sprite = Sprite2D.new()
	sprite.texture = TextureLoader.load_texture(ArtRegistry.object_path("scrap_wall", "res://assets/art/objects/wall_segment.png"))
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(0.58, 0.58)
	sprite.scale = Vector2(1.5, 1.5)
	add_child(sprite)

	collision_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(84, 42)
	collision_shape.position = Vector2(0, 8)
	collision_shape.shape = rect
	add_child(collision_shape)
	queue_redraw()


func is_blocking() -> bool:
	return health > 0


func apply_damage(amount: int) -> void:
	if health <= 0:
		return
	health = max(0, health - amount)
	GameState.record_wall_damage(amount)
	if health <= 0:
		modulate = Color(0.35, 0.32, 0.30, 1.0)
		if collision_shape != null:
			collision_shape.disabled = true
		destroyed.emit(self)
	queue_redraw()


func _draw() -> void:
	var ratio := float(health) / float(max_health)
	draw_rect(Rect2(Vector2(-28, -42), Vector2(56, 5)), Color(0.14, 0.05, 0.04))
	draw_rect(Rect2(Vector2(-28, -42), Vector2(56 * ratio, 5)), Color(0.78, 0.18, 0.12))
