extends Node
## État global d'une partie : couleurs débloquées, progression de la peinture,
## chrono, fin de partie.

signal couleur_debloquee(couleur: Color)
signal progression_changee(ratio: float)
signal partie_terminee(victoire: bool)

const COULEURS_ARC_EN_CIEL: Array[Color] = [
	Color.RED, Color.ORANGE, Color.YELLOW, Color.GREEN,
	Color.CYAN, Color.BLUE, Color.VIOLET,
]
const SEUIL_VICTOIRE := 0.85

var couleurs_debloquees: Array[Color] = []
var progression := 0.0
var temps_ecoule := 0.0
var partie_en_cours := false


func _process(delta: float) -> void:
	if partie_en_cours:
		temps_ecoule += delta


func nouvelle_partie() -> void:
	couleurs_debloquees.clear()
	progression = 0.0
	temps_ecoule = 0.0
	partie_en_cours = true


func couleur(index: int) -> Color:
	return COULEURS_ARC_EN_CIEL[index]


func nb_couleurs_total() -> int:
	return COULEURS_ARC_EN_CIEL.size()


func debloquer_couleur(index: int) -> bool:
	if index < 0 or index >= COULEURS_ARC_EN_CIEL.size():
		return false
	var c := COULEURS_ARC_EN_CIEL[index]
	if couleurs_debloquees.has(c):
		return false
	couleurs_debloquees.append(c)
	couleur_debloquee.emit(c)
	return true


func prochain_index_couleur() -> int:
	var i := couleurs_debloquees.size()
	return i if i < COULEURS_ARC_EN_CIEL.size() else -1


func signaler_progression(ratio: float) -> void:
	progression = ratio
	progression_changee.emit(ratio)
	if partie_en_cours and ratio >= SEUIL_VICTOIRE:
		terminer_partie(true)


func terminer_partie(victoire: bool) -> void:
	if not partie_en_cours:
		return
	partie_en_cours = false
	partie_terminee.emit(victoire)


static func formater_temps(secondes: float) -> String:
	var total := int(secondes)
	return "%d:%02d" % [total / 60, total % 60]
