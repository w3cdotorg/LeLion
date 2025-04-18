extends CharacterBody2D

@export var speed: float = 200.0

@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer

func _physics_process(delta):
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

	# Animation vomi
	if Input.is_action_pressed("ui_accept"):
		if anim.current_animation != "Vomit":
			anim.play("Vomit")
	else:
		if anim.current_animation != "Idle":
			anim.play("Idle")
