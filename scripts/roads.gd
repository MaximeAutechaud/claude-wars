class_name Roads
extends ConnectedRibbon

# Voir ConnectedRibbon pour l'algorithme (ruban de matière lissé,
# connecté aux voisines Route). La case Route n'a pas de texture de base
# propre : elle réutilise plains.png dans GameMap.TERRAIN_TEXTURE, le
# chemin peint par-dessus. Un pont n'est qu'une case Route qui coupe une
# rangée de Rivière (aucun art dédié — le chemin continue simplement
# par-dessus le "trou" dans la rivière), sans traitement spécial puisque
# ConnectedRibbon ne regarde que les voisins de même terrain.

func _init() -> void:
	terrain_type = GameMap.Terrain.ROAD
	ribbon_half_width = 9.0
	ribbon_tex = preload("res://assets/tiles/road.png")
