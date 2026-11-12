class_name ResidentService
extends RefCounted
var inventory: InventoryService
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/defenders.json"))
func _init(service: InventoryService) -> void:
	inventory = service
func living_count(s: Dictionary) -> int:
	var count := 0
	for r in s.base.get("residents", []):
		if r.hp > 0: count += 1
	return count
func recruit(s: Dictionary, source_id: String) -> Dictionary:
	if source_id.is_empty() or source_id in s.base.get("recruited_sources", []) or living_count(s) >= int(s.base.get("resident_capacity",0)): return {"ok":false}
	var t := s.duplicate(true)
	var id := "resident:%d" % int(t.base.get("resident_next_id",1))
	t.containers[id] = InventoryService.container(0,0,-1)
	var weapon := inventory.spawn(t,str(config.resident.weapon),id)
	if weapon.is_empty(): return {"ok":false}
	var rng := RandomNumberGenerator.new()
	rng.state = int(t.rng_state)
	var hp := rng.randi_range(int(config.resident.hp_min),int(config.resident.hp_max))
	var power := rng.randi_range(int(config.resident.power_min),int(config.resident.power_max))
	var resident := {"id":id,"hp":hp,"max_hp":hp,"power":power,"weapon_instance":weapon.id,"weapon_definition":config.resident.weapon,"weapon_energy":0.0,"weapon_capacity":weapon.capacity,"energy_per_power":config.resident.energy_per_power,"joined_day":t.day,"joined_phase":t.phase,"attributes":{"max_hp":hp,"power":power},"source_id":source_id}
	if not t.base.has("residents"): t.base.residents = []
	t.base.residents.append(resident)
	t.base.resident_next_id = int(t.base.get("resident_next_id",1)) + 1
	if not t.base.has("recruited_sources"): t.base.recruited_sources = []
	t.base.recruited_sources.append(source_id)
	t.rng_state = str(rng.state)
	InventoryService.commit(s,t)
	return {"ok":true,"id":id}
func dismiss(s: Dictionary, id: String) -> bool:
	if s.phase not in ["morning","dusk"] or s.base.get("combat",false) or s.expedition.get("active",false): return false
	var t := s.duplicate(true)
	for index in t.base.get("residents",[]).size():
		var r: Dictionary = t.base.residents[index]
		if r.id != id or r.hp <= 0: continue
		# 自带装备随遣散离开，不产生玩家可拿取副本。
		if t.items.has(r.weapon_instance): inventory.destroy(t,r.weapon_instance)
		t.containers.erase(id)
		t.base.residents.remove_at(index)
		InventoryService.commit(s,t)
		return true
	return false
