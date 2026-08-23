class_name Rivers
extends ConnectedRibbon

# Voir ConnectedRibbon pour l'algorithme. Ruban bien plus large que Roads
# puisque la rivière doit occuper quasiment tout l'hexagone (juste un peu
# de berge — l'herbe de plains.png, réutilisée aussi comme base de
# Terrain.RIVER — visible aux coins), contre un filet étroit pour la route.

func _init() -> void:
	terrain_type = GameMap.Terrain.RIVER
	ribbon_half_width = 23.0
	ribbon_tex = preload("res://assets/tiles/river.png")
	# Segments droits : le lissage en courbe fait onduler un ruban aussi
	# large comme de l'eau agitée plutôt que de couler (voir ConnectedRibbon).
	smooth_curve = false
