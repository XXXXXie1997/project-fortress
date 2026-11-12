class_name ExplorationService
extends RefCounted
var inventory: InventoryService
var maps: Dictionary
func _init(service: InventoryService, catalog: Dictionary) -> void:
 inventory = service
 maps = catalog
func setup(s: Dictionary) -> void:
 if not s.world.has("exploration"):
  s.world.exploration = {"unlocked":["suburbs","armory"],"spawns":{},"travel":{},"doors":{},"death_bags":{},"used_slots":[],"next_session":1}
 for id: String in maps:
  if not s.world.exploration.spawns.has(id): s.world.exploration.spawns[id] = [maps[id].initial_spawn]
func start(s: Dictionary, map_id: String, spawn_id: String, period: String) -> bool:
 setup(s)
 var w: Dictionary = s.world.exploration
 var slot := str(s.day)+":"+period
 if s.expedition.get("active",false) or not period in ["day","night"] or slot in w.used_slots: return false
 if not map_id in w.unlocked or not maps.has(map_id) or not spawn_id in w.spawns[map_id]: return false
 var t := s.duplicate(true)
 cleanup_session(t)
 t.expedition = {"active":true,"id":t.world.exploration.next_session,"period":period,"map_id":map_id,"point_id":spawn_id,"maps":{},"search":{}}
 t.world.exploration.next_session += 1
 t.world.exploration.used_slots.append(slot)
 ensure_map(t,map_id)
 inventory.commit(s,t)
 return true
func ensure_map(s: Dictionary, id: String) -> void:
 if s.expedition.maps.has(id): return
 var runtime := {"enemies":{},"containers":{}}
 for enemy: Dictionary in maps[id].get("enemies",[]): runtime.enemies[enemy.id] = enemy.duplicate(true)
 s.expedition.maps[id] = runtime
 for box: Dictionary in maps[id].get("containers",[]):
  var cid := "exp_%s_%s_%s" % [s.expedition.id,id,box.id]
  s.containers[cid] = inventory.container(0,0,-1)
  s.expedition.maps[id].containers[box.id] = {"container_id":cid,"revealed":[],"position":box.get("position",[0,0]),"search_seconds":box.get("search_seconds",0.5)}
  for entry: Dictionary in box.get("loot",[]):
   if not loot_allowed(s,entry): continue
   inventory.spawn(s,entry.definition_id,cid,int(entry.get("quantity",1)))
func loot_allowed(s: Dictionary, entry: Dictionary) -> bool:
 var door_key: String = entry.get("door_key","")
 return door_key.is_empty() or not s.world.exploration.doors.has(door_key)
func active(s: Dictionary) -> bool:
 return s.expedition.get("active",false)
func point(s: Dictionary, id: String, kind: String) -> Dictionary:
 if not active(s): return {}
 var p: Dictionary = maps[s.expedition.map_id].points.get(id,{})
 return p if p.get("kind","") == kind else {}
func exit_map(s: Dictionary, exit_id: String) -> bool:
 var p := point(s,exit_id,"exit")
 if p.is_empty() or not p.target_map in s.world.exploration.unlocked: return false
 var t := s.duplicate(true)
 ensure_map(t,p.target_map)
 t.expedition.map_id = p.target_map
 t.expedition.point_id = p.target_point
 t.expedition.search = {}
 inventory.commit(s,t)
 return true
func discover(s: Dictionary, id: String) -> bool:
 if point(s,id,"spawn").is_empty(): return false
 var known: Array = s.world.exploration.spawns[s.expedition.map_id]
 if not id in known: known.append(id)
 return true
func repair_travel(s: Dictionary, id: String, costs: Dictionary) -> bool:
 if point(s,id,"travel").is_empty(): return false
 var key: String = s.expedition.map_id+":"+id
 if s.world.exploration.travel.has(key): return true
 var t := s.duplicate(true)
 for material: String in costs:
  if not inventory.consume(t,material,int(costs[material])): return false
 t.world.exploration.travel[key] = true
 inventory.commit(s,t)
 return true
