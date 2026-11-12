extends RefCounted
const Catalog = preload("res://scripts/content/catalog.gd")
const Snapshot = preload("res://scripts/game/session/runtime_snapshot.gd")

static func mount(arena: Node2D, mode: String) -> void:
	# This function is reached before any inherited fixture _ready is invoked.
	arena.set_physics_process(false)
	arena.set_process(false)
	var session = arena.session_context.coordinator
	arena.state = session.state
	arena.inventory = session.services.inventory
	arena.config = Catalog.read("data/combat.json")
	arena.weapons = Catalog.weapons()
	arena.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arena.y_sort_enabled = true
	InputBindings.install()
	if mode in ["combat", "enemy"]:
		await mount_minimal(arena, mode)
		return
	var is_base := mode in ["base", "management"]
	arena.exploration = session.services.exploration
	arena.ai_config = Catalog.read("data/enemies.json")
	arena.add_child(arena.darkness)
	if is_base:
		arena.building = session.services.building
		arena.cycle = session.services.cycle
	else:
		arena.services = session.services
		arena.cycle = session.services.cycle
		arena.logical_catalog = Catalog.maps()
		arena.catalog = arena.exploration.maps
		arena.navigation = load("res://scripts/world/grid/projected_navigation.gd").new()
		arena.navigation.projection = arena.projection
		arena.station = Vector2(-10000, -10000)
	arena.player = load("res://scripts/base/actors/base_player.gd" if is_base else "res://scripts/game/player_actor.gd").new()
	arena.player.arena = arena
	arena.add_child(arena.player)
	arena.player.set_physics_process(false)
	arena.hud = load("res://scripts/game/session/base_session_hud.gd" if is_base else "res://scripts/game/session/map_session_hud.gd").new()
	arena.hud.arena = arena
	arena.add_child(arena.hud)
	if is_base:
		mount_base(arena, mode == "management")
		mount_encounters(arena)
		if arena.state.phase == "night" and arena.state.cycle.night.get("mode", "") == "manual": arena.start_wave()
	else:
		arena.loaded_session = str(arena.state.expedition.id)
		arena.loaded_map = arena.state.expedition.map_id
		for record: Dictionary in arena.state.expedition.maps[arena.loaded_map].enemies.values(): arena.spawn_enemy(record)
		await arena.rebuild_map()
		arena.ready_world = true
	# Deferred tactical and progression child creation must complete before restoration.
	await arena.get_tree().process_frame
	Snapshot.restore(arena, arena.state)
	arena.player.inventory_movement_locked = false
	arena.player.progression_panel.close()
	if is_base: arena.rebuild_base_navigation()
	arena.player.set_physics_process(true)
	arena.set_physics_process(true)
	arena.set_process(true)
	arena.session_context.ready = true

static func mount_base(arena: Node2D, management: bool) -> void:
	if not arena.state.base.has("shield"):
		var config: Dictionary = Catalog.read("scripts/game/session/session_config.json")
		arena.state.base.shield = {"energy": config.shield_initial_energy, "capacity": config.shield_capacity}
	var ui := CanvasLayer.new()
	arena.add_child(ui)
	arena.status_label = Label.new()
	arena.status_label.position = Vector2(20, 70)
	arena.status_label.text = "B 基地经营 · 点击设施 · Tab 背包 · T 天赋 · J 任务"
	ui.add_child(arena.status_label)
	for id: String in arena.state.base.buildings:
		var b: Dictionary = arena.state.base.buildings[id]
		var actor = load("res://scripts/base/actors/defense_fixture.gd").new()
		actor.arena = arena; actor.id = id; actor.kind = b.type
		var size: Array = arena.building.config.types[b.type].size
		actor.logical_rect = Rect2(Vector2(b.cell[0], b.cell[1]) * 48, Vector2(size[0], size[1]) * 48)
		actor.position = arena.grid.logical_to_world(actor.logical_rect.get_center())
		arena.add_child(actor); arena.fixtures.append(actor)
		if b.type == "warehouse": arena.station = actor.position
	var shield = load("res://scripts/base/actors/defense_fixture.gd").new()
	shield.arena = arena; shield.kind = "shield"; shield.logical_rect = Rect2(1143, 405, 18, 130)
	shield.position = arena.grid.logical_to_world(arena.gate_logical)
	arena.add_child(shield); arena.fixtures.append(shield)
	arena.sync_perimeter()
	for i in arena.state.base.residents.size():
		var resident = load("res://scripts/base/actors/resident_actor.gd").new()
		resident.arena = arena; resident.id = arena.state.base.residents[i].id
		resident.position = arena.grid.logical_to_world(Vector2(900, 430 + i * 80)); resident.post = resident.position
		arena.add_child(resident); arena.residents.append(resident)
	arena.player.position = arena.grid.logical_to_world(Vector2(850, 470))
	if management:
		arena.management = BaseManagementUI.new()
		arena.management.bind_context(arena.state, arena.session_context.coordinator.services)
		# Component compatibility augmentation must not override the official directory.
		arena.inventory.definitions = Catalog.items()
		arena.add_child(arena.management)
		arena.management.root_panel.hide()
		arena.management.world_changed.connect(arena.sync_layout)
		arena.management.world_changed.connect(func(): arena.session_context.coordinator.request_save())
		arena.management.placement_requested.connect(func(type, id): arena.placing_type = type; arena.moving_id = id)
		# Match current actors so the first _process does not rebuild restored fixtures.
		for id: String in arena.state.base.buildings: arena.layout_signature += id + str(arena.state.base.buildings[id].cell)
		arena.bind_inventory_player()

static func mount_encounters(arena: Node2D) -> void:
	var script := preload("res://scripts/game/session/survivor_encounter.gd")
	for child in arena.get_children():
		if child.get_script() == script: child.hide(); child.queue_free()
	var here: String = arena.state.expedition.map_id if arena.state.expedition.get("active",false) else "base"
	for candidate: Dictionary in arena.state.world.get("recruitment",{}).get("candidates",{}).values():
		if candidate.map_id != here or candidate.accepted: continue
		var actor := Node2D.new()
		actor.set_script(script)
		actor.arena = arena; actor.candidate_id = candidate.id
		actor.position = GridProjection.new().logical_to_world(Vector2(candidate.logical_position[0],candidate.logical_position[1]))
		arena.add_child(actor)

static func mount_minimal(arena: Node2D, mode: String) -> void:
	if mode == "enemy":
		arena.exploration = arena.session_context.coordinator.services.exploration
		arena.ai_config = Catalog.read("data/enemies.json")
		arena.add_child(arena.darkness)
	if not arena.state.world.has("combat_targets"): arena.state.world.combat_targets = {}
	arena.player = load("res://scripts/game/player_actor.gd").new()
	arena.player.arena = arena; arena.add_child(arena.player)
	arena.hud = load("res://scripts/ui/combat_hud.gd").new()
	arena.hud.arena = arena; arena.add_child(arena.hud)
	await arena.get_tree().process_frame
	if mode == "enemy": arena.rebuild_navigation()
	Snapshot.restore(arena, arena.state)
	arena.set_physics_process(true); arena.set_process(true)
	arena.session_context.ready = true
