class_name DayCycle
extends RefCounted
var services: Dictionary
var threat := preload("res://scripts/base/threat_service.gd").new()
var defense := preload("res://scripts/base/defense_resolution.gd").new()
func _init(dependencies: Dictionary) -> void:
	services = dependencies
func setup(s: Dictionary) -> void:
	if not s.has("cycle"): s.cycle = {"settled":[],"night":{},"results":{},"pending_loot":{},"failed":false}
	threat.setup(s)
func facility(s: Dictionary, type: String) -> Dictionary:
	# 唯一功能设施的实例是等级事实来源，不另维护base.*_level镜像。
	for building in s.base.get("buildings", {}).values():
		if building.type == type: return building
	return {}
func _settle(s: Dictionary, phase: String) -> bool:
	var id := "%s:%s" % [s.day, phase]
	if id in s.cycle.settled: return true
	for key in ["building", "production"]:
		if not services[key].settle(s, id): return false
	if not services.farming.settle(s, id, s.base.get("technology", {}).has("agriculture")): return false
	if phase == "morning":
		threat.morning(s)
		services.quests.expire(s)
		var rng := RandomNumberGenerator.new()
		rng.state = int(s.rng_state)
		services.quests.refresh(s, rng)
		var trade_station := facility(s, "trade")
		if not trade_station.is_empty(): services.trade.refresh(s, int(trade_station.level))
		services.exploration.expire(s, int(s.day))
	s.cycle.settled.append(id)
	return true
func to_dusk(s: Dictionary) -> bool:
	setup(s)
	if s.phase not in ["morning", "day"] or s.expedition.get("active", false) or s.cycle.failed: return false
	var t := s.duplicate(true)
	t.phase = "dusk"
	if not _settle(t, "dusk"): return false
	InventoryService.commit(s, t)
	return true
func depart_day(s: Dictionary, map_id: String, spawn_id: String) -> bool:
	setup(s)
	if s.phase != "morning" or s.cycle.failed: return false
	var t := s.duplicate(true)
	if not services.exploration.start(t, map_id, spawn_id, "day"): return false
	t.phase = "day"
	InventoryService.commit(s,t)
	return true
func begin_night(s: Dictionary, mode: String, confirmed: bool = false, map_id: String = "", spawn_id: String = "") -> Dictionary:
	setup(s)
	if s.phase != "dusk" or mode not in ["manual", "rest", "explore"] or s.cycle.failed: return {"ok":false}
	var t := s.duplicate(true)
	var snapshot := defense.capture(t, threat.strength(t), "night:%s" % t.day)
	var assessment := defense.evaluate(snapshot)
	if mode != "manual" and assessment.rating == "weak" and not confirmed: return {"ok":false,"confirmation_required":true,"assessment":assessment}
	if mode == "explore" and not services.exploration.start(t,map_id,spawn_id,"night"): return {"ok":false}
	t.cycle.night = {"mode":mode,"snapshot":snapshot}
	t.phase = "night"
	t.base.combat = true
	InventoryService.commit(s,t)
	return {"ok":true,"assessment":assessment}
func finish_night(s: Dictionary, manual_remaining: Dictionary = {}, manual_complete: bool = false) -> Dictionary:
	setup(s)
	if s.phase != "night" or s.cycle.night.is_empty() or s.expedition.get("active",false): return {"ok":false}
	var t := s.duplicate(true)
	var night: Dictionary = t.cycle.night
	var original: Dictionary = night.snapshot
	if t.cycle.results.has(original.id): return {"ok":false}
	var result: Dictionary
	if night.mode == "manual":
		# 残局由真实实体同步到state后提交，不能用出发能源回滚消耗。
		if manual_remaining.is_empty() or not manual_remaining.has("enemy_power") or float(manual_remaining.enemy_power) < 0: return {"ok":false}
		if manual_complete and float(manual_remaining.enemy_power) != 0: return {"ok":false}
		var remainder := defense.capture(t,float(manual_remaining.enemy_power),original.id)
		remainder.weights = original.weights.duplicate(true)
		result = remainder if manual_complete else defense.resolve(remainder)
		if manual_complete:
			result.result = {"energy_spent":0.0,"destroyed":[],"dead":[],"held":not defense.lost(result),"loot":defense.config.loot.duplicate(true)}
		else:
			t.base.energy_store.energy = result.base.energy_store.energy
	else:
		result = defense.resolve(original)
		# 只扣冻结能源实际消耗；不覆盖夜探期间新增库存。
		t.base.energy_store.energy = maxf(0.0,float(t.base.energy_store.energy) - float(result.result.energy_spent))
	for id in result.base.buildings:
		if t.base.buildings.has(id): t.base.buildings[id].durability = result.base.buildings[id].durability
	if result.base.has("shield"): t.base.shield = result.base.shield.duplicate(true)
	for r in result.base.get("residents",[]):
		for live in t.base.get("residents",[]):
			if live.id == r.id: live.hp = r.hp
	# 同ID武器真实实例成为地面遗物；已存在则移动，不复制。
	for r in result.base.get("residents", []):
		if r.get("hp", 0) <= 0 and t.items.has(r.get("weapon_instance", "")):
			services.inventory.move(t, r.weapon_instance, "ground")
	if night.mode == "manual" and manual_complete:
		for r in t.base.get("residents", []):
			if r.get("hp",0) > 0: r.hp = r.get("max_hp",r.hp)
	t.cycle.results[original.id] = result.result
	t.cycle.pending_loot[original.id] = result.result.loot
	t.cycle.night = {}
	t.base.combat = false
	# 夜探返回已推进世界随机流，不能用出发快照覆盖它。
	if night.mode != "explore": t.rng_state = result.rng_state
	if not result.result.held:
		t.cycle.failed = true
		t.cycle.failure_snapshot = {"day":t.day,"base":t.base.duplicate(true),"result_id":original.id}
	else:
		t.day += 1
		t.phase = "morning"
		if not _settle(t,"morning"): return {"ok":false}
	InventoryService.commit(s,t)
	return {"ok":true,"held":result.result.held,"report":result.result}
func claim_loot(s: Dictionary, id: String) -> bool:
	setup(s)
	if not s.cycle.pending_loot.has(id): return false
	var t := s.duplicate(true)
	if not services.inventory.exchange(t,{},t.cycle.pending_loot[id]).ok: return false
	t.cycle.pending_loot.erase(id)
	InventoryService.commit(s,t)
	return true
