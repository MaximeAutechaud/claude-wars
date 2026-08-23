class_name Villages
extends Node2D

# Soin d'une unité qui commence son tour sur un village allié
const VILLAGE_HEAL := 3

@onready var map: GameMap = $"../GameMap"
@onready var fog: Fog = get_node_or_null("../Fog")

var owners: Dictionary = {}
var _tex: Texture2D = preload("res://assets/tiles/village.png")

func _ready() -> void:
	# cell -> propriétaire initial (-1 = neutre), depuis le scénario courant
	owners = (Scenario.active["villages"] as Dictionary).duplicate()
	queue_redraw()

func is_village(cell: Vector2i) -> bool:
	return owners.has(cell)

func owner_of(cell: Vector2i) -> int:
	return owners.get(cell, -2)

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
		# Sous le voile noir, le village n'existe pas encore pour le joueur
		if fog and not fog.is_explored(cell):
			continue
		var p := to_local(map.to_global(map.map_to_local(cell)))
		draw_texture(_tex, p - Vector2(50.0, 60.0))
		# Fanion à la couleur du propriétaire (gris = neutre)
		var col := Color(0.62, 0.62, 0.62)
		if owners[cell] >= 0:
			col = Unit.TEAM_COLORS[owners[cell]]
		draw_line(p + Vector2(36, -60), p + Vector2(36, -40), Color(0.32, 0.26, 0.2), 1.5)
		draw_colored_polygon(PackedVector2Array([
			p + Vector2(36, -60), p + Vector2(48, -55), p + Vector2(36, -50),
		]), col)
