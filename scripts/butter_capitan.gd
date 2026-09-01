extends AnimatableBody2D

const MAX_HEALTH = 6
const HITS_TO_PHASE2 = 3

const SUMMON_INTERVAL_PHASE1 = 3.0
const SUMMON_INTERVAL_PHASE2 = 5.0

const INVINCIBLE_TIME = 0.5
const MAX_BUTTERRECTANGLES = 3
const MAX_BILLY_BUTTERS = 1

var health = MAX_HEALTH
var entered_phase2 = false
var invincible_timer = 0.0
var summon_timer = SUMMON_INTERVAL_PHASE1

@export var enemy_to_summon: PackedScene       # Butterrectangle
@export var phase2_enemy_to_summon: PackedScene # Billy Butter
@export var door_tile_cells: Array[Vector2i] = []  # coordenadas de CELDA (columna, fila) de la puerta a borrar
@export var facing_direction: int = 1           # 1 = mira a la derecha, -1 = mira a la izquierda

@onready var sprite = $AnimatedSprite2D
@onready var tilemap = get_node("/root/Game/TileMapLayer")

func _ready() -> void:
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	sprite.flip_h = facing_direction < 0
	sprite.play("Idle")

func _physics_process(delta: float) -> void:
	if invincible_timer > 0:
		invincible_timer -= delta
		sprite.modulate.a = 0.4 if fmod(invincible_timer, 0.2) < 0.1 else 1.0
		collision_layer = 0
		$HurtArea.monitoring = false
		if invincible_timer <= 0:
			collision_layer = 1
			$HurtArea.monitoring = true
	else:
		sprite.modulate.a = 1.0

	# Mientras está reproduciendo la invocación, no cuenta el timer (evita solaparse)
	if sprite.animation == "Summon":
		return

	summon_timer -= delta
	if summon_timer <= 0:
		sprite.play("Summon")

func _on_sprite_animation_finished() -> void:
	if sprite.animation == "Summon":
		do_summon()
		summon_timer = SUMMON_INTERVAL_PHASE2 if entered_phase2 else SUMMON_INTERVAL_PHASE1
		sprite.play("Idle")

func do_summon() -> void:
	var enemy: Node
	if entered_phase2:
		if phase2_enemy_to_summon == null:
			return
		if get_tree().get_nodes_in_group("summoned_billy_butter").size() >= MAX_BILLY_BUTTERS:
			return
		enemy = phase2_enemy_to_summon.instantiate()
		enemy.add_to_group("summoned_billy_butter")
	else:
		if enemy_to_summon == null:
			return
		if get_tree().get_nodes_in_group("summoned_butterrectangle").size() >= MAX_BUTTERRECTANGLES:
			return
		enemy = enemy_to_summon.instantiate()
		enemy.add_to_group("summoned_butterrectangle")

	get_parent().add_child(enemy)
	enemy.global_position = global_position + Vector2(20 * facing_direction, 0)

func stomp() -> void:
	if invincible_timer > 0:
		return
	health -= 1
	invincible_timer = INVINCIBLE_TIME
	do_summon()

	if health <= MAX_HEALTH - HITS_TO_PHASE2 and not entered_phase2:
		entered_phase2 = true

	if health <= 0:
		open_door()
		queue_free()

func open_door() -> void:
	for cell in door_tile_cells:
		print("Borrando celda: ", cell)
		tilemap.erase_cell(cell)

func _on_hurt_area_body_entered(body: Node2D) -> void:
	if body.name != "Jammy":
		return
	if body.global_position.y < global_position.y - 8:
		return
	get_tree().reload_current_scene()
