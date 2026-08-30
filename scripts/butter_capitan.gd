extends AnimatableBody2D

const MAX_HEALTH = 5
const HITS_TO_PHASE2 = 3

const SUMMON_INTERVAL_PHASE1 = 3.0
const SUMMON_INTERVAL_PHASE2 = 5.0

const INVINCIBLE_TIME = 1.0

var health = MAX_HEALTH
var entered_phase2 = false
var invincible_timer = 0.0
var summon_timer = SUMMON_INTERVAL_PHASE1

@export var enemy_to_summon: PackedScene       # Butterrectangle
@export var phase2_enemy_to_summon: PackedScene # Billy Butter
@export var door_tile_positions: Array[Vector2] = []  # posiciones (mundo) de las celdas de la puerta a borrar
@export var facing_direction: int = 1           # 1 = mira a la derecha, -1 = mira a la izquierda

@onready var sprite = $AnimatedSprite2D
@onready var tilemap = get_node("/root/Game/TileMapLayer")

func _ready() -> void:
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	sprite.flip_h = facing_direction < 0
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	velocity.x = 0
	move_and_slide()

	if invincible_timer > 0:
		invincible_timer -= delta
		sprite.modulate.a = 0.4 if fmod(invincible_timer, 0.2) < 0.1 else 1.0
	else:
		sprite.modulate.a = 1.0

	# Mientras está reproduciendo la invocación, no cuenta el timer (evita solaparse)
	if sprite.animation == "invocacion":
		return

	summon_timer -= delta
	if summon_timer <= 0:
		sprite.play("invocacion")

func _on_sprite_animation_finished() -> void:
	if sprite.animation == "invocacion":
		do_summon()
		summon_timer = SUMMON_INTERVAL_PHASE2 if entered_phase2 else SUMMON_INTERVAL_PHASE1
		sprite.play("idle")

func do_summon() -> void:
	var scene_to_use = phase2_enemy_to_summon if entered_phase2 else enemy_to_summon
	if scene_to_use == null:
		return
	var enemy = scene_to_use.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = global_position + Vector2(20 * facing_direction, 0)

func stomp() -> void:
	if invincible_timer > 0:
		return
	health -= 1
	invincible_timer = INVINCIBLE_TIME

	if health <= MAX_HEALTH - HITS_TO_PHASE2 and not entered_phase2:
		entered_phase2 = true

	if health <= 0:
		open_door()
		queue_free()

func open_door() -> void:
	for world_pos in door_tile_positions:
		var local_pos = tilemap.to_local(world_pos)
		var map_pos = tilemap.local_to_map(local_pos)
		tilemap.erase_cell(map_pos)

func _on_hurt_area_body_entered(body: Node2D) -> void:
	if body.name != "Jammy":
		return
	if body.global_position.y < global_position.y - 8:
		return
	get_tree().reload_current_scene()
