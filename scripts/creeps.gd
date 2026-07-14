class_name Creeps
extends Node2D

# Camps de bandits neutres (équipe 2) : dormants tant qu'on ne les approche
# pas, agressifs mais leashés à leur camp une fois réveillés. Chaque camp
# garde un prisonnier prédéfini, visible sur la carte : vaincre le camp le
# fait rallier le camp du dernier coup porté, et le camp devient un point
# de repos allié (+REST_HEAL PV/tour, comme un village).

const WAKE_RADIUS := 2    # un camp se réveille si une unité finit à <= 2 cases
const LEASH_RADIUS := 3   # distance max au centre du camp une fois réveillé
const REST_HEAL := 3      # soin d'un camp vaincu (aligné sur Villages.VILLAGE_HEAL)

const ACT_DELAY := 0.4    # pause visuelle entre deux actions de creep

signal camp_cleared(center: Vector2i, prize: Unit)

# Contenu des camps : deux petits camps sur les flancs, un gros au centre
# (avec un chef) qui garde le village central. "prize" = le prisonnier.
const CAMPS: Array = [
	{ "center": Vector2i(11, 1), "prize": Unit.Type.INFANTRY, "units": [
		{ "cell": Vector2i(11, 1), "type": Unit.Type.INFANTRY },
		{ "cell": Vector2i(11, 2), "type": Unit.Type.ARCHER },
	] },
	{ "center": Vector2i(1, 8), "prize": Unit.Type.ARCHER, "units": [
		{ "cell": Vector2i(1, 8), "type": Unit.Type.INFANTRY },
		{ "cell": Vector2i(2, 9), "type": Unit.Type.ARCHER },
	] },
	{ "center": Vector2i(5, 4), "prize": Unit.Type.TANK, "units": [
		{ "cell": Vector2i(5, 4), "type": Unit.Type.TANK, "chief": true },
		{ "cell": Vector2i(5, 5), "type": Unit.Type.INFANTRY },
		{ "cell": Vector2i(6, 5), "type": Unit.Type.ARCHER },
	] },
]

@onready var map: GameMap = $"../GameMap"
@onready var fog: Fog = get_node_or_null("../Fog")

# camp : { center, prize, owner, awake, hp_seen, units: Array[Unit] }
# owner = -1 tant que le camp tient, puis l'équipe qui l'a vaincu (repos).
# hp_seen = total de PV constaté au dernier tour neutre — toute baisse
# signifie que le camp a été attaqué (même à distance) et doit se réveiller.
var camps: Array = []

# Appelé par main._ready (l'ordre des _ready des nœuds frères n'est pas fiable)
func spawn_camps(units_layer: UnitsLayer) -> void:
	for def: Dictionary in CAMPS:
		var camp := { "center": def["center"], "prize": def["prize"],
				"owner": -1, "awake": false, "hp_seen": 0, "units": [] }
		for udef: Dictionary in def["units"]:
			var u := units_layer.spawn(udef["cell"], Unit.NEUTRAL_TEAM, udef["type"])
			u.home_cell = udef["cell"]
			if udef.get("chief", false):
				u.display_name = "Chef bandit"
				u.scale = Vector2(1.18, 1.18)
			else:
				u.display_name = "Bandit — " + Unit.STATS[udef["type"]]["name"]
			camp["hp_seen"] += u.max_hp
			camp["units"].append(u)
		camps.append(camp)
	queue_redraw()

# Camp de repos : équipe propriétaire du camp vaincu en `cell`, sinon -2
func rest_owner_of(cell: Vector2i) -> int:
	for camp: Dictionary in camps:
		if camp["center"] == cell and int(camp["owner"]) >= 0:
			return camp["owner"]
	return -2

