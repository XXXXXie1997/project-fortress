extends SceneTree
const Save=preload("res://scripts/persistence/save_service.gd")
func _initialize():
 var svc=Save.new("res://.godot-local/qa-save-v2-"+str(Time.get_ticks_usec()))
 var s=WorldState.fresh()
 svc.request("first",s)
 s.run_failed=true
 svc.capture_failure("first",s)
 assert(svc.shutdown().ok)
 assert(svc.load_snapshot("first").ok and svc.load_snapshot("first","failure").ok)
 s=WorldState.fresh()
 s.world.entities=[]
 for i in range(10000): s.world.entities.append({"id":i,"position":[i,2],"alive":true})
 var times=[]
 for i in range(10):
  var t=Time.get_ticks_usec()
  svc.request("race",s)
  times.append(Time.get_ticks_usec()-t)
 var t=Time.get_ticks_usec()
 svc.tick(1.0)
 print("request us=",times," dispatch tick us=",Time.get_ticks_usec()-t)
 s.day=12
 svc.request("race",s)
 s.day=13
 svc.request("race",s,"morning")
 s.day=99
 assert(svc.shutdown().ok and svc.worker==null)
 assert(svc.load_snapshot("race").state.day==12)
 assert(svc.load_snapshot("race","morning").state.day==13)
 print("P1 and in-flight version isolation PASS")
 s=WorldState.fresh()
 svc.request("error",s)
 svc.fail_next="write"
 svc.tick(1.0)
 while svc.worker.is_alive(): OS.delay_msec(1)
 print("tick failure result=",svc.tick(0.01)," stored=",svc.last_result)
 assert(not svc.last_result.ok)
 assert(svc.shutdown().ok)
 assert(svc.load_snapshot("error").ok)
 for mode in ["truncated","version","type","checksum"]:
  var slot="bad_"+mode
  svc.request(slot,s)
  assert(svc.flush().ok)
  var path=svc.root.path_join(slot).path_join("latest.json")
  var raw=FileAccess.get_file_as_string(path)
  var e=JSON.parse_string(raw)
  if mode=="version": e.format=999
  if mode=="type": e.type="other"
  if mode=="checksum": e.sha256="wrong"
  var bad="{" if mode=="truncated" else JSON.stringify(e)
  var f=FileAccess.open(path,FileAccess.WRITE)
  f.store_string(bad);f.close()
  assert(not svc.load_snapshot(slot).ok)
  svc.request(slot,s)
  assert(not svc.flush().ok)
  assert(FileAccess.get_file_as_string(path)==bad)
  svc.pending.erase(slot+"/latest")
 assert(svc.shutdown().ok)
 svc=null
 print("corruption preserved; joined release PASS")
 quit()
