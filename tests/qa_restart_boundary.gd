extends SceneTree
func _initialize():
 var defs: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items
 var inv:=InventoryService.new(defs)
 var b:=BuildingService.new(inv,JSON.parse_string(FileAccess.get_file_as_string("res://data/buildings.json")))
 var e:=ExplorationService.new(inv,JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/exploration.json")).maps)
 var r:=RunRestart.new(inv,b,e,QuestService.new(inv))
 var saver:=SaveService.new("res://.godot-local/qa_restart_boundary")
 if "read" in OS.get_cmdline_user_args():
  var morning:=r.restore(saver,"slot",true)
  print("CROSS_PROCESS_SECOND_MORNING_DAY=",morning.state.day)
  quit();return
 var old: Dictionary=r.new_game(75).state
 old.day=8
 saver.request("slot",old);saver.request("slot",old,"morning");saver.shutdown()
 var accepted:=r.persist_choice(saver,"slot",r.new_game(89))
 assert(accepted.ok)
 var morning:=r.restore(saver,"slot",true)
 assert(morning.ok and morning.state.day==1)
 saver.request("slot",morning.state);assert(saver.shutdown().ok)
 var again:=r.restore(saver,"slot",true)
 print("FIRST_MORNING_DAY=",morning.state.day," SECOND_MORNING_DAY=",again.state.day)
 saver.request("cancel",old);saver.capture_failure("cancel",old);assert(saver.shutdown().ok)
 saver.fail_next="write"
 var rejected:=r.persist_choice(saver,"cancel",r.new_game(90))
 print("CHOICE_OK=",rejected.ok," DISK_IMMEDIATELY=",saver.load_snapshot("cancel").state.day," PENDING=",saver.pending.size()," FAILURE_LOCK=",saver.failed_slots.has("cancel"))
 assert(saver.shutdown().ok)
 print("CANCEL_THEN_SHUTDOWN_DISK_DAY=",saver.load_snapshot("cancel").state.day)
 quit()
