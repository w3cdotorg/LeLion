extends CharacterBody2D
@export var speed: float = 200.0
@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer
#@onready var vomi_particles = $VomiParticles
@onready var vomi_container = $VomiParticlesContainer

@onready var vomi_timer = $VomiTimer
@export var couleurs_arc_en_ciel: Array[Color] = [
	Color.RED,
	Color.ORANGE,
	Color.YELLOW,
	Color.GREEN,
	Color.CYAN,
	Color.BLUE,
	Color.VIOLET
]
var couleurs_debloquees: Array[Color] = []
var est_en_train_de_vomir := false

@onready var pickup_timer1 = $PickupTimer1
@export var color_pickup_scene: PackedScene  # à assigner dans l’inspecteur avec ColorPickup.tscn
@export var soucoupe_scene: PackedScene  # à assigner dans l’inspecteur (Soucoupe.tscn)
@export var coccinelle_scene: PackedScene  # à assigner dans l’inspecteur
@export var ville_scene: PackedScene  # à assigner dans l’inspecteur
@onready var gerbe_traceuse = $GerbeTraceuse2
@onready var traceuse_debug = $TraceuseDebug
@onready var bouche = $Bouche
@onready var traceuse_shape = $GerbeTraceuse2/CollisionShape2D

func mettre_a_jour_degrade_vomi():
	print("🎨 Mise à jour de la gerbe multicolore")

	# Supprimer les anciens émetteurs
	for child in vomi_container.get_children():
		child.queue_free()

	await get_tree().process_frame  # attendre qu'ils soient vraiment supprimés

	var n = couleurs_debloquees.size()
	for i in range(n):
		var couleur = couleurs_debloquees[i]

		# Créer un gradient
		var gradient := Gradient.new()
		gradient.add_point(0.0, couleur)
		gradient.add_point(1.0, couleur)

		var gradient_texture := GradientTexture1D.new()
		gradient_texture.gradient = gradient
		gradient_texture.width = 256

		# Calculer l'angle
		var angle_min = 15.0
		var angle_max = 70.0
		var chaos = randf_range(-5.0, 5.0)
#		var angle_deg: float = lerp(angle_min, angle_max, float(i) / max(n - 1, 1)) + chaos
		var angle_deg: float = lerp(angle_min, angle_max, float(i) / max(n - 1, 1))
		var angle_rad := deg_to_rad(angle_deg)
		var direction_vector := Vector3(sin(angle_rad), cos(angle_rad), 0)
		var material := ParticleProcessMaterial.new()
		material.color_ramp = gradient_texture
		material.direction = direction_vector
		material.spread = 10.0
		material.initial_velocity_min = 200
		material.initial_velocity_max = 300

		# Créer le GPUParticles2D
		var emitter = GPUParticles2D.new()
		emitter.process_material = material
		emitter.amount = 7500
		emitter.lifetime = 1
		emitter.one_shot = true
		emitter.emitting = false
		emitter.position = Vector2.ZERO  # centré sur le lion

		vomi_container.add_child(emitter)
		print("🎯 Couleurs débloquées :", couleurs_debloquees)
		print("🛠 Nombre de gerbes créées :", couleurs_debloquees.size())

func debloquer_couleur(index: int):
	print("🔶 debloquer_couleur appelée avec index :", index)
	if index >= 0 and index < couleurs_arc_en_ciel.size():
		var couleur = couleurs_arc_en_ciel[index]
		print("💡 Couleur candidate :", couleur)
		if not couleurs_debloquees.has(couleur):
			couleurs_debloquees.append(couleur)
			print("🌈 Couleur ajoutée :", couleur)
			mettre_a_jour_degrade_vomi()
		else:
			print("⚠️ Couleur déjà débloquée :", couleur)
		var ville = get_tree().current_scene.get_node("Ville")  # ou le bon chemin
		if ville and ville.has_method("appliquer_couleur"):
			ville.appliquer_couleur(couleur)

func _ready():
	add_to_group("lion")
	print("🦁 _ready du LION exécuté")

	var ville = ville_scene.instantiate()
	print("🏙️ Ville instanciée :", ville)

	get_tree().current_scene.call_deferred("add_child", ville)

	var screen_size = get_viewport().get_visible_rect().size
	var texture_size = ville.get_node("Sprite2D").texture.get_size()

	ville.global_position = Vector2(
		screen_size.x / 2,
		screen_size.y - texture_size.y / 2
	)
	print("📍 Ville positionnée :", ville.global_position)
	
	gerbe_traceuse.monitoring = true
	gerbe_traceuse.set_deferred("monitoring", true)  # pour être sûr
	if traceuse_debug == null:
		print("⚠️ TraceuseDebug n’est pas trouvée dans la scène !")
	couleurs_debloquees.clear()
