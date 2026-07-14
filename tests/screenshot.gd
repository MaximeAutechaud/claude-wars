extends Node

# Capture d'écran de la scène principale pour vérification visuelle :
#   Godot --path . res://tests/screenshot.tscn -- chemin/sortie.png
# (fenêtre visible ~1 s ; le rendu exige un vrai contexte GL, pas de --headless)

func _ready() -> void:
	var out := "user://screenshot.png"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var main: Node2D = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await get_tree().create_timer(1.0).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(out)
	print("Capture enregistrée : " + out)
	get_tree().quit()
