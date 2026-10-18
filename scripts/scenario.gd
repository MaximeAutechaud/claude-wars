class_name Scenario

# Tableau actuellement chargé par main.tscn (GameMap/Villages/UnitsLayer/
# Creeps lisent tous Scenario.active). L'écran d'accueil le choisit :
# campagne (CURRENT) ou carte de test (SANDBOX).
static var active: Dictionary = CURRENT

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
# Drapeaux optionnels : "sandbox" (carte de test — sauvegarde désactivée),
#              "reveal_all" (pas de brouillard : tout est révélé).
# "decor"    : optionnel, cell -> id de prop purement visuel (voir Decor).

# « La Marche du Bord » — premier grand tableau fait main (22×16).
# Le fleuve coupe la carte en deux, franchissable sur deux ponts (routes).
# Boucle voulue : explorer la rive ouest, farmer les petits camps, forcer un
# pont gardé, prendre les villages du centre, puis l'assaut final au sud-est
# contre l'armée du Fossoyeur — c'est LUI le chef à abattre pour finir le
# tableau (armée menée par un boss : pas de héros IA).
# Effectifs volontairement serrés (playtest du 15/07/2026 : « trop d'unités,
# l'XP monte trop vite ») : joueur 5 (dont l'Éclaireur), IA 6, 11 creeps en
# 5 camps. Les nouveaux types de la décision 16 entrent par les camps :
# le Mage des braises au pont nord, l'Apothicaire au camp du gué.
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
			{ "cell": Vector2i(2, 3), "type": "scout" },
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
		# 2 — camp moyen qui garde la sortie est du pont nord ; il détient le
		# Mage des braises (décision 16 : les types rares sont des récompenses)
		{ "center": Vector2i(12, 2), "prize": "mage", "units": [
			{ "cell": Vector2i(12, 2), "type": "tank", "chief": true },
			{ "cell": Vector2i(13, 2), "type": "archer" },
		] },
		# 3 — camp des collines, garde le village sud-ouest et la route
		{ "center": Vector2i(4, 13), "prize": "infantry", "units": [
			{ "cell": Vector2i(4, 13), "type": "infantry" },
			{ "cell": Vector2i(5, 12), "type": "archer" },
		] },
		# 4 — camp du gué, le plus dur : garde le village central au bord du
		# fleuve, et sa récompense premium — l'Apothicaire (décision 16 :
		# une par tableau, prix du camp le plus dur)
		{ "center": Vector2i(12, 8), "prize": "medic", "units": [
			{ "cell": Vector2i(12, 8), "type": "tank", "chief": true },
			{ "cell": Vector2i(12, 9), "type": "infantry" },
			{ "cell": Vector2i(13, 10), "type": "archer" },
		] },
	],
}

