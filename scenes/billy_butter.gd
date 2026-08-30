extends CharacterBody2D

const CHARGE_SPEED = 52.5
const PHASE2_CHARGE_SPEED = CHARGE_SPEED * 2.0
const CHARGE_RANGE_X = 60.0
const CHARGE_RANGE_Y = 10.0

const MAX_HEALTH = 3
const SUMMON_INTERVAL = 4.0

const INVINCIBLE_TIME = 1.5
const KNOCKBACK_SPEED = 90.0
const KNOCKBACK_UP = -120.0
const TURN_PAUSE_TIME = 0.3

# Límites del área del jefe: ajusta estos dos valores en el Inspector
# a la posición X de la pared izquierda y derecha de tu arena, para que
# el knockback nunca lo empuje fuera de la plataforma.
@export var arena_min_x: float = -100000.0
@export var arena_max_x: float = 100000.0

var direction = 1
var health = MAX_HEALTH
var is_charging = false
var invincible_timer = 0.0
var knockback_timer = 0.0
var summon_timer = 0.0
var entered_phase2 = false
var turn_pause_timer = 0.0

@export var enemy_to_summon: PackedScene

@onready var sprite = $AnimatedSprite2D
@onready var wall_ray = $WallRayCast
@onready var tilemap = get_node("/root/Game/TileMapLayer")

func _ready() -> void:
	sprite.animation_finished.connect(_on_sprite_animation_finished)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if invincible_timer > 0:
		invincible_timer -= delta
		sprite.modulate.a = 0.4 if fmod(invincible_timer, 0.2) < 0.1 else 1.0
	else:
		sprite.modulate.a = 1.0

	if knockback_timer > 0:
		knockback_timer -= delta
		move_and_slide()
		global_position.x = clamp(global_position.x, arena_min_x, arena_max_x)
		return

	var jammy = get_tree().get_first_node_in_group("player")

	# --- Entrar a FASE 2 (última vida): reproduce "transition" una sola vez ---
	if health <= 1 and not entered_phase2:
		entered_phase2 = true
		summon_timer = 5.0
		sprite.play("transition")

	if health <= 1 and enemy_to_summon != null:
		summon_timer -= delta
		if summon_timer <= 0:
			summon_enemy()
			summon_timer = SUMMON_INTERVAL

	# --- Solo se mueve si detecta a Jammy cerca; si no, se queda quieto ---
	# En la última fase (entered_phase2), no se detiene nunca: persigue a Jammy sin importar la distancia.
	is_charging = false
	var desired_direction = direction
	if jammy != null:
		var diff = jammy.global_position - global_position
		if entered_phase2:
			is_charging = true
			if diff.x != 0:
				desired_direction = sign(diff.x)
		elif abs(diff.y) < CHARGE_RANGE_Y and abs(diff.x) < CHARGE_RANGE_X:
			is_charging = true
			desired_direction = sign(diff.x) if diff.x != 0 else direction

	# --- Seguridad: si hay vacío o pared en la dirección hacia la que camina, se voltea sin importar a Jammy ---
	wall_ray.target_position.x = 8 * direction
	if is_charging and (wall_ray.is_colliding() or not has_floor_ahead()):
		desired_direction = -direction

	# --- Pausa antes de voltear ---
	if is_charging and desired_direction != direction and turn_pause_timer <= 0:
		turn_pause_timer = TURN_PAUSE_TIME

	if turn_pause_timer > 0:
		turn_pause_timer -= delta
		velocity.x = 0
		if turn_pause_timer <= 0:
			direction = desired_direction
	elif is_charging:
		velocity.x = direction * (PHASE2_CHARGE_SPEED if entered_phase2 else CHARGE_SPEED)
	else:
		velocity.x = 0

	sprite.flip_h = direction < 0

	# --- Animaciones ---
	if not entered_phase2:
		if is_charging:
			sprite.play("Run")
		else:
			sprite.play("idle")

	move_and_slide()
	global_position.x = clamp(global_position.x, arena_min_x, arena_max_x)

func _on_sprite_animation_finished() -> void:
	if sprite.animation == "transition":
		sprite.play("Move")

func has_floor_ahead() -> bool:
	var check_pos = global_position + Vector2(6 * direction, 12)
	var local_pos = tilemap.to_local(check_pos)
	var map_pos = tilemap.local_to_map(local_pos)
	return tilemap.get_cell_source_id(map_pos) != -1

func summon_enemy() -> void:
	var enemy = enemy_to_summon.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = global_position + Vector2(20 * direction, 0)

func _on_hurt_area_body_entered(body: Node2D) -> void:
	if body.name != "Jammy":
		return
	if body.global_position.y < global_position.y - 8:
		return
	get_tree().reload_current_scene()

func stomp() -> void:
	if invincible_timer > 0:
		return
	health -= 1
	invincible_timer = INVINCIBLE_TIME
	knockback_timer = 0.3
	velocity.x = direction * -KNOCKBACK_SPEED
	velocity.y = KNOCKBACK_UP
	if health <= 0:
		queue_free()
