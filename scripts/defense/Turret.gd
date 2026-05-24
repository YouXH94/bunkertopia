extends Node2D

const TextureLoader := preload("res://scripts/core/TextureLoader.gd")

@export var attack_range := 260.0
@export var damage := 12
@export var fire_interval := 0.45

var cooldown := 0.0
var shot_timer := 0.0
var shot_target := Vector2.ZERO
var sprite: Sprite2D


func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture = TextureLoader.load_texture("res://assets/art/objects/turret.png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(1.55, 1.55)
	add_child(sprite)
	queue_redraw()


func _process(delta: float) -> void:
	cooldown = max(0.0, cooldown - delta)
	shot_timer = max(0.0, shot_timer - delta)
	if cooldown <= 0.0:
		_try_fire()
	queue_redraw()


func _try_fire() -> void:
	if not GameState.turret_ready:
		return
	if int(GameState.resources.get("ammo", 0)) <= 0 or int(GameState.resources.get("power", 0)) <= 0:
		return

	var target := _find_target()
	if target == null:
		return

	target.take_damage(damage)
	GameState.apply_resource_delta({"ammo": -1}, "turret_fire")
	shot_target = to_local(target.global_position)
	shot_timer = 0.08
	cooldown = fire_interval


func _find_target() -> Node:
	var best: Node = null
	var best_distance := attack_range
	for zombie in get_tree().get_nodes_in_group("zombies"):
		if zombie == null or not is_instance_valid(zombie):
			continue
		var distance := global_position.distance_to(zombie.global_position)
		if distance < best_distance:
			best_distance = distance
			best = zombie
	return best


func _draw() -> void:
	draw_arc(Vector2.ZERO, attack_range, 0, TAU, 48, Color(0.50, 0.72, 0.55, 0.10), 1.0)
	if shot_timer > 0.0:
		draw_line(Vector2.ZERO, shot_target, Color(1.0, 0.78, 0.36), 3.0)
