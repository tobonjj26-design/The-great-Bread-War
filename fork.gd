extends AnimatableBody2D

func _on_hurt_area_body_entered(body: Node2D) -> void:
	if body.name == "Jammy":
		get_tree().reload_current_scene()
