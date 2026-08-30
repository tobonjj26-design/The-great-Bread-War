extends CharacterBody2D
 
func _on_win_area_body_entered(body: Node2D) -> void:
	if body.name == "Jammy":
		get_tree().change_scene_to_file("res://scenes/win_screen.tscn")
 
