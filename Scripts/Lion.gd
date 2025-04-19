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
#@onready var pickup_timer2 = $PickupTimer2
@export var color_pickup_scene: PackedScene  # à assigner dans l’inspecteur avec ColorPickup.tscn
#var prochaine_couleur_index = 1

#func mettre_a_jour_degrade_vomi():
	#print("🎨 Mise à jour du vomi")
#
	#if vomi_particles == null or couleurs_debloquees.is_empty():
		#print("⚠️ vomi_particles est null ou aucune couleur débloquée.")
		#return
#
	#var particule_mat := vomi_particles.process_material as ParticleProcessMaterial
	#if particule_mat == null:
		#print("⚠️ Aucun ProcessMaterial.")
		#return
#
	#var gradient_texture := particule_mat.color_ramp as GradientTexture1D
	#if gradient_texture == null:
		#print("⚠️ Pas de GradientTexture2D dans color_ramp.")
		#return
#
	## 🧽 Crée un nouveau gradient (remplace l'ancien proprement)
	#var new_gradient := Gradient.new()
#
	#if couleurs_debloquees.size() == 1:
		#new_gradient.add_point(0.0, couleurs_debloquees[0])
		#new_gradient.add_point(1.0, couleurs_debloquees[0])
	#else:
		#var n := couleurs_debloquees.size()
		#for i in range(n):
			#var offset: float = float(i) / max(n - 1, 1)
			#new_gradient.add_point(offset, couleurs_debloquees[i])
#
	#gradient_texture.gradient = new_gradient  # 🟢 remplacement propre
	#gradient_texture.width = 256  # pour que Godot le régénère
	#print("🧾 Gradient final :")
	#for i in range(new_gradient.get_point_count()):
		#print(" -", i, ":", new_gradient.get_color(i))
		#print("💬 Material actuel :", vomi_particles.process_material)
	#vomi_particles.emitting = false
	#await get_tree().process_frame
#	vomi_particles.emitting = true

#func mettre_a_jour_degrade_vomi():
	#print("🎨 Mise à jour du vomi")
#
	#if vomi_particles == null or couleurs_debloquees.is_empty():
		#print("⚠️ vomi_particles est null ou aucune couleur débloquée.")
		#return
#
	#var particule_mat := vomi_particles.process_material as ParticleProcessMaterial
	#if particule_mat == null:
		#print("⚠️ Aucun ProcessMaterial.")
		#return
#
	## Nouveau gradient
	#var gradient := Gradient.new()
#
	#if couleurs_debloquees.size() == 1:
		#gradient.add_point(0.0, couleurs_debloquees[0])
		#gradient.add_point(1.0, couleurs_debloquees[0])
	#else:
		#var n := couleurs_debloquees.size()
		#for i in range(n):
			#var offset: float = float(i) / max(n - 1, 1)
			#gradient.add_point(offset, couleurs_debloquees[i])
#
	## Nouveau GradientTexture1D
	#var texture := GradientTexture1D.new()
	#texture.gradient = gradient
	#texture.width = 256
#
	## Remplacer complètement la color_ramp
	#particule_mat.color_ramp = texture
#
	#print("🧾 Nouveau gradient :")
	#for i in range(gradient.get_point_count()):
		#print(" -", i, ":", gradient.get_color(i))
#
	## Redémarrer les particules
	#vomi_particles.emitting = false
	#await get_tree().process_frame
#	vomi_particles.emitting = true

#func mettre_a_jour_degrade_vomi():
	#print("🎨 Mise à jour complète du vomi")
#
	#var gradient := Gradient.new()
#
	#var n := couleurs_debloquees.size()
	#for i in range(n):
		#var offset: float = float(i) / max(n - 1, 1)
		#gradient.add_point(offset, couleurs_debloquees[i])
#
	#var gradient_texture := GradientTexture1D.new()
	#gradient_texture.gradient = gradient
	#gradient_texture.width = 256
