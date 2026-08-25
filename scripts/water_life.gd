class_name WaterLife
extends Node2D

# Décor animé d'un plan d'eau, façon case ressource de Civilization : un banc
# de poissons qui parcourt tout le bassin, des mouettes qui tournent au-dessus
# avec leur ombre portée, et des ondulations qui apparaissent çà et là.
#
# Le banc nage dans **tout** le plan d'eau, pas autour d'un point fixe : le
# nœud reçoit le contour du bassin (l'union des hexagones d'eau calculée par
# Rivers) et s'en sert pour rester dedans. Les positions sont donc exprimées
# dans le même repère que ce polygone — ce nœud doit rester à l'origine.
#
# Formes procédurales dessinées en code, en attendant d'éventuels sprites
# peints ; le code est structuré pour que le remplacement soit local à _draw.

# Contour du bassin, à renseigner avant l'entrée en scène
var poly: PackedVector2Array

@export var fish_count: int = 7
@export var gull_count: int = 2
@export var ripple_interval: float = 3.0

const LEADER_SPEED := 16.0
# Distance à laquelle le banc anticipe la berge pour amorcer son virage
const LOOKAHEAD := 28.0
const SCHOOL_SPREAD := 13.0

var _time := 0.0
var _rng := RandomNumberGenerator.new()

# Le banc suit un meneur invisible : c'est lui seul qui évite les berges, les
# poissons se contentent de tenir leur place par rapport à lui. Beaucoup plus
# simple qu'un évitement par poisson, et ça donne un banc qui se tient.
var _leader_pos := Vector2.ZERO
var _leader_heading := 0.0
var _wander := 0.0
var _wander_left := 0.0

var _fish: Array[Fish] = []
var _gulls: Array[Gull] = []
var _shadows: Array[BirdShadow] = []
var _gull_phase: Array[float] = []
var _center := Vector2.ZERO
var _orbit := 24.0
var _ripple: CPUParticles2D

static var _ripple_tex: Texture2D

func _ready() -> void:
	if poly.size() < 3:
		set_process(false)
		return
	_rng.randomize()
	var bounds := _bounds()
	_center = bounds.get_center()
	_orbit = clampf(minf(bounds.size.x, bounds.size.y) * 0.28, 14.0, 40.0)
	_leader_pos = _random_inside(_center)
	_leader_heading = _rng.randf_range(0.0, TAU)

	for i in fish_count:
		var f := Fish.new()
		# Réparti en quinconce derrière le meneur plutôt qu'au hasard : ça se
		# lit comme un banc et non comme des poissons qui vont au même endroit.
		var row := i / 2
		var side := 1.0 if i % 2 == 0 else -1.0
		f.offset = Vector2(-row * SCHOOL_SPREAD * 0.8,
				side * SCHOOL_SPREAD * (0.4 + 0.3 * row))
		f.phase = _rng.randf_range(0.0, TAU)
		f.position = _leader_pos + f.offset
		add_child(f)
		_fish.append(f)

	for i in gull_count:
		var shadow := BirdShadow.new()
		add_child(shadow)
		_shadows.append(shadow)
		var gull := Gull.new()
		add_child(gull)
		_gulls.append(gull)
		_gull_phase.append(TAU * i / maxf(gull_count, 1) + _rng.randf_range(0.0, 0.5))

	_ripple = CPUParticles2D.new()
	_ripple.texture = _get_ripple_texture()
	_ripple.amount = 1
	_ripple.one_shot = true
	_ripple.explosiveness = 1.0
	_ripple.lifetime = ripple_interval * 0.7
	_ripple.emitting = false
	_ripple.direction = Vector2.ZERO
	_ripple.spread = 0.0
	_ripple.initial_velocity_min = 0.0
	_ripple.initial_velocity_max = 0.0
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.1))
	scale_curve.add_point(Vector2(1.0, 1.6))
	_ripple.scale_amount_curve = scale_curve
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.45))
	ramp.set_color(1, Color(1, 1, 1, 0.0))
	_ripple.color_ramp = ramp
	add_child(_ripple)
	var timer := Timer.new()
	timer.wait_time = ripple_interval
	timer.autostart = true
	timer.timeout.connect(_pop_ripple)
	add_child(timer)

func _pop_ripple() -> void:
	_ripple.position = _random_inside(_leader_pos)
	_ripple.restart()

func _bounds() -> Rect2:
	var r := Rect2(poly[0], Vector2.ZERO)
	for p: Vector2 in poly:
		r = r.expand(p)
	return r

