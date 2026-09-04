extends Control
## Écran titre : choix de la difficulté, puis un bouton par niveau avec le record
## enregistré pour cette difficulté.

const SCENE_JEU := "res://Scenes/Main.tscn"

@onready var difficultes: HBoxContainer = $Centre/Colonne/Difficultes
@onready var niveaux: HBoxContainer = $Centre/Colonne/Niveaux

var boutons_difficulte: Array[Button] = []
var boutons: Array[Button] = []


func _ready() -> void:
	get_tree().paused = false
	GameState.difficulte_courante = clamp(int(Scores.preference("difficulte", GameState.difficulte_courante)), 0, GameState.DIFFICULTES.size() - 1)
	GameState.niveau_courant = clamp(int(Scores.preference("niveau", GameState.niveau_courant)), 0, GameState.NIVEAUX.size() - 1)
	for i in range(GameState.DIFFICULTES.size()):
		var d: Dictionary = GameState.DIFFICULTES[i]
		var bouton := Button.new()
		bouton.toggle_mode = true
		bouton.custom_minimum_size = Vector2(260, 84)
		bouton.text = "%s\n%s" % [d.nom, d.description]
		bouton.add_theme_font_size_override("font_size", 22)
		bouton.pressed.connect(choisir_difficulte.bind(i))
		difficultes.add_child(bouton)
		boutons_difficulte.append(bouton)

	for i in range(GameState.NIVEAUX.size()):
		var bouton := Button.new()
		bouton.custom_minimum_size = Vector2(300, 110)
		bouton.add_theme_font_size_override("font_size", 28)
		bouton.pressed.connect(lancer.bind(i))
		niveaux.add_child(bouton)
		boutons.append(bouton)

	choisir_difficulte(GameState.difficulte_courante)
	boutons[clamp(GameState.niveau_courant, 0, boutons.size() - 1)].grab_focus()


func choisir_difficulte(index: int) -> void:
	GameState.difficulte_courante = index
	Scores.definir_preference("difficulte", index)
	for i in range(boutons_difficulte.size()):
		boutons_difficulte[i].set_pressed_no_signal(i == index)
	for i in range(boutons.size()):
		boutons[i].text = _texte_niveau(i)


func _texte_niveau(index: int) -> String:
	var niveau: Dictionary = GameState.NIVEAUX[index]
	var cle := "%s/%s" % [niveau.id, GameState.difficulte().id]
	var record: float = Scores.meilleur_temps(cle)
	var ligne_record := "record %s" % GameState.formater_temps(record) if record >= 0.0 else "pas encore peint"
	return "%s\n%s" % [niveau.nom, ligne_record]


func lancer(index: int) -> void:
	GameState.niveau_courant = index
	Scores.definir_preference("niveau", index)
	get_tree().change_scene_to_file(SCENE_JEU)
