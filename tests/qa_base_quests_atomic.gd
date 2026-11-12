extends SceneTree
func _initialize():
 var defs = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items
 var crops = JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
 defs.merge(crops.item_definitions)
 var inv = InventoryService.new(defs)
 var s = WorldState.fresh()
 inv.setup(s)
 s.containers.warehouse.width = 1
 s.containers.warehouse.height = 1
 inv.spawn(s,"scrap","warehouse",2)
 var q = QuestService.new(inv)
 q.setup(s)
 q.config.definitions.main_1.objective = "deliver"
 q.config.definitions.main_1.materials = {"scrap":2}
 q.config.definitions.main_1.reward.materials = {"seed_material":1}
 assert(q.accept(s,"main_1",true).ok)
 assert(q.deliver(s,"main_1",true).ok)
 assert(inv.count(s,"scrap","warehouse") == 0)
 assert(inv.count(s,"seed_material","warehouse") == 1)
 assert(q.accept(s,"main_2",true).ok)
 q.record(s,"reach","map_2_transmitter","a")
 var before = JSON.stringify(s)
 assert(not q.deliver(s,"main_2",true).ok)
 assert(JSON.stringify(s) == before)
 print("QA312_ATOMIC_PASS")
 s = WorldState.fresh()
 inv.setup(s)
 var b = BuildingService.new(inv,JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json")))
 b.setup(s)
 inv.spawn(s,"scrap","warehouse",100)
 var id = b.build(s,"farm",[0,4],Rect2i(0,0,24,18))
 var f = FarmingService.new(b,crops.crops)
 inv.spawn(s,"seed_material","warehouse",2)
 assert(f.plant(s,id,"material"))
 var age = s.base.buildings[id].batches[0].age
 before = JSON.stringify(s)
 assert(f.collect_ready(s) == 0)
 assert(s.base.buildings[id].batches[0].age == age)
 var energy = s.base.energy_store.energy
 var rng = s.rng_state
 assert(f.collect_ready(s) == 0)
 assert(s.rng_state == rng and s.base.energy_store.energy == energy)
 var width = s.containers.warehouse.width
 var cap = s.base.energy_store.capacity
 assert(b.upgrade(s,"building_1"))
 assert(s.containers.warehouse.width == width + 2)
 assert(s.base.energy_store.capacity == cap + 500)
 b.settle(s,"qa")
 energy = s.base.energy_store.energy
 assert(not b.settle(s,"qa"))
 assert(s.base.energy_store.energy == energy)
 print("QA301_COLLECT_PASS")
 quit()
