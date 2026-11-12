extends SceneTree
const Save = preload("res://scripts/persistence/save_service.gd")
func _initialize():
 var args:=OS.get_cmdline_user_args()
 var svc:=Save.new(args[1])
 if args[0]=="read":
  var got: Dictionary=svc.load_snapshot("slot1")
  assert(got.ok and got.state.quests.unknown.reward==7)
  assert(got.state.rng_state=="9223372036854775807")
  assert(svc.load_snapshot("slot1","morning").state.day==1)
  assert(svc.load_snapshot("slot1","failure").state.run_failed)
  assert(svc.load_tutorial().state.completed==["intro"])
  print("SAVE RESTART READ PASSED")
  quit()
  return
 var s:=WorldState.fresh()
 s.quests={"unknown":{"reward":7}}
 s.rng_state="9223372036854775807"
 s.base={"energy_store":{"energy":12.0,"capacity":100.0},"orders":[{"prepaid":17}]}
 s.expedition={"search":{"elapsed":0.3},"death_bags":[{"expires":9}]}
 s.progression={"tech":["seed"]};s.trade={"stock":["x"]};s.settled_ids=["1:night"]
 var item:=WorldState.create_item(s,"weapon","equipment")
 item.plugins={"tactical":"item_2"}
 WorldState.create_item(s,"light","plugin")
 assert(not svc.request("../bad",s).ok)
 assert(svc.request("slot1",s,"morning").ok)
 assert(svc.request("slot1",s).ok)
 s.quests.unknown.reward=99
 assert(svc.flush().ok)
 assert(svc.load_snapshot("slot1").state.quests.unknown.reward==7)
 s.quests.unknown.reward=7
 svc.begin_transaction("slot1")
 assert(not svc.request("slot1",s).ok)
 assert(svc.end_transaction("slot1",s).ok)
 svc.request("slot1",s)
 assert(svc.merged==1)
 svc.fail_next="write"
 assert(not svc.flush().ok and svc.pending.size()==1)
 assert(svc.load_snapshot("slot1").ok)
 svc.fail_next="before_replace"
 assert(not svc.flush().ok)
 svc.fail_next="after_backup"
 assert(not svc.flush().ok)
 assert(svc.load_snapshot("slot1").get("recovered",false))
 assert(svc.flush().ok)
 s.run_failed=true
 var failure_result: Dictionary=svc.capture_failure("slot1",s)
 print(failure_result)
 if not failure_result.ok: quit(1); return
 assert(not svc.request("slot1",s).ok)
 assert(svc.flush().ok)
 assert(not svc.load_snapshot("slot1").state.get("run_failed",false))
 assert(svc.save_tutorial(["intro"]).ok)
 var large:=WorldState.fresh()
 large.world.extra=[]
 for i in range(10000): large.world.extra.append({"id":i,"position":[i,2],"alive":true})
 var start:=Time.get_ticks_usec()
 for i in range(10): svc.request("bench",large)
 assert(svc.flush().ok)
 print("SAVE SELF CHECK PASSED; 10 requests elapsed_us=",Time.get_ticks_usec()-start," writes=",svc.writes," merged=",svc.merged)
 quit()



