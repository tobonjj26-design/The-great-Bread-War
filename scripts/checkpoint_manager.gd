extends Node

var has_checkpoint = false
var checkpoint_position = Vector2.ZERO

func set_checkpoint(pos: Vector2) -> void:
	has_checkpoint = true
	checkpoint_position = pos

func clear_checkpoint() -> void:
	has_checkpoint = false
	checkpoint_position = Vector2.ZERO
