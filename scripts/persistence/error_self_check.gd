extends SceneTree
const Save=preload("res://scripts/persistence/save_service.gd")
func _initialize():
 var svc:=Save.new("res://.godot-local/save-error-v3-"+str(Time.get_ticks_usec()))
 var s:=WorldState.fresh()
 svc.request("slot",s)
 svc.fail_next="write"
 assert(svc.tick(1.0).started)
 while svc.worker.is_alive(): OS.delay_msec(1)
 var failed: Dictionary=svc.tick(0.01)
 assert(not failed.ok and failed.errors[0].error=="injected_write_failure")
 assert(svc.pending.size()==1 and svc.worker==null)
 for i in range(3):
  assert(not svc.tick(1.0).ok and svc.worker==null)
  assert(not svc.poll().ok)
 # Explicit retry may start but must not claim disk success before completion.
 assert(svc.dispatch().started)
 while svc.worker.is_alive(): OS.delay_msec(1)
 assert(svc.poll().ok and svc.pending.is_empty())
 assert(svc.tick(0.01).ok and svc.load_snapshot("slot").ok)
 svc.request("slot",s)
 svc.fail_next="write"
 svc.dispatch()
 while svc.worker.is_alive(): OS.delay_msec(1)
 assert(not svc.poll().ok)
 assert(not svc.tick(2.0).ok)
 assert(svc.shutdown().ok and svc.worker==null)
 assert(svc.poll().ok)
 print("ERROR PROPAGATION/STICKY RETRY SELF CHECK PASSED")
 quit()
