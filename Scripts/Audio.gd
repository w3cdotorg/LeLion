extends Node
## Effets sonores. Écoute GameState pour les sons d'événements ; le lion pilote la boucle de vomi.

const DB_VOMI := -8.0
const DB_MUSIQUE := -12.0

const SONS := {
	"pickup": preload("res://Assets/Sons/pickup.wav"),
	"mort": preload("res://Assets/Sons/mort.wav"),
	"victoire": preload("res://Assets/Sons/victoire.wav"),
	"boss": preload("res://Assets/Sons/boss.wav"),
	"pret": preload("res://Assets/Sons/pret.wav"),
}
var _vomi_stream: AudioStreamWAV = preload("res://Assets/Sons/vomi.wav")
var _musique_stream: AudioStreamWAV = preload("res://Assets/Sons/musique.wav")
var _vomi: AudioStreamPlayer
var _musique: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_vomi_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_vomi_stream.loop_end = int(_vomi_stream.get_length() * _vomi_stream.mix_rate)
	_vomi = AudioStreamPlayer.new()
	_vomi.stream = _vomi_stream
	add_child(_vomi)

	_musique_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_musique_stream.loop_end = int(_musique_stream.get_length() * _musique_stream.mix_rate)
	_musique = AudioStreamPlayer.new()
	_musique.stream = _musique_stream
	add_child(_musique)
	_musique.play()
	appliquer_volumes()
	Parametres.volumes_changes.connect(appliquer_volumes)

	GameState.couleur_debloquee.connect(func(_c: Color) -> void: jouer("pickup"))
	GameState.partie_terminee.connect(_on_partie_terminee)


func appliquer_volumes() -> void:
	_musique.volume_db = DB_MUSIQUE + Parametres.en_db(Parametres.musique)
	_vomi.volume_db = DB_VOMI + Parametres.en_db(Parametres.effets)


func jouer(nom: String) -> void:
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = SONS[nom]
	lecteur.volume_db = Parametres.en_db(Parametres.effets)
	lecteur.finished.connect(lecteur.queue_free)
	add_child(lecteur)
	lecteur.play()


func demarrer_vomi() -> void:
	if not _vomi.playing:
		_vomi.play()


func arreter_vomi() -> void:
	_vomi.stop()


func _on_partie_terminee(victoire: bool) -> void:
	arreter_vomi()
	jouer("victoire" if victoire else "mort")
