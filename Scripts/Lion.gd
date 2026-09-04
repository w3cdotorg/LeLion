extends CharacterBody2D
## Le lion : déplacement, gerbe de vomi multicolore, traceuse de peinture.
## La gerbe part de la bouche à 45° vers le bas ; la traceuse est placée au point de
## chute calculé avec la même physique que les particules.

const ANGLE_GERBE_DEG := 45.0
const ECART_EVENTAIL_DEG := 24.0
const VITESSE_GERBE := 320.0
const GRAVITE_GERBE := 300.0
const DUREE_GERBE := 0.6
const PARTICULES_PAR_COULEUR := 400
const RAYON_TRACEUSE := Vector2i(16, 46)  # min, max
const FACTEUR_BONUS := 2.0
const TEXTURE_PARTICULE := preload("res://Assets/Sprites/circle_white.png")
const BOUCHE_X_DROITE := 89.0
const BOUCHE_X_GAUCHE := 47.0

@export var speed: float = 350.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var vomi_container: Node2D = $VomiParticlesContainer
@onready var gerbe_traceuse: Area2D = $GerbeTraceuse
@onready var traceuse_shape: CollisionShape2D = $GerbeTraceuse/CollisionShape2D
@onready var bouche: Marker2D = $Bouche

var est_en_train_de_vomir := false
var direction_du_lion: int = 1  # 1 = droite, -1 = gauche


func _ready() -> void:
	GameState.couleur_debloquee.connect(_on_couleur_debloquee)
	GameState.bonus_change.connect(_on_bonus_change)
	_appliquer_direction()
	mettre_a_jour_degrade_vomi()


func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("deplacer_gauche", "deplacer_droite", "deplacer_haut", "deplacer_bas")

	if input_vector.x != 0:
		var nouvelle_direction := 1 if input_vector.x > 0 else -1
		if nouvelle_direction != direction_du_lion:
			direction_du_lion = nouvelle_direction
			_appliquer_direction()

	velocity = input_vector * speed
	move_and_slide()

	var screen_rect := get_viewport_rect()
	var sprite_size := sprite.texture.get_size()
	global_position.x = clamp(global_position.x, 0, screen_rect.size.x - sprite_size.x)
	global_position.y = clamp(global_position.y, 0, screen_rect.size.y - sprite_size.y)


func _process(_delta: float) -> void:
	if Input.is_action_pressed("vomir"):
		if not est_en_train_de_vomir:
			demarrer_vomi()
	elif est_en_train_de_vomir:
		arreter_vomi()


func _on_couleur_debloquee(_couleur: Color) -> void:
	mettre_a_jour_degrade_vomi()


func _on_bonus_change(_actif: bool) -> void:
	_placer_traceuse()
	_appliquer_taille_particules()


func _facteur_bonus() -> float:
	return FACTEUR_BONUS if GameState.bonus_actif() else 1.0


func _appliquer_taille_particules() -> void:
	for emitter in vomi_container.get_children():
		var mat := emitter.process_material as ParticleProcessMaterial
		if mat != null:
			mat.scale_min = 0.6 * _facteur_bonus()
			mat.scale_max = 1.4 * _facteur_bonus()


## Retourne le sprite, déplace la bouche et réoriente gerbe et traceuse.
func _appliquer_direction() -> void:
	sprite.scale.x = direction_du_lion
	bouche.position.x = BOUCHE_X_DROITE if direction_du_lion > 0 else BOUCHE_X_GAUCHE
	vomi_container.position = bouche.position
	_orienter_emetteurs()
	_placer_traceuse()


func _angle_gerbe(index: int, count: int) -> float:
	var base := ANGLE_GERBE_DEG if direction_du_lion > 0 else 180.0 - ANGLE_GERBE_DEG
	var offset: float = lerp(-ECART_EVENTAIL_DEG / 2, ECART_EVENTAIL_DEG / 2, float(index) / max(count - 1, 1))
	return deg_to_rad(base + offset * direction_du_lion)


## Point de chute d'une particule tirée à 45° (même physique que le ParticleProcessMaterial).
func _point_de_chute() -> Vector2:
	var v := Vector2.from_angle(deg_to_rad(ANGLE_GERBE_DEG)) * VITESSE_GERBE
	var chute := Vector2(v.x * DUREE_GERBE, v.y * DUREE_GERBE + 0.5 * GRAVITE_GERBE * DUREE_GERBE * DUREE_GERBE)
	chute.x *= direction_du_lion
	return bouche.position + chute


func _placer_traceuse() -> void:
	gerbe_traceuse.position = _point_de_chute()
	if traceuse_shape.shape is CircleShape2D:
		var n := GameState.couleurs_debloquees.size()
		var rayon: float = clamp(RAYON_TRACEUSE.x + n * 5, RAYON_TRACEUSE.x, RAYON_TRACEUSE.y)
		traceuse_shape.shape.radius = rayon * _facteur_bonus()


func _orienter_emetteurs() -> void:
	var emitters := vomi_container.get_children()
	for index in range(emitters.size()):
		var mat := emitters[index].process_material as ParticleProcessMaterial
		if mat != null:
			var angle := _angle_gerbe(index, emitters.size())
			mat.direction = Vector3(cos(angle), sin(angle), 0)


## Reconstruit un émetteur par couleur débloquée.
func mettre_a_jour_degrade_vomi() -> void:
	for child in vomi_container.get_children():
		vomi_container.remove_child(child)
		child.queue_free()

	for couleur in GameState.couleurs_debloquees:
		var gradient := Gradient.new()
		gradient.set_color(0, couleur)
		gradient.set_color(1, Color(couleur, 0.0))
		gradient.add_point(0.75, couleur)
		var gradient_texture := GradientTexture1D.new()
		gradient_texture.gradient = gradient

		var material := ParticleProcessMaterial.new()
		material.color_ramp = gradient_texture
		material.spread = 6.0
		material.initial_velocity_min = VITESSE_GERBE * 0.9
		material.initial_velocity_max = VITESSE_GERBE * 1.1
		material.gravity = Vector3(0, GRAVITE_GERBE, 0)
		material.scale_min = 0.6 * _facteur_bonus()
		material.scale_max = 1.4 * _facteur_bonus()

		var emitter := GPUParticles2D.new()
		emitter.texture = TEXTURE_PARTICULE
		emitter.process_material = material
		emitter.amount = PARTICULES_PAR_COULEUR
		emitter.lifetime = DUREE_GERBE
		emitter.emitting = est_en_train_de_vomir
		vomi_container.add_child(emitter)

	_orienter_emetteurs()
	_placer_traceuse()


func demarrer_vomi() -> void:
	if GameState.couleurs_debloquees.is_empty():
		return
	est_en_train_de_vomir = true
	gerbe_traceuse.monitoring = true
	anim.play("Vomit")
	Audio.demarrer_vomi()
	for emitter in vomi_container.get_children():
		emitter.emitting = true


func arreter_vomi() -> void:
	est_en_train_de_vomir = false
	gerbe_traceuse.monitoring = false
	anim.play("Idle")
	Audio.arreter_vomi()
	for emitter in vomi_container.get_children():
		emitter.emitting = false
