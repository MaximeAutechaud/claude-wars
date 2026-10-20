class_name GameMap
extends TileMapLayer

# Hexagone flat-top : largeur pointe à pointe, hauteur bord à bord (≈ W·√3/2)
const TILE_W := 64
const TILE_H := 56

enum Terrain { PLAINS, FOREST, MOUNTAIN, ROAD, RIVER }

# Caractères du format de tableau (Scenario.CURRENT["terrain"])
const TERRAIN_CHARS: Dictionary = {
	"P": Terrain.PLAINS, "F": Terrain.FOREST, "M": Terrain.MOUNTAIN,
	"R": Terrain.ROAD,   "W": Terrain.RIVER,
}

const TERRAIN_DEFENSE: Dictionary = {
	Terrain.PLAINS:   0,
	Terrain.FOREST:   1,
	Terrain.MOUNTAIN: 2,
	Terrain.ROAD:     0,
	Terrain.RIVER:    0,
}

const TERRAIN_TEXTURE: Dictionary = {
	Terrain.PLAINS:   preload("res://assets/tiles/plains.png"),
	Terrain.FOREST:   preload("res://assets/tiles/forest.png"),
	Terrain.MOUNTAIN: preload("res://assets/tiles/mountain.png"),
	# La route n'a pas de texture de base propre : c'est de l'herbe, le
	# chemin est peint par-dessus par Roads (ruban procédural connecté aux
	# voisins — assets/tiles/road.png n'est qu'un échantillon de matière).
	Terrain.ROAD:     preload("res://assets/tiles/plains.png"),
	# Même principe que la route (voir Roads) : pas de texture de base
	# propre, le ruban d'eau de Rivers est peint par-dessus — un peu de
	# berge (l'herbe de la plaine) reste visible aux coins de la case.
	Terrain.RIVER:    preload("res://assets/tiles/plains.png"),
}

# Variantes visuelles optionnelles d'un terrain (Terrain -> Array[Texture2D],
# chacune à TILE_W×TILE_H comme les autres, cf. le piège de _build_tileset) :
# chaque case en tire une au hasard — mais de façon stable, d'après ses
# coordonnées — parmi la texture de base et ses variantes, pour casser la
# répétition d'une même tuile sur une grande étendue. Vide par défaut.
static var terrain_variants: Dictionary = {}
const VARIANT_SOURCE_BASE := 100   # source_id = base + terrain * 10 + index

# grid[col][row] = valeur Terrain — chargée depuis le scénario courant
var grid: Array = []
var map_size := Vector2i.ZERO

func _ready() -> void:
	_build_tileset()
	_init_grid()
	_paint_grid()

func _build_tileset() -> void:
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_HEXAGON
	ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
	ts.tile_size = Vector2i(TILE_W, TILE_H)

	# Une source par terrain : source_id = valeur de l'enum Terrain.
	#
	# Piège vécu : la région source DOIT valoir TILE_W×TILE_H pour toutes les
	# sources. Un TileSet hexagonal avec des sources de texture_region_size
	# hétérogènes (ex. une source fournie en haute résolution pour rester
	# nette au zoom, les autres à la taille native) rend cassé : toutes les
	# sources sauf la première deviennent invisibles (remplacées par
	# l'apparence de la première), qu'elles soient SVG ou PNG — confirmé par
	# élimination sur Godot 4.7.1. Donc : toujours fournir les textures de
	# terrain déjà à la taille finale de la case (voir assets/tiles/*.png,
	# exportées à 64×56 depuis leurs sources haute résolution).
	for t: int in Terrain.values():
		var source := TileSetAtlasSource.new()
		var tex: Texture2D = TERRAIN_TEXTURE[t]
		source.texture = tex
		source.texture_region_size = Vector2i(TILE_W, TILE_H)
		source.create_tile(Vector2i.ZERO)
		ts.add_source(source, t)
		var variants: Array = terrain_variants.get(t, [])
		for i in variants.size():
			var vsource := TileSetAtlasSource.new()
			vsource.texture = variants[i]
			vsource.texture_region_size = Vector2i(TILE_W, TILE_H)
			vsource.create_tile(Vector2i.ZERO)
			ts.add_source(vsource, VARIANT_SOURCE_BASE + t * 10 + i)

	tile_set = ts

func _init_grid() -> void:
	var rows: Array = Scenario.active["terrain"]
	map_size = Vector2i((rows[0] as String).length(), rows.size())
	grid.resize(map_size.x)
	for col in map_size.x:
		grid[col] = []
		grid[col].resize(map_size.y)
		for row in map_size.y:
			grid[col][row] = TERRAIN_CHARS[(rows[row] as String)[col]]

func _paint_grid() -> void:
	clear()
	for col in map_size.x:
		for row in map_size.y:
			var t: int = grid[col][row]
			var cell := Vector2i(col, row)
			var source_id := t
			var n_variants: int = (terrain_variants.get(t, []) as Array).size()
			if n_variants > 0:
				var pick := hash(cell) % (n_variants + 1)
				if pick > 0:
					source_id = VARIANT_SOURCE_BASE + t * 10 + pick - 1
			set_cell(cell, source_id, Vector2i.ZERO)

func get_terrain(cell: Vector2i) -> int:
	if not is_in_bounds(cell):
		return -1
	return grid[cell.x][cell.y]

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < map_size.x and cell.y >= 0 and cell.y < map_size.y

func get_defense_bonus(cell: Vector2i) -> int:
	return TERRAIN_DEFENSE.get(get_terrain(cell), 0)

func get_map_size() -> Vector2i:
	return map_size

# Sommets d'un hexagone flat-top centré sur `center` (hw/hh = demi-taille)
static func hex_corners(center: Vector2, hw: float, hh: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(-hw, 0),
		center + Vector2(-hw * 0.5, -hh),
		center + Vector2(hw * 0.5, -hh),
		center + Vector2(hw, 0),
		center + Vector2(hw * 0.5, hh),
		center + Vector2(-hw * 0.5, hh),
	])