#	couleurs_debloquees.append(couleurs_arc_en_ciel[0])  # rouge
	pickup_timer1.start()  # il démarrera à 0 et décomptera 20s
	mettre_a_jour_degrade_vomi()
	await get_tree().create_timer(2.0).timeout
	apparaitre_soucoupe()
	await get_tree().create_timer(5.0).timeout
	apparaitre_coccinelle()
	# La placer en bas de l’écran :

func _physics_process(_delta):
	var input_vector = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1

	input_vector = input_vector.normalized() * speed
	self.velocity = input_vector
	move_and_slide()

func _process(_delta):
	if Input.is_action_pressed("ui_accept"):
		if not est_en_train_de_vomir:
			demarrer_vomi()
		mettre_a_jour_traceuse()
		# 💦 Peindre pendant le vomi
		#var ville = get_tree().current_scene.get_node_or_null("Ville")
		#if ville:
			#var ville_sprite = ville.get_node("Sprite2D")
			#var trace_pos = gerbe_traceuse.global_position
			#var local_pos = ville_sprite.to_local(trace_pos)
#
			#if local_pos.y > 0 and local_pos.y < ville_sprite.texture.get_height():
				#var couleur = couleurs_debloquees[randi() % couleurs_debloquees.size()]
				#ville.peindre(local_pos, couleur)
	else:
		if est_en_train_de_vomir:
#			mettre_a_jour_traceuse()
			# 🛑 Stop du vomi
			est_en_train_de_vomir = false
			anim.play("Idle")
			gerbe_traceuse.monitoring = false
			for emitter in vomi_container.get_children():
				emitter.emitting = false


func demarrer_vomi():
	if couleurs_debloquees.is_empty():
		print("🛑 Pas de couleur disponible, vomi bloqué !")
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

	vomi_timer.start()

func _on_VomiTimer_timeout():
	if Input.is_action_pressed("ui_accept"):
		demarrer_vomi()
	else:
		est_en_train_de_vomir = false

func _on_vomi_timer_timeout() -> void:
	if Input.is_action_pressed("ui_accept"):
		demarrer_vomi()
	else:
		est_en_train_de_vomir = false

func creer_pickup(couleur_index: int, position: Vector2):
	var pickup = color_pickup_scene.instantiate()
	pickup.name = "ColorPickup"
	pickup.couleur_index = couleur_index
	pickup.global_position = position
	get_tree().current_scene.add_child(pickup)

func _on_pickup_timer_1_timeout() -> void:
	creer_pickup(0, Vector2(400, 300))  # rouge
	
func lancer_pickup_suivant(couleur_precedente: int):
	var prochain_index = couleur_precedente + 1
	if prochain_index < couleurs_arc_en_ciel.size():
		print("🕒 Préparation du pickup suivant :", prochain_index)
		await get_tree().create_timer(10).timeout
		var pos_x = 300 + 100 * prochain_index
		creer_pickup(prochain_index, Vector2(pos_x, 300))
	else:
		print("🎉 Toutes les couleurs ont été débloquées !")
		
func apparaitre_soucoupe():
	var soucoupe = soucoupe_scene.instantiate()
	soucoupe.position = Vector2(-200, 200)  # position d’entrée à gauche
	get_tree().current_scene.add_child(soucoupe)

func apparaitre_coccinelle():
	var c = coccinelle_scene.instantiate()
	c.position = Vector2(get_viewport().get_visible_rect().size.x + 100, randf_range(150.0, 400.0))
	get_tree().current_scene.add_child(c)

func mettre_a_jour_traceuse():
	if couleurs_debloquees.size() == 0 or vomi_container.get_child_count() == 0:
		return

	var dernier_emetteur = vomi_container.get_child(vomi_container.get_child_count() - 1)

	# Direction du vomi (convertie de 3D en 2D)
	var direction_3d: Vector3 = dernier_emetteur.process_material.direction
	var direction_2d := Vector2(direction_3d.x, direction_3d.y).normalized()

	# Point de départ : la bouche !
	var origine = bouche.global_position

	# Distance devant la bouche
	var distance = 100.0
	var offset = direction_2d * distance

	# Position de la traceuse
	var pos_traceuse = origine + offset
	gerbe_traceuse.global_position = pos_traceuse
	traceuse_debug.global_position = pos_traceuse

	gerbe_traceuse.rotation = direction_2d.angle()
	gerbe_traceuse.modulate = Color(1, 0, 0, 0.5)
	print("🎯 Traceuse pos :", gerbe_traceuse.global_position)
	if traceuse_shape and traceuse_shape.shape is CircleShape2D:
		var nb = couleurs_debloquees.size()
		var radius = clamp(10 + nb * 5, 10, 50)  # Par exemple : entre 10 et 50 px
		traceuse_shape.shape.radius = radius
