extends SceneTree
const Save = preload("res://scripts/persistence/save_service.gd")
func _initialize():
 var svc:=Save.new(OS.get_cmdline_user_args()[0])
 var s:=WorldState.fresh()
 s.world.entities=[]
 for i in range(10000): s.world.entities.append({"id":i,"position":[i,2],"alive":true})
 var samples: Array=[]
 for i in range(10):
  s.world.revision=i
  var started:=Time.get_ticks_usec()
  assert(svc.request("race",s).ok)
  samples.append(Time.get_ticks_usec()-started)
 assert(svc.dispatch().ok)
 # Modify live state and enqueue version 11 while version 10 is in flight.
 s.world.revision=123
 assert(svc.request("race",s).ok)
 s.world.revision=999
 assert(svc.shutdown().ok)
 assert(svc.worker==null)
 assert(svc.load_snapshot("race").state.world.revision==123)
 print("LARGE WORKER TIMINGS=",svc.last_timings)
 var valid:=WorldState.fresh()
 valid.world.revision=7
 svc.request("new_slot",valid)
 valid.run_failed=true
 svc.capture_failure("new_slot",valid)
 assert(svc.shutdown().ok)
 assert(svc.load_snapshot("new_slot").state.world.revision==7)
 assert(not svc.load_snapshot("new_slot").state.get("run_failed",false))
 assert(svc.load_snapshot("new_slot","failure").state.run_failed)
 print("ASYNC RACE/FAILURE PASSED capture_us=",samples," timings=",svc.last_timings," writes=",svc.writes," merged=",svc.merged)
 quit()

