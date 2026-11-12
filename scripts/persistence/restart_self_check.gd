extends SceneTree
const Restart=preload("res://scripts/persistence/run_restart.gd")
func _initialize():
 var defs: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items
 var crops: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/crops.json"))
 defs.merge(crops.item_definitions)
 var inv:=InventoryService.new(defs)
 var buildings:=BuildingService.new(inv,JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json")))
 var e:=ExplorationService.new(inv,JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/exploration.json")).maps)
 var q:=QuestService.new(inv)
 var restart:=Restart.new(inv,buildings,e,q)
 var created: Dictionary=restart.new_game(42)
 assert(created.ok)
 var s: Dictionary=created.state
 s.day=8;s.phase="night";s.cycle.failed=true
 s.base.technology={"agriculture":true}
 s.player.growth.xp=999
 s.world.exploration.unlocked.append("city")
 s.world.exploration.travel={"city:relay":true}
 var first: String=s.base.buildings.keys()[0]
 s.base.buildings[first].durability=0
 s.base.buildings[first].order={"recipe":"medical","remaining":2,"produced":1}
 s.base.buildings[first].batches=[{"crop":"material","age":9,"harvest":{"scrap":4}}]
 s.base.residents=[{"id":"live","hp":12,"max_hp":100},{"id":"dead","hp":0,"max_hp":100}]
 var extra:=inv.spawn(s,"nightvision","ground")
 inv.equip(s,extra.id,"extra_1")
 var lost:=inv.spawn(s,"aim_assist","ground")
 s.containers.death_99=InventoryService.container(0,0,-1)
 inv.move(s,lost.id,"death_99")
 s.world.exploration.death_bags.death_99={"expires_day":99}
 var energy: float=s.base.energy_store.energy
 var items_before: int=s.items.size()
 var original:=WorldState.encode(s)
 var result: Dictionary=restart.plus(s)
 assert(result.ok and WorldState.encode(s)==original)
 var next: Dictionary=result.state
 assert(next.base.energy_store.energy==energy and next.base.buildings[first].durability==0)
 assert(next.base.buildings[first].order.remaining==2 and next.base.buildings[first].batches[0].harvest.scrap==4)
 assert(next.base.residents.size()==1 and next.base.residents[0].hp==12)
 assert(next.items.size()==items_before-1 and not next.unique_items.has("aim_assist"))
 assert(next.unique_items.nightvision==extra.id and next.items[extra.id].container_id==result.relic_container)
 assert(next.day==1 and next.phase=="morning" and next.player.growth.xp==0)
 assert(next.player.equipment.weapon_1=="" and next.world.exploration.travel.has("city:relay"))
 assert(not restart.plus(next).ok)
 assert(WorldState.encode(restart.plus(s).state)==WorldState.encode(next))
 var saver:=SaveService.new("res://.godot-local/restart-"+str(Time.get_ticks_usec()))
 saver.request("slot",s,"failure")
 var old:=s.duplicate(true)
 old.cycle.failed=false
 saver.request("slot",old)
 saver.request("slot",old,"morning")
 assert(saver.flush().ok)
 var accepted:=restart.persist_choice(saver,"slot",result)
 assert(accepted.ok)
 assert(restart.restore(saver,"slot",true).state.day==1)
 assert(saver.load_snapshot("slot","failure").state.day==8)
 var deps: Dictionary={"inventory":inv,"building":buildings,"production":ProductionService.new(buildings,JSON.parse_string(FileAccess.get_file_as_string("res://data/recipes.json")).recipes),"farming":FarmingService.new(buildings,crops.crops),"quests":q,"trade":TradeService.new(inv,JSON.parse_string(FileAccess.get_file_as_string("res://data/trade.json"))),"exploration":e}
 var cycle:=DayCycle.new(deps)
 assert(cycle.to_dusk(next))
 assert(cycle.begin_night(next,"manual").ok)
 # Only one prefab was destroyed, below global loss threshold.
 assert(cycle.finish_night(next,{"enemy_power":0},true).ok)
 assert(next.day==2 and next.phase=="morning")
 print("RESTART SELF CHECK PASSED")
 quit()
