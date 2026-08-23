extends Node

# Capture la boîte de dialogue en cours de frappe (vérification visuelle) :
#   Godot --headless --path . res://tests/screenshot_dialogue.tscn -- chemin/sortie.png
# Sans argument : user://dialogue.png

func _ready() -> void:
	var out := "user://dialogue.png"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out = args[0]
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.1, 1)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)
	var box: DialogueBox = (load("res://scenes/dialogue_box.tscn") as PackedScene).instantiate()
	add_child(box)
	box.play([
		{"speaker": "Le Héros", "text": "Voilà donc le fameux Fossoyeur... Je ne pensais pas te trouver si vite."},
	])
	await get_tree().create_timer(1.0).timeout   # laisse le typewriter avancer et le portrait bumper
	get_viewport().get_texture().get_image().save_png(out)
	print("Capture écrite : " + ProjectSettings.globalize_path(out))
	get_tree().quit(0)
