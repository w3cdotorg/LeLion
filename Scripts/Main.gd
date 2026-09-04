extends Node2D
## Racine de la partie : place la ville, écoute la fin de partie et affiche l'overlay.

@export var game_over_scene: PackedScene

@onready var ville: Node2D = $Ville
@onready var lion: CharacterBody2D = $Lion


func _ready() -> void:
	GameState.nouvelle_partie()
	GameState.partie_terminee.connect(_on_partie_terminee)
	_placer_ville()


func _placer_ville() -> void:
	var screen_size := get_viewport_rect().size
	var texture_size: Vector2 = ville.get_node("Sprite2D").texture.get_size()
	ville.position = Vector2(screen_size.x / 2, screen_size.y - texture_size.y / 2)


func _on_partie_terminee(victoire: bool) -> void:
	if not victoire:
		lion.hide()
	var overlay := game_over_scene.instantiate()
	add_child(overlay)
	overlay.afficher(victoire, GameState.progression, GameState.temps_ecoule)
	get_tree().paused = true
