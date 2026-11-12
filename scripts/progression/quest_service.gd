class_name QuestService
extends RefCounted
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/quests.json"))
var inventory: InventoryService
var growth := preload("res://scripts/progression/player_growth.gd").new()
func _init(service: InventoryService) -> void:
	inventory = service
func fresh() -> Dictionary:
	return {"offers": {}, "active": {}, "completed": {}, "next_id": 1, "refresh_day": 0, "pending_stages": [], "ending": ""}
func setup(state: Dictionary) -> void:
	if not state.has("quests") or state.quests.is_empty(): state.quests = fresh()
func expire(state: Dictionary) -> void:
	setup(state)
	for id in state.quests.active.keys():
		var q: Dictionary = state.quests.active[id]
		if q.deadline > 0 and state.day >= q.deadline: state.quests.active.erase(id)
func refresh(state: Dictionary, rng: RandomNumberGenerator) -> void:
	setup(state)
	expire(state)
	if state.quests.refresh_day == state.day: return
	state.quests.refresh_day = state.day
	state.quests.offers = {}
	var pool: Array = []
	for id in config.definitions:
		if config.definitions[id].kind == "daily": pool.append(id)
	for index in int(config.daily_count):
		var id := "daily:%d:%d" % [state.day, index]
		state.quests.offers[id] = pool[rng.randi_range(0, pool.size() - 1)]
	state.rng_state = str(rng.state)
func accept(state: Dictionary, id: String, at_base: bool) -> Dictionary:
	if not at_base: return {"ok": false}
	setup(state)
	expire(state)
	var definition_id: String = state.quests.offers.get(id, id)
	if not config.definitions.has(definition_id): return {"ok": false}
	var d: Dictionary = config.definitions[definition_id]
	if d.kind == "daily":
		if state.quests.refresh_day != state.day or not state.quests.offers.has(id): return {"ok": false}
		var count := 0
		for q in state.quests.active.values():
			if config.definitions[q.definition].kind == "daily": count += 1
		if count >= 5: return {"ok": false}
	else:
		if state.quests.completed.has(definition_id): return {"ok": false}
		for required in d.get("requires", []):
			if not state.quests.completed.has(required): return {"ok": false}
	if state.quests.active.has(id): return {"ok": false}
	state.quests.active[id] = {"definition": definition_id, "progress": 0, "seen": {}, "deadline": int(state.day) + int(d.get("duration", 0)) if d.kind == "daily" else 0, "instance": state.quests.next_id}
	state.quests.next_id += 1
	state.quests.offers.erase(id)
	return {"ok": true}
func record(state: Dictionary, kind: String, target: String, event_id: String) -> void:
	if event_id.is_empty() or kind not in ["kill", "reach"]: return
	expire(state)
	for q in state.quests.active.values():
		var d: Dictionary = config.definitions[q.definition]
		if d.objective == kind and d.target == target and not q.seen.has(event_id):
			q.progress = mini(int(d.count), int(q.progress) + 1)
			q.seen[event_id] = true
func abandon(state: Dictionary, id: String) -> void:
	setup(state)
	state.quests.active.erase(id)
func status(state: Dictionary, id: String) -> Dictionary:
	setup(state)
	if not state.quests.active.has(id): return {}
	var q: Dictionary = state.quests.active[id].duplicate(true)
	q.definition_data = config.definitions[q.definition].duplicate(true)
	q.days_remaining = maxi(0, int(q.deadline) - int(state.day)) if q.deadline > 0 else -1
	q.expired = q.deadline > 0 and state.day >= q.deadline
	q.near_deadline = q.days_remaining == 1
	return q
func deliver(state: Dictionary, id: String, at_base: bool) -> Dictionary:
	if not at_base: return {"ok": false}
	setup(state)
	var q := status(state, id)
	if q.is_empty() or q.expired: return {"ok": false}
	var d: Dictionary = config.definitions[q.definition]
	if d.objective != "deliver" and q.progress < d.count: return {"ok": false}
	var trial := state.duplicate(true)
	var reward: Dictionary = d.reward
	var store: Dictionary = trial.base.energy_store
	if float(store.energy) + float(reward.energy) > float(store.capacity): return {"ok": false}
	if not inventory.exchange(trial, d.materials, reward.materials).ok: return {"ok": false}
	trial.base.energy_store.energy += float(reward.energy)
	if not growth.award(trial, "quest", int(reward.xp), "quest:%s" % q.instance).ok: return {"ok": false}
	trial.quests.active.erase(id)
	trial.quests.completed[q.definition] = true
	if d.has("threat_stage"):
		trial.quests.pending_stages.append({"id": "quest_stage:%s" % q.instance, "effective_day": int(state.day) + 1, "stage": d.threat_stage})
	if d.has("ending"): trial.quests.ending = d.ending
	inventory.commit(state, trial)
	return {"ok": true}
func new_survivor(state: Dictionary) -> void:
	state.quests = fresh()
