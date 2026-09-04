extends CharacterBody2D
## Le lion : déplacement, gerbe de vomi multicolore, traceuse de peinture.

const SPREAD_ANGLE_DEG := 30.0
const PARTICULES_PAR_COULEUR := 1500

@export var speed: float = 200.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var vomi_container: Node2D = $VomiParticlesContainer
@onready var vomi_timer: Timer = $VomiTimer
@onready var gerbe_traceuse: Area2D = $GerbeTraceuse
@onready var traceuse_shape: CollisionShape2D = $GerbeTraceuse/CollisionShape2D
@onready var bouche: Marker2D = $Bouche

var est_en_train_de_vomir := false
var direction_du_lion: int = 1  # 1 = droite, -1 = gauche


func _ready() -> void:
	GameState.couleur_debloquee.connect(_on_couleur_debloquee)
	mettre_a_jour_degrade_vomi()


func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("deplacer_gauche", "deplacer_droite", "deplacer_haut", "deplacer_bas")

	if input_vector.x != 0:
		var nouvelle_direction := 1 if input_vector.x > 0 else -1
		if nouvelle_direction != direction_du_lion:
			direction_du_lion = nouvelle_direction
			sprite.scale.x = direction_du_lion
			bouche.position.x = 150 if direction_du_lion > 0 else -30
			mettre_a_jour_traceuse()

	velocity = input_vector * speed
	move_and_slide()

	var screen_rect := get_viewport_rect()
	var sprite_size := sprite.texture.get_size()
	global_position.x = clamp(global_position.x, 0, screen_rect.size.x - sprite_size.x)
	global_position.y = clamp(global_position.y, 0, screen_rect.size.y - sprite_size.y)


func _process(_delta: float) -> void:
	if est_en_train_de_vomir:
		mettre_a_jour_traceuse()

	if Input.is_action_pressed("vomir"):
		if not est_en_train_de_vomir:
			demarrer_vomi()
	elif est_en_train_de_vomir:
		arreter_vomi()


func _on_couleur_debloquee(_couleur: Color) -> void:
	mettre_a_jour_degrade_vomi()


func mettre_a_jour_degrade_vomi() -> void:
	for child in vomi_container.get_children():
		vomi_container.remove_child(child)
		child.queue_free()

	var couleurs := GameState.couleurs_debloquees
	var n := couleurs.size()
	var base_angle := deg_to_rad(0) if direction_du_lion > 0 else deg_to_rad(180)

	for i in range(n):
		var gradient := Gradient.new()
		gradient.add_point(0.0, couleurs[i])
		gradient.add_point(1.0, couleurs[i])
		var gradient_texture := GradientTexture1D.new()
		gradient_texture.gradient = gradient
		gradient_texture.width = 256

		var final_angle := base_angle + deg_to_rad(_angle_offset(i, n))
		var material := ParticleProcessMaterial.new()
		material.color_ramp = gradient_texture
		material.direction = Vector3(cos(final_angle), sin(final_angle), 0).normalized()
		material.spread = 10.0
		material.initial_velocity_min = 200
		material.initial_velocity_max = 300

		var emitter := GPUParticles2D.new()
		emitter.process_material = material
		emitter.amount = PARTICULES_PAR_COULEUR
		emitter.lifetime = 1
		emitter.one_shot = true
		emitter.emitting = false
		vomi_container.add_child(emitter)

	if est_en_train_de_vomir:
		for emitter in vomi_container.get_children():
			emitter.emitting = true


func _angle_offset(index: int, count: int) -> float:
	return lerp(-SPREAD_ANGLE_DEG / 2, SPREAD_ANGLE_DEG / 2, float(index) / max(count - 1, 1))


func mettre_a_jour_traceuse() -> void:
	var n := GameState.couleurs_debloquees.size()
	if n == 0:
		return

	var base_angle := deg_to_rad(45) if direction_du_lion > 0 else deg_to_rad(135)
	var direction_2d := Vector2(cos(base_angle), sin(base_angle))
	var correction_x := 20.0 if direction_du_lion > 0 else -20.0
	var origine := bouche.global_position + Vector2(correction_x, 0)

	gerbe_traceuse.global_position = origine + direction_2d * 100.0
	gerbe_traceuse.rotation = direction_2d.angle()
	if traceuse_shape.shape is CircleShape2D:
		traceuse_shape.shape.radius = clamp(10 + n * 5, 10, 50)

	var emitters := vomi_container.get_children()
	var count := emitters.size()
	for index in range(count):
		var mat := emitters[index].process_material as ParticleProcessMaterial
		if mat == null:
			continue
		var visual_index := (count - 1 - index) if direction_du_lion < 0 else index
		var final_angle := base_angle + deg_to_rad(_angle_offset(visual_index, count))
		mat.direction = Vector3(cos(final_angle), sin(final_angle), 0).normalized()


func demarrer_vomi() -> void:
	if GameState.couleurs_debloquees.is_empty():
		return

	est_en_train_de_vomir = true
	gerbe_traceuse.monitoring = true
	if anim.current_animation != "Vomit":
		anim.play("Vomit")

	for emitter in vomi_container.get_children():
		emitter.restart()
	mettre_a_jour_traceuse()
	vomi_timer.start()


func arreter_vomi() -> void:
	est_en_train_de_vomir = false
	anim.play("Idle")
	gerbe_traceuse.monitoring = false
	for emitter in vomi_container.get_children():
		emitter.emitting = false


func _on_vomi_timer_timeout() -> void:
	if Input.is_action_pressed("vomir"):
		demarrer_vomi()
	else:
		arreter_vomi()
