extends SceneTree
func _init() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items
	var crops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	var trade: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/trade.json"))
	defs.merge(crops.item_definitions)
	defs.merge(trade.item_definitions)
	var inv := InventoryService.new(defs)
	var s := WorldState.fresh()
	inv.setup(s)
	var b := BuildingService.new(inv,JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json")))
	b.setup(s)
	var deps := {"inventory":inv,"building":b,"production":ProductionService.new(b,{}),"farming":FarmingService.new(b,crops.crops),"quests":QuestService.new(inv),"trade":TradeService.new(inv,trade),"exploration":ExplorationService.new(inv,JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/exploration.json")).maps)}
	var cycle = load("res://scripts/base/day_cycle.gd").new(deps)
	cycle.setup(s)
	var original = s.duplicate(true)
	# 最后农业服务拒绝时，之前发电等所有改动回滚。
	s.base.farming_ids = ["1:dusk"]
	var before = s.duplicate(true)
	assert(not cycle.to_dusk(s) and s == before)
	s = original.duplicate(true)
	assert(cycle.to_dusk(s))
	assert(not cycle.to_dusk(s))
	# 夜探新增能源与居民既不能支援本夜也不能被覆盖。
	s.base.energy_store.energy = 0
	assert(cycle.begin_night(s,"explore",true,"suburbs","south").ok)
	assert(not cycle.finish_night(s).ok)
	s.base.energy_store.energy = 50
	s.base.residents.append({"id":"new","hp":37,"max_hp":100,"power":1000})
	assert(deps.exploration.finish(s,false,[0,0],3,"escape").ok)
	var frozen = s.cycle.night.snapshot.duplicate(true)
	assert(frozen.base.residents.is_empty() and frozen.base.energy_store.energy == 0)
	var r = cycle.finish_night(s)
	assert(r.ok and r.report.energy_spent == 0 and s.base.energy_store.energy >= 50)
	assert(s.base.residents[0].hp == 37)
	assert(not cycle.finish_night(s).ok)
	print("QA night snapshot PASS")
	# 手动已耗20，残局只扣剩敌强度所需2，清晨发电另计。
	s = original.duplicate(true)
	assert(cycle.to_dusk(s))
	s.base.residents = [{"id":"r","hp":100,"max_hp":100,"power":100}]
	s.base.energy_store.energy = 100
	assert(cycle.begin_night(s,"manual").ok)
	s.base.energy_store.energy = 80
	# 清晨农业失败时连夜结算结果、损失、日期一起回滚。
	deps.quests.setup(s)
	s.quests.active["expired"] = {"deadline":2}
	deps.exploration.setup(s)
	s.containers.death_test = InventoryService.container(0,0,-1)
	s.world.exploration.death_bags.death_test = {"container_id":"death_test","expires_day":2}
	s.base.farming_ids.append("2:morning")
	before = s.duplicate(true)
	assert(not cycle.finish_night(s,{"enemy_power":4}).ok and s == before)
	s.base.farming_ids.erase("2:morning")
	var generation = 0.0
	for building in s.base.buildings.values():
		if building.type == "generator": generation += b.config.generation * building.level
	r = cycle.finish_night(s,{"enemy_power":4})
	assert(r.ok and r.report.energy_spent == 2)
	assert(not s.quests.active.has("expired") and s.quests.refresh_day == 2)
	assert(not s.world.exploration.death_bags.has("death_test") and not s.containers.has("death_test"))
	assert(s.base.energy_store.energy == 78 + generation)
	# 满仓时待领取原样保留；腾空后一次领取。
	var normal = s.containers.warehouse.duplicate(true)
	s.containers.warehouse = InventoryService.container(1,1,-1)
	inv.spawn(s,"rifle_basic","warehouse")
	# 使用无可用格容器形成真实容量拒绝。
	s.containers.warehouse.width = 1
	s.containers.warehouse.height = 1
	assert(not inv.spawn(s,"scrap","warehouse",200).is_empty())
	before = s.duplicate(true)
	assert(not cycle.claim_loot(s,"night:1") and s == before)
	for item in inv.items_in(s,"warehouse"): inv.destroy(s,item.id)
	s.containers.warehouse = normal
	assert(cycle.claim_loot(s,"night:1"))
	assert(not cycle.claim_loot(s,"night:1"))
	print("QA manual residual, rollback, loot PASS")
	quit()


