extends Node

# Aperçu du jeu avec le pack pixel art (assets_pixelart/, généré avec PixelLab)
# à la place des assets actuels — sans toucher au code du jeu.
#
# Principe : avant de charger main.tscn, chaque nouvelle texture est enregistrée
# dans le cache de ressources SOUS LE CHEMIN de l'ancienne (take_over_path). Les
# preload() des scripts du jeu (unit.gd, game_map.gd, rivers.gd…) reçoivent donc
# la nouvelle sans le savoir. Conséquence : ce script ne doit référencer AUCUNE
# classe du jeu (Unit, GameMap…) avant l'échange, sinon leur script — et ses
# preload — serait compilé trop tôt avec les anciennes textures.
#
# Jouer en pixel art (carte de test) :
#   Godot --path . res://tests/pixelart_preview.tscn
# Capture, pour comparer les deux styles sur le même cadrage :
#   Godot --path . res://tests/pixelart_preview.tscn -- sortie.png pixel|orig sandbox|campaign fit|<zoom>

const UNIT_NAMES := ["infantry", "tank", "archer", "hero", "boss", "scout", "medic", "mage"]
const TILE_NAMES := ["plains", "forest", "mountain", "village", "river", "sand", "road"]

# Le cache de ressources ne tient que des références faibles : sans ce tableau,
# chaque texture serait libérée en sortant de _take_over et le preload du jeu
# rechargerait silencieusement l'ancienne.
var _keep_alive: Array[Texture2D] = []

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else ""
	var style: String = args[1] if args.size() > 1 else "pixel"
	var map_name: String = args[2] if args.size() > 2 else "sandbox"
	var framing: String = args[3] if args.size() > 3 else "fit"

	if style == "pixel":
		_swap_textures()
		get_viewport().canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST

	var scenario: GDScript = load("res://scripts/scenario.gd")
	if map_name == "sandbox":
		scenario.active = scenario.SANDBOX
	var main: Node2D = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	if style == "pixel":
		main.get_node("UnitsLayer").child_entered_tree.connect(_smooth_unit_sprite)
	add_child(main)
	if out == "":
		return  # mode interactif : on joue normalement

	await get_tree().process_frame
	_reveal(main)
	_frame(main, framing)
	await get_tree().create_timer(1.0).timeout
	get_viewport().get_texture().get_image().save_png(out)
	print("Capture enregistrée : " + out)
	get_tree().quit()

func _swap_textures() -> void:
	# Unités : version HD (double densité, units_hd/) si elle existe, sinon 48 px
	for n: String in UNIT_NAMES:
		for suffix: String in ["", "_2"]:
			var hd := "res://assets_pixelart/units_hd/%s%s.png" % [n, suffix]
			var dst := "res://assets/units/%s%s.svg" % [n, suffix]
			if FileAccess.file_exists(hd):
				_take_over(hd, dst, true)
			else:
				_take_over("res://assets_pixelart/units/%s%s.png" % [n, suffix], dst)
	for n: String in TILE_NAMES:
		_take_over("res://assets_pixelart/tiles/%s.png" % n, "res://assets/tiles/%s.png" % n)
	# Variantes de plaine (même sol, détails différents), aussi sous les routes.
	# Chargé seulement maintenant : compiler game_map.gd plus tôt figerait ses
	# preload sur les anciennes textures.
	var variants: Array[Texture2D] = []
	for i in range(1, 10):
		var path := ProjectSettings.globalize_path("res://assets_pixelart/tiles/plains_v%d.png" % i)
		if not FileAccess.file_exists(path):
			break
		variants.append(ImageTexture.create_from_image(Image.load_from_file(path)))
	_keep_alive.append_array(variants)
	var game_map: GDScript = load("res://scripts/game_map.gd")
	var terrain: Dictionary = game_map.Terrain
	game_map.terrain_variants = {terrain["PLAINS"]: variants, terrain["ROAD"]: variants}

# Chargée depuis le fichier brut (pas via l'import) : pas de cache .godot/imported
# périmé possible quand le pack est régénéré.
# hd : sprite dessiné en double densité, affiché à la moitié de sa taille (même
# encombrement que la version 48 px, deux fois plus de détail ; mipmaps pour le
# filtrage lissé posé sur les sprites d'unités, cf. _smooth_unit_sprites).
func _take_over(src: String, dst: String, hd := false) -> void:
	if not FileAccess.file_exists(src):
		push_warning("Pixel art manquant, ancien asset conservé : " + src)
		return
	var img := Image.load_from_file(ProjectSettings.globalize_path(src))
	if hd:
		img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	if hd:
		tex.set_size_override(img.get_size() / 2)
	tex.take_over_path(dst)
	_keep_alive.append(tex)

# Les sprites HD sont affichés à ~1 pixel source par pixel écran : un filtrage
# lissé (avec mipmaps pour le dézoom) les rend nets, là où le filtre « nearest »
# du reste de la carte ferait des pixels de tailles irrégulières.
func _smooth_unit_sprite(node: Node) -> void:
	var sprite := node.get_node_or_null("Sprite") as CanvasItem
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _reveal(main: Node2D) -> void:
	var map := main.get_node("GameMap")
	var fog := main.get_node("Fog")
	var size: Vector2i = map.get_map_size()
	for col in size.x:
		for row in size.y:
			fog.explored[Vector2i(col, row)] = true
			fog.visible_now[Vector2i(col, row)] = true
	for child in main.get_node("UnitsLayer").get_children():
		if child is Node2D:
			child.visible = true
	for layer in ["Fog", "Villages", "Creeps", "Roads", "Rivers"]:
		main.get_node(layer).queue_redraw()

func _frame(main: Node2D, framing: String) -> void:
	var map := main.get_node("GameMap")
	var camera: Camera2D = main.get_node("Camera2D")
	var size: Vector2i = map.get_map_size()
	var top_left: Vector2 = map.to_global(map.map_to_local(Vector2i.ZERO))
	var bottom_right: Vector2 = map.to_global(map.map_to_local(size - Vector2i.ONE))
	if framing == "fit":
		camera.global_position = (top_left + bottom_right) * 0.5
		var extent := bottom_right - top_left + Vector2(64 * 2, 56 * 2)
		var vp := get_viewport().get_visible_rect().size
		var z := minf(vp.x / extent.x, vp.y / extent.y)
		camera.zoom = Vector2(z, z)
		return
	# "<zoom>" : centre de gravité de toutes les unités ; "<zoom>@<type>" : sur
	# la première unité bleue de ce type (valeur de l'enum Unit.Type)
	var parts := framing.split("@")
	var sum := Vector2.ZERO
	var n := 0
	for child in main.get_node("UnitsLayer").get_children():
		if not child is Node2D or child.get("team") == null:
			continue
		if parts.size() > 1:
			if child.get("team") == 0 and child.get("type") == parts[1].to_int():
				sum = (child as Node2D).global_position
				n = 1
				break
			continue
		sum += (child as Node2D).global_position
		n += 1
	camera.global_position = sum / maxi(n, 1)
	camera.zoom = Vector2.ONE * parts[0].to_float()
