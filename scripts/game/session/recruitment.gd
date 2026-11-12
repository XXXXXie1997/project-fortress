extends RefCounted
const Catalog = preload("res://scripts/content/catalog.gd")
var config: Dictionary = Catalog.read("scripts/game/session/recruitment.json")
var resident_config: Dictionary = Catalog.read("data/defenders.json").resident

func refresh(s: Dictionary) -> void:
	if not s.world.has("recruitment"): s.world.recruitment = {"checked": [], "candidates": {}}
	var data: Dictionary = s.world.recruitment
	for entry: Dictionary in config.field_candidates:
		if not data.candidates.has(entry.id): create_candidate(s, entry.id, entry.map_id, entry.logical_position, entry.name)
	if s.phase != "morning": return
	var key := "%s:%s" % [s.get("run_number", 1), s.day]
	if key in data.checked: return
	data.checked.append(key)
	if int(s.day) < int(config.visitor_start_day) or (int(s.day) - int(config.visitor_start_day)) % int(config.visitor_interval) != 0: return
	var rng := RandomNumberGenerator.new(); rng.state = int(s.rng_state)
	var arrived := rng.randf() < float(config.visitor_probability)
	s.rng_state = str(rng.state)
	if arrived: create_candidate(s, "visitor:" + key, "base", config.visitor_logical, "来访的幸存者")

func create_candidate(s: Dictionary, id: String, map_id: String, position: Array, title: String) -> void:
	var rng := RandomNumberGenerator.new(); rng.state = int(s.rng_state)
	var hp := rng.randi_range(int(resident_config.hp_min), int(resident_config.hp_max))
	var power := rng.randi_range(int(resident_config.power_min), int(resident_config.power_max))
	s.world.recruitment.candidates[id] = {"id": id, "map_id": map_id, "logical_position": position.duplicate(), "name": title, "hp": hp, "power": power, "accepted": id in s.base.get("recruited_sources", [])}
	s.rng_state = str(rng.state)

func accept(s: Dictionary, id: String, inventory: InventoryService) -> Dictionary:
	var candidate: Dictionary = s.world.get("recruitment", {}).get("candidates", {}).get(id, {})
	if candidate.is_empty() or candidate.accepted: return {"ok": false, "reason": "candidate_unavailable"}
	var here: String = s.expedition.map_id if s.expedition.get("active", false) else "base"
	if candidate.map_id != here: return {"ok": false, "reason": "wrong_location"}
	var trial := s.duplicate(true)
	var rng_before: String = trial.rng_state
	var result := ResidentService.new(inventory).recruit(trial, id)
	if not result.ok: return {"ok": false, "reason": "resident_capacity"}
	# Candidate attributes were drawn once when the encounter was created.
	trial.rng_state = rng_before
	for resident: Dictionary in trial.base.residents:
		if resident.id == result.id:
			resident.hp = candidate.hp; resident.max_hp = candidate.hp; resident.power = candidate.power
			resident.attributes = {"max_hp": candidate.hp, "power": candidate.power}
	trial.world.recruitment.candidates[id].accepted = true
	InventoryService.commit(s, trial)
	return result
