extends Control
## Écran titre : un bouton par niveau, avec le meilleur temps enregistré.

const SCENE_JEU := "res://Scenes/Main.tscn"

@onready var niveaux: HBoxContainer = $Centre/Colonne/Niveaux

var boutons: Array[Button] = []


func _ready() -> void:
	get_tree().paused = false
	for i in range(GameState.NIVEAUX.size()):
		var bouton := Button.new()
		bouton.custom_minimum_size = Vector2(300, 110)
		bouton.text = _texte_niveau(i)
		bouton.add_theme_font_size_override("font_size", 28)
		bouton.pressed.connect(lancer.bind(i))
		niveaux.add_child(bouton)
		boutons.append(bouton)
	boutons[clamp(GameState.niveau_courant, 0, boutons.size() - 1)].grab_focus()


func _texte_niveau(index: int) -> String:
	var niveau: Dictionary = GameState.NIVEAUX[index]
	var record: float = Scores.meilleur_temps(niveau.id)
	var ligne_record := "record %s" % GameState.formater_temps(record) if record >= 0.0 else "pas encore peint"
	return "%s\n%s" % [niveau.nom, ligne_record]


func lancer(index: int) -> void:
	GameState.niveau_courant = index
	get_tree().change_scene_to_file(SCENE_JEU)
