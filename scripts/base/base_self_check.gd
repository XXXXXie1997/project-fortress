extends SceneTree
func _initialize() -> void:
	var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items
	var crops: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
	defs.merge(crops.item_definitions)
	var inv := InventoryService.new(defs)
	var s := WorldState.fresh()
	inv.setup(s)
	var b := BuildingService.new(inv, JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json")))
	assert(b.setup(s))
	assert(not b.setup(s))
	assert(not inv.spawn(s, "scrap", "warehouse", 100).is_empty())
	var p := ProductionService.new(b, JSON.parse_string(FileAccess.get_file_as_string("res://data/recipes.json")).recipes)
	assert(p.order(s, "building_4", "medical", 3))
	assert(p.settle(s, "1:dusk"))
	assert(not p.settle(s, "1:dusk"))
	assert(inv.count(s, "medical_needle", "warehouse") == 1)
	assert(p.cancel(s, "building_4"))
	var farm := b.build(s, "farm", [0,4], Rect2i(0,0,24,18))
	assert(not farm.is_empty())
	assert(not inv.spawn(s,"seed_material","warehouse",1).is_empty())
	var f := FarmingService.new(b,crops.crops)
	assert(f.plant(s,farm,"material"))
	assert(f.settle(s,"1:dusk",true))
	assert(f.settle(s,"2:morning",true))
	assert(inv.count(s,"seed_material","warehouse") == 1)
	assert(f.plant(s,farm,"material"))
	assert(inv.spawn(s,"seed_material","warehouse",1).size() > 0)
	assert(f.plant(s,farm,"material"))
	s.containers.warehouse.width = 1
	s.containers.warehouse.height = 1
	assert(f.settle(s,"2:dusk",true))
	assert(f.settle(s,"3:morning",true))
	assert(s.base.buildings[farm].batches.size() == 2)
	var saved_rng: String = s.rng_state
	var saved_energy: float = s.base.energy_store.energy
	assert(f.collect_ready(s) == 0)
	assert(s.rng_state == saved_rng)
	s.containers.warehouse.width = 12
	s.containers.warehouse.height = 8
	assert(f.collect_ready(s) == 2)
	assert(f.collect_ready(s) == 0)
	assert(s.rng_state == saved_rng)
	assert(s.base.energy_store.energy == saved_energy)
	assert(inv.count(s,"seed_material","warehouse") == 2)
	s.base.buildings[farm].durability = 0
	assert(b.repair(s,farm))
	assert(b.upgrade(s,"building_1"))
	assert(b.expand(s))
	assert(b.settle(s,"1:dusk"))
	assert(not b.settle(s,"1:dusk"))
	print("BASE_SELF_CHECK_OK")
	quit()

