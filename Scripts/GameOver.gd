extends CanvasLayer

func _on_Rejouer_pressed() -> void:
	print("✅ Le bouton a bien été cliqué !")
	print("🔁 Rechargement de la scène...")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Lion.tscn")
