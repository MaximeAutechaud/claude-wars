class_name Boss

# Mécaniques de boss (décision 10), partagées entre un boss chef d'armée
# (ex. le Fossoyeur à la tête de l'armée IA — le tuer met fin au tableau)
# et un éventuel boss de camp neutre. L'état vit sur l'unité elle-même
# (doom_cells / doom_armed / boss_phase), les appelants fournissent la
# liste d'alliés sacrifiables et déclenchent act_doom à leur tour.

const DOOM_RANGE := 4       # portée de ciblage de la malédiction
const DOOM_RADIUS := 1      # rayon de la zone maudite
const DOOM_DAMAGE := 5      # dégâts sur toute unité restée dans la zone
const SACRIFICE_HEAL := 6
const ENRAGE_ATK := 1

# Paliers de PV à 66 % / 33 % : le boss sacrifie le plus faible des alliés
# fournis (soin + enrage). Sans allié restant, il s'enrage quand même.
static func phase_check(boss: Unit, allies: Array[Unit], units_layer: UnitsLayer) -> void:
	var phase := 0
	if boss.hp <= boss.max_hp / 3.0:
		phase = 2
	elif boss.hp <= boss.max_hp * 2.0 / 3.0:
		phase = 1
	if phase <= boss.boss_phase:
		return
	boss.boss_phase = phase
	boss.gain_atk(ENRAGE_ATK)
	var weakest: Unit = null
	for u: Unit in allies:
		if is_instance_valid(u) and not u.is_queued_for_deletion() \
				and (weakest == null or u.hp < weakest.hp):
			weakest = u
	if weakest != null:
		print("%s sacrifie %s ! (+%d PV, +%d atk)"
				% [boss.unit_name(), weakest.unit_name(), SACRIFICE_HEAL, ENRAGE_ATK])
		weakest.queue_free()
		units_layer._on_kill(weakest, boss)
		boss.hp = mini(boss.hp + SACRIFICE_HEAL, boss.max_hp)
	else:
		print("%s s'enrage ! (+%d atk)" % [boss.unit_name(), ENRAGE_ATK])
	boss.queue_redraw()
	units_layer.boss_event.emit(boss.cell, "Sacrifice !")

# La malédiction, un tour sur deux : frappe si armée au tour précédent,
# sinon télégraphe une nouvelle zone. Action gratuite (le boss agit ensuite).
static func act_doom(boss: Unit, units_layer: UnitsLayer, map: GameMap) -> void:
	if boss.doom_armed:
		resolve_doom(boss, units_layer)
	else:
		telegraph_doom(boss, units_layer, map)

# Marque la zone qui sera frappée au prochain tour du boss : le meilleur
# groupe d'ennemis (ni son équipe, ni les neutres) à portée. Combat
# déterministe → le joueur voit la zone pendant tout son tour et peut
# l'évacuer (pattern télégraphié).
static func telegraph_doom(boss: Unit, units_layer: UnitsLayer, map: GameMap) -> void:
	var best := Vector2i(-99, -99)
	var best_hits := 0
	for center in Pathfinder.cells_in_range(boss.cell, DOOM_RANGE):
		if not map.is_in_bounds(center):
			continue
		var hits := 0
		for cell in Pathfinder.cells_in_range(center, DOOM_RADIUS):
			var u := units_layer.get_unit_at(cell)
			if u != null and u.team != boss.team and u.team != Unit.NEUTRAL_TEAM:
				hits += 1
		if hits > best_hits:
			best_hits = hits
			best = center
	if best_hits == 0:
		return
	var cells: Array[Vector2i] = []
	for cell in Pathfinder.cells_in_range(best, DOOM_RADIUS):
		if map.is_in_bounds(cell):
			cells.append(cell)
	boss.doom_cells = cells
	boss.doom_armed = true
	print("%s prépare une malédiction !" % boss.unit_name())
	units_layer.boss_event.emit(best, "Malédiction !")
	units_layer.queue_redraw()

# La malédiction frappe tout ce qui est resté dans la zone — les propres
# troupes du boss comprises (le Fossoyeur ne s'embarrasse pas des siens),
# boss excepté.
static func resolve_doom(boss: Unit, units_layer: UnitsLayer) -> void:
	for cell: Vector2i in boss.doom_cells:
		var u := units_layer.get_unit_at(cell)
		if u == null or u == boss:
			continue
		u.hp -= DOOM_DAMAGE
		u.queue_redraw()
		print("La malédiction frappe %s : -%d PV → %d PV"
				% [u.unit_name(), DOOM_DAMAGE, u.hp])
		if u.hp <= 0:
			u.queue_free()
			units_layer._on_kill(u, boss)
	boss.doom_cells = []
	boss.doom_armed = false
	units_layer.boss_event.emit(boss.cell, "La malédiction frappe !")
	units_layer.queue_redraw()

# Annule une malédiction en préparation (boss de camp qui se rendort)
static func clear_doom(boss: Unit, units_layer: UnitsLayer) -> void:
	boss.doom_cells = []
	boss.doom_armed = false
	units_layer.queue_redraw()
