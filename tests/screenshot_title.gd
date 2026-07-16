extends Node

# Capture l'écran d'accueil en PNG (vérification visuelle) :
#   Godot --path . res://tests/screenshot_title.tscn -- chemin/sortie.png
# Sans argument : user://title.png

func _ready() -> void:
	var out := "user://title.png"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		out = args[0]
	var title: Control = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	add_child(title)
	await get_tree().create_timer(0.7).timeout   # laisse finir le fondu d'entrée
	get_viewport().get_texture().get_image().save_png(out)
	print("Capture écrite : " + ProjectSettings.globalize_path(out))
	get_tree().quit(0)
