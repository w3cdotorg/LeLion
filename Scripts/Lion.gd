extends CharacterBody2D

const SPREAD_ANGLE_DEG := 30.0

@export var speed: float = 200.0
@export var couleurs_arc_en_ciel: Array[Color] = [
	Color.RED, Color.ORANGE, Color.YELLOW, Color.GREEN,
	Color.CYAN, Color.BLUE, Color.VIOLET,
]
@export var color_pickup_scene: PackedScene
@export var soucoupe_scene: PackedScene
@export var coccinelle_scene: PackedScene
@export var ville_scene: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var vomi_container: Node2D = $VomiParticlesContainer
@onready var vomi_timer: Timer = $VomiTimer
@onready var pickup_timer1: Timer = $PickupTimer1
@onready var gerbe_traceuse: Area2D = $GerbeTraceuse2
@onready var traceuse_shape: CollisionShape2D = $GerbeTraceuse2/CollisionShape2D
@onready var bouche: Marker2D = $Bouche

var couleurs_debloquees: Array[Color] = []
var est_en_train_de_vomir := false
var direction_du_lion: int = 1  # 1 = droite, -1 = gauche


func _ready() -> void:
	sprite.z_index = 1
	add_to_group("lion")

	var ville := ville_scene.instantiate()
	get_tree().current_scene.call_deferred("add_child", ville)
	var screen_size := get_viewport().get_visible_rect().size
	var texture_size: Vector2 = ville.get_node("Sprite2D").texture.get_size()
	ville.global_position = Vector2(screen_size.x / 2, screen_size.y - texture_size.y / 2)

	gerbe_traceuse.monitoring = false
	couleurs_debloquees.clear()
	mettre_a_jour_degrade_vomi()
	pickup_timer1.start()
	await get_tree().create_timer(2.0).timeout
	apparaitre_soucoupe()
	await get_tree().create_timer(5.0).timeout
	apparaitre_coccinelle()


func _physics_process(_delta: float) -> void:
	var input_vector := Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1

	if input_vector.x != 0:
		var nouvelle_direction := 1 if input_vector.x > 0 else -1
		if nouvelle_direction != direction_du_lion:
			direction_du_lion = nouvelle_direction
			await get_tree().process_frame
			mettre_a_jour_traceuse()

	velocity = input_vector.normalized() * speed
	move_and_slide()

	var screen_rect := get_viewport_rect()
	var sprite_size := sprite.texture.get_size()
	global_position.x = clamp(global_position.x, 0, screen_rect.size.x - sprite_size.x)
	global_position.y = clamp(global_position.y, 0, screen_rect.size.y - sprite_size.y)

	if input_vector.x != 0:
		sprite.scale.x = 1 if input_vector.x > 0 else -1
		bouche.position.x = 150 if direction_du_lion > 0 else -30


func _process(_delta: float) -> void:
	if est_en_train_de_vomir:
		mettre_a_jour_traceuse()

	if Input.is_action_pressed("ui_accept"):
		if not est_en_train_de_vomir:
			demarrer_vomi()
	elif est_en_train_de_vomir:
		arreter_vomi()


func mettre_a_jour_degrade_vomi() -> void:
	direction_du_lion = 1 if sprite.scale.x > 0 else -1

	for child in vomi_container.get_children():
		child.queue_free()
	await get_tree().process_frame

	var n := couleurs_debloquees.size()
	var base_angle := deg_to_rad(0) if direction_du_lion > 0 else deg_to_rad(180)

	for i in range(n):
		var couleur := couleurs_debloquees[i]

		var gradient := Gradient.new()
		gradient.add_point(0.0, couleur)
		gradient.add_point(1.0, couleur)
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
		emitter.amount = 7500
		emitter.lifetime = 1
		emitter.one_shot = true
		emitter.emitting = false
		vomi_container.add_child(emitter)


