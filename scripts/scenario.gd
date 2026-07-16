class_name Scenario

# ── Format de tableau (décision 13, phase 9) ─────────────────────────────────
# Un tableau est un dictionnaire de données pures — aucune référence de classe,
# pour rester trivialement portable vers des fichiers (JSON…) plus tard.
#
# "terrain"  : une string par ligne de la carte, un caractère par colonne —
#              P plaine, F forêt, M montagne, R route, W rivière
#              (mapping dans GameMap.TERRAIN_CHARS ; la taille de la carte est
#              déduite du nombre de lignes / de leur longueur).
# "villages" : cell -> équipe de départ (-1 = neutre).
# "armies"   : équipe -> liste de { cell, type } ; les types d'unités sont des
#              strings, mappées par Unit.TYPE_BY_ID. Un "hero" par équipe.
# "camps"    : camps de bandits — center, prize (type du prisonnier),
#              prize_veteran (le prisonnier arrive vétéran), units. Sur une
#              unité : "chief" (look de chef), "boss" (comportement de boss —
#              phases, sacrifice, malédiction), "name" (nom affiché).

# « La Marche du Bord » — premier grand tableau fait main (22×16).
# Le fleuve coupe la carte en deux, franchissable sur deux ponts (routes).
# Boucle voulue : explorer la rive ouest, farmer les petits camps, forcer un
# pont gardé, prendre les villages du centre, puis l'assaut final au sud-est
# contre l'armée du Fossoyeur — c'est LUI le chef à abattre pour finir le
# tableau (armée menée par un boss : pas de héros IA).
# Effectifs volontairement serrés (playtest du 15/07/2026 : « trop d'unités,
# l'XP monte trop vite ») : joueur 4, IA 6, 11 creeps en 5 camps.
const CURRENT: Dictionary = {
	"name": "La Marche du Bord",

	#          0         1         2
	#          0123456789012345678901
	"terrain": [
		"PPPPPPPPPPWPPPMMMPPPPP",  #  0
		"PPPFFPPPPPWPPPMMMMPPPP",  #  1
		"PPPPFFPPPPWPPPPMMPPPPP",  #  2
		"RRRRRRRRRRRRRRRRRPPPPP",  #  3  route ouest-est + pont nord (10,3)
		"PPPPPPPPPPWPPPPPPPPPPP",  #  4
		"PPFFPPPPPPWPPPFFPPPPPP",  #  5
		"PPFPPPPPPPWWPPPFFPPPPP",  #  6
		"PPPPPPFFPPWWPMPPPPPPPP",  #  7  le fleuve s'élargit
		"PPPPPPFFFPWWPMMPPPPPPP",  #  8
		"PPPPPPPFPPWWPPMPPPPPPP",  #  9
		"PPPPPPFFPPWPPPPPPFFPPP",  # 10
		"PPPPPPPFFPWPPPPPPPFPPP",  # 11
		"PPPRRRRRRRRRRRRRRRPPPP",  # 12  route sud + pont sud (10,12)
		"PPMMPPPPPPWPPPPPPPPPPP",  # 13
		"PMMMPPPPPPWPPPPPPPPPPP",  # 14
		"PPMMMPPPPPWPPPPPPPPPPP",  # 15
	],

	"villages": {
		Vector2i(2, 2):   0,    # village de départ joueur
		Vector2i(19, 12): 1,    # villages de la base IA
		Vector2i(18, 14): 1,
		Vector2i(6, 2):  -1,    # rive ouest, sur la route nord
		Vector2i(5, 13): -1,    # rive ouest, gardé par le camp des collines
		Vector2i(12, 7): -1,    # centre, gardé par le camp du gué
		Vector2i(16, 4): -1,    # rive est, sur la route nord
		Vector2i(13, 11): -1,   # rive est, sur la route sud
	},

	"armies": {
		0: [
			{ "cell": Vector2i(1, 2), "type": "hero" },
			{ "cell": Vector2i(1, 1), "type": "infantry" },
			{ "cell": Vector2i(0, 3), "type": "tank" },
			{ "cell": Vector2i(0, 1), "type": "archer" },
		],
		1: [
			{ "cell": Vector2i(19, 13), "type": "boss", "name": "Le Fossoyeur" },
			{ "cell": Vector2i(18, 12), "type": "tank" },
			{ "cell": Vector2i(18, 13), "type": "infantry" },
			{ "cell": Vector2i(19, 14), "type": "infantry" },
			{ "cell": Vector2i(19, 12), "type": "archer" },
			{ "cell": Vector2i(20, 13), "type": "archer" },
		],
	},

	"camps": [
		# 0 — petit camp près du départ joueur : premier farm
		{ "center": Vector2i(2, 8), "prize": "archer", "units": [
			{ "cell": Vector2i(2, 8), "type": "infantry" },
			{ "cell": Vector2i(1, 9), "type": "archer" },
		] },
		# 1 — petit camp au nord de la route ouest
		{ "center": Vector2i(7, 1), "prize": "infantry", "units": [
			{ "cell": Vector2i(7, 1), "type": "infantry" },
			{ "cell": Vector2i(6, 0), "type": "archer" },
		] },
		# 2 — camp moyen qui garde la sortie est du pont nord
		{ "center": Vector2i(12, 2), "prize": "tank", "units": [
			{ "cell": Vector2i(12, 2), "type": "tank", "chief": true },
			{ "cell": Vector2i(13, 2), "type": "archer" },
		] },
		# 3 — camp des collines, garde le village sud-ouest et la route
		{ "center": Vector2i(4, 13), "prize": "infantry", "units": [
			{ "cell": Vector2i(4, 13), "type": "infantry" },
			{ "cell": Vector2i(5, 12), "type": "archer" },
		] },
		# 4 — camp du gué, le plus dur : garde le village central au bord du
		# fleuve, et sa récompense premium — un Char vétéran
		{ "center": Vector2i(12, 8), "prize": "tank", "prize_veteran": true, "units": [
			{ "cell": Vector2i(12, 8), "type": "tank", "chief": true },
			{ "cell": Vector2i(12, 9), "type": "infantry" },
			{ "cell": Vector2i(13, 10), "type": "archer" },
		] },
	],
}
