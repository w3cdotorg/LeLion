extends CanvasLayer
## Affiche la progression de la peinture, les couleurs débloquées et le chrono.

const TAILLE_PASTILLE := Vector2(36, 36)
const COULEUR_VERROUILLEE := Color(1, 1, 1, 0.15)

@onready var progression: ProgressBar = $Marge/Ligne/Progression
@onready var pourcent: Label = $Marge/Ligne/Progression/Pourcent
@onready var couleurs: HBoxContainer = $Marge/Ligne/Couleurs
@onready var chrono: Label = $Marge/Ligne/Chrono
@onready var indice: Label = $Indice

var _pastilles: Array[ColorRect] = []


func _ready() -> void:
	for i in range(GameState.nb_couleurs_total()):
		var pastille := ColorRect.new()
		pastille.custom_minimum_size = TAILLE_PASTILLE
		pastille.color = COULEUR_VERROUILLEE
		couleurs.add_child(pastille)
		_pastilles.append(pastille)

	GameState.progression_changee.connect(_on_progression_changee)
	GameState.couleur_debloquee.connect(_on_couleur_debloquee)
	_on_progression_changee(GameState.progression)
	for c in GameState.couleurs_debloquees:
		_on_couleur_debloquee(c)


func _process(_delta: float) -> void:
	chrono.text = GameState.formater_temps(GameState.temps_ecoule)


func _on_progression_changee(ratio: float) -> void:
	var valeur := ratio * 100.0
	progression.value = valeur
	pourcent.text = "%d %%" % int(valeur)


func _on_couleur_debloquee(couleur: Color) -> void:
	var index := GameState.couleurs_debloquees.find(couleur)
	if index >= 0 and index < _pastilles.size():
		_pastilles[index].color = couleur
	indice.hide()
