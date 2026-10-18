class_name Decor
extends Node2D

# Couche de décor du tableau (DA.md) : bâtiments, champs, bêtes… posés sur
# des cases sans aucun effet de jeu — la case garde son terrain et ses règles.
# Format de tableau : "decor" (optionnel) = cell -> id de prop, l'image étant
# assets_pixelart/decor/<id>.png (pas de version peinte : ce décor n'existe
# qu'en pixel art). Chaque image est déjà à sa taille d'affichage, rognée au
# plus juste ; elle est posée pied au sol, centrée sur la case.
#
# Forêt en arbres individuels : si `forest_trees` est rempli (par l'aperçu
# pixel art — en style peint, la tuile de forêt porte déjà ses arbres), chaque
# case de forêt reçoit quelques arbres tirés de cette liste, placés avec un
# léger décalage propre à la case et débordant sur les voisines, comme dans
# Wesnoth.
static var forest_trees: Array[String] = []

# Le pied du prop est un peu sous le centre de la case (hauteur bord à bord
# 56 px) : la case reste lisible au-dessus, et le prop « tient » sur l'hex.
const FOOT_Y := 20.0

# Pieds des arbres d'une case de forêt, depuis son centre : deux au fond, un
# devant. Chacun bouge ensuite de ±TREE_JITTER px selon la case.
const TREE_SPOTS := [Vector2(-12, -2), Vector2(12, 0), Vector2(0, 20)]
const TREE_JITTER := 4

@onready var map: GameMap = $"../GameMap"
@onready var fog: Fog = get_node_or_null("../Fog")

var props: Dictionary = {}   # cell -> id
var _tex: Dictionary = {}    # id -> Texture2D
var _items: Array = []       # [cell, pied (local à la case), id], triés de haut en bas

func _ready() -> void:
	props = (Scenario.active.get("decor", {}) as Dictionary)
	for cell: Vector2i in props:
		_items.append([cell, Vector2(0, FOOT_Y), props[cell]])
	if not forest_trees.is_empty():
		for col in map.map_size.x:
			for row in map.map_size.y:
				var cell := Vector2i(col, row)
				if map.get_terrain(cell) == GameMap.Terrain.FOREST:
					_add_trees(cell)
	for item: Array in _items:
		if not _tex.has(item[2]):
			_tex[item[2]] = load("res://assets_pixelart/decor/%s.png" % item[2])
	# De haut en bas : ce qui est plus bas à l'écran passe devant
	_items.sort_custom(func(a: Array, b: Array) -> bool:
		return map.map_to_local(a[0]).y + a[1].y < map.map_to_local(b[0]).y + b[1].y)
	queue_redraw()

func _add_trees(cell: Vector2i) -> void:
	var h := hash(cell)
	for i in TREE_SPOTS.size():
		var spot: Vector2 = TREE_SPOTS[i]
		var jx := (h >> (i * 4)) % (TREE_JITTER * 2 + 1) - TREE_JITTER
		var jy := (h >> (i * 4 + 12)) % (TREE_JITTER * 2 + 1) - TREE_JITTER
		var id: String = forest_trees[(h >> (i * 5 + 3)) % forest_trees.size()]
		_items.append([cell, spot + Vector2(jx, jy), id])

func _draw() -> void:
	for item: Array in _items:
		var cell: Vector2i = item[0]
		# Comme les villages : rien sous le voile noir
		if fog and not fog.is_explored(cell):
			continue
		var tex: Texture2D = _tex[item[2]]
		var foot: Vector2 = to_local(map.to_global(map.map_to_local(cell))) + item[1]
		var size := tex.get_size()
		draw_texture(tex, foot - Vector2(size.x * 0.5, size.y))
