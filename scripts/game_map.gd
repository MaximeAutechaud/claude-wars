class_name GameMap
extends TileMapLayer

const MAP_W := 12
const MAP_H := 10
const TILE_W := 64
const TILE_H := 32

enum Terrain { PLAINS, FOREST, MOUNTAIN, ROAD, RIVER }

const TERRAIN_COST: Dictionary = {
	Terrain.PLAINS:   1,
	Terrain.FOREST:   2,
	Terrain.MOUNTAIN: 3,
	Terrain.ROAD:     1,
	Terrain.RIVER:   99,
}

const TERRAIN_DEFENSE: Dictionary = {
	Terrain.PLAINS:   0,
	Terrain.FOREST:   1,
	Terrain.MOUNTAIN: 2,
	Terrain.ROAD:     0,
	Terrain.RIVER:    0,
}

const TERRAIN_COLOR: Dictionary = {
	Terrain.PLAINS:   Color(0.45, 0.72, 0.30),
	Terrain.FOREST:   Color(0.13, 0.40, 0.10),
	Terrain.MOUNTAIN: Color(0.55, 0.45, 0.35),
	Terrain.ROAD:     Color(0.65, 0.58, 0.42),
	Terrain.RIVER:    Color(0.25, 0.45, 0.82),
}

# grid[col][row] = valeur Terrain
var grid: Array = []

func _ready() -> void:
	_build_tileset()
	_init_grid()
	_paint_grid()

func _build_tileset() -> void:
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_size = Vector2i(TILE_W, TILE_H)

	# Atlas horizontal : un terrain par colonne, tous dans une seule texture
	var terrains := Terrain.values()
	var img := Image.create(TILE_W * terrains.size(), TILE_H, false, Image.FORMAT_RGBA8)
	for i in terrains.size():
		_fill_diamond(img, i * TILE_W, 0, TERRAIN_COLOR[terrains[i]])

	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(img)
	source.texture_region_size = Vector2i(TILE_W, TILE_H)
	for i in terrains.size():
		source.create_tile(Vector2i(i, 0))

	ts.add_source(source)  # source_id 0
	tile_set = ts

# Remplit un losange dans l'image ; pixels hors losange restent transparents
func _fill_diamond(img: Image, ox: int, oy: int, fill: Color) -> void:
	var border := Color(fill.r * 0.55, fill.g * 0.55, fill.b * 0.55, 1.0)
	for py in TILE_H:
		for px in TILE_W:
			# Normalise par rapport au centre de la case
			var nx := absf(px - TILE_W * 0.5 + 0.5) / (TILE_W * 0.5)
			var ny := absf(py - TILE_H * 0.5 + 0.5) / (TILE_H * 0.5)
			var d := nx + ny
			if d < 0.92:
				img.set_pixel(ox + px, oy + py, fill)
			elif d <= 1.0:
				img.set_pixel(ox + px, oy + py, border)
			# else : transparent (coin du bounding-box)

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
			set_cell(Vector2i(col, row), 0, Vector2i(t, 0))

func get_terrain(cell: Vector2i) -> int:
	if not is_in_bounds(cell):
		return -1
	return grid[cell.x][cell.y]

func get_movement_cost(cell: Vector2i) -> int:
	var t := get_terrain(cell)
	return TERRAIN_COST.get(t, 99)

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < MAP_W and cell.y >= 0 and cell.y < MAP_H

func get_defense_bonus(cell: Vector2i) -> int:
	return TERRAIN_DEFENSE.get(get_terrain(cell), 0)

func get_map_size() -> Vector2i:
	return Vector2i(MAP_W, MAP_H)