func travel(s: Dictionary, source_id: String, target_map: String, target_id: String, cost: float) -> bool:
 if point(s,source_id,"travel").is_empty() or not maps.has(target_map) or not is_finite(cost) or cost < 0: return false
 var w: Dictionary = s.world.exploration
 if not target_map in w.unlocked or not w.travel.has(s.expedition.map_id+":"+source_id) or not w.travel.has(target_map+":"+target_id): return false
 if maps[target_map].points.get(target_id,{}).get("kind","") != "travel": return false
 var t := s.duplicate(true)
 var remaining := cost
 for item: Dictionary in inventory.items_in(t,"bag"):
  if not item.get("is_battery",false): continue
  var paid := minf(remaining,item.energy)
  item.energy -= paid
  remaining -= paid
 if remaining > 0: return false
 ensure_map(t,target_map)
 t.expedition.map_id = target_map
 t.expedition.point_id = target_id
 t.expedition.search = {}
 inventory.commit(s,t)
 return true
func unlock_door(s: Dictionary, door_id: String, key_type: String) -> bool:
 if not active(s) or not maps[s.expedition.map_id].get("doors",{}).has(door_id): return false
 var key: String = s.expedition.map_id+":"+door_id
 if s.world.exploration.doors.has(key): return true
 if maps[s.expedition.map_id].doors[door_id] != key_type: return false
 var t := s.duplicate(true)
 if not inventory.consume(t,key_type,1): return false
 t.world.exploration.doors[key] = true
 inventory.commit(s,t)
 return true
func kill(s: Dictionary, enemy_id: String) -> bool:
 if not active(s): return false
 var enemies: Dictionary = s.expedition.maps[s.expedition.map_id].enemies
 if not enemies.has(enemy_id) or enemies[enemy_id].get("dead",false): return false
 enemies[enemy_id].dead = true
 return true
func box(s: Dictionary, id: String) -> Dictionary:
 if not active(s): return {}
 if s.world.exploration.death_bags.has(id):
  var b: Dictionary = s.world.exploration.death_bags[id]
  return b if b.map_id == s.expedition.map_id else {}
 return s.expedition.maps[s.expedition.map_id].containers.get(id,{})
func open_search(s: Dictionary, id: String) -> bool:
 if box(s,id).is_empty(): return false
 s.expedition.search = {"box_id":id,"elapsed":0.0}
 return true
func close_search(s: Dictionary) -> void:
 s.expedition.search = {}
func tick_search(s: Dictionary, dt: float, paused: bool = false) -> void:
 if paused or not active(s) or s.expedition.search.is_empty() or not is_finite(dt) or dt <= 0: return
 var search: Dictionary = s.expedition.search
 var b := box(s,search.box_id)
 search.elapsed += dt
 var duration := maxf(0.01,b.get("search_seconds",0.5))
 for item: Dictionary in inventory.items_in(s,b.container_id):
  if item.id in b.revealed: continue
  if search.elapsed < duration: break
  search.elapsed -= duration
  b.revealed.append(item.id)
func pickup(s: Dictionary, box_id: String, item_id: String) -> bool:
 var b := box(s,box_id)
 if b.is_empty() or s.expedition.search.get("box_id","") != box_id: return false
 if not item_id in b.revealed or not s.items.has(item_id) or s.items[item_id].container_id != b.container_id: return false
 return inventory.move(s,item_id,"bag").ok
func take_all(s: Dictionary, id: String) -> Array:
 var b := box(s,id)
 var taken: Array = []
 if b.is_empty(): return taken
 for item_id: String in b.revealed.duplicate():
  if pickup(s,id,item_id): taken.append(item_id)
 return taken
