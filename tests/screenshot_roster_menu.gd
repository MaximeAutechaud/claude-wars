extends Node

# Capture de la galerie du roster (scenes/roster.tscn) :
#   Godot --path . res://tests/screenshot_roster_menu.tscn -- chemin/sortie.png
# (fenêtre visible ~1 s ; le rendu exige un vrai contexte GL, pas de --headless)

func _ready() -> void:
	var out := "user://screenshot_roster_menu.png"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var roster: Control = (load("res://scenes/roster.tscn") as PackedScene).instantiate()
	add_child(roster)
	await get_tree().create_timer(1.0).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(out)
	print("Capture enregistrée : " + out)
	get_tree().quit()
