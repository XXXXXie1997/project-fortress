extends SceneTree
func _initialize():
 var a=load('res://scenes/base/base_defense.tscn').instantiate();root.add_child(a)
 for i in 20:await physics_frame
 a.start_wave()
 a.queue.clear()
 a.spawn_timer=999
 var p=a.grid.logical_to_world(Vector2(1500,470))
 var d={'id':'qa','type':'basic','position':[p.x,p.y]}
 a.state.expedition.maps.base.enemies.qa=d.duplicate(true);a.spawn_enemy(d)
 for e in a.targets:e.set_physics_process(false)
 for r in a.residents:r.set_physics_process(false)
 for f in a.fixtures:f.set_physics_process(false)
 a.player.set_physics_process(false)
 var shield=a.fixtures[-1]
 var bank=a.state.base.energy_store.energy
 a.fire_base(a.grid.logical_to_world(Vector2(1230,470)),shield.position,10,true)
 for i in 40:await physics_frame
 print('QA_SHIELD ',a.state.base.shield.energy,' bank_same=',a.state.base.energy_store.energy==bank)
 assert(a.state.base.shield.energy==90)
 assert(a.state.base.energy_store.energy==bank)
 a.state.base.energy_store.energy=0
 var r=a.residents[0]
 r.position=a.station+a.grid.logical_vector_to_world(Vector2(0,90));r.set_physics_process(true)
 for i in 120:await physics_frame
 assert(a.state.items[r.data().weapon_instance].energy==0)
 print('QA_NO_FREE_CHARGE PASS')
 r.receive_damage(999)
 var inv=JSON.stringify(a.state.items)
 r.receive_damage(999)
 assert(JSON.stringify(a.state.items)==inv)
 print('QA_SINGLE_DEATH PASS')
 a.state.player.vitals.hp=0
 for i in 5:await physics_frame
 var snap=JSON.stringify(a.state)
 for i in 120:await physics_frame
 assert(snap==JSON.stringify(a.state))
 print('QA_SETTLEMENT_STABLE PASS')
 quit()
