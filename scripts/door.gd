extends Area2D

@export_file("*.tscn") var next_level: String = ""

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if next_level == "":
			push_warning("Door: next_level path is not set!")
			return
		#HUD.hide()
		get_tree().change_scene_to_file.call_deferred(next_level)
