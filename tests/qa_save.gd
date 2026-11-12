extends SceneTree
const Save = preload("res://scripts/persistence/save_service.gd")
func _initialize():
 var args=OS.get_cmdline_user_args()
 var svc=Save.new(args[1])
 var s=WorldState.fresh()
 s.unknown={"nested":[{"energy":12,"id":"x","plugin":"p"}]}
 s.rng_state="9223372036854775807"
 s.settled_ids=["paid:123"]
 if args[0]=="read":
  assert(svc.load_snapshot("a").state.day==3)
  assert(svc.load_snapshot("a").state.unknown.nested[0].energy==12 and svc.load_snapshot("a").state.unknown.nested[0].plugin=="p")
  assert(svc.load_snapshot("a").state.rng_state==s.rng_state)
  assert(svc.load_snapshot("a").state.settled_ids==s.settled_ids)
  assert(svc.load_snapshot("a","morning").state.day==1)
  assert(svc.load_snapshot("a","failure").state.day==4)
  assert(svc.load_tutorial().state.completed==["intro"])
  print("QA cross process PASS")
  quit();return
 assert(not svc.request("../outside",s).ok)
 assert(svc.request("a",s,"morning").ok)
 assert(svc.request("a",s).ok)
 s.day=2
 assert(svc.request("a",s).ok)
 assert(svc.merged==1)
 assert(svc.flush().ok)
 assert(svc.load_snapshot("a").state.day==2)
 svc.begin_transaction("a")
 s.day=3
 assert(not svc.request("a",s).ok)
 assert(svc.load_snapshot("a").state.day==2)
 assert(svc.end_transaction("a",s).ok)
 assert(svc.flush().ok)
 for fault in ["write","before_replace","after_backup"]:
  s.day=4
  svc.request("a",s)
  svc.fail_next=fault
  assert(not svc.flush().ok)
  assert(svc.load_snapshot("a").state.day==3)
  s.day=3
  svc.request("a",s)
  assert(svc.flush().ok)
 s.day=4
 s.run_failed=true
 assert(svc.capture_failure("a",s).ok)
 assert(svc.flush().ok)
 assert(svc.load_snapshot("a").state.day==3)
 assert(svc.save_tutorial(["intro"]).ok)
 var fresh=WorldState.fresh()
 assert(svc.request("first",fresh).ok)
 fresh.run_failed=true
 assert(svc.capture_failure("first",fresh).ok)
 assert(svc.flush().ok)
 print("QA FIRST FAILURE latest=",svc.load_snapshot("first"))
 var large=WorldState.fresh()
 large.world.entities=[]
 for i in range(10000): large.world.entities.append({"id":i,"position":[i,2],"alive":true})
 var timings=[]
 for i in range(10):
  var start=Time.get_ticks_usec()
  svc.request("bench",large)
  timings.append(Time.get_ticks_usec()-start)
 print("QA request timings us=",timings)
 var start=Time.get_ticks_usec()
 assert(svc.flush().ok)
 print("QA flush us=",Time.get_ticks_usec()-start)
 print("QA baseline PASS; pending failure bug reproduced")
 quit()


