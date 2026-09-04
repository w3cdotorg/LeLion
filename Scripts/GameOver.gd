extends CanvasLayer


func _on_Rejouer_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
