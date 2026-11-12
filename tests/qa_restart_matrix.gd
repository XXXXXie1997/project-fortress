extends SceneTree
func _initialize():
 var defs: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items
 var inv:=InventoryService.new(defs)
 var b:=BuildingService.new(inv,JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json")))
 var e:=ExplorationService.new(inv,JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/exploration.json")).maps)
 var r:=RunRestart.new(inv,b,e,QuestService.new(inv))
 var s: Dictionary=r.new_game(789).state
 var gun: String=s.player.equipment.weapon_1
 var plug:=inv.spawn(s,"battery_basic","ground")
 s.items[plug.id].container_id="plugin";s.items[plug.id].energy=17;s.items[gun].plugins.tactical=plug.id;s.items[gun].durability=23
 var keep:=inv.spawn(s,"nightvision","ground")
 s.items[keep.id].container_id="warehouse"
 var shop:=inv.spawn(s,"exoskeleton","ground")
 s.items[shop.id].container_id="shop"
 var lost:=inv.spawn(s,"aim_assist","ground")
 s.containers.death_qa=InventoryService.container(0,0,-1);s.items[lost.id].container_id="death_qa"
 s.world.exploration.death_bags.death_qa={"expires_day":88}
 s.containers.warehouse=InventoryService.container(1,1,0)
 s.base.residents=[{"id":"alive","hp":5},{"id":"dead","hp":0}]
 s.base.technology={"qa":true};s.player.growth.xp=500
 s.trade={"day":9,"stock":[shop.id],"price":41}
 s.cycle.failed=true;s.day=9
 s.base.buildings.qa_order={"type":"workstation","durability":4,"order":{"recipe":"medical","remaining":2,"produced":7}}
 s.base.buildings.qa_ruin={"type":"generator","durability":0,"batches":[{"harvest":{"scrap":3},"age":9}]}
 s.base.production_ids=["night_1"]
 s.quests.completed={"old":true};s.quests.active={"old":{"deadline":99}}
 var before:=WorldState.encode(s)
 var result:=r.plus(s)
 assert(result.ok)
 var n: Dictionary=result.state
 assert(before==WorldState.encode(s))
 assert(n.items[gun].durability==23 and n.items[gun].container_id==result.relic_container)
 assert(n.items[gun].plugins.tactical==plug.id and n.items[plug.id].energy==17 and n.items[plug.id].container_id=="plugin")
 assert(n.unique_items.nightvision==keep.id and n.unique_items.exoskeleton==shop.id and not n.unique_items.has("aim_assist"))
 assert(not n.items.has(lost.id) and n.items.size()==s.items.size()-1)
 assert(n.base.energy_store==s.base.energy_store and n.base.technology==s.base.technology)
 assert(n.base.residents.size()==1 and n.base.residents[0].hp==5 and n.player.growth.xp==0)
 assert(n.trade.stock==s.trade.stock and n.trade.price==41 and n.trade.day==1)
 assert(WorldState.encode(r.plus(s).state)==WorldState.encode(n))
 assert(n.base.buildings==s.base.buildings)
 assert(n.quests.completed.is_empty() and n.quests.active.is_empty() and n.quests.refresh_day==1 and not n.quests.offers.is_empty())
 n.containers.warehouse=InventoryService.container(20,20,1000)
 var prod:=ProductionService.new(b,JSON.parse_string(FileAccess.get_file_as_string("res://data/recipes.json")).recipes)
 var count_before:=inv.count(n,"medical_needle","warehouse")
 assert(prod.settle(n,"night_1"))
 assert(n.base.buildings.qa_order.order.remaining==1 and n.base.buildings.qa_order.order.produced==8)
 assert(inv.count(n,"medical_needle","warehouse")==count_before+1)
 assert(not prod.settle(n,"night_1"))
 assert(inv.count(n,"medical_needle","warehouse")==count_before+1)
 var saver:=SaveService.new("res://.godot-local/qa_restart_versions")
 var a:=saver.request("a",n);var newer:=saver.request("a",n)
 var other:=saver.request("b",n)
 assert(not saver.cancel_pending_version("a","latest",a.version).ok)
 assert(saver.pending.size()==2)
 assert(saver.cancel_pending_version("a","latest",newer.version).cancelled and saver.pending.size()==1)
 saver.fail_next="write";saver.dispatch()
 assert(not saver.cancel_pending_version("b","latest",other.version).ok)
 assert(not saver.shutdown().ok and saver.pending.size()==1)
 assert(saver.shutdown().ok and saver.load_snapshot("b").ok)
 print("QA RESTART MATRIX PASSED")
 quit()

