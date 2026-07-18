class_name Unit
extends Node2D

enum Type { INFANTRY, TANK, ARCHER, HERO, BOSS, SCOUT, MEDIC, MAGE }

# Ids du format de scénario (Scenario.CURRENT) vers les types
const TYPE_BY_ID: Dictionary = {
	"infantry": Type.INFANTRY, "tank": Type.TANK, "archer": Type.ARCHER,
	"hero": Type.HERO, "boss": Type.BOSS,
	"scout": Type.SCOUT, "medic": Type.MEDIC, "mage": Type.MAGE,
}

const TEAM_COLORS := [Color(0.25, 0.55, 1.0), Color(1.0, 0.30, 0.30), Color(0.95, 0.74, 0.18)]

# Équipe des creeps : ignorée par les conditions de victoire, ne capture pas
const NEUTRAL_TEAM := 2

# Stats et coûts de terrain par type d'unité (décision 16 : « chacun son
# thème » — le Guerrier encaisse, le Cavalier court et frappe, l'Archer tire).
# "range" : portée d'attaque en distance hex.
# "min_range" : portée minimale (Mage : nul au corps à corps), 1 par défaut.
# "counter" : dégâts de contre-attaque (subis seulement si le défenseur a la portée).
# "vision" : rayon de vision sous brouillard de guerre.
# "pierce" : les dégâts ignorent les bonus de défense (terrain + posture).
const STATS: Dictionary = {
	Type.INFANTRY: {
		"name": "Guerrier", "max_hp": 14, "mp": 3, "atk": 3, "counter": 3, "range": 1,
		"vision": 3,
		"costs": {
			GameMap.Terrain.PLAINS: 1,  GameMap.Terrain.FOREST: 1,
			GameMap.Terrain.MOUNTAIN: 2, GameMap.Terrain.ROAD: 1,
			GameMap.Terrain.RIVER: 99,
		},
	},
	Type.TANK: {
		"name": "Cavalier", "max_hp": 11, "mp": 5, "atk": 4, "counter": 2, "range": 1,
		"vision": 2,
		"costs": {
			GameMap.Terrain.PLAINS: 1,  GameMap.Terrain.FOREST: 2,
			GameMap.Terrain.MOUNTAIN: 99, GameMap.Terrain.ROAD: 1,
			GameMap.Terrain.RIVER: 99,
		},
	},
	Type.ARCHER: {
		"name": "Archer", "max_hp": 8, "mp": 3, "atk": 3, "counter": 1, "range": 2,
		"vision": 3,
		"costs": {
			GameMap.Terrain.PLAINS: 1,  GameMap.Terrain.FOREST: 2,
			GameMap.Terrain.MOUNTAIN: 3, GameMap.Terrain.ROAD: 1,
			GameMap.Terrain.RIVER: 99,
		},
	},
	Type.HERO: {
		"name": "Héros", "max_hp": 20, "mp": 4, "atk": 5, "counter": 4, "range": 1,
		"vision": 4,
		"costs": {
			GameMap.Terrain.PLAINS: 1,  GameMap.Terrain.FOREST: 1,
			GameMap.Terrain.MOUNTAIN: 2, GameMap.Terrain.ROAD: 1,
			GameMap.Terrain.RIVER: 99,
		},
	},
	Type.BOSS: {
		"name": "Boss", "max_hp": 30, "mp": 3, "atk": 6, "counter": 4, "range": 1,
		"vision": 3,
		"costs": {
			GameMap.Terrain.PLAINS: 1,  GameMap.Terrain.FOREST: 1,
			GameMap.Terrain.MOUNTAIN: 2, GameMap.Terrain.ROAD: 1,
			GameMap.Terrain.RIVER: 99,
		},
	},
	Type.SCOUT: {
		"name": "Éclaireur", "max_hp": 7, "mp": 4, "atk": 2, "counter": 1, "range": 1,
		"vision": 5,
		"costs": {
			GameMap.Terrain.PLAINS: 1,  GameMap.Terrain.FOREST: 1,
			GameMap.Terrain.MOUNTAIN: 1, GameMap.Terrain.ROAD: 1,
			GameMap.Terrain.RIVER: 99,
		},
	},
	Type.MEDIC: {
		"name": "Apothicaire", "max_hp": 8, "mp": 3, "atk": 1, "counter": 1, "range": 1,
		"vision": 3,
		"costs": {
			GameMap.Terrain.PLAINS: 1,  GameMap.Terrain.FOREST: 1,
			GameMap.Terrain.MOUNTAIN: 2, GameMap.Terrain.ROAD: 1,
			GameMap.Terrain.RIVER: 99,
		},
	},
	Type.MAGE: {
		"name": "Mage des braises", "max_hp": 7, "mp": 2, "atk": 4, "counter": 1,
		"range": 3, "min_range": 2, "pierce": true, "vision": 2,
		"costs": {
			GameMap.Terrain.PLAINS: 1,  GameMap.Terrain.FOREST: 2,
			GameMap.Terrain.MOUNTAIN: 3, GameMap.Terrain.ROAD: 1,
			GameMap.Terrain.RIVER: 99,
		},
	},
}

