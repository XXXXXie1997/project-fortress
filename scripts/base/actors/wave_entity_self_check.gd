extends SceneTree
func _initialize():
 var a=load('res://scenes/base/base_defense.tscn').instantiate();root.add_child(a)
 for i in 20:await physics_frame
 a.start_wave()
 assert(a.state.base.wave_plan.budget==a.state.cycle.night.snapshot.enemy_power)
 assert(is_equal_approx(a.remaining_enemy_power(),a.state.base.wave_plan.budget))
 for i in 40:await physics_frame
 assert(a.targets.size()>0)
 var first=a.targets[0]
 first.record().vitals.hp=first.record().vitals.max_hp*0.5
 var before:float=a.remaining_enemy_power()
 assert(before<a.state.base.wave_plan.budget)
 a.running=false
 for enemy in a.targets:enemy.set_physics_process(false);enemy.hide();enemy.queue_free()
 a.targets.clear()
 var serialized:=JSON.stringify(a.state)
 a.state=JSON.parse_string(serialized)
 var rng:String=a.state.rng_state
 var queue_size:int=a.state.base.defense_runtime.queue.size()
 a.start_wave()
 assert(a.state.rng_state==rng)
 assert(a.queue.size()==queue_size)
 assert(is_equal_approx(a.remaining_enemy_power(),before))
 a.state.player.vitals.hp=0
 for i in 5:await physics_frame
 assert(not a.running)
 var snapshot:=JSON.stringify(a.state)
 for i in 120:await physics_frame
 assert(JSON.stringify(a.state)==snapshot)
 print('DEV402 FORMAL WAVE RESTORE RESIDUAL ENTITY PASS')
 quit()
