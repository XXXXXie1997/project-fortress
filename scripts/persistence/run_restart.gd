class_name RunRestart
extends RefCounted
var inventory: InventoryService
var building: BuildingService
var exploration: ExplorationService
var quests: QuestService
var config: Dictionary
func _init(inv: InventoryService, buildings: BuildingService, expeditions: ExplorationService, quest_service: QuestService) -> void:
 inventory=inv
 building=buildings
 exploration=expeditions
 quests=quest_service
 config=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat.json"))
func player_fresh() -> Dictionary:
 return {"equipment":{"weapon_1":"","weapon_2":"","weapon_3":"","armor":"","backpack":"","extra_1":"","extra_2":"","extra_3":"","extra_4":""},"quick":["medical_needle","","","","",""],"vitals":{"hp":100.0,"max_hp":100.0},"combat":ActionRules.fresh(config),"growth":PlayerGrowth.new().fresh()}
func reset_cycle(s: Dictionary) -> void:
 var old_loot: Dictionary=s.get("cycle",{}).get("pending_loot",{}).duplicate(true)
 var inherited: Dictionary={}
 for id: String in old_loot: inherited["legacy:%s:%s" % [s.get("run_number",1),id]]=old_loot[id]
 s.cycle={"settled":[],"night":{},"results":{},"pending_loot":inherited,"failed":false}
 s.threat={"stage":1,"entered_day":1,"events":{},"consumed_stages":[]}
 s.settled_ids=[]
 s.events=[]
 for key in ["generation_ids","production_ids","farming_ids"]: s.base[key]=[]
 s.base.combat=false
 # Night IDs restart at day one; old combat plans belong to the previous run.
 s.base.erase("wave_plan")
 s.base.erase("defense_runtime")
 s.day=1
 s.phase="morning"
 s.run_failed=false
func refresh_quests(s: Dictionary) -> void:
 s.quests=quests.fresh()
 var rng:=RandomNumberGenerator.new()
 rng.state=int(s.rng_state)
 quests.refresh(s,rng)
func new_game(seed: int = 1) -> Dictionary:
 var s:=WorldState.fresh()
 var rng:=RandomNumberGenerator.new()
 rng.seed=seed
 s.rng_state=str(rng.state)
 inventory.setup(s)
 if not building.setup(s): return {"ok":false,"reason":"base_setup"}
 exploration.setup(s)
 s.player=player_fresh()
 s.run_number=1
 reset_cycle(s)
 for pair: Array in [["backpack_small","backpack"],["rifle_basic","weapon_1"],["knife_basic","weapon_2"],["armor_basic","armor"]]:
  var item:=inventory.spawn(s,pair[0],"ground")
  if item.is_empty() or not inventory.equip(s,item.id,pair[1]).ok: return {"ok":false,"reason":"initial_equipment"}
 for n in 2:
  var battery:=inventory.spawn(s,"battery_basic","bag")
  if battery.is_empty(): return {"ok":false,"reason":"initial_battery"}
  s.items[battery.id].energy=s.items[battery.id].capacity
 if inventory.spawn(s,"medical_needle","bag",5).is_empty(): return {"ok":false,"reason":"initial_supplies"}
 refresh_quests(s)
 return {"ok":true,"state":s}
