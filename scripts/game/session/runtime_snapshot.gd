extends RefCounted
# Explicit runtime fields; no Node, Resource, Variant object or double projection.
const PLAYER_FIELDS = ["slot", "cooldown", "bloom", "heals", "sprint_latched", "selected_charge_battery", "selected_charge_target"]
const TACTICAL_FIELDS = ["enabled", "mode", "selected_weapon", "flight", "pulse", "map_context"]
const TACTICAL_VECTORS = ["flight_start", "destination", "landing"]
const BULLET = "res://scripts/game/projectile.gd"
const BASE_BULLET = "res://scripts/base/actors/base_projectile.gd"

static func vector(point: Vector2) -> Array: return [point.x, point.y]
static func from_array(point: Array) -> Vector2: return Vector2(point[0], point[1])
static func fields(object: Object, names: Array) -> Dictionary:
	var result := {}
	for key: String in names:
		var value: Variant = object.get(key)
		result[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	return result
static func apply_fields(object: Object, record: Dictionary) -> void:
	for key: String in record: object.set(key, record[key])
static func has_property(object: Object, name: String) -> bool:
	for property: Dictionary in object.get_property_list():
		if property.name == name: return true
	return false

static func capture(arena: Node2D, state: Dictionary) -> void:
	var player: CharacterBody2D = arena.player
	player.growth_bridge.observe(state, arena.inventory)
	var runtime := {"coordinate_version": "diamond_world_v1", "player": fields(player, PLAYER_FIELDS), "projectiles": [], "enemies": {}, "residents": {}, "fixtures": {}}
	runtime.player.position = vector(player.position)
	runtime.player.velocity = vector(player.velocity)
	runtime.player.tactical = fields(player.tactical, TACTICAL_FIELDS)
	for key: String in TACTICAL_VECTORS: runtime.player.tactical[key] = vector(player.tactical.get(key))
	for enemy in arena.targets:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion(): continue
		runtime.enemies[enemy.enemy_id] = {"position": vector(enemy.position), "velocity": vector(enemy.velocity), "push": vector(enemy.push), "home": vector(enemy.home)}
	if has_property(arena, "residents"):
		for resident in arena.residents:
			var record := fields(resident, ["cooldown", "invulnerable", "returning"])
			record.position = vector(resident.position)
			record.post = vector(resident.post)
			runtime.residents[resident.id] = record
		for fixture in arena.fixtures:
			runtime.fixtures[fixture.id if fixture.kind != "shield" else "shield"] = {"cooldown": fixture.cooldown}
	for child in arena.get_children():
		if child.is_queued_for_deletion() or child.get_script() == null: continue
		var path: String = child.get_script().resource_path
		if path not in [BULLET, BASE_BULLET]: continue
		var record := fields(child, ["damage", "hostile", "speed", "lifetime", "attack"] if path == BULLET else ["damage", "hostile", "life"])
		record.script = path
		record.position = vector(child.position)
		record.direction = vector(child.direction)
		runtime.projectiles.append(record)
	state.session.runtime = runtime

static func restore(arena: Node2D, state: Dictionary) -> void:
	var runtime: Dictionary = state.session.get("runtime", {})
	if runtime.is_empty(): return
	var record: Dictionary = runtime.player.duplicate(true)
	arena.player.position = from_array(record.position)
	arena.player.velocity = from_array(record.velocity)
	var tactical: Dictionary = record.tactical
	record.erase("position"); record.erase("velocity"); record.erase("tactical")
	apply_fields(arena.player, record)
	for key: String in TACTICAL_VECTORS:
		arena.player.tactical.set(key, from_array(tactical[key]))
		tactical.erase(key)
	apply_fields(arena.player.tactical, tactical)
	for enemy in arena.targets:
		var saved: Dictionary = runtime.enemies.get(enemy.enemy_id, {})
		for key: String in saved: enemy.set(key, from_array(saved[key]))
	if has_property(arena, "residents"):
		for resident in arena.residents:
			var saved: Dictionary = runtime.residents.get(resident.id, {}).duplicate(true)
			if saved.is_empty(): continue
			resident.position = from_array(saved.position)
			resident.post = from_array(saved.post)
			saved.erase("position"); saved.erase("post")
			apply_fields(resident, saved)
		for fixture in arena.fixtures:
			fixture.cooldown = runtime.fixtures.get(fixture.id if fixture.kind != "shield" else "shield", {}).get("cooldown", 0.0)
	for source: Dictionary in runtime.projectiles:
		if source.script not in [BULLET, BASE_BULLET]: continue
		var projectile: Node2D = load(source.script).new()
		projectile.arena = arena
		projectile.position = from_array(source.position)
		projectile.direction = from_array(source.direction)
		var saved := source.duplicate(true)
		for key in ["script", "position", "direction"]: saved.erase(key)
		apply_fields(projectile, saved)
		arena.add_child(projectile)