# Appelé sur chaque kill (signal UnitsLayer.unit_killed) : si le dernier
# creep d'un camp tombe, le prisonnier rallie le camp du tueur et le camp
# devient un point de repos.
func on_unit_killed(victim: Unit, killer: Unit, units_layer: UnitsLayer) -> void:
	if not victim.is_creep() or killer.team == Unit.NEUTRAL_TEAM:
		return
	for camp: Dictionary in camps:
		if not (camp["units"] as Array).has(victim) or int(camp["owner"]) >= 0:
			continue
		if not alive_units(camp).is_empty():
			return
		camp["owner"] = killer.team
		camp["awake"] = false
		var cell := _prize_cell(camp, units_layer)
		var prize := units_layer.spawn(cell, killer.team, camp["prize"])
		prize.has_moved = true
		prize.queue_redraw()
		print("Camp vaincu ! Le prisonnier (%s) rejoint l'équipe %d"
				% [prize.unit_name(), killer.team])
		queue_redraw()
		camp_cleared.emit(camp["center"], prize)
		return

# Case du prisonnier : le centre du camp s'il est libre et praticable,
# sinon la première case voisine qui l'est
func _prize_cell(camp: Dictionary, units_layer: UnitsLayer) -> Vector2i:
	var candidates: Array[Vector2i] = [camp["center"]]
	candidates.append_array(Pathfinder.get_neighbors(camp["center"]))
	var costs: Dictionary = Unit.STATS[camp["prize"]]["costs"]
	for cell in candidates:
		if map.is_in_bounds(cell) and units_layer.get_unit_at(cell) == null \
				and costs.get(map.get_terrain(cell), 99) < 99:
			return cell
	return camp["center"]

func alive_units(camp: Dictionary) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in camp["units"]:
		if is_instance_valid(u) and not u.is_queued_for_deletion():
			out.append(u)
	return out

# Tour neutre, joué après celui de l'IA. `should_stop` (→ bool) est
# interrogé après chaque action pour s'arrêter dès la fin de partie.
func run_turn(units_layer: UnitsLayer, should_stop: Callable) -> void:
	units_layer.reset_team(Unit.NEUTRAL_TEAM)
	for camp: Dictionary in camps:
		var members := alive_units(camp)
		if members.is_empty():
			continue
		var hp_now := 0
		for u: Unit in members:
			hp_now += u.hp
		if not camp["awake"] \
				and (hp_now < int(camp["hp_seen"]) or _enemy_near(members, units_layer)):
			camp["awake"] = true
			print("Un camp de creeps se réveille !")
			queue_redraw()
		camp["hp_seen"] = hp_now
		if not camp["awake"]:
			continue
		for u: Unit in members:
			if not is_instance_valid(u):
				continue
			var acted := _act_creep(u, camp, units_layer)
			if should_stop.call():
				return
			if acted:
				await get_tree().create_timer(ACT_DELAY).timeout
		_maybe_sleep(camp, units_layer)
	queue_redraw()

# Une unité non neutre finit son tour à portée de réveil d'un creep du camp ?
func _enemy_near(members: Array[Unit], units_layer: UnitsLayer) -> bool:
	for u: Unit in members:
		if _nearest_enemy(u.cell, units_layer, WAKE_RADIUS) != null:
			return true
	return false