# « Aubry-le-Bas » — tableau vitrine du biome 1, les Terres habitées (DA.md) :
# le monde normal qu'on protège. La garnison de l'Ordre à l'ouest, le bourg
# d'Aubry-le-Bas sur la grand-route (auberge, puits de Vessial), ses champs,
# son moulin et ses vergers ; la rivière à l'est, franchie par un seul pont,
# d'où arrive une colonne du Chœur. Deux bandes de pillards tiennent une ferme
# et le verger du sud. Le décor ("decor") est purement visuel.
const HABITEES: Dictionary = {
	"name": "Aubry-le-Bas",

	#          0         1
	#          01234567890123456789
	"terrain": [
		"FFPPPPPPPPPPPPPWPPMM",  #  0
		"FFFPPPPPPPPPPPPWPPPM",  #  1
		"FFPPPPPPPPPRPPPWPPPP",  #  2  chemin du moulin (11,2)
		"PPPPPPPPPPPRPPPWWPPP",  #  3
		"PPPPPPPPPPPRPPPPWPPP",  #  4
		"PPPPPPPPPPPRPPPPWPPF",  #  5
		"RRRRRRRRRRRRRRRRRRRR",  #  6  grand-route + pont (16,6)
		"PPPPPPPPPPPPPPPPWPFF",  #  7
		"PPPPPPPPPPPPPPPWWPPF",  #  8
		"PPPPPPPPPPPPPPPWPPPP",  #  9
		"PMMPPPPPPPPPPPPWPPPP",  # 10
		"MMPPPPPPPPPPPPPWPPPP",  # 11
		"MPPPPPPPPPPPPPPWPPMM",  # 12
		"PPPPPPPPPPPPPPPWPPMM",  # 13
	],

	"villages": {
		Vector2i(2, 7):   0,    # le hameau de la garnison
		Vector2i(8, 5):  -1,    # Aubry-le-Bas, nord de la route
		Vector2i(10, 7): -1,    # Aubry-le-Bas, sud de la route
		Vector2i(13, 11): -1,   # la ferme du sud, tenue par des pillards
		Vector2i(18, 4):  1,    # rive est, tenue par le Chœur
		Vector2i(18, 9):  1,
	},

	"armies": {
		0: [
			{ "cell": Vector2i(1, 6), "type": "hero" },
			{ "cell": Vector2i(2, 6), "type": "infantry" },
			{ "cell": Vector2i(1, 7), "type": "archer" },
			{ "cell": Vector2i(0, 6), "type": "tank" },
			{ "cell": Vector2i(3, 6), "type": "scout" },
		],
		1: [
			{ "cell": Vector2i(18, 6), "type": "hero" },
			{ "cell": Vector2i(17, 6), "type": "infantry" },
			{ "cell": Vector2i(18, 5), "type": "infantry" },
			{ "cell": Vector2i(19, 7), "type": "archer" },
			{ "cell": Vector2i(19, 5), "type": "tank" },
		],
	},

	"camps": [
		# Pillards du verger sud-ouest : premier farm près de la garnison
		{ "center": Vector2i(4, 11), "prize": "archer", "units": [
			{ "cell": Vector2i(4, 11), "type": "infantry" },
			{ "cell": Vector2i(5, 12), "type": "archer" },
		] },
		# Pillards de la ferme du sud : gardent le village et l'Apothicaire
		{ "center": Vector2i(12, 11), "prize": "medic", "units": [
			{ "cell": Vector2i(12, 11), "type": "tank", "chief": true },
			{ "cell": Vector2i(13, 12), "type": "archer" },
		] },
	],

	"decor": {
		# La garnison de l'Ordre, point de départ du joueur
		Vector2i(1, 4): "garrison",
		Vector2i(3, 7): "firewood",
		Vector2i(0, 7): "barrels",
		# Vergers au pied du bois, et leurs ruches
		Vector2i(3, 1): "apple_tree",
		Vector2i(4, 1): "apple_tree",
		Vector2i(3, 2): "apple_tree",
		Vector2i(4, 2): "apple_tree",
		Vector2i(5, 1): "beehives",
		# Les champs du moulin, au bout du chemin
		Vector2i(11, 1): "windmill",
		Vector2i(10, 2): "wheat",
		Vector2i(12, 2): "wheat",
		Vector2i(10, 3): "wheat",
		Vector2i(12, 3): "wheat",
		Vector2i(9, 3): "scarecrow",
		Vector2i(13, 2): "haystack",
		Vector2i(6, 3): "farmhouse",
		# Aubry-le-Bas : l'auberge, le puits de Vessial, les maisons du bourg
		Vector2i(9, 4): "inn",
		Vector2i(6, 5): "house",
		Vector2i(10, 5): "barrels",
		Vector2i(12, 5): "bread_oven",
		Vector2i(8, 8): "well",
		Vector2i(7, 7): "house",
		Vector2i(12, 7): "cart",
		# Le carré cultivé de Sella
		Vector2i(5, 8): "cabbages",
		Vector2i(6, 8): "cabbages",
		Vector2i(7, 9): "chicken_coop",
		# Pâturages
		Vector2i(9, 9): "sheep_pen",
		Vector2i(8, 10): "sheep_pen",
		Vector2i(10, 10): "cow",
		Vector2i(11, 9): "flower_bush",
		# La ferme du sud, occupée par les pillards
		Vector2i(14, 10): "farmhouse",
		Vector2i(14, 12): "barn",
		Vector2i(11, 12): "haystack",
		Vector2i(11, 11): "wheat",
		# Le verger du sud-ouest, l'autre repaire de pillards
		Vector2i(3, 11): "apple_tree",
		Vector2i(3, 12): "apple_tree",
		Vector2i(4, 12): "apple_tree",
		Vector2i(5, 11): "apple_tree",
		# Rive est, tenue par le Chœur — le pays est le même de l'autre côté
		Vector2i(17, 11): "windmill_b",
		Vector2i(17, 2): "cart",
		Vector2i(17, 8): "haystack",
	},
}

# « Terrain d'essai » — carte de test accessible depuis l'écran d'accueil :
# le roster complet des deux côtés sur un petit tableau varié (forêt,
# montagne, route, lac), sans brouillard, pour vérifier sprites, animations
# et mécaniques en jouant. La sauvegarde y est désactivée (drapeau sandbox).
const SANDBOX: Dictionary = {
	"name": "Terrain d'essai",
	"sandbox": true,
	"reveal_all": true,

	#          0         1
	#          012345678901
	"terrain": [
		"PPPPPFFPPPPP",  # 0
		"PPPPPFFPPMPP",  # 1
		"PPPPPPPPPMMP",  # 2
		"RRRRRRRRRRRR",  # 3  route qui traverse
		"PPPPPWWPPPPP",  # 4  petit lac central
		"PPPPPWWPPPPP",  # 5
		"PPFPPPPPPPPP",  # 6
		"PPFFPPPPPPPP",  # 7
		"PPPPPPPPPPPP",  # 8
	],

	"villages": {
		Vector2i(2, 7):  0,
		Vector2i(9, 7):  1,
		Vector2i(4, 1): -1,
	},

	"armies": {
		0: [
			{ "cell": Vector2i(1, 4), "type": "hero" },
			{ "cell": Vector2i(1, 3), "type": "infantry" },
			{ "cell": Vector2i(0, 5), "type": "tank" },
			{ "cell": Vector2i(0, 3), "type": "archer" },
			{ "cell": Vector2i(2, 5), "type": "scout" },
			{ "cell": Vector2i(1, 5), "type": "medic" },
			{ "cell": Vector2i(0, 4), "type": "mage" },
		],
		1: [
			{ "cell": Vector2i(10, 4), "type": "boss", "name": "Le Fossoyeur" },
			{ "cell": Vector2i(10, 3), "type": "infantry" },
			{ "cell": Vector2i(11, 5), "type": "tank" },
			{ "cell": Vector2i(11, 3), "type": "archer" },
			{ "cell": Vector2i(9, 5),  "type": "scout" },
			{ "cell": Vector2i(10, 5), "type": "medic" },
			{ "cell": Vector2i(11, 4), "type": "mage" },
		],
	},

	"camps": [
		{ "center": Vector2i(5, 7), "prize": "infantry", "units": [
			{ "cell": Vector2i(5, 7), "type": "infantry" },
			{ "cell": Vector2i(6, 7), "type": "archer" },
		] },
	],
}
