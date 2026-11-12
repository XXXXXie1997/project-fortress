extends SceneTree
func _initialize():
 var arena=load('res://scenes/base/base_defense.tscn').instantiate();root.add_child(arena)
 for i in 10:await physics_frame
 arena.start_fixture_wave()
 for i in 50:await physics_frame
 assert(arena.targets.size()>0 and arena.queue.size()>0)
 arena.state.player.vitals.hp=0
 for i in 5:await physics_frame
 assert(not arena.running and arena.targets.is_empty() and arena.queue.is_empty())
 var snapshot:=JSON.stringify(arena.state)
 for i in 120:await physics_frame
 assert(JSON.stringify(arena.state)==snapshot)
 print('DEV402 DOWNED SETTLEMENT QUIESCENT PASS')
 quit()