func _inside(p: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(p, poly)

# Tirage par rejet dans la boîte englobante ; `fallback` sert si le bassin est
# trop biscornu pour qu'on tombe dedans en quelques essais.
func _random_inside(fallback: Vector2) -> Vector2:
	var b := _bounds()
	for _i in 24:
		var p := Vector2(
			_rng.randf_range(b.position.x, b.end.x),
			_rng.randf_range(b.position.y, b.end.y))
		if _inside(p):
			return p
	return fallback

func _process(delta: float) -> void:
	_time += delta
	_move_leader(delta)
	var follow := clampf(delta * 3.0, 0.0, 1.0)
	for f in _fish:
		var target := _leader_pos + f.offset.rotated(_leader_heading)
		var previous := f.position
		f.position = f.position.lerp(target, follow)
		# Seul le meneur évite les berges ; un suiveur peut donc déborder sur le
		# sable quand le banc longe le bord ou coupe un virage. Dans ce cas on
		# le ramène vers le meneur, qui lui est toujours dans l'eau.
		if not _inside(f.position):
			f.position = previous.lerp(_leader_pos, follow)
		var step := f.position - previous
		if step.length_squared() > 0.01:
			f.rotation = step.angle()
		f.wiggle = sin(_time * 7.0 + f.phase) * 0.5
	for i in _gulls.size():
		var a := _time * 0.5 + _gull_phase[i]
		var flat := _center + Vector2(cos(a) * _orbit, sin(a) * _orbit * 0.45)
		var lift := 10.0 + 4.0 * sin(a * 2.0)
		var height_t := sin(a * 2.0) * 0.5 + 0.5
		_shadows[i].position = flat
		_shadows[i].scale = Vector2.ONE * lerpf(0.65, 1.0, height_t)
		_shadows[i].modulate.a = lerpf(0.5, 0.25, height_t)
		_gulls[i].position = flat + Vector2(0, -lift)
		_gulls[i].rotation = a + PI / 2.0

# Le meneur regarde devant lui : si le point visé sort du bassin, il cherche le
# plus petit écart de cap qui le ramène dedans, et fait demi-tour en dernier
# recours (cul-de-sac étroit).
func _move_leader(delta: float) -> void:
	var ahead := _leader_pos + Vector2.RIGHT.rotated(_leader_heading) * LOOKAHEAD
	if _inside(ahead):
		_wander_left -= delta
		if _wander_left <= 0.0:
			_wander = _rng.randf_range(-0.8, 0.8)
			_wander_left = _rng.randf_range(1.0, 3.0)
		_leader_heading += _wander * delta
	else:
		var turned := false
		for step: float in [0.5, -0.5, 1.0, -1.0, 1.7, -1.7, 2.4, -2.4]:
			var probe := _leader_pos + Vector2.RIGHT.rotated(_leader_heading + step) * LOOKAHEAD
			if _inside(probe):
				_leader_heading += step
				turned = true
				break
		if not turned:
			_leader_heading += PI
		_wander_left = 0.0
	var next := _leader_pos + Vector2.RIGHT.rotated(_leader_heading) * LEADER_SPEED * delta
	# Garde-fou : si malgré tout on sortait (bassin très étroit), on reste sur
	# place ce tick plutôt que de laisser le banc s'échapper sur la terre.
	if _inside(next):
		_leader_pos = next

# Silhouette de mouette en plein vol, à remplacer par une texture peinte le
# moment venu.
class Gull extends Node2D:
	func _draw() -> void:
		var col := Color(0.15, 0.15, 0.18, 0.9)
		var pts := PackedVector2Array([
			Vector2(-6, 0), Vector2(-2, -2.5), Vector2(0, 0),
			Vector2(2, -2.5), Vector2(6, 0),
		])
		draw_polyline(pts, col, 1.4, true)

# Ombre projetée sur l'eau, décalée sous la mouette — donne l'impression de
# hauteur sans avoir à simuler une vraie caméra 3D.
class BirdShadow extends Node2D:
	func _draw() -> void:
		var col := Color(0.02, 0.05, 0.05, 0.4)
		var pts := PackedVector2Array()
		var colors := PackedColorArray()
		for i in 16:
			var a := TAU * i / 16.0
			pts.append(Vector2(cos(a) * 4.0, sin(a) * 2.0))
			colors.append(col)
		draw_polygon(pts, colors)

# Petit poisson en silhouette, nageoire caudale frétillante. Orienté vers +x :
# WaterLife règle sa rotation sur sa direction de nage.
class Fish extends Node2D:
	var offset := Vector2.ZERO
	var phase := 0.0
	var wiggle := 0.0

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var col := Color(0.05, 0.14, 0.14, 0.55)
		draw_polygon(PackedVector2Array([
			Vector2(-3, 0), Vector2(1, -1.8), Vector2(3, 0), Vector2(1, 1.8),
		]), PackedColorArray([col, col, col, col]))
		var tail := wiggle * 2.5
		draw_polygon(PackedVector2Array([
			Vector2(-3, 0), Vector2(-6, -1.5 + tail), Vector2(-6, 1.5 + tail),
		]), PackedColorArray([col, col, col]))

# Texture d'anneau partagée pour l'ondulation : un dégradé radial
# transparent -> opaque -> transparent, généré en code (même technique que la
# fumée de cheminée dans villages.gd).
static func _get_ripple_texture() -> Texture2D:
	if _ripple_tex:
		return _ripple_tex
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.6), Color(1, 1, 1, 0.0),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 48
	tex.height = 48
	_ripple_tex = tex
	return _ripple_tex
