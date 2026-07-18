extends Node

# Capture de la carte de test (Scenario.SANDBOX) entière :
#   Godot --path . res://tests/screenshot_sandbox.tscn -- chemin/sortie.png
# (fenêtre visible ~1 s ; le rendu exige un vrai contexte GL, pas de --headless)

func _ready() -> void:
	var out := "user://screenshot_sandbox.png"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	Scenario.active = Scenario.SANDBOX
	var main: Node2D = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await get_tree().process_frame

	var map: GameMap = main.get_node("GameMap")
	var camera: Camera2D = main.get_node("Camera2D")

	# Cadre la carte entière (le brouillard est déjà révélé : reveal_all)
	var size := map.get_map_size()
	var top_left := map.to_global(map.map_to_local(Vector2i.ZERO))
	var bottom_right := map.to_global(map.map_to_local(size - Vector2i.ONE))
	camera.global_position = (top_left + bottom_right) * 0.5
	var extent := bottom_right - top_left + Vector2(GameMap.TILE_W * 2, GameMap.TILE_H * 2)
	var vp := get_viewport().get_visible_rect().size
	var z := minf(vp.x / extent.x, vp.y / extent.y)
	camera.zoom = Vector2(z, z)

	await get_tree().create_timer(1.0).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(out)
	print("Capture enregistrée : " + out)
	get_tree().quit()
