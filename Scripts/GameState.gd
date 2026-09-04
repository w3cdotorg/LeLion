extends Node
## État global d'une partie : couleurs débloquées, progression de la peinture,
## chrono, fin de partie.

signal couleur_debloquee(couleur: Color)
signal progression_changee(ratio: float)
signal partie_terminee(victoire: bool)
signal bonus_change(actif: bool)
signal vies_changees(vies: int)
signal partie_prete()
signal lion_touche(origine: Vector2)

const COULEURS_ARC_EN_CIEL: Array[Color] = [
	Color.RED, Color.ORANGE, Color.YELLOW, Color.GREEN,
	Color.CYAN, Color.BLUE, Color.VIOLET,
]
const VIES_MAX := 3
const NB_ETAPES_ARCADE := 9  # 3 niveaux × 3 difficultés
const DUREE_INVULNERABILITE := 1.5
const DIFFICULTES: Array[Dictionary] = [
	{"id": "facile", "nom": "DIFF_FACILE", "description": "DIFF_FACILE_DESC", "vies": 3, "pickups_coeur": true, "seuil": 0.85},
	{"id": "moyen", "nom": "DIFF_MOYEN", "description": "DIFF_MOYEN_DESC", "vies": 3, "pickups_coeur": false, "seuil": 0.90},
	{"id": "hardcore", "nom": "DIFF_HARDCORE", "description": "DIFF_HARDCORE_DESC", "vies": 1, "pickups_coeur": false, "seuil": 0.95},
]
const NIVEAUX: Array[Dictionary] = [
	{"id": "skyline", "nom": "NIVEAU_SKYLINE", "texture": "res://Assets/Sprites/skyline_2000px.png"},
	{"id": "metropole", "nom": "NIVEAU_METROPOLE", "texture": "res://Assets/Sprites/skyline_metropole.png"},
	{"id": "village", "nom": "NIVEAU_VILLAGE", "texture": "res://Assets/Sprites/skyline_village.png", "boss": true},
]

var couleurs_debloquees: Array[Color] = []
var progression := 0.0
var temps_ecoule := 0.0
var partie_en_cours := false
var pret := false  # false pendant l'intro « Prêt ? Vomissez ! »
var niveau_courant := 0
var difficulte_courante := 0
var mode_arcade := false
var demo := false  # attract mode : le jeu se joue tout seul
var etape_arcade := 0
var temps_arcade := 0.0  # somme des temps des stages gagnés
var vies := 3
var coups_recus := 0
var invulnerable_restant := 0.0
var bonus_restant := 0.0


func _process(delta: float) -> void:
	if not partie_en_cours or not pret:
		return
	temps_ecoule += delta
	if invulnerable_restant > 0.0:
		invulnerable_restant = max(0.0, invulnerable_restant - delta)
	if bonus_restant > 0.0:
		bonus_restant -= delta
		if bonus_restant <= 0.0:
			bonus_restant = 0.0
			bonus_change.emit(false)


func nouvelle_partie() -> void:
	couleurs_debloquees.clear()
	progression = 0.0
	temps_ecoule = 0.0
	bonus_restant = 0.0
	invulnerable_restant = 0.0
	vies = difficulte().vies
	coups_recus = 0
	pret = false
	partie_en_cours = true


## Fin de l'intro : le jeu réagit aux commandes, les ennemis arrivent, le chrono tourne.
func demarrer() -> void:
	if pret:
		return
	pret = true
	partie_prete.emit()


func difficulte() -> Dictionary:
	return DIFFICULTES[difficulte_courante]


## Texte affiché par l'intro : « STAGE n/9 » en arcade, sinon le nom du niveau.
func titre_etape() -> String:
	if mode_arcade:
		return tr("STAGE") % [etape_arcade + 1, NB_ETAPES_ARCADE]
	return tr(niveau().nom).to_upper()


## Arcade : les neuf stages à la suite, Facile puis Moyen puis Hardcore, trois niveaux chacun.
func demarrer_arcade() -> void:
	mode_arcade = true
	etape_arcade = 0
	temps_arcade = 0.0
	_appliquer_etape_arcade()


func quitter_arcade() -> void:
	mode_arcade = false


func _appliquer_etape_arcade() -> void:
	difficulte_courante = etape_arcade / NIVEAUX.size()
	niveau_courant = etape_arcade % NIVEAUX.size()


func etape_arcade_suivante_existe() -> bool:
	return etape_arcade + 1 < NB_ETAPES_ARCADE


func passer_etape_arcade() -> void:
	if etape_arcade_suivante_existe():
		etape_arcade += 1
		_appliquer_etape_arcade()


func arcade_termine() -> bool:
	return mode_arcade and not etape_arcade_suivante_existe()


## Part de la ville à peindre pour gagner, selon la difficulté.
func seuil_victoire() -> float:
	return difficulte().seuil


func cle_score() -> String:
	return "%s/%s" % [niveau().id, difficulte().id]


func est_invulnerable() -> bool:
	return invulnerable_restant > 0.0


## Un ennemi touche le lion : perd une vie, ou termine la partie s'il n'en reste plus.
## `origine` = position de l'ennemi, pour le recul (Vector2.INF si inconnue).
func toucher_lion(origine: Vector2 = Vector2.INF) -> void:
	if not partie_en_cours or not pret or est_invulnerable():
		return
	vies -= 1
	coups_recus += 1
	vies_changees.emit(vies)
	if vies <= 0:
		terminer_partie(false)
		return
	invulnerable_restant = DUREE_INVULNERABILITE
	lion_touche.emit(origine)


func gagner_vie() -> bool:
	if vies >= VIES_MAX:
		return false
	vies += 1
	vies_changees.emit(vies)
	return true


func niveau() -> Dictionary:
	return NIVEAUX[niveau_courant]


func niveau_suivant_existe() -> bool:
	return niveau_courant + 1 < NIVEAUX.size()


func passer_au_niveau_suivant() -> void:
	if niveau_suivant_existe():
		niveau_courant += 1


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


func bonus_actif() -> bool:
	return bonus_restant > 0.0


## Active (ou prolonge) la gerbe XXL pour `duree` secondes.
func activer_bonus(duree: float) -> void:
	var etait_actif := bonus_actif()
	bonus_restant = max(bonus_restant, duree)
	if not etait_actif:
		bonus_change.emit(true)


func signaler_progression(ratio: float) -> void:
	progression = ratio
	progression_changee.emit(ratio)
	if partie_en_cours and ratio >= seuil_victoire():
		terminer_partie(true)


func terminer_partie(victoire: bool) -> void:
	if not partie_en_cours:
		return
	partie_en_cours = false
	if victoire and mode_arcade:
		temps_arcade += temps_ecoule
	partie_terminee.emit(victoire)


static func formater_temps(secondes: float) -> String:
	var total := int(secondes)
	return "%d:%02d" % [total / 60, total % 60]
