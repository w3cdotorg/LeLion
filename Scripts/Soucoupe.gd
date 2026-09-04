extends Area2D

@export var speed: float = 150.0
@export var game_over_scene: PackedScene


func _physics_process(delta: float) -> void:
	position.y = 324
	position.x += speed * delta
	if position.x > 2000:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	body.queue_free()
	var overlay := game_over_scene.instantiate()
	get_tree().current_scene.add_child(overlay)
	get_tree().paused = true
