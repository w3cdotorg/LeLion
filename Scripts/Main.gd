extends Node2D
## Racine de la partie : place la ville, écoute la fin de partie et affiche l'overlay.

@export var game_over_scene: PackedScene

@export var force_tremblement := 14.0
@export var duree_tremblement := 0.35

@onready var ville: Node2D = $Ville
@onready var lion: CharacterBody2D = $Lion
@onready var camera: Camera2D = $Camera

var _tremblement_restant := 0.0


const ACTIONS_DE_JEU := ["deplacer_gauche", "deplacer_droite", "deplacer_haut", "deplacer_bas", "vomir"]


func _ready() -> void:
	for action in ACTIONS_DE_JEU:
		Input.action_release(action)
	GameState.nouvelle_partie()
	GameState.partie_terminee.connect(_on_partie_terminee)
	GameState.lion_touche.connect(func(_o: Vector2) -> void: trembler())
	ville.charger_skyline(load(GameState.niveau().texture))
	_placer_ville()


func _placer_ville() -> void:
	var screen_size := get_viewport_rect().size
	var texture_size: Vector2 = ville.get_node("Sprite2D").texture.get_size()
	ville.position = Vector2(screen_size.x / 2, screen_size.y - texture_size.y / 2)


func _process(delta: float) -> void:
	if _tremblement_restant <= 0.0:
		return
	_tremblement_restant = max(0.0, _tremblement_restant - delta)
	var intensite := force_tremblement * (_tremblement_restant / duree_tremblement)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensite
	if _tremblement_restant == 0.0:
		camera.offset = Vector2.ZERO


func trembler() -> void:
	_tremblement_restant = duree_tremblement


func _on_partie_terminee(victoire: bool) -> void:
	if not victoire:
		lion.hide()
	var overlay := game_over_scene.instantiate()
	add_child(overlay)
	overlay.afficher(victoire, GameState.progression, GameState.temps_ecoule)
	get_tree().paused = true
