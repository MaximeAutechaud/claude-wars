class_name SaveGame

# ── Sauvegarde / chargement (décision 15) ────────────────────────────────────
# Une seule sauvegarde manuelle, en JSON pur dans user:// — mêmes contraintes
# que le format de scénario : données portables, aucune référence de classe.
# La sauvegarde capture l'état complet du tableau en cours de tour joueur :
# unités (des deux camps), camps de bandits, villages, brouillard exploré,
# compteur de tours et alerte de l'armée IA.
#
# Flux de chargement : l'écran d'accueil dépose la sauvegarde lue dans
# `pending`, puis charge main.tscn ; main._ready trouve `pending` non vide,
# purge les unités du scénario et applique la sauvegarde à la place.

const SAVE_PATH := "user://save.json"
const VERSION := 1

# Sauvegarde en attente d'application par main._ready (vide = partie neuve)
static var pending: Dictionary = {}

static func has_save(path := SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)

static func write(data: Dictionary, path := SAVE_PATH) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))

# Sauvegarde lue, ou {} si absente/illisible
static func read(path := SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

static func erase(path := SAVE_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

# ── Capture ──────────────────────────────────────────────────────────────────

# Photographie l'état complet de la partie (à appeler pendant le tour joueur)
static func capture(main: Node2D) -> Dictionary:
	var units: Array = []
	for child in main.units_layer.get_children():
		if child is Unit and not child.is_queued_for_deletion() \
				and not (child as Unit).is_creep():
			units.append(_unit_to_dict(child as Unit))

	# Les creeps vivants sont sauvés dans leur camp (pour retrouver
	# l'appartenance au chargement), jamais dans la liste plate
	var camps: Array = []
	for camp: Dictionary in main.creeps.camps:
		var members: Array = []
		for u: Unit in main.creeps.alive_units(camp):
			members.append(_unit_to_dict(u))
		camps.append({
			"center": _cell_to_arr(camp["center"]),
			"prize": _type_id(camp["prize"]),
			"prize_veteran": camp["prize_veteran"],
			"owner": camp["owner"], "awake": camp["awake"],
			"hp_seen": camp["hp_seen"], "units": members,
		})

	var villages: Array = []
	for cell: Vector2i in main.villages.owners:
		villages.append([cell.x, cell.y, main.villages.owners[cell]])

	var explored: Array = []
	for cell: Vector2i in main.fog.explored:
		explored.append([cell.x, cell.y])

	return {
		"version": VERSION,
		"scenario": Scenario.CURRENT["name"],
		"turn": main.turn_count,
		"ai_alerted": main.ai_alerted,
		"units": units, "camps": camps,
		"villages": villages, "explored": explored,
	}

# ── Application ──────────────────────────────────────────────────────────────

# Remplace l'état spawné par le scénario par celui de la sauvegarde.
# À appeler depuis main._ready, à la place de creeps.spawn_camps.
static func apply(main: Node2D, data: Dictionary) -> void:
	var units_layer: UnitsLayer = main.units_layer

	# Purge des unités de départ du scénario (sorties de l'arbre tout de
	# suite : get_unit_at ne doit plus les voir)
	for child in units_layer.get_children():
		if child is Unit:
			units_layer.remove_child(child)
			child.queue_free()

	main.turn_count = int(data["turn"])
	main.ai_alerted = bool(data["ai_alerted"])

	var owners: Dictionary = {}
	for v: Array in data["villages"]:
		owners[Vector2i(int(v[0]), int(v[1]))] = int(v[2])
	main.villages.owners = owners
	main.villages.queue_redraw()

	main.fog.explored.clear()
	for c: Array in data["explored"]:
		main.fog.explored[Vector2i(int(c[0]), int(c[1]))] = true

	for udata: Dictionary in data["units"]:
		_unit_from_dict(units_layer, udata)

	main.creeps.camps.clear()
	for cdata: Dictionary in data["camps"]:
		var camp := {
			"center": _arr_to_cell(cdata["center"]),
			"prize": Unit.TYPE_BY_ID[cdata["prize"]],
			"prize_veteran": bool(cdata["prize_veteran"]),
			"owner": int(cdata["owner"]), "awake": bool(cdata["awake"]),
			"hp_seen": int(cdata["hp_seen"]), "units": [],
		}
		for udata: Dictionary in cdata["units"]:
			(camp["units"] as Array).append(_unit_from_dict(units_layer, udata))
		main.creeps.camps.append(camp)
	main.creeps.queue_redraw()

# ── Sérialisation d'une unité ────────────────────────────────────────────────

static func _unit_to_dict(u: Unit) -> Dictionary:
	var doom: Array = []
	for cell in u.doom_cells:
		doom.append([cell.x, cell.y])
	return {
		"type": _type_id(u.type), "team": u.team, "cell": _cell_to_arr(u.cell),
		"hp": u.hp, "max_hp": u.max_hp,
		"has_moved": u.has_moved, "remaining_mp": u.remaining_mp,
		"home_cell": _cell_to_arr(u.home_cell), "name": u.display_name,
		"kills": u.kills, "veteran": u.veteran, "defending": u.defending,
		"atk_bonus": u._atk_bonus, "counter_bonus": u._counter_bonus,
		"xp": u.xp, "level": u.level, "pending_levelups": u.pending_levelups,
		"spells": u.learned_spells, "cooldowns": u.cooldowns,
		"has_cast": u.has_cast, "temp_atk": u.temp_atk_bonus,
		"boss_phase": u.boss_phase, "doom_armed": u.doom_armed,
		"doom_cells": doom, "scale": u.scale.x,
	}

# Les bonus (vétérance, niveaux, enrage de boss) sont déjà comptés dans
# atk_bonus/max_hp sauvés : on restaure les champs tels quels, sans rejouer
# les promotions.
static func _unit_from_dict(units_layer: UnitsLayer, d: Dictionary) -> Unit:
	var u := units_layer.spawn(_arr_to_cell(d["cell"]),
			int(d["team"]), Unit.TYPE_BY_ID[d["type"]])
	u.max_hp = int(d["max_hp"])
	u.hp = int(d["hp"])
	u.has_moved = bool(d["has_moved"])
	u.remaining_mp = int(d["remaining_mp"])
	u.home_cell = _arr_to_cell(d["home_cell"])
	u.display_name = str(d["name"])
	u.kills = int(d["kills"])
	u.veteran = bool(d["veteran"])
	u.defending = bool(d["defending"])
	u._atk_bonus = int(d["atk_bonus"])
	u._counter_bonus = int(d["counter_bonus"])
	u.xp = int(d["xp"])
	u.level = int(d["level"])
	u.pending_levelups = int(d["pending_levelups"])
	var spells: Array[String] = []
	for id in d["spells"]:
		spells.append(str(id))
	u.learned_spells = spells
	u.cooldowns.clear()
	for id: String in d["cooldowns"]:
		u.cooldowns[id] = int(d["cooldowns"][id])
	u.has_cast = bool(d["has_cast"])
	u.temp_atk_bonus = int(d["temp_atk"])
	u.boss_phase = int(d["boss_phase"])
	u.doom_armed = bool(d["doom_armed"])
	var doom: Array[Vector2i] = []
	for c in d["doom_cells"]:
		doom.append(_arr_to_cell(c))
	u.doom_cells = doom
	var s := float(d["scale"])
	u.scale = Vector2(s, s)
	u.queue_redraw()
	return u

# ── Helpers JSON (Vector2i <-> [x, y], enum <-> string) ──────────────────────

static func _cell_to_arr(cell: Vector2i) -> Array:
	return [cell.x, cell.y]

static func _arr_to_cell(a: Array) -> Vector2i:
	return Vector2i(int(a[0]), int(a[1]))

static func _type_id(type: int) -> String:
	for id: String in Unit.TYPE_BY_ID:
		if int(Unit.TYPE_BY_ID[id]) == int(type):
			return id
	return "infantry"
