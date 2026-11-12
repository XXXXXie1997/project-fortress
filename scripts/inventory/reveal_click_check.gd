extends "res://tests/ui_input_helpers.gd"
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1280,720)
 var shell=load("res://scenes/main.tscn").instantiate();root.add_child(shell);shell.tutorial_enabled=false
 shell.coordinator.saver=SaveService.new("user://qa606-timing-%s"%Time.get_ticks_usec())
 assert(shell.coordinator.create_world(11).ok)
 while shell.arena==null or shell.mounting or shell.mount_queued:await process_frame
 assert(shell.coordinator.depart("suburbs","south").ok);shell.queue_mount()
 while shell.mounting or shell.mount_queued:await process_frame
 var s:Dictionary=shell.coordinator.state
 var chosen:String=""
 for key in s.expedition.maps.suburbs.containers:
  var b:Dictionary=s.expedition.maps.suburbs.containers[key]
  if shell.arena.inventory.items_in(s,b.container_id).size()>=2:chosen=key;break
 assert(chosen!="")
 var box:Dictionary=shell.arena.exploration.box(s,chosen)
 shell.arena.player.position=Vector2(box.position[0],box.position[1])
 shell.arena.hud.open_inventory(chosen)
 var p=shell.arena.hud.inventory_panel
 while box.revealed.size()<1:await process_frame
 var first:String=box.revealed[0]
 var original=find_button(p,"全部拾取已揭示");assert(original!=null)
 var cancel_point:Vector2=original.get_global_rect().get_center()
 var cancel_down:=InputEventMouseButton.new();cancel_down.position=cancel_point;cancel_down.button_index=1;cancel_down.pressed=true
 root.push_input(cancel_down,true)
 p.refresh()
 var outside:=Vector2(5,5)
 var motion:=InputEventMouseMotion.new();motion.position=outside;motion.button_mask=1;root.push_input(motion,true)
 var cancel_up:=InputEventMouseButton.new();cancel_up.position=outside;cancel_up.button_index=1;cancel_up.pressed=false;root.push_input(cancel_up,true)
 await process_frame
 assert(s.items[first].container_id==box.container_id)
 original=find_button(p,"全部拾取已揭示")
 cancel_down.position=original.get_global_rect().get_center();root.push_input(cancel_down,true)
 p.close_panel();cancel_up.position=cancel_down.position;root.push_input(cancel_up,true);await process_frame
 assert(s.items[first].container_id==box.container_id)
 p.open_panel(chosen)
 for n in 3:await process_frame
 original=find_button(p,"全部拾取已揭示")
 print("MOVE_OUT_AND_CLOSE_CANCEL_PASS")
 var callbacks:=[0]
 original.pressed.connect(func():callbacks[0]+=1)
 var original_id:int=original.get_instance_id()
 var point:Vector2=original.get_global_rect().get_center()
 var down:=InputEventMouseButton.new();down.position=point;down.button_index=1;down.pressed=true;root.push_input(down,true)
 print("DOWN id=",original_id," count=",box.revealed.size()," pressed=",original.is_pressed()," queued=",original.is_queued_for_deletion())
 while box.revealed.size()<2:await process_frame
 var replacement=find_button(p,"全部拾取已揭示")
 print("UP old_valid=",is_instance_valid(original)," new_id=",replacement.get_instance_id()," count=",box.revealed.size()," rect=",replacement.get_global_rect())
 assert(not paused and p.visible)
 var revealed_at_release:Array=box.revealed.duplicate()
 var hidden_ids:Array=[]
 for id in shell.arena.inventory.items_in(s,box.container_id):
  if not revealed_at_release.has(id.id):hidden_ids.append(id.id)
 var up:=InputEventMouseButton.new();up.position=point;up.button_index=1;up.pressed=false;root.push_input(up,true);await process_frame
 print("RESULT first_container=",s.items[first].container_id," expected_bag; box=",box.container_id)
 assert(s.items[first].container_id=="bag")
 for id in hidden_ids:assert(s.items[id].container_id==box.container_id)
 assert(callbacks[0]==1)
 root.push_input(up,true);await process_frame
 for id in hidden_ids:assert(s.items[id].container_id==box.container_id)
 assert(callbacks[0]==1)
 print("REFRESH_HELD_CLICK_SINGLE_TRANSFER_PASS")
 shell.request_exit()




