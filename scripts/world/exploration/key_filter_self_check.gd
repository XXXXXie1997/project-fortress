extends SceneTree
func _initialize():
 var s := WorldState.fresh()
 var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items
 defs.test_key={"category":"key","size":[1,1],"weight":0.0,"backpack_stack":1,"warehouse_stack":1}
 var inv:=InventoryService.new(defs)
 inv.setup(s)
 var maps: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/exploration.json")).maps
 maps.suburbs.doors.cache="test_key"
 maps.suburbs.enemies.append({"id":"second","position":[0,0]})
 maps.suburbs.containers[0].loot.append({"definition_id":"test_key","door_key":"suburbs:cache"})
 var e:=ExplorationService.new(inv,maps)
 assert(e.start(s,"suburbs","south","day"))
 e.kill(s,"infected_01")
 assert(e.enemy_loot(s,"infected_01",[{"definition_id":"test_key","door_key":"suburbs:cache"}]))
 assert(inv.count(s,"test_key",e.box(s,"loot_infected_01").container_id)==1)
 inv.spawn(s,"test_key","bag")
 assert(e.unlock_door(s,"cache","test_key"))
 e.kill(s,"second")
 assert(e.enemy_loot(s,"second",[{"definition_id":"test_key","door_key":"suburbs:cache"},{"definition_id":"medical_needle","quantity":3}]))
 var cid: String=e.box(s,"loot_second").container_id
 assert(inv.count(s,"test_key",cid)==0 and inv.count(s,"medical_needle",cid)==3)
 assert(e.finish(s,false,[0,0],3,"escape").ok)
 assert(e.start(s,"suburbs","south","night"))
 cid=e.box(s,"crate_01").container_id
 assert(inv.count(s,"test_key",cid)==0 and inv.count(s,"medical_needle",cid)==2)
 assert(e.kill(s,"infected_01"))
 assert(e.enemy_loot(s,"infected_01",[{"definition_id":"test_key","door_key":"suburbs:cache"}]))
 assert(inv.items_in(s,e.box(s,"loot_infected_01").container_id).is_empty())
 print("EXPLORATION KEY FILTER SELF CHECK PASSED")
 quit()
