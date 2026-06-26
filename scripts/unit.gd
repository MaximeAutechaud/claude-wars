class_name Unit
extends Node2D

const TEAM_COLORS := [Color(0.25, 0.55, 1.0), Color(1.0, 0.30, 0.30)]

@export var team: int = 0
@export var movement_points: int = 3

var cell: Vector2i = Vector2i.ZERO
var has_moved    := false
var selected     := false
var attackable   := false
var remaining_mp := 0   # initialisé depuis movement_points dans units_layer

var hp:     int = 10
var max_hp: int = 10

func _draw() -> void:
	var col: Color = TEAM_COLORS[team]
	if has_moved:
		col = col.darkened(0.45)
	draw_circle(Vector2.ZERO, 11.0, col)

	var outline_w := 2.5 if selected else 1.5
	draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 24, Color.WHITE, outline_w)

	# Anneau rouge : cette unité peut être attaquée maintenant
	if attackable:
		draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 24, Color(1.0, 0.15, 0.15), 2.5)

	# Barre de PV sous le cercle
	var bw := 22.0
	var bh := 3.0
	var by := 14.0
	draw_rect(Rect2(-bw * 0.5, by, bw, bh), Color(0.35, 0.0, 0.0))
	draw_rect(Rect2(-bw * 0.5, by, bw * hp / float(max_hp), bh), Color(0.15, 0.85, 0.2))
