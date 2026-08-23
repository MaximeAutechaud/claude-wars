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
	Terrain.ROAD:     preload("res://assets/tiles/road.svg"),
	Terrain.RIVER:    preload("res://assets/tiles/river.svg"),
}

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
			set_cell(Vector2i(col, row), t, Vector2i.ZERO)

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
