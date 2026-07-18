extends Node

# Capture du roster complet : une rangée par équipe, tous les types côte à
# côte — pour valider les sprites et leur lisibilité sur la carte :
#   Godot --path . res://tests/screenshot_roster.tscn -- chemin/sortie.png
# (fenêtre visible ~1 s ; le rendu exige un vrai contexte GL, pas de --headless)

const ROSTER: Array = [
	Unit.Type.INFANTRY, Unit.Type.TANK, Unit.Type.ARCHER, Unit.Type.SCOUT,
	Unit.Type.MEDIC, Unit.Type.MAGE, Unit.Type.HERO, Unit.Type.BOSS,
]

func _ready() -> void:
	var out := "user://screenshot_roster.png"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var main: Node2D = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await get_tree().process_frame

	var map: GameMap = main.get_node("GameMap")
	var fog: Fog = main.get_node("Fog")
	var units: UnitsLayer = main.get_node("UnitsLayer")
	var camera: Camera2D = main.get_node("Camera2D")

	# Vide le tableau, garde juste les rangées de démonstration
	for child in units.get_children():
		if child is Unit:
			child.free()
	for i in ROSTER.size():
		units.spawn(Vector2i(1 + i, 4), 0, ROSTER[i])
		units.spawn(Vector2i(1 + i, 6), 1, ROSTER[i])

	var size := map.get_map_size()
	for col in size.x:
		for row in size.y:
			fog.explored[Vector2i(col, row)] = true
			fog.visible_now[Vector2i(col, row)] = true
	for child in units.get_children():
		if child is Unit:
			(child as Unit).visible = true
			if (child as Unit).is_boss():
				(child as Unit).scale = Vector2(1.35, 1.35)
	fog.queue_redraw()
	main.get_node("Villages").queue_redraw()
	main.get_node("Creeps").queue_redraw()

	# Cadre les deux rangées
	var top_left := map.to_global(map.map_to_local(Vector2i(0, 3)))
	var bottom_right := map.to_global(map.map_to_local(Vector2i(ROSTER.size() + 1, 7)))
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
