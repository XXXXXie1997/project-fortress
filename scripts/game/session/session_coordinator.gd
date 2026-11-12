extends RefCounted
signal committed(revision: int)
signal world_replaced
signal save_error(result: Dictionary)
const Bundle = preload("res://scripts/game/session/service_bundle.gd")
const Catalog = preload("res://scripts/content/catalog.gd")
var state: Dictionary = {}
var services: Dictionary = {}
var saver: SaveService
var slot := "slot_1"
var busy := false
var capture_runtime: Callable
var morning_queued_key := ""

func _init(directory := "user://saves") -> void:
	saver = SaveService.new(directory)
	services = Bundle.create()

func create_world(seed_value: int) -> Dictionary:
	if busy: return {"ok": false, "reason": "busy"}
	var result := Bundle.fresh(services, seed_value)
	if not result.ok: return result
	return install_choice(result.state)

func install_choice(candidate: Dictionary) -> Dictionary:
	var trial := candidate.duplicate(true)
	var migration := Catalog.migrate(trial)
	if not migration.ok: return migration
	var result: Dictionary = services.restart.persist_choice(saver, slot, {"ok": true, "state": trial})
	if not result.ok:
		save_error.emit(result)
		return result
	capture_runtime = Callable()
	state = result.state
	morning_queued_key = morning_key()
	world_replaced.emit()
	return {"ok": true}

func restore(morning := false) -> Dictionary:
	if busy: return {"ok": false, "reason": "busy"}
	var result: Dictionary = services.restart.restore(saver, slot, morning)
	if not result.ok: return result
	var migration := Catalog.migrate(result.state)
	if not migration.ok: return migration
	capture_runtime = Callable()
	state = result.state
	morning_queued_key = morning_key() if state.phase == "morning" else ""
	if state.expedition.has("catalog"): services.exploration.maps = state.expedition.catalog.duplicate(true)
	saver.resume_slot(slot)
	world_replaced.emit()
	return {"ok": true}

func transact(operation: Callable) -> Dictionary:
	if busy or state.is_empty(): return {"ok": false, "reason": "busy_or_no_world"}
	busy = true
	if capture_runtime.is_valid(): capture_runtime.call(state)
	var trial := state.duplicate(true)
	var result: Dictionary = operation.call(trial)
	if result.get("ok", false):
		services.recruitment.refresh(trial)
		if int(trial.get("threat",{}).get("stage",1)) >= 2: services.exploration.unlock_map(trial,"city")
		trial.session.revision = int(trial.session.get("revision", 0)) + 1
		InventoryService.commit(state, trial)
		committed.emit(int(state.session.revision))
		request_save(false)
	busy = false
	return result

func depart(map_id: String, spawn_id: String) -> Dictionary:
	return transact(func(trial: Dictionary) -> Dictionary:
		services.exploration.maps = Bundle.projected_maps()
		if not services.cycle.depart_day(trial, map_id, spawn_id): return {"ok": false}
		trial.expedition.catalog = services.exploration.maps.duplicate(true)
		trial.session.location = "exploration"
		trial.session.erase("runtime")
		return {"ok": true})

func to_dusk() -> Dictionary:
	return transact(func(trial: Dictionary) -> Dictionary: return {"ok": services.cycle.to_dusk(trial)})

func begin_night(mode: String, confirmed := false, map_id := "", spawn_id := "") -> Dictionary:
	return transact(func(trial: Dictionary) -> Dictionary:
		if mode == "explore":
			services.exploration.maps = Bundle.projected_maps()
			var rng := RandomNumberGenerator.new()
			rng.state = int(trial.rng_state)
			for map: Dictionary in services.exploration.maps.values():
				map.enemies.append_array(map.night_enemies)
				if not map.containers.is_empty() and rng.randf() < 0.7: map.containers[-1].loot.append({"definition_id": "catalyst", "quantity": 1})
			trial.rng_state = str(rng.state)
		var result: Dictionary = services.cycle.begin_night(trial, mode, confirmed, map_id, spawn_id)
		if result.ok:
			if mode == "explore": trial.expedition.catalog = services.exploration.maps.duplicate(true)
			if mode == "manual":
				var plan: Dictionary = BaseWavePlan.new().ensure_plan(trial, GridProjection.new())
				if plan.is_empty(): return {"ok": false, "reason": "wave_plan"}
			trial.session.location = "exploration" if mode == "explore" else "base"
			if mode == "explore": trial.session.erase("runtime")
		return result)

func finish_exploration(died: bool, position: Array, extraction_id := "") -> Dictionary:
	return transact(func(trial: Dictionary) -> Dictionary:
		var result: Dictionary = services.exploration.finish(trial, died, position, 3, extraction_id)
		if not result.ok: return result
		result = {"ok": services.cycle.to_dusk(trial)} if trial.phase == "day" else services.cycle.finish_night(trial)
		if result.ok:
			trial.session.location = "base"
			trial.session.erase("runtime")
		return result)

func finish_night(remaining: Dictionary = {}, complete := false) -> Dictionary:
	return transact(func(trial: Dictionary) -> Dictionary:
		var before := {"mode": trial.cycle.night.get("mode",""), "manual_complete": complete, "downed": trial.player.vitals.hp <= 0, "day": trial.day}
		var result: Dictionary = services.cycle.finish_night(trial, remaining, complete)
		if result.get("ok", false):
			trial.session.last_night = before
			trial.session.erase("runtime")
			# D007: provisional recovery only for a downed player whose base held.
			if result.get("held", false) and trial.player.vitals.hp <= 0:
				trial.player.vitals.hp = trial.player.vitals.max_hp
		return result)

func failure_choice(choice: String, seed_value: int = 1) -> Dictionary:
	if busy or not state.get("cycle", {}).get("failed", false): return {"ok": false, "reason": "not_failed"}
	match choice:
		"new": return create_world(seed_value)
		"latest": return restore(false)
		"morning": return restore(true)
		"plus":
			var result: Dictionary = services.restart.plus(state)
			if not result.ok: return result
			result.state.session = {"location": "base", "coordinate_version": "diamond_world_v1", "revision": 0}
			return install_choice(result.state)
	return {"ok": false, "reason": "unknown_choice"}

func request_save(capture := true) -> Dictionary:
	if state.is_empty(): return {"ok": false, "reason": "no_world"}
	if capture and capture_runtime.is_valid(): capture_runtime.call(state)
	if state.get("cycle", {}).get("failed", false):
		state.run_failed = true
		return saver.capture_failure(slot, state)
	var result := saver.request(slot, state, "latest")
	if not result.ok:
		save_error.emit(result)
		return result
	if state.phase == "morning" and not state.expedition.get("active", false):
		var key := morning_key()
		if morning_queued_key != key:
			result = saver.request(slot, state, "morning")
			# Accepted captures remain in SaveService.pending after asynchronous failure.
			# Do not overwrite the first dawn with subsequent morning shopping actions.
			if result.ok: morning_queued_key = key
			else: save_error.emit(result)
	return result

func morning_key() -> String:
	return "%s:%s:%s" % [slot, state.get("recovery_epoch", ""), state.day]

func tick(delta: float) -> Dictionary:
	var result := saver.tick(delta)
	if not result.ok: save_error.emit(result)
	return result

func shutdown() -> Dictionary:
	var requested := {"ok": true}
	if not state.is_empty(): requested = request_save()
	var result := saver.shutdown()
	if not requested.ok:
		requested["flush_result"] = result
		save_error.emit(requested)
		return requested
	if not result.ok: save_error.emit(result)
	return result
