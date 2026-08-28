extends CharacterBody2D

const SPEED = 20.0
var direction = 1
var turn_cooldown = 0.0
var no_floor_frames = 0
const NO_FLOOR_THRESHOLD = 3

@onready var sprite = $AnimatedSprite2D
@onready var wall_ray = $WallRayCast
@onready var tilemap = get_node("/root/Game/TileMapLayer")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	wall_ray.target_position.x = 8 * direction

	if not has_floor_ahead():
		no_floor_frames += 1
	else:
		no_floor_frames = 0

	if turn_cooldown > 0:
		turn_cooldown -= delta
	elif wall_ray.is_colliding() or no_floor_frames >= NO_FLOOR_THRESHOLD:
		direction *= -1
		sprite.flip_h = direction < 0
		turn_cooldown = 0.3
		no_floor_frames = 0

	velocity.x = direction * SPEED
	move_and_slide()

func has_floor_ahead() -> bool:
	var check_pos = global_position + Vector2(6 * direction, 12)
	var local_pos = tilemap.to_local(check_pos)
	var map_pos = tilemap.local_to_map(local_pos)
	return tilemap.get_cell_source_id(map_pos) != -1

func _on_hurt_area_2_body_entered(body: Node2D) -> void:
	if body.name == "Jammy":
		get_tree().reload_current_scene()
