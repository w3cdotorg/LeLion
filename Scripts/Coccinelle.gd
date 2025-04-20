extends Area2D

@export var game_over_scene: PackedScene  # à assigner dans l’inspecteur

# Paramètres dynamiques
var speed: float
var frequency: float
var amplitude_depart: float
var amplitude_arrivee: float
var time := 0.0
var start_y := randf_range(-300.0, 300.0)
var phase_offset: float

func _ready():
	start_y = position.y

	# 🎲 Génération aléatoire des paramètres
	speed = randf_range(80.0, 180.0)
	frequency = randf_range(0.5, 3.0)
	amplitude_depart = randf_range(20.0, 40.0)
	amplitude_arrivee = randf_range(60.0, 120.0)
	phase_offset = randf_range(0.0, PI * 2.0)

	print("🐞 Nouvelle coccinelle")
	print(" - Vitesse :", speed)
	print(" - Fréquence :", frequency)
	print(" - Amplitude : de", amplitude_depart, "à", amplitude_arrivee)

func _physics_process(delta):
	time += delta
	position.x -= speed * delta

	# 🧮 Calcul progressif de l'amplitude
	var distance_total = get_viewport().get_visible_rect().size.x + 200.0
	var distance_faite = get_viewport().get_visible_rect().size.x - position.x
	var progression: float = clamp(distance_faite / distance_total, 0.0, 1.0)
	var amplitude = lerp(amplitude_depart, amplitude_arrivee, progression)

	# 🎲 Déplacement erratique sur Y
	var sin_base := sin(time * frequency * PI * 2.0)
	var bruit_doux : float = sin(time * 7.0 + phase_offset * 0.7) * 0.1  # pseudo-bruit lissé
	var offset_y : float = sin_base * amplitude + bruit_doux * amplitude
	position.y = start_y + offset_y
	rotation = deg_to_rad(offset_y * 0.1)

	# ⏳ Suppression hors écran
	if position.x < -200:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	print("💥 Le lion s'est fait attaquer par une coccinelle enragée")
	body.queue_free()

	var overlay = game_over_scene.instantiate()
	get_tree().current_scene.add_child(overlay)
	get_tree().paused = true
