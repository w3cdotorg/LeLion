extends Control
## Stick virtuel dynamique : il apparaît là où le pouce touche la moitié gauche de l'écran
## et pilote les actions deplacer_* avec une intensité proportionnelle.

const ACTIONS := ["deplacer_gauche", "deplacer_droite", "deplacer_haut", "deplacer_bas"]

@export var rayon := 110.0
@export var rayon_bouton := 48.0
@export var zone_morte := 0.15
@export var part_ecran := 0.45  # fraction de la largeur où le stick peut apparaître
@export var couleur_base := Color(1, 1, 1, 0.18)
@export var couleur_bouton := Color(1, 1, 1, 0.55)

var vecteur := Vector2.ZERO
var actif := false
var _index_touche := -1
var _centre := Vector2.ZERO
var _position_repos := Vector2.ZERO


func _ready() -> void:
	_position_repos = Vector2(rayon + 60.0, get_viewport_rect().size.y - rayon - 60.0)
	_centre = _position_repos
	GameState.partie_terminee.connect(func(_v: bool) -> void: fin())
	queue_redraw()


## Les actions vivent dans le singleton Input : on les relâche quand le stick disparaît
## (changement de scène), sinon le lion garderait la dernière direction.
func _exit_tree() -> void:
	relacher_actions()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _index_touche < 0 and event.position.x < get_viewport_rect().size.x * part_ecran:
			_index_touche = event.index
			debut(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _index_touche:
			fin()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _index_touche:
		glisser(event.position)
		get_viewport().set_input_as_handled()


func debut(position_touche: Vector2) -> void:
	actif = true
	_centre = position_touche
	glisser(position_touche)


func glisser(position_touche: Vector2) -> void:
	var brut := (position_touche - _centre) / rayon
	if brut.length() > 1.0:
		brut = brut.normalized()
	vecteur = brut if brut.length() >= zone_morte else Vector2.ZERO
	_appliquer_actions()
	queue_redraw()


func fin() -> void:
	actif = false
	_index_touche = -1
	vecteur = Vector2.ZERO
	_centre = _position_repos
	relacher_actions()
	queue_redraw()


static func relacher_actions() -> void:
	for action in ACTIONS:
		Input.action_release(action)


func _appliquer_actions() -> void:
	_action(ACTIONS[0], -vecteur.x)
	_action(ACTIONS[1], vecteur.x)
	_action(ACTIONS[2], -vecteur.y)
	_action(ACTIONS[3], vecteur.y)


func _action(nom: String, force: float) -> void:
	if force > 0.0:
		Input.action_press(nom, min(force, 1.0))
	else:
		Input.action_release(nom)


func _draw() -> void:
	draw_circle(_centre, rayon, couleur_base)
	draw_arc(_centre, rayon, 0.0, TAU, 48, Color(1, 1, 1, 0.4), 3.0, true)
	draw_circle(_centre + vecteur * (rayon - rayon_bouton), rayon_bouton, couleur_bouton)