#
	#var new_material := ParticleProcessMaterial.new()
	#new_material.color_ramp = gradient_texture
#
	## BONUS : jouer sur la direction pour créer un "effet arc-en-ciel vivant"
	#new_material.direction = Vector3(0, 3, 0)
	#new_material.spread = 20.0  # léger cône
	#new_material.initial_velocity_min = 200
	#new_material.initial_velocity_max = 300
#
	## Option : tu peux aussi assigner une Curve pour la vélocité directionnelle
	## ou faire varier l'angle à chaque couleur
#
	#vomi_particles.process_material = new_material
#
	## Restart
	#vomi_particles.emitting = false
	#await get_tree().process_frame
##	vomi_particles.emitting = true

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
#		var angle_min = 15.0
#		var angle_max = 70.0
#		var chaos = randf_range(-5.0, 5.0)
#		var angle_deg: float = lerp(angle_min, angle_max, float(i) / max(n - 1, 1)) + chaos
		#var angle_deg: float = lerp(angle_min, angle_max, float(i) / max(n - 1, 1))
		#var angle_rad := deg_to_rad(angle_deg)
		#var direction_vector := Vector3(sin(angle_rad), cos(angle_rad), 0)
#		var angle_deg: float = lerp(15.0, 30.0, float(i) / max(n - 1, 1))
#		var angle_rad := deg_to_rad(angle_deg)
#		var direction_vector := Vector3(sin(angle_rad), cos(angle_rad), 0)
		#var angle_min = 15.0
		#var angle_max = 70.0
		#var courbure = 0.3  # < 1.0 → resserre le début
		#var t := pow(float(i) / max(n - 1, 1), courbure)
		#var angle_deg: float = lerp(angle_min, angle_max, t)
		#var angle_rad := deg_to_rad(angle_deg)
		#var direction_vector := Vector3(sin(angle_rad), cos(angle_rad), 0)
		var angle_min = 15.0
		var angle_max = 70.0
		var angle_deg: float

		if n == 2:
			# Cas spécial : deux couleurs → très proches
			angle_deg = lerp(25.0, 30.0, float(i))
		else:
			var t: float
			if i == 0:
				t = 0.0
			elif i == 1:
				t = 0.05  # très proche de la première
			else:
				var courbure = 0.5
				t = lerp(0.1, 1.0, pow(float(i - 2) / max(n - 3, 1), courbure))
			
			angle_deg = lerp(angle_min, angle_max, t)
		var angle_rad := deg_to_rad(angle_deg)
		var direction_vector := Vector3(sin(angle_rad), cos(angle_rad), 0)
		# Créer le matériau
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

func _ready():
	couleurs_debloquees.clear()
	couleurs_debloquees.append(couleurs_arc_en_ciel[0])  # rouge
	pickup_timer1.start()  # il démarrera à 0 et décomptera 20s
	mettre_a_jour_degrade_vomi()
	

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
	else:
		if est_en_train_de_vomir:
			anim.play("Idle")
			for emitter in vomi_container.get_children():
				emitter.emitting = false
			est_en_train_de_vomir = false

func demarrer_vomi():
	est_en_train_de_vomir = true

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
	creer_pickup(1, Vector2(400, 300))  # orange

#func _on_pickup_timer_2_timeout() -> void:
	#prochaine_couleur_index = 2  # jaune
	#creer_pickup(prochaine_couleur_index, Vector2(500, 300))
	
func lancer_pickup_suivant(couleur_precedente: int):
	var prochain_index = couleur_precedente + 1
	if prochain_index < couleurs_arc_en_ciel.size():
		print("🕒 Préparation du pickup suivant :", prochain_index)
		await get_tree().create_timer(10).timeout
		var pos_x = 300 + 100 * prochain_index
		creer_pickup(prochain_index, Vector2(pos_x, 300))
	else:
		print("🎉 Toutes les couleurs ont été débloquées !")