func _angle_offset(index: int, count: int) -> float:
	return lerp(-SPREAD_ANGLE_DEG / 2, SPREAD_ANGLE_DEG / 2, float(index) / max(count - 1, 1))


func mettre_a_jour_traceuse() -> void:
	if couleurs_debloquees.is_empty() or vomi_container.get_child_count() == 0:
		return

	var base_angle := deg_to_rad(45) if direction_du_lion > 0 else deg_to_rad(135)
	var direction_2d := Vector2(cos(base_angle), sin(base_angle)).normalized()
	var correction_x := 20.0 if direction_du_lion > 0 else -20.0
	var origine := bouche.global_position + Vector2(correction_x, 0)

	gerbe_traceuse.global_position = origine + direction_2d * 100.0
	gerbe_traceuse.rotation = direction_2d.angle()

	if traceuse_shape.shape is CircleShape2D:
		traceuse_shape.shape.radius = clamp(10 + couleurs_debloquees.size() * 5, 10, 50)

	var emitters := vomi_container.get_children()
	var n := emitters.size()
	for index in range(n):
		var emitter := emitters[index]
		if not emitter is GPUParticles2D:
			continue
		var mat := emitter.process_material as ParticleProcessMaterial
		if mat == null:
			continue
		var visual_index := (n - 1 - index) if direction_du_lion < 0 else index
		var final_angle := base_angle + deg_to_rad(_angle_offset(visual_index, n))
		mat.direction = Vector3(cos(final_angle), sin(final_angle), 0).normalized()


func demarrer_vomi() -> void:
	if couleurs_debloquees.is_empty():
		return

	est_en_train_de_vomir = true
	gerbe_traceuse.monitoring = true
	if not anim.is_playing() or anim.current_animation != "Vomit":
		anim.play("Vomit")

	for emitter in vomi_container.get_children():
		emitter.emitting = false
	await get_tree().process_frame
	for emitter in vomi_container.get_children():
		emitter.emitting = true

	mettre_a_jour_traceuse()
	vomi_timer.start()


func arreter_vomi() -> void:
	est_en_train_de_vomir = false
	anim.play("Idle")
	gerbe_traceuse.monitoring = false
	for emitter in vomi_container.get_children():
		emitter.emitting = false


func _on_vomi_timer_timeout() -> void:
	if Input.is_action_pressed("ui_accept"):
		demarrer_vomi()
	else:
		est_en_train_de_vomir = false


func debloquer_couleur(index: int) -> void:
	if index < 0 or index >= couleurs_arc_en_ciel.size():
		return
	var couleur := couleurs_arc_en_ciel[index]
	if not couleurs_debloquees.has(couleur):
		couleurs_debloquees.append(couleur)
		mettre_a_jour_degrade_vomi()


func creer_pickup(couleur_index: int, position_pickup: Vector2) -> void:
	var pickup := color_pickup_scene.instantiate()
	pickup.name = "ColorPickup"
	pickup.couleur_index = couleur_index
	pickup.global_position = position_pickup
	get_tree().current_scene.add_child(pickup)


func _on_pickup_timer_1_timeout() -> void:
	creer_pickup(0, Vector2(400, 300))


func lancer_pickup_suivant(couleur_precedente: int) -> void:
	var prochain_index := couleur_precedente + 1
	if prochain_index >= couleurs_arc_en_ciel.size():
		return
	await get_tree().create_timer(10).timeout
	creer_pickup(prochain_index, Vector2(300 + 100 * prochain_index, 300))


func apparaitre_soucoupe() -> void:
	var soucoupe := soucoupe_scene.instantiate()
	soucoupe.position = Vector2(-200, 200)
	get_tree().current_scene.add_child(soucoupe)


func apparaitre_coccinelle() -> void:
	var c := coccinelle_scene.instantiate()
	c.position = Vector2(get_viewport().get_visible_rect().size.x + 100, randf_range(150.0, 400.0))
	get_tree().current_scene.add_child(c)
