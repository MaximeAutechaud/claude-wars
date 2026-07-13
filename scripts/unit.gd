class_name Unit
extends Node2D

enum Type { INFANTRY, TANK, ARCHER }

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
}

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

func setup(p_type: Type, p_team: int) -> void:
	type = p_type
	team = p_team
	max_hp = STATS[type]["max_hp"]
	hp = max_hp
	remaining_mp = movement_points()

func unit_name() -> String:
	return STATS[type]["name"]

func movement_points() -> int:
	return STATS[type]["mp"]

func atk() -> int:
	return STATS[type]["atk"]

func counter_atk() -> int:
	return STATS[type]["counter"]

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

	# Losanges sur la case : blanc = sélectionnée, rouge = attaquable
	var hw := GameMap.TILE_W * 0.5 - 3.0
	var hh := GameMap.TILE_H * 0.5 - 1.5
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

func _draw_cell_outline(hw: float, hh: float, color: Color, width: float) -> void:
	draw_polyline(PackedVector2Array([
		Vector2(0, -hh), Vector2(hw, 0), Vector2(0, hh), Vector2(-hw, 0), Vector2(0, -hh),
	]), color, width)
