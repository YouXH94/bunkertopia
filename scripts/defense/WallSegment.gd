extends Node2D

const TextureLoader := preload("res://scripts/core/TextureLoader.gd")

signal destroyed(segment)

@export var max_health := 100
var health := 100
var sprite: Sprite2D


func _ready() -> void:
	health = max_health
	sprite = Sprite2D.new()
	sprite.texture = TextureLoader.load_texture("res://assets/art/objects/wall_segment.png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(1.5, 1.5)
	add_child(sprite)
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
		destroyed.emit(self)
	queue_redraw()


func _draw() -> void:
	var ratio := float(health) / float(max_health)
	draw_rect(Rect2(Vector2(-28, -42), Vector2(56, 5)), Color(0.14, 0.05, 0.04))
	draw_rect(Rect2(Vector2(-28, -42), Vector2(56 * ratio, 5)), Color(0.78, 0.18, 0.12))
