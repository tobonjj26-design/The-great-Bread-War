extends CharacterBody2D

const SPEED = 140.0
const WAIT_TIME = 3.0

var direction = 1
var wait_timer = 0.0

@onready var sprite = $AnimatedSprite2D
@onready var wall_ray = $WallRayCast
@onready var tilemap = get_node("/root/Game/TileMapLayer")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if wait_timer > 0:
		wait_timer -= delta
		velocity.x = 0
		sprite.play("Idle")
		move_and_slide()
		return

	wall_ray.target_position.x = 8 * direction

	print("on_floor=", is_on_floor(), " wall=", wall_ray.is_colliding(), " floor_ahead=", has_floor_ahead(), " pos=", global_position)

	if wall_ray.is_colliding() or not has_floor_ahead():
		direction *= -1
		sprite.flip_h = direction < 0
		wait_timer = WAIT_TIME
		velocity.x = 0
		sprite.play("Idle")
		move_and_slide()
		return

	velocity.x = direction * SPEED
	sprite.flip_h = direction < 0
	sprite.play("Run")
	move_and_slide()

func has_floor_ahead() -> bool:
	var check_pos = global_position + Vector2(6 * direction, 12)
	var local_pos = tilemap.to_local(check_pos)
	var map_pos = tilemap.local_to_map(local_pos)
	return tilemap.get_cell_source_id(map_pos) != -1

func _on_hurt_area_body_entered(body: Node2D) -> void:
	if body.name != "Jammy":
		return
	if body.global_position.y < global_position.y - 8:
		return
	get_tree().reload_current_scene()

func stomp() -> void:
	queue_free()
