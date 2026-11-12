extends SceneTree
func _initialize():call_deferred("run")
func run():
 var a=load("res://scenes/ui/base/base_management_arena.tscn").instantiate();root.add_child(a)
 while a.management==null:await process_frame
 a.hud.open_inventory()
 var p=a.management.inventory_panel
 print("QA303_CHARGE_CONNECTIONS=",p.charging_requested.get_connections().size())
 p.movement_lock_changed.emit(true)
 print("QA303_PLAYER_MOVEMENT_LOCK=",a.player.inventory_movement_locked)
 a.queue_free();await process_frame;quit()
