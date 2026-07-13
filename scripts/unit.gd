class_name Unit
extends Node2D

enum Type { INFANTRY, TANK, ARCHER, HERO }

const TEAM_COLORS := [Color(0.25, 0.55, 1.0), Color(1.0, 0.30, 0.30)]

# Stats et coûts de terrain par type d'unité.
# "range" : portée d'attaque en distance Manhattan.
# "counter" : dégâts de contre-attaque (subis seulement si le défenseur a la portée).
const STATS: Dictionary = {
	Type.INFANTRY: {
		"name": "Infanterie", "max_hp": 10, "mp": 3, "atk": 3, "counter": 2, "range": 1,
		"costs": {
			GameMap.Terrain.PLAINS: 1,  GameMap.Terrain.FOREST: 1,
			GameMap.Terrain.MOUNTAIN: 2, GameMap.Terrain.ROAD: 1,
			GameMap.Terrain.RIVER: 99,
		},
	},
	Type.TANK: {
		"name": "Char", "max_hp": 14, "mp": 5, "atk": 5, "counter": 3, "range": 1,
		"costs": {
			GameMap.Terrain.PLAINS: 1,  GameMap.Terrain.FOREST: 2,
			GameMap.Terrain.MOUNTAIN: 99, GameMap.Terrain.ROAD: 1,
			GameMap.Terrain.RIVER: 99,
		},
	},
	Type.ARCHER: {
		"name": "Archer", "max_hp": 8, "mp": 3, "atk": 3, "counter": 1, "range": 2,
		"costs": {
			GameMap.Terrain.PLAINS: 1,  GameMap.Terrain.FOREST: 2,
			GameMap.Terrain.MOUNTAIN: 3, GameMap.Terrain.ROAD: 1,
			GameMap.Terrain.RIVER: 99,
		},
	},
	Type.HERO: {
		"name": "Héros", "max_hp": 20, "mp": 4, "atk": 5, "counter": 4, "range": 1,
		"costs": {
			GameMap.Terrain.PLAINS: 1,  GameMap.Terrain.FOREST: 1,
			GameMap.Terrain.MOUNTAIN: 2, GameMap.Terrain.ROAD: 1,
			GameMap.Terrain.RIVER: 99,
		},
	},
}

# ── Progression du héros ─────────────────────────────────────────────────────
# XP cumulée requise pour atteindre les niveaux 2, 3, 4, 5 (cap)
const XP_THRESHOLDS := [2, 5, 9, 14]
const MAX_LEVEL := 5
const LEVELUP_HP := 4
const LEVELUP_ATK := 1

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
}

const IDLE_FRAME_TIME := 0.5

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
	return STATS[type]["name"]

func is_hero() -> bool:
	return type == Type.HERO

func movement_points() -> int:
	return STATS[type]["mp"]

func atk() -> int:
	return STATS[type]["atk"] + _atk_bonus + temp_atk_bonus

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

var _idle_frame := 0

func _ready() -> void:
	sprite.texture = TEXTURES[type][0]
	var timer := Timer.new()
	timer.wait_time = IDLE_FRAME_TIME
	timer.autostart = true
	timer.timeout.connect(_advance_idle_frame)
	add_child(timer)

func _advance_idle_frame() -> void:
	_idle_frame = 1 - _idle_frame
	sprite.texture = TEXTURES[type][_idle_frame]

func _draw() -> void:
	# Teinte d'équipe sur le sprite (dessiné en niveaux de gris)
	var tint: Color = TEAM_COLORS[team]
	if has_moved:
		tint = tint.darkened(0.45)
	sprite.self_modulate = tint

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
