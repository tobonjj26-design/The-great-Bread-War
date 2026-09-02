extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -240.0
const SUPER_JUMP_VELOCITY = -380.0

const JUMP_GRAVITY_MULT = 1.0
const FALL_GRAVITY_MULT = 1.8
const JUMP_CUT_MULT = 2.5

const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.1
const SUPER_JUMP_COOLDOWN = 5.0
const DEATH_Y = 70.0

var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var wants_super_jump = false
var super_jump_cooldown_timer = 0.0

@onready var sprite = $AnimatedSprite2D
@onready var camera = $Camera2D

func _ready() -> void:
	if CheckpointManager.has_checkpoint:
		global_position = CheckpointManager.checkpoint_position

func _physics_process(delta: float) -> void:
	if global_position.y > DEATH_Y:
		get_tree().reload_current_scene()
		return

	var gravity = get_gravity()

	# --- Actualizar timers ---
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	if super_jump_cooldown_timer > 0:
		super_jump_cooldown_timer -= delta

	var can_super_jump = super_jump_cooldown_timer <= 0

	if Input.is_action_just_pressed("ui_accept") or (Input.is_action_just_pressed("super_jump") and can_super_jump):
		jump_buffer_timer = JUMP_BUFFER_TIME
		wants_super_jump = Input.is_action_just_pressed("super_jump") and can_super_jump
	else:
		jump_buffer_timer -= delta

	# --- Gravedad variable ---
	if not is_on_floor():
		if velocity.y < 0:
			if Input.is_action_just_released("ui_accept") and not wants_super_jump:
				velocity += gravity * JUMP_CUT_MULT * delta
			else:
				velocity += gravity * JUMP_GRAVITY_MULT * delta
		else:
			velocity += gravity * FALL_GRAVITY_MULT * delta

	# --- Salto (coyote time + jump buffer) ---
	if jump_buffer_timer > 0 and coyote_timer > 0:
		if wants_super_jump:
			velocity.y = SUPER_JUMP_VELOCITY
			super_jump_cooldown_timer = SUPER_JUMP_COOLDOWN
			sprite.play("SuperJump")
		else:
			velocity.y = JUMP_VELOCITY
			sprite.play("Jump")
		jump_buffer_timer = 0
		coyote_timer = 0
		wants_super_jump = false

	# --- Movimiento horizontal ---
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	# --- Detección de pisada sobre enemigos ---
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider != null and collider.is_in_group("enemy") and collision.get_normal().y < -0.5:
			if collider.has_method("stomp"):
				collider.stomp()
			velocity.y = JUMP_VELOCITY * 0.85
			hitstop(0.12)
			shake_camera(3.0, 0.15)

	# --- Animaciones ---
	if is_on_floor():
		if direction != 0:
			sprite.play("run")
			sprite.flip_h = direction < 0
		else:
			sprite.play("idle")
	elif direction != 0:
		sprite.flip_h = direction < 0

func hitstop(duration: float) -> void:
	Engine.time_scale = 0.02
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func shake_camera(strength: float, duration: float) -> void:
	var timer = get_tree().create_timer(duration, true, false, true)
	var original_offset = camera.offset
	while timer.time_left > 0:
		camera.offset = original_offset + Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		await get_tree().create_timer(0.02, true, false, true).timeout
	camera.offset = original_offset
