extends CharacterBody2D

const SPEED = 20.0
const CHARGE_SPEED = 70.0
const CHARGE_RANGE_X = 60.0
const CHARGE_RANGE_Y = 10.0

const MAX_HEALTH = 3
const SUMMON_INTERVAL = 4.0

var direction = 1
var turn_cooldown = 0.0
var no_floor_frames = 0
const NO_FLOOR_THRESHOLD = 3

var health = MAX_HEALTH
var is_charging = false
var invincible_timer = 0.0
var summon_timer = 0.0

@export var enemy_to_summon: PackedScene

@onready var sprite = $AnimatedSprite2D
@onready var wall_ray = $WallRayCast
@onready var tilemap = get_node("/root/Game/TileMapLayer")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if invincible_timer > 0:
		invincible_timer -= delta

	var jammy = get_tree().get_first_node_in_group("player")

	# --- Fase 2: invocar enemigos (última vida) ---
	if health <= 1 and enemy_to_summon != null:
		summon_timer -= delta
		if summon_timer <= 0:
			summon_enemy()
			summon_timer = SUMMON_INTERVAL

	# --- Detectar si debe embestir ---
	is_charging = false
	if jammy != null:
		var diff = jammy.global_position - global_position
		if abs(diff.y) < CHARGE_RANGE_Y and abs(diff.x) < CHARGE_RANGE_X:
			is_charging = true
			direction = sign(diff.x) if diff.x != 0 else direction

	wall_ray.target_position.x = 8 * direction

	if not has_floor_ahead():
		no_floor_frames += 1
	else:
		no_floor_frames = 0

	if turn_cooldown > 0:
		turn_cooldown -= delta
	elif not is_charging and (wall_ray.is_colliding() or no_floor_frames >= NO_FLOOR_THRESHOLD):
		direction *= -1
		sprite.flip_h = direction < 0
		turn_cooldown = 0.3
		no_floor_frames = 0

	var current_speed = CHARGE_SPEED if is_charging else SPEED
	velocity.x = direction * current_speed
	sprite.flip_h = direction < 0
	move_and_slide()

func has_floor_ahead() -> bool:
	var check_pos = global_position + Vector2(6 * direction, 12)
	var local_pos = tilemap.to_local(check_pos)
	var map_pos = tilemap.local_to_map(local_pos)
	return tilemap.get_cell_source_id(map_pos) != -1

func summon_enemy() -> void:
	var enemy = enemy_to_summon.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = global_position + Vector2(0, -20)

func _on_hurt_area_body_entered(body: Node2D) -> void:
	if body.name == "Jammy":
		get_tree().reload_current_scene()

func stomp() -> void:
	if invincible_timer > 0:
		return
	health -= 1
	invincible_timer = 0.8
	if health <= 0:
		queue_free()