func plus(failure: Dictionary) -> Dictionary:
 if not WorldState.valid(failure): return {"ok":false,"reason":"invalid_world"}
 if not failure.get("run_failed",false) and not failure.get("cycle",{}).get("failed",false): return {"ok":false,"reason":"not_base_failure"}
 var s:=failure.duplicate(true)
 exploration.setup(s)
 var old_player: Dictionary=s.player
 var relic_id: String="relics_%s" % int(s.get("run_number",1))
 if s.containers.has(relic_id): return {"ok":false,"reason":"relic_collision"}
 s.containers[relic_id]=InventoryService.container(0,0,-1)
 # Preserve all remaining personal belongings without charging/merging them.
 for item: Dictionary in s.items.values():
  if item.container_id in ["bag","equipment"]: item.container_id=relic_id
 for id: String in old_player.get("equipment",{}).values():
  if not id.is_empty() and s.items.has(id): s.items[id].container_id=relic_id
 # Destruction is limited to the old expedition and timed lost-property bags.
 exploration.cleanup_session(s)
 for id: String in s.world.exploration.death_bags.keys(): exploration.clear_container(s,id)
 s.world.exploration.death_bags={}
 s.world.exploration.used_slots=[]
 s.expedition={}
 s.player=player_fresh()
 s.containers.bag=InventoryService.container(3,2,10.0)
 for resident: Dictionary in s.base.get("residents",[]):
  if resident.get("hp",0) <= 0 and s.items.has(resident.get("weapon_instance","")):
   s.items[resident.weapon_instance].container_id="ground"
 # Survivors retain all fields including equipment IDs and current HP.
 s.base.residents=s.base.get("residents",[]).filter(func(r: Dictionary)->bool: return r.get("hp",0)>0)
 reset_cycle(s)
 s.erase("run_start_snapshot")
 s.erase("recovery_epoch")
 s.run_number=int(s.get("run_number",1))+1
 # Keep real stock/buyback identities without re-rolling the inherited shop.
 if not s.trade.is_empty(): s.trade.day=1
 refresh_quests(s)
 if not WorldState.valid(s): return {"ok":false,"reason":"invalid_result"}
 return {"ok":true,"state":s,"relic_container":relic_id}
# No side effects until caller explicitly commits a menu choice. Disk failures
# never replace the caller's in-memory world or delete morning/failure points.
func persist_choice(saver: SaveService, slot: String, candidate: Dictionary) -> Dictionary:
 if not candidate.get("ok",false): return candidate
 var joined:=saver.shutdown()
 if not joined.ok: return joined
 var original_lock:=saver.is_failure_locked(slot)
 saver.resume_slot(slot)
 var committed: Dictionary=candidate.state.duplicate(true)
 committed.recovery_epoch=str(Time.get_unix_time_from_system())+":"+str(Time.get_ticks_usec())
 committed.erase("run_start_snapshot")
 # One atomic latest write also carries the first morning of this new run.
 # An old slot's morning/failure files remain intact until future daily saves.
 committed.run_start_snapshot=committed.duplicate(true)
 var requested:=saver.request(slot,committed)
 if not requested.ok:
  saver.set_failure_lock(slot,original_lock)
  return requested
 var saved:=saver.shutdown()
 if not saved.ok:
  var cancelled:=saver.cancel_pending_version(slot,"latest",int(requested.version))
  saver.set_failure_lock(slot,original_lock)
  saved.candidate_cancelled=cancelled
  return saved
 return {"ok":true,"state":committed}
func restore(saver: SaveService, slot: String, morning: bool = false) -> Dictionary:
 var joined:=saver.shutdown()
 if not joined.ok: return joined
 var latest:=saver.load_snapshot(slot,"latest")
 if not morning or not latest.ok: return latest
 var dawn:=saver.load_snapshot(slot,"morning")
 if latest.state.has("recovery_epoch") and (not dawn.ok or dawn.state.get("recovery_epoch","") != latest.state.recovery_epoch):
  if latest.state.has("run_start_snapshot"):
   var initial: Dictionary=latest.state.run_start_snapshot.duplicate(true)
   initial.erase("run_start_snapshot")
   if initial.get("recovery_epoch","") != latest.state.recovery_epoch:
    return {"ok":false,"error":"invalid_run_start_epoch"}
   var restored: Dictionary=initial.duplicate(true)
   restored.run_start_snapshot=initial
   return {"ok":true,"state":restored,"source":"run_start"}
  return {"ok":false,"error":"missing_current_run_morning"}
 return dawn