# XP supplémentaire créditée au héros du camp qui abat un boss
const BOSS_XP_BONUS := 3

# ── Progression du héros ─────────────────────────────────────────────────────
# XP cumulée requise pour atteindre les niveaux 2, 3, 4, 5 (cap)
const XP_THRESHOLDS := [2, 5, 9, 14]
const MAX_LEVEL := 5
const LEVELUP_HP := 4
const LEVELUP_ATK := 1

# ── Vétérance (toutes les unités sauf le héros, creeps inclus) ───────────────
const VETERAN_KILLS := 3   # kills pour la promotion
const VETERAN_ATK := 1
const VETERAN_HP := 2      # PV max ajoutés, remplis à la promotion

# ── Verbes de classe (décision 16) ───────────────────────────────────────────
# Charge du Cavalier : bonus d'attaque si le déplacement qui précède couvre
# au moins CHARGE_MIN_DIST cases de distance hex (l'élan, pas le chemin)
const CHARGE_BONUS := 2
const CHARGE_MIN_DIST := 3
# Endurci de l'Éclaireur : auto-soin en début de tour hors village
const SCOUT_REGEN := 2
# Soin de l'Apothicaire : l'action du tour, sur un allié adjacent
const MEDIC_HEAL := 4

# ── Posture Défendre (décision 14) ───────────────────────────────────────────
# Se mettre en garde remplace l'action du tour ; le bonus de défense tient
# jusqu'à la prochaine action de l'unité (bouger, attaquer ou lancer un sort).
const DEFEND_BONUS := 2

# Deux frames d'idle par type, alternées en continu (style Advance Wars)
const TEXTURES: Dictionary = {
	Type.INFANTRY: [
		preload("res://assets/units/infantry.svg"),
		preload("res://assets/units/infantry_2.svg"),
	],
	Type.TANK: [
		preload("res://assets/units/tank.svg"),
		preload("res://assets/units/tank_2.svg"),
	],
	Type.ARCHER: [
		preload("res://assets/units/archer.svg"),
		preload("res://assets/units/archer_2.svg"),
	],
	Type.HERO: [
		preload("res://assets/units/hero.svg"),
		preload("res://assets/units/hero_2.svg"),
	],
	Type.BOSS: [
		preload("res://assets/units/boss.svg"),
		preload("res://assets/units/boss_2.svg"),
	],
	Type.SCOUT: [
		preload("res://assets/units/scout.svg"),
		preload("res://assets/units/scout_2.svg"),
	],
	Type.MEDIC: [
		preload("res://assets/units/medic.svg"),
		preload("res://assets/units/medic_2.svg"),
	],
	Type.MAGE: [
		preload("res://assets/units/mage.svg"),
		preload("res://assets/units/mage_2.svg"),
	],
}

const IDLE_FRAME_TIME := 0.5

# ── Marche visuelle (animations de déplacement, style rétro) ────────────────
# La logique de jeu est instantanée (move_unit met tout à jour au clic) ;
# seul le sprite voyage, case par case sur le chemin réel du Dijkstra.
# Locomotion par bonds : chaque case est un petit saut en cloche — étirement
# en l'air, écrasement à l'atterrissage, inclinaison dans le sens de la
# course, poussière à l'arrivée (juice procédural, pas de frames dédiées).
const WALK_STEP := 0.16        # secondes par case (un bond)
const WALK_STEP_FAST := 0.12   # monture et éclaireur : plus vifs
const HOP_HEIGHT := 8.0        # hauteur de l'arc du bond (px)
const LEAN_DEG := 7.0          # inclinaison du sprite dans le sens du mouvement

