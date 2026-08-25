class_name WaterLifeLayer
extends Node2D

# Pose un WaterLife (banc de poissons, mouettes, ondulations) sur chaque plan
# d'eau assez grand du tableau. Les bassins viennent de Rivers, qui sait déjà
# calculer l'union des hexagones d'eau — d'où le fait qu'il n'y ait plus rien
# à déclarer dans le scénario : le décor suit la carte.
#
# Le contour est demandé sans tenir compte du brouillard, pour que le banc
# nage dans le vrai bassin et pas dans la portion révélée (sinon il changerait
# de bassin en cours de partie). Ce n'est pas une fuite d'information : le
# voile de Fog est dessiné après cette couche, il masque ce qui n'est pas
# encore exploré.

# En deçà, le bassin est trop petit pour qu'un banc y soit lisible
const MIN_CELLS := 2.0

@onready var rivers: Rivers = $"../Rivers"

func _ready() -> void:
	var hex_area := 0.75 * GameMap.TILE_W * GameMap.TILE_H
	for poly in rivers.build_outlines(true):
		if _polygon_area(poly) < MIN_CELLS * hex_area:
			continue
		var life := WaterLife.new()
		life.poly = poly
		# Les positions de WaterLife sont dans le repère du polygone : ce nœud
		# et ses enfants doivent donc rester à l'origine.
		life.position = Vector2.ZERO
		add_child(life)

static func _polygon_area(poly: PackedVector2Array) -> float:
	var n := poly.size()
	if n < 3:
		return 0.0
	var twice := 0.0
	for i in n:
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % n]
		twice += a.x * b.y - b.x * a.y
	return absf(twice) * 0.5