# Fait agir un creep réveillé. Renvoie true si une action visible a eu lieu.
func _act_creep(u: Unit, camp: Dictionary, units_layer: UnitsLayer) -> bool:
	# Attaque sur place si une cible est déjà à portée
	var in_range := units_layer.get_enemies_in_range(u)
	if not in_range.is_empty():
		units_layer.do_combat(u, AIPlayer.pick_attack_target(in_range))
		if is_instance_valid(u):
			u.has_moved = true
			u.queue_redraw()
		return true

	# Cases atteignables qui restent dans le leash du camp
	var reachable := Pathfinder.get_reachable(u.cell, u.remaining_mp, map, u.type)
	var leashed: Dictionary = {}
	for cell: Vector2i in reachable:
		if Pathfinder.distance(cell, camp["center"]) <= LEASH_RADIUS \
				and (cell == u.cell or units_layer.get_unit_at(cell) == null):
			leashed[cell] = reachable[cell]

	var target := _nearest_enemy(u.cell, units_layer)
	var dest := u.cell
	if target != null and Pathfinder.distance(target.cell, camp["center"]) \
			<= LEASH_RADIUS + u.attack_range():
		dest = AIPlayer.best_move_towards(u, target.cell, leashed, units_layer)
	else:
		# Personne à défier : retour vers la position d'origine
		var best_d := Pathfinder.distance(u.cell, u.home_cell)
		for cell: Vector2i in leashed:
			var d := Pathfinder.distance(cell, u.home_cell)
			if d < best_d:
				best_d = d
				dest = cell

	var acted := dest != u.cell
	if acted:
		units_layer.move_unit(u, dest, leashed.get(dest, 0))

	# Attaque après déplacement
	if is_instance_valid(u):
		var after := units_layer.get_enemies_in_range(u)
		if not after.is_empty():
			units_layer.do_combat(u, AIPlayer.pick_attack_target(after))
			acted = true
		if is_instance_valid(u):
			u.has_moved = true
			u.queue_redraw()
	return acted

# Le camp se rendort quand tous ses creeps sont rentrés et que personne ne rôde
func _maybe_sleep(camp: Dictionary, units_layer: UnitsLayer) -> void:
	for u: Unit in alive_units(camp):
		if u.cell != u.home_cell \
				or _nearest_enemy(u.cell, units_layer, WAKE_RADIUS) != null:
			return
	camp["awake"] = false
	print("Un camp de creeps se rendort.")
	queue_redraw()

# Unité non neutre la plus proche de `cell` (à max_dist au plus), ou null
func _nearest_enemy(cell: Vector2i, units_layer: UnitsLayer, max_dist := 9999) -> Unit:
	var best: Unit = null
	var best_d := max_dist + 1
	for child in units_layer.get_children():
		if not (child is Unit) or child.is_queued_for_deletion():
			continue
		var u := child as Unit
		if u.team == Unit.NEUTRAL_TEAM:
			continue
		var d := Pathfinder.distance(cell, u.cell)
		if d < best_d:
			best_d = d
			best = u
	return best

func _draw() -> void:
	var font := ThemeDB.fallback_font
	for camp: Dictionary in camps:
		# Le camp (fanion, cage, sommeil) n'apparaît qu'une fois exploré
		if fog and not fog.is_explored(camp["center"]):
			continue
		var p := to_local(map.to_global(map.map_to_local(camp["center"])))
		var owner := int(camp["owner"])
		if owner >= 0:
			# Camp de repos : fanion à la couleur du vainqueur
			_draw_flag(p, Unit.TEAM_COLORS[owner])
			continue
		if alive_units(camp).is_empty():
			continue
		_draw_flag(p, Unit.TEAM_COLORS[Unit.NEUTRAL_TEAM])

		# Prisonnier en cage : mini-sprite du type promis, derrière des barreaux
		var tex: Texture2D = Unit.TEXTURES[camp["prize"]][0]
		var r := Rect2(p + Vector2(8, -32), Vector2(18, 18))
		draw_texture_rect(tex, r, false, Color(0.82, 0.82, 0.82))
		var bar_col := Color(0.24, 0.19, 0.13)
		for i in 4:
			var x: float = r.position.x + 1.0 + i * (r.size.x - 2.0) / 3.0
			draw_line(Vector2(x, r.position.y - 1), Vector2(x, r.end.y + 1), bar_col, 1.5)
		draw_rect(r.grow(1.5), bar_col, false, 1.5)

		if not camp["awake"]:
			draw_string(font, p + Vector2(-28, -24), "z z",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.88, 0.88, 0.98, 0.9))

func _draw_flag(p: Vector2, color: Color) -> void:
	draw_line(p + Vector2(-16, -20), p + Vector2(-16, -4), Color(0.35, 0.26, 0.15), 2.0)
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(-16, -20), p + Vector2(-6, -16.5), p + Vector2(-16, -13),
	]), color)