const TEAM_SHADER := preload("res://assets/team_color.gdshader")

@export var type: Type = Type.INFANTRY
@export var team: int = 0

@onready var sprite: Sprite2D = $Sprite

var cell: Vector2i = Vector2i.ZERO
var has_moved    := false
var selected     := false
var attackable   := false
var remaining_mp := 0

var hp:     int = 10
var max_hp: int = 10

# Creeps : position d'origine (leash) et nom affiché
var home_cell := Vector2i.ZERO
var display_name := ""

# Vétérance
var kills := 0
var veteran := false

# Boss (état des mécaniques de boss.gd)
var doom_cells: Array[Vector2i] = []
var doom_armed := false
var boss_phase := 0

# Posture Défendre — cassée par toute nouvelle action (voir UnitsLayer)
var defending := false

# Charge du Cavalier : armée par un déplacement d'élan, consommée à l'attaque
var charge_ready := false

# Marche visuelle en cours (le tour IA/creeps attend la fin avant d'enchaîner)
var walking := false

# Progression (héros uniquement)
var xp    := 0
var level := 1
var _atk_bonus     := 0
var _counter_bonus := 0

# Sorts (héros uniquement)
var learned_spells: Array[String] = []
var cooldowns: Dictionary = {}        # spell_id -> tours restants
var has_cast := false                 # un seul sort par tour
var pending_levelups := 0             # choix de sort en attente
var temp_atk_bonus := 0               # buff Cri de guerre, remis à 0 à son tour

func setup(p_type: Type, p_team: int) -> void:
	type = p_type
	team = p_team
	max_hp = STATS[type]["max_hp"]
	hp = max_hp
	remaining_mp = movement_points()

func unit_name() -> String:
	if type == Type.HERO:
		return "Héros niv. %d" % level
	var n: String = display_name if display_name != "" else STATS[type]["name"]
	if veteran:
		n += " vétéran"
	return n

func is_hero() -> bool:
	return type == Type.HERO

func is_boss() -> bool:
	return type == Type.BOSS

func is_creep() -> bool:
	return team == NEUTRAL_TEAM

# Seules les unités à pied capturent les villages (jamais les creeps ni
# les boss — un boss reste concentré sur le combat)
func can_capture() -> bool:
	return type != Type.TANK and type != Type.BOSS and not is_creep()

func movement_points() -> int:
	return STATS[type]["mp"]

func atk() -> int:
	var total: int = STATS[type]["atk"] + _atk_bonus + temp_atk_bonus
	if charge_ready:
		total += CHARGE_BONUS
	return total

func spell_ready(id: String) -> bool:
	return not has_cast and learned_spells.has(id) and cooldowns.get(id, 0) == 0

func has_ready_spell() -> bool:
	for id in learned_spells:
		if spell_ready(id):
			return true
	return false

func unlearned_spells() -> Array[String]:
	var out: Array[String] = []
	for id in Spells.POOL:
		if not learned_spells.has(id):
			out.append(id)
	return out

func counter_atk() -> int:
	return STATS[type]["counter"] + _counter_bonus

# Bonus d'attaque permanent (enrage de boss, futurs objets…)
func gain_atk(amount: int) -> void:
	_atk_bonus += amount
	queue_redraw()

# Comptabilise un kill ; à VETERAN_KILLS l'unité passe vétéran
# (+1 atk, +2 PV max remplis, galon doré). Le héros a ses niveaux d'XP,
# le boss a ses phases : ni l'un ni l'autre ne cumule de vétérance.
func add_kill() -> void:
	if type == Type.HERO or type == Type.BOSS:
		return
	kills += 1
	if veteran or kills < VETERAN_KILLS:
		return
	veteran = true
	max_hp += VETERAN_HP
	hp = mini(hp + VETERAN_HP, max_hp)
	_atk_bonus += VETERAN_ATK
	print("%s est promu vétéran ! (+%d atk, +%d PV max)"
			% [unit_name(), VETERAN_ATK, VETERAN_HP])
	_level_up_flash()
	queue_redraw()

