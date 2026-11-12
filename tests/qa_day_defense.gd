extends SceneTree
func _init():
 var d = load("res://scripts/base/defense_resolution.gd").new()
 var s = {"base":{"buildings":{"warehouse":{"type":"warehouse","durability":100,"maximum":100},"turret":{"type":"turret","durability":100,"maximum":100}},"energy_store":{"energy":100},"residents":[{"id":"r1","hp":30,"max_hp":100,"power":20}]},"rng_state":"123"}
 for n in range(100):
  s.rng_state = str(n*12345)
  var out = d.resolve(d.capture(s,10,"test"))
  assert(out.result.held and out.result.dead.is_empty())
  assert(out.base.residents[0].hp == 100)
  assert(out.result.energy_spent == 5)
 s.base.energy_store.energy = 0
 assert(d.evaluate(d.capture(s,10,"test")).power == 0)
 var snap = d.capture(s,10,"test")
 snap.base.buildings.warehouse.durability = 0
 snap.base.buildings["cheap"] = {"type":"farm","durability":100,"maximum":100}
 assert(d.lost(snap))
 var t = load("res://scripts/base/threat_service.gd").new()
 var world = {"day":1,"quests":{"pending_stages":[]}}
 t.setup(world)
 assert(t.schedule(world,"major",true,true))
 var ev = world.threat.events.major.duplicate(true)
 world.quests.pending_stages.append({"id":"up","stage":2,"effective_day":2})
 t.morning(world)
 assert(world.threat.stage == 1)
 world.day = 2
 t.morning(world)
 assert(world.threat.stage == 2 and world.threat.entered_day == 2)
 assert(world.threat.events.major == ev and ev.day == 3)
 print("QA defense 100 seeds, shortage, fixed weights, frozen event, next-day stage PASS")
 quit()
