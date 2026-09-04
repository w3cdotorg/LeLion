extends Node
## Effets sonores. Écoute GameState pour les sons d'événements ; le lion pilote la boucle de vomi.

const SONS := {
	"pickup": preload("res://Assets/Sons/pickup.wav"),
	"mort": preload("res://Assets/Sons/mort.wav"),
	"victoire": preload("res://Assets/Sons/victoire.wav"),
	"boss": preload("res://Assets/Sons/boss.wav"),
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
	_vomi.volume_db = -8.0
	add_child(_vomi)

	_musique_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_musique_stream.loop_end = int(_musique_stream.get_length() * _musique_stream.mix_rate)
	_musique = AudioStreamPlayer.new()
	_musique.stream = _musique_stream
	_musique.volume_db = -12.0
	add_child(_musique)
	_musique.play()

	GameState.couleur_debloquee.connect(func(_c: Color) -> void: jouer("pickup"))
	GameState.partie_terminee.connect(_on_partie_terminee)


func jouer(nom: String) -> void:
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = SONS[nom]
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