func add_xp(amount: int) -> void:
	if type != Type.HERO:
		return
	xp += amount
	while level < MAX_LEVEL and xp >= XP_THRESHOLDS[level - 1]:
		level += 1
		max_hp += LEVELUP_HP
		hp = mini(hp + LEVELUP_HP, max_hp)
		_atk_bonus += LEVELUP_ATK
		_counter_bonus += LEVELUP_ATK
		pending_levelups += 1
		print("%s ! (+%d PV max, +%d atk)" % [unit_name(), LEVELUP_HP, LEVELUP_ATK])
		_level_up_flash()
	queue_redraw()

func _level_up_flash() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.45, 1.45), 0.15) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.25)

func attack_range() -> int:
	return STATS[type]["range"]

# Portée minimale : en deçà, ni attaque ni riposte (Mage nul au corps à corps)
func min_range() -> int:
	return STATS[type].get("min_range", 1)

# Dégâts qui ignorent les bonus de défense (terrain + posture) — le Mage
func pierces_defense() -> bool:
	return STATS[type].get("pierce", false)

func vision() -> int:
	return STATS[type]["vision"]

var _idle_frame := 0
var _idle_timer: Timer
var _sprite_base_y := 0.0

func _ready() -> void:
	sprite.texture = TEXTURES[type][0]
	var mat := ShaderMaterial.new()
	mat.shader = TEAM_SHADER
	sprite.material = mat
	_sprite_base_y = sprite.position.y
	# Les rouges regardent vers la gauche (face au joueur, façon Advance Wars)
	sprite.flip_h = (team == 1)
	_idle_timer = Timer.new()
	_idle_timer.wait_time = IDLE_FRAME_TIME
	_idle_timer.autostart = true
	_idle_timer.timeout.connect(_advance_idle_frame)
	add_child(_idle_timer)

func _advance_idle_frame() -> void:
	_idle_frame = 1 - _idle_frame
	sprite.texture = TEXTURES[type][_idle_frame]

# ── Marche visuelle ──────────────────────────────────────────────────────────

# Fait bondir le sprite le long de `points` (positions locales au parent,
# une par case du chemin) : un saut en cloche par case, sprite retourné et
# incliné selon la direction, frames d'idle accélérées.
func walk_along(points: PackedVector2Array) -> void:
	if points.is_empty():
		return
	walking = true
	_idle_timer.wait_time = IDLE_FRAME_TIME / 3.0
	var step := WALK_STEP_FAST if type in [Type.TANK, Type.SCOUT] else WALK_STEP
	var tw := create_tween()
	var prev := position
	for p in points:
		var dx := p.x - prev.x
		tw.tween_callback(_step_start.bind(dx, step))
		tw.tween_property(self, "position", p, step)
		prev = p
	await tw.finished
	_spawn_dust(position)
	walking = false
	_idle_timer.wait_time = IDLE_FRAME_TIME
	sprite.rotation_degrees = 0.0
	sprite.scale = Vector2.ONE
	sprite.position.y = _sprite_base_y
	queue_redraw()   # applique le grisé « a déjà agi » à l'arrivée

# Oriente le sprite selon la direction horizontale (les segments verticaux
# gardent l'orientation courante)
func _face(dx: float) -> void:
	if absf(dx) > 0.5:
		sprite.flip_h = dx < 0.0

# Un bond : le sprite s'incline, monte en cloche en s'étirant, retombe et
# s'écrase brièvement à l'atterrissage — c'est ce qui vend le poids
func _step_start(dx: float, step: float) -> void:
	_face(dx)
	if absf(dx) > 0.5:
		sprite.rotation_degrees = LEAN_DEG * signf(dx)
	var t := create_tween()
	t.tween_property(sprite, "position:y", _sprite_base_y - HOP_HEIGHT, step * 0.4) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(sprite, "scale", Vector2(0.93, 1.08), step * 0.4)
	t.chain().tween_property(sprite, "position:y", _sprite_base_y, step * 0.45) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(sprite, "scale", Vector2.ONE, step * 0.45)
	t.chain().tween_property(sprite, "scale", Vector2(1.12, 0.86), step * 0.075)
	t.chain().tween_property(sprite, "scale", Vector2.ONE, step * 0.075)

