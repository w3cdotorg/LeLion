extends Node
## Fait apparaître pickups et ennemis dans la scène parente.
## La difficulté (0 → 1) suit la progression de la peinture et le temps écoulé.

@export var color_pickup_scene: PackedScene = preload("res://Scenes/ColorPickup.tscn")
@export var soucoupe_scene: PackedScene = preload("res://Scenes/Soucoupe.tscn")
@export var coccinelle_scene: PackedScene = preload("res://Scenes/Coccinelle.tscn")

@export_group("Pickups")
@export var delai_premier_pickup := 1.0
@export var delai_entre_pickups := 6.0
@export var zone_pickups := Rect2(150, 80, 1700, 300)
@export var distance_min_du_lion := 300.0

@export_group("Ennemis")
@export var zone_y_ennemis := Vector2(120, 480)
@export var intervalle_soucoupe := Vector2(6.0, 2.5)  # début → fin
@export var intervalle_coccinelle := Vector2(8.0, 3.0)
@export var vitesse_soucoupe := Vector2(150.0, 320.0)
@export var duree_montee_difficulte := 120.0

var _timer_soucoupe: Timer
var _timer_coccinelle: Timer


func _ready() -> void:
	GameState.couleur_debloquee.connect(_on_couleur_debloquee)
	GameState.partie_terminee.connect(_on_partie_terminee)
	_programmer(delai_premier_pickup, _spawn_prochain_pickup)
	_timer_soucoupe = _creer_timer(_on_timer_soucoupe)
	_timer_coccinelle = _creer_timer(_on_timer_coccinelle)
	_timer_soucoupe.start(intervalle_soucoupe.x * 0.5)
	_timer_coccinelle.start(intervalle_coccinelle.x * 0.8)


## 0 au début, 1 quand la ville est presque peinte ou après `duree_montee_difficulte`.
func difficulte() -> float:
	var par_progression := GameState.progression / GameState.SEUIL_VICTOIRE
	var par_temps := GameState.temps_ecoule / duree_montee_difficulte
	return clamp(max(par_progression, par_temps), 0.0, 1.0)


func _intervalle(bornes: Vector2) -> float:
	return lerp(bornes.x, bornes.y, difficulte()) * randf_range(0.8, 1.2)


func _creer_timer(action: Callable) -> Timer:
	var t := Timer.new()
	t.one_shot = true
	t.timeout.connect(action)
	add_child(t)
	return t


func _programmer(delai: float, action: Callable) -> void:
	get_tree().create_timer(delai).timeout.connect(action)


func _on_partie_terminee(_victoire: bool) -> void:
	_timer_soucoupe.stop()
	_timer_coccinelle.stop()


func _on_timer_soucoupe() -> void:
	spawn_soucoupe()
	_timer_soucoupe.start(_intervalle(intervalle_soucoupe))


func _on_timer_coccinelle() -> void:
	spawn_coccinelle()
	_timer_coccinelle.start(_intervalle(intervalle_coccinelle))


func _on_couleur_debloquee(_couleur: Color) -> void:
	_programmer(delai_entre_pickups, _spawn_prochain_pickup)


func _spawn_prochain_pickup() -> void:
	var index := GameState.prochain_index_couleur()
	if index < 0 or not GameState.partie_en_cours:
		return
	spawn_pickup(index, _position_pickup_aleatoire())


func _position_pickup_aleatoire() -> Vector2:
	var lion: Node2D = get_tree().get_first_node_in_group("lion")
	var pos := Vector2.ZERO
	for tentative in range(10):
		pos = Vector2(
			randf_range(zone_pickups.position.x, zone_pickups.end.x),
			randf_range(zone_pickups.position.y, zone_pickups.end.y))
		if lion == null or pos.distance_to(lion.global_position) >= distance_min_du_lion:
			break
	return pos


func spawn_pickup(index: int, position_pickup: Vector2) -> Node:
	var pickup := color_pickup_scene.instantiate()
	pickup.couleur_index = index
	pickup.global_position = position_pickup
	get_parent().add_child(pickup)
	return pickup


## `y_depart` négatif = hauteur aléatoire.
func spawn_soucoupe(y_depart: float = -1.0) -> Node:
	var soucoupe := soucoupe_scene.instantiate()
	if y_depart < 0.0:
		y_depart = randf_range(zone_y_ennemis.x, zone_y_ennemis.y)
	soucoupe.position = Vector2(-200, y_depart)
	soucoupe.speed = lerp(vitesse_soucoupe.x, vitesse_soucoupe.y, difficulte())
	get_parent().add_child(soucoupe)
	return soucoupe


## `y_depart` négatif = hauteur aléatoire.
func spawn_coccinelle(y_depart: float = -1.0) -> Node:
	var c := coccinelle_scene.instantiate()
	var largeur := get_viewport().get_visible_rect().size.x
	if y_depart < 0.0:
		y_depart = randf_range(zone_y_ennemis.x, zone_y_ennemis.y)
	c.position = Vector2(largeur + 100, y_depart)
	get_parent().add_child(c)
	return c
