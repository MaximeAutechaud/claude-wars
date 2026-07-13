class_name Villages
extends Node2D

# Revenu par village possédé, au début du tour du propriétaire
const INCOME_PER_VILLAGE := 2
# Soin d'une unité qui commence son tour sur un village allié
const VILLAGE_HEAL := 3

# cell -> propriétaire initial (-1 = neutre)
const START_OWNERS: Dictionary = {
	Vector2i(1, 2):  0,    # village de départ bleu
	Vector2i(10, 7): 1,    # village de départ rouge
	Vector2i(6, 4):  -1,
	Vector2i(4, 7):  -1,
	Vector2i(8, 1):  -1,
}

@onready var map: GameMap = $"../GameMap"

var owners: Dictionary = {}
var _tex: Texture2D = preload("res://assets/tiles/village.svg")

func _ready() -> void:
	owners = START_OWNERS.duplicate()
	queue_redraw()

func is_village(cell: Vector2i) -> bool:
	return owners.has(cell)

func owner_of(cell: Vector2i) -> int:
	return owners.get(cell, -2)

func village_count(team: int) -> int:
	var n := 0
	for cell in owners:
		if owners[cell] == team:
			n += 1
	return n

func income_for(team: int) -> int:
	return village_count(team) * INCOME_PER_VILLAGE

# Capture instantanée par les unités à pied qui terminent leur mouvement dessus
func try_capture(unit: Unit) -> bool:
	if not owners.has(unit.cell) or owners[unit.cell] == unit.team:
		return false
	if not unit.can_capture():
		return false
	owners[unit.cell] = unit.team
	print("Village %s capturé par %s" % [unit.cell, unit.unit_name()])
	queue_redraw()
	return true

func _draw() -> void:
	for cell: Vector2i in owners:
		var p := to_local(map.to_global(map.map_to_local(cell)))
		draw_texture(_tex, p - Vector2(16.0, 22.0))
		# Fanion à la couleur du propriétaire (gris = neutre)
		var col := Color(0.62, 0.62, 0.62)
		if owners[cell] >= 0:
			col = Unit.TEAM_COLORS[owners[cell]]
		draw_line(p + Vector2(9, -22), p + Vector2(9, -7), Color(0.32, 0.26, 0.2), 1.5)
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(9, -22), p + Vector2(18, -18.5), p + Vector2(9, -15),
		]), col)