func finish(s: Dictionary, died: bool, position: Array = [0,0], retention_days: int = 3, extraction_id: String = "") -> Dictionary:
 if not active(s): return {"ok":false}
 if not died and point(s,extraction_id,"extraction").is_empty(): return {"ok":false}
 var t := s.duplicate(true)
 if died:
  var id := "death_%s" % t.expedition.id
  t.containers[id] = inventory.container(0,0,-1)
  var revealed: Array = []
  for item: Dictionary in inventory.items_in(t,"bag"):
   item.container_id = id
   revealed.append(item.id)
  t.world.exploration.death_bags[id] = {"container_id":id,"revealed":revealed,"map_id":t.expedition.map_id,"position":position.duplicate(),"expires_day":int(t.day)+maxi(1,retention_days),"search_seconds":0.01}
 if t.player.has("max_hp"): t.player.hp = t.player.max_hp
 if t.player.has("vitals"): t.player.vitals.hp = t.player.vitals.max_hp
 var period: String = t.expedition.period
 t.expedition.active = false
 t.expedition.search = {}
 inventory.commit(s,t)
 return {"ok":true,"period":period,"requires_settlement":true,"died":died}
func cleanup_session(s: Dictionary) -> void:
 var containers: Array = []
 for id: String in s.containers:
  if id.begins_with("exp_"): containers.append(id)
 for id: String in containers: clear_container(s,id)
func clear_container(s: Dictionary, id: String) -> void:
 for item: Dictionary in inventory.items_in(s,id):
  for plugin_id: String in item.plugins.values(): inventory.destroy(s,plugin_id)
  item.plugins = {}
  inventory.destroy(s,item.id)
 s.containers.erase(id)
func expire(s: Dictionary, day: int) -> void:
 setup(s)
 for id: String in s.world.exploration.death_bags.keys():
  if day >= s.world.exploration.death_bags[id].expires_day:
   clear_container(s,id)
   s.world.exploration.death_bags.erase(id)
func enemy_loot(s: Dictionary, enemy_id: String, loot: Array) -> bool:
 if not active(s): return false
 var runtime: Dictionary = s.expedition.maps[s.expedition.map_id]
 if not runtime.enemies.has(enemy_id) or not runtime.enemies[enemy_id].get("dead",false): return false
 var box_id := "loot_"+enemy_id
 if runtime.containers.has(box_id): return false
 var t := s.duplicate(true)
 var cid := "exp_%s_%s_%s" % [t.expedition.id,t.expedition.map_id,box_id]
 t.containers[cid] = inventory.container(0,0,-1)
 t.expedition.maps[t.expedition.map_id].containers[box_id] = {"container_id":cid,"revealed":[],"position":runtime.enemies[enemy_id].get("position",[0,0]),"search_seconds":0.5}
 for entry: Dictionary in loot:
  if not loot_allowed(t,entry): continue
  if inventory.spawn(t,entry.definition_id,cid,int(entry.get("quantity",1))).is_empty(): return false
 inventory.commit(s,t)
 return true
func unlock_map(s: Dictionary, id: String) -> bool:
 setup(s)
 if not maps.has(id): return false
 if not id in s.world.exploration.unlocked: s.world.exploration.unlocked.append(id)
 return true
func movement_blocked(s: Dictionary) -> bool:
 return active(s) and not s.expedition.search.is_empty()
func markers(s: Dictionary, main_markers: Array = []) -> Array:
 setup(s)
 var result := main_markers.duplicate(true)
 for map_id: String in s.world.exploration.spawns:
  if not map_id in s.world.exploration.unlocked: continue
  for id: String in s.world.exploration.spawns[map_id]: result.append({"kind":"spawn","map_id":map_id,"id":id})
 for id: String in s.world.exploration.death_bags:
  var b: Dictionary = s.world.exploration.death_bags[id]
  result.append({"kind":"death_bag","map_id":b.map_id,"id":id,"position":b.position,"remaining_days":maxi(0,b.expires_day-int(s.day))})
 return result
