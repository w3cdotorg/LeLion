extends Node
## Fait apparaître pickups et ennemis dans la scène parente.

@export var color_pickup_scene: PackedScene = preload("res://Scenes/ColorPickup.tscn")
@export var soucoupe_scene: PackedScene = preload("res://Scenes/Soucoupe.tscn")
@export var coccinelle_scene: PackedScene = preload("res://Scenes/Coccinelle.tscn")

@export var delai_premier_pickup := 1.0
@export var delai_entre_pickups := 10.0
@export var delai_soucoupe := 2.0
@export var delai_coccinelle := 7.0


func _ready() -> void:
	GameState.couleur_debloquee.connect(_on_couleur_debloquee)
	_programmer(delai_premier_pickup, _spawn_prochain_pickup)
	_programmer(delai_soucoupe, spawn_soucoupe)
	_programmer(delai_coccinelle, spawn_coccinelle)


func _programmer(delai: float, action: Callable) -> void:
	get_tree().create_timer(delai).timeout.connect(action)


func _on_couleur_debloquee(_couleur: Color) -> void:
	_programmer(delai_entre_pickups, _spawn_prochain_pickup)


func _spawn_prochain_pickup() -> void:
	var index := GameState.prochain_index_couleur()
	if index < 0 or not GameState.partie_en_cours:
		return
	spawn_pickup(index, Vector2(300 + 100 * index, 300))


func spawn_pickup(index: int, position_pickup: Vector2) -> Node:
	var pickup := color_pickup_scene.instantiate()
	pickup.couleur_index = index
	pickup.global_position = position_pickup
	get_parent().add_child(pickup)
	return pickup


func spawn_soucoupe() -> Node:
	var soucoupe := soucoupe_scene.instantiate()
	soucoupe.position = Vector2(-200, 324)
	get_parent().add_child(soucoupe)
	return soucoupe


## `y_depart` négatif = hauteur aléatoire.
func spawn_coccinelle(y_depart: float = -1.0) -> Node:
	var c := coccinelle_scene.instantiate()
	var largeur := get_viewport().get_visible_rect().size.x
	if y_depart < 0.0:
		y_depart = randf_range(150.0, 400.0)
	c.position = Vector2(largeur + 100, y_depart)
	get_parent().add_child(c)
	return c