# Nuage de poussière procédural au point d'arrivée
func _spawn_dust(at: Vector2) -> void:
	if get_parent() == null:
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 5
	p.lifetime = 0.3
	p.position = at + Vector2(0, 10)
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.gravity = Vector2(0, 60)
	p.initial_velocity_min = 12.0
	p.initial_velocity_max = 26.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 2.6
	p.color = Color(0.82, 0.78, 0.68, 0.8)
	p.emitting = true
	p.finished.connect(p.queue_free)
	get_parent().add_child(p)

# Pop d'arrivée du Bond : une téléportation, pas une marche
func blink_pop() -> void:
	scale = Vector2(0.35, 1.5)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	# Couleur d'équipe : le shader remplace les zones magenta du sprite
	# (bouclier, capuche, pennon…) par la couleur de la faction
	var mat := sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("team_color", TEAM_COLORS[team])
	# Unité qui a déjà agi : sprite entier assombri — mais seulement une fois
	# arrivée (grisée en pleine marche, la course ferait fantôme)
	sprite.self_modulate = Color(0.55, 0.55, 0.55) if has_moved and not walking \
			else Color.WHITE

	# Contours d'hexagone sur la case : blanc = sélectionnée, rouge = attaquable
	var hw := GameMap.TILE_W * 0.5 - 3.0
	var hh := GameMap.TILE_H * 0.5 - 2.5
	if selected:
		_draw_cell_outline(hw, hh, Color.WHITE, 2.0)
	if attackable:
		_draw_cell_outline(hw, hh, Color(1.0, 0.15, 0.15), 2.5)

	# Barre de PV au pied de l'unité
	var bw := 22.0
	var bh := 3.0
	var by := 9.0
	draw_rect(Rect2(-bw * 0.5, by, bw, bh), Color(0.35, 0.0, 0.0))
	draw_rect(Rect2(-bw * 0.5, by, bw * hp / float(max_hp), bh), Color(0.15, 0.85, 0.2))

	# Bouclier de la posture Défendre (bas-gauche du sprite)
	if defending:
		var sp := Vector2(-13.0, 2.0)
		var shield := PackedVector2Array([
			sp + Vector2(-4.5, -5), sp + Vector2(4.5, -5), sp + Vector2(4.5, 0),
			sp + Vector2(0, 5), sp + Vector2(-4.5, 0),
		])
		draw_colored_polygon(shield, Color(0.75, 0.78, 0.85))
		var outline := shield.duplicate()
		outline.append(shield[0])
		draw_polyline(outline, Color(0.2, 0.25, 0.35), 1.4)

	# Galons dorés du vétéran : deux chevrons pleins au-dessus de la tête,
	# liseré sombre pour rester lisibles sur tous les terrains
	if veteran:
		var gold := Color(1.0, 0.82, 0.15)
		var dark := Color(0.25, 0.15, 0.0)
		for i in 2:
			var y := -19.0 - i * 4.5
			var pts := PackedVector2Array([
				Vector2(-6.5, y - 2.5), Vector2(0, y + 1.5), Vector2(6.5, y - 2.5),
				Vector2(6.5, y), Vector2(0, y + 4.0), Vector2(-6.5, y),
			])
			draw_colored_polygon(pts, gold)
			var outline := pts.duplicate()
			outline.append(pts[0])
			draw_polyline(outline, dark, 1.0)

	if type == Type.HERO:
		# Barre d'XP dorée sous la barre de PV
		var frac := 1.0
		if level < MAX_LEVEL:
			var prev: int = 0 if level == 1 else XP_THRESHOLDS[level - 2]
			var next_xp: int = XP_THRESHOLDS[level - 1]
			frac = clampf((xp - prev) / float(next_xp - prev), 0.0, 1.0)
		draw_rect(Rect2(-bw * 0.5, by + bh + 1, bw, 2.0), Color(0.25, 0.2, 0.05))
		draw_rect(Rect2(-bw * 0.5, by + bh + 1, bw * frac, 2.0), Color(1.0, 0.82, 0.15))
		# Pips de niveau au-dessus du sprite
		for i in level - 1:
			draw_rect(Rect2(-10.0 + i * 5.5, -27.0, 3.5, 3.5), Color(1.0, 0.82, 0.15))

func _draw_cell_outline(hw: float, hh: float, color: Color, width: float) -> void:
	var pts := GameMap.hex_corners(Vector2.ZERO, hw, hh)
	pts.append(pts[0])
	draw_polyline(pts, color, width)
