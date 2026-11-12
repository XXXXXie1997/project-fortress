extends SceneTree
var n := 0
func ck(ok: bool, label: String):
 if not ok:
  push_error(label)
  quit(1)
  assert(ok)
 n += 1
 print("PASS ", label)
func _initialize():
 var s := WorldState.fresh()
 var defs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items
 defs.test_key = {"category":"key","size":[1,1],"weight":0,"backpack_stack":1,"warehouse_stack":1}
 var inv := InventoryService.new(defs)
 inv.setup(s)
 var maps: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/exploration.json")).maps
 maps.suburbs.doors.cache = "test_key"
 maps.suburbs.containers[0].loot = [{"definition_id":"medical_needle"},{"definition_id":"scrap"},{"definition_id":"test_key","door_key":"suburbs:cache"}]
 var e := ExplorationService.new(inv,maps)
 ck(e.start(s,"suburbs","south","day"),"free start")
 ck(not e.discover(s,"relay") and not e.exit_map(s,"south") and not e.finish(s,false,[],3,"south").ok,"three point separation")
 ck(e.open_search(s,"crate_01") and e.movement_blocked(s),"search blocks movement")
 var first: String = inv.items_in(s,e.box(s,"crate_01").container_id)[0].id
 ck(not e.pickup(s,"crate_01",first),"unrevealed forbidden")
 e.tick_search(s,0.3)
 e.close_search(s)
 e.open_search(s,"crate_01")
 e.tick_search(s,0.3)
 ck(e.box(s,"crate_01").revealed.is_empty(),"partial reset")
 s.player.hp=1
 e.tick_search(s,0.21)
 ck(e.box(s,"crate_01").revealed.size()==1 and e.movement_blocked(s),"damage preserves search and sequential reveal")
 ck(e.pickup(s,"crate_01",first),"revealed pickup")
 e.tick_search(s,2)
 e.take_all(s,"crate_01")
 ck(e.unlock_door(s,"cache","test_key"),"permanent door consumes key")
 ck(e.kill(s,"infected_01"),"kill")
 ck(e.enemy_loot(s,"infected_01",[{"definition_id":"test_key","door_key":"suburbs:cache"},{"definition_id":"medical_needle"}]),"mixed enemy loot")
 ck(inv.items_in(s,e.box(s,"loot_infected_01").container_id).size()==1,"enemy key filtered")
 ck(e.box(s,"loot_infected_01").revealed.is_empty(),"enemy loot requires search")
 ck(e.repair_travel(s,"relay",{"scrap":1}),"repair cost")
 ck(e.exit_map(s,"armory_road") and e.repair_travel(s,"relay",{}),"repair target")
 var battery := inv.spawn(s,"battery_basic","bag")
 ck(not battery.is_empty(),"battery fixture")
 s.items[battery.id].energy=12
 s.base.energy_store.energy=700
 var before := WorldState.encode(s)
 ck(not e.travel(s,"relay","suburbs","relay",13) and WorldState.encode(s)==before,"insufficient energy atomic")
 ck(e.travel(s,"relay","suburbs","relay",7),"travel")
 ck(s.items[battery.id].energy==5 and s.base.energy_store.energy==700,"portable battery only")
 ck(s.expedition.maps.suburbs.enemies.infected_01.dead and inv.items_in(s,e.box(s,"crate_01").container_id).is_empty(),"cross map no refresh")
 s.player.max_hp=100
 s.progression.xp=42
 s.quests.fixture={"progress":3}
 s.base.residents=["test"]
 var unique := inv.spawn(s,"nightvision","bag")
 ck(not unique.is_empty(),"unique fixture")
 for pair in [["rifle_basic","weapon_1"],["armor_basic","armor"],["backpack_small","backpack"],["aim_assist","extra_1"]]:
  var gear := inv.spawn(s,pair[0],"warehouse")
  ck(inv.equip(s,gear.id,pair[1]).ok,"equip "+pair[1])
 var equip: Dictionary = s.player.equipment.duplicate(true)
 ck(e.finish(s,true,[12,34],2).ok,"death")
 ck(s.player.hp==100 and s.player.equipment==equip and s.progression.xp==42 and s.quests.fixture.progress==3 and s.base.residents==["test"],"death preserves growth equipment recruitment hp")
 ck(inv.items_in(s,"bag").is_empty() and s.items[unique.id].container_id=="death_1","death bag items")
 ck(not e.start(s,"suburbs","south","day"),"used action rejected")
 ck(e.start(s,"suburbs","south","night"),"night refresh")
 ck(not s.expedition.maps.suburbs.enemies.infected_01.get("dead",false) and inv.items_in(s,e.box(s,"crate_01").container_id).size()==2,"night ordinary refresh static key filtered")
 ck(s.world.exploration.travel.has("suburbs:relay") and s.world.exploration.doors.has("suburbs:cache"),"permanent state")
 ck(e.open_search(s,"death_1") and e.box(s,"death_1").revealed.has(unique.id),"own death immediately revealed")
 s=WorldState.decode(WorldState.encode(s))
 ck(not s.is_empty() and e.movement_blocked(s),"json resume search")
 e.expire(s,2)
 ck(s.items.has(unique.id) and inv.spawn(s,"nightvision","ground").is_empty(),"unexpired holds unique")
 e.expire(s,3)
 ck(not s.items.has(unique.id) and not inv.spawn(s,"nightvision","ground").is_empty(),"expiry releases unique")
 ck(e.finish(s,false,[],3,"escape").ok,"free extraction")
 s.day=2
 ck(e.start(s,"suburbs","south","day"),"new day refresh")
 print("QA EXPLORATION PASSED ",n)
 quit()


