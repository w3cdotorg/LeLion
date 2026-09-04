extends CanvasLayer
## Stick et boutons tactiles, affichés seulement quand un écran tactile est disponible.

@export var forcer_affichage := false  # pour tester sur un ordinateur

@onready var joystick: Control = $Joystick


func _ready() -> void:
	visible = forcer_affichage or DisplayServer.is_touchscreen_available()
	for enfant in get_children():
		if enfant is TouchScreenButton:
			enfant.set_process_input(visible)
	joystick.set_process_input(visible)


static func ecran_tactile() -> bool:
	return DisplayServer.is_touchscreen_available()
