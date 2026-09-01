extends Area2D

var activated = false

@onready var sprite = $AnimatedSprite2D

func _ready() -> void:
	sprite.play("Butter Flag")

func _process(_delta: float) -> void:
	if not activated:
		sprite.play("Butter Flag")

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Jammy":
		return
	if activated:
		return
	activated = true
	CheckpointManager.set_checkpoint(global_position)
	sprite.play("Jammy Flag")
