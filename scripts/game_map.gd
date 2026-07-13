class_name GameMap
extends TileMapLayer

const MAP_W := 12
const MAP_H := 10
# Hexagone flat-top : largeur pointe à pointe, hauteur bord à bord (≈ W·√3/2)
const TILE_W := 64
const TILE_H := 56

enum Terrain { PLAINS, FOREST, MOUNTAIN, ROAD, RIVER }

const TERRAIN_DEFENSE: Dictionary = {
	Terrain.PLAINS:   0,
	Terrain.FOREST:   1,
	Terrain.MOUNTAIN: 2,
	Terrain.ROAD:     0,
	Terrain.RIVER:    0,
}

const TERRAIN_TEXTURE: Dictionary = {
	Terrain.PLAINS:   preload("res://assets/tiles/plains.svg"),
	Terrain.FOREST:   preload("res://assets/tiles/forest.svg"),
	Terrain.MOUNTAIN: preload("res://assets/tiles/mountain.svg"),
	Terrain.ROAD:     preload("res://assets/tiles/road.svg"),
	Terrain.RIVER:    preload("res://assets/tiles/river.svg"),
}

# grid[col][row] = valeur Terrain
var grid: Array = []

func _ready() -> void:
	_build_tileset()
	_init_grid()
	_paint_grid()

func _build_tileset() -> void:
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_HEXAGON
	ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL
	ts.tile_size = Vector2i(TILE_W, TILE_H)

	# Une source par terrain : source_id = valeur de l'enum Terrain
	for t: int in Terrain.values():
		var source := TileSetAtlasSource.new()
		source.texture = TERRAIN_TEXTURE[t]
		source.texture_region_size = Vector2i(TILE_W, TILE_H)
		source.create_tile(Vector2i.ZERO)
		ts.add_source(source, t)

	tile_set = ts

func _init_grid() -> void:
	grid.resize(MAP_W)
	for col in MAP_W:
		grid[col] = []
		grid[col].resize(MAP_H)
		for row in MAP_H:
			grid[col][row] = Terrain.PLAINS

	for pos in [Vector2i(2,2), Vector2i(3,2), Vector2i(3,3), Vector2i(4,3), Vector2i(2,4)]:
		grid[pos.x][pos.y] = Terrain.FOREST
	for pos in [Vector2i(5,1), Vector2i(5,2), Vector2i(6,2)]:
		grid[pos.x][pos.y] = Terrain.MOUNTAIN
	for pos in [Vector2i(7,3), Vector2i(7,4), Vector2i(7,5), Vector2i(7,6)]:
		grid[pos.x][pos.y] = Terrain.RIVER
	for pos in [Vector2i(3,6), Vector2i(4,6), Vector2i(5,6), Vector2i(6,6)]:
		grid[pos.x][pos.y] = Terrain.ROAD

func _paint_grid() -> void:
	clear()
	for col in MAP_W:
		for row in MAP_H:
			var t: int = grid[col][row]
			set_cell(Vector2i(col, row), t, Vector2i.ZERO)

func get_terrain(cell: Vector2i) -> int:
	if not is_in_bounds(cell):
		return -1
	return grid[cell.x][cell.y]

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < MAP_W and cell.y >= 0 and cell.y < MAP_H

func get_defense_bonus(cell: Vector2i) -> int:
	return TERRAIN_DEFENSE.get(get_terrain(cell), 0)

func get_map_size() -> Vector2i:
	return Vector2i(MAP_W, MAP_H)

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
