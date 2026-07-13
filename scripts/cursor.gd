extends Node2D

@onready var map: GameMap = $"../GameMap"
@onready var coord_label: Label = $"../UI/CoordLabel"

var hovered_cell := Vector2i(-1, -1)

func _process(_delta: float) -> void:
	var cell := map.local_to_map(map.to_local(get_global_mouse_position()))
	if cell == hovered_cell:
		return
	hovered_cell = cell
	queue_redraw()
	if coord_label:
		coord_label.text = "(%d, %d)" % [cell.x, cell.y] if map.is_in_bounds(cell) else "(-, -)"

func _draw() -> void:
	if not map.is_in_bounds(hovered_cell):
		return
	# Convertit coordonnées grille → espace local du Cursor (= espace monde si Cursor.position = 0)
	var world_pos := map.to_global(map.map_to_local(hovered_cell))
	var p := to_local(world_pos)
	var hw := map.tile_set.tile_size.x * 0.5
	var hh := map.tile_set.tile_size.y * 0.5
	var pts := GameMap.hex_corners(p, hw, hh)
	pts.append(pts[0])
	draw_polyline(pts, Color(1.0, 0.9, 0.0, 0.9), 2.0)
