extends SceneTree
const Save=preload("res://scripts/persistence/save_service.gd")
func _initialize():
 var svc=Save.new("res://.godot-local/qa-save-v3-"+str(Time.get_ticks_usec()))
 var s=WorldState.fresh()
 svc.request("slot",s)
 svc.fail_next="write"
 svc.tick(1)
 while svc.worker.is_alive(): OS.delay_msec(1)
 var result=svc.tick(0.01)
 assert(not result.ok and result.errors[0].error=="injected_write_failure")
 for i in range(3):
  assert(not svc.poll().ok and not svc.tick(2).ok and svc.worker==null)
 s.day=2
 svc.request("slot",s)
 assert(svc.dispatch().started)
 s.day=3
 svc.request("slot",s)
 while svc.worker.is_alive(): OS.delay_msec(1)
 assert(svc.poll().ok)
 assert(svc.pending.size()==1)
 assert(svc.load_snapshot("slot").state.day==2)
 assert(svc.shutdown().ok and svc.pending.is_empty() and svc.worker==null)
 assert(svc.load_snapshot("slot").state.day==3 and svc.poll().ok)
 s.day=4
 svc.request("slot",s)
 svc.fail_next="before_replace"
 svc.dispatch()
 while svc.worker.is_alive(): OS.delay_msec(1)
 assert(not svc.poll().ok and not svc.tick(0.01).ok)
 assert(svc.shutdown().ok and svc.poll().ok)
 assert(svc.load_snapshot("slot").state.day==4)
 print("QA v3 error propagation/repeated poll/new pending/retry/join PASS")
 quit()
