extends SceneTree
func _initialize():
 var a=load('res://scenes/base/base_defense.tscn').instantiate();root.add_child(a)
 for i in 20:await physics_frame
 a.player.set_physics_process(false)
 a.start_wave()
 a.queue.clear()
 var p=a.grid.logical_to_world(Vector2(1230,470))
 var d={'id':'qa2','type':'basic','position':[p.x,p.y]}
 a.state.expedition.maps.base.enemies.qa2=d.duplicate(true);a.spawn_enemy(d)
 var e=a.targets[0];e.set_physics_process(false)
 for r in a.residents:r.set_physics_process(false)
 for f in a.fixtures:f.set_physics_process(false)
 var hp=e.record().vitals.hp
 a.fire_base(a.grid.logical_to_world(Vector2(1090,470)),p,10,false)
 for i in 50:await physics_frame
 assert(e.record().vitals.hp<hp)
 print('QA_FRIENDLY_SHIELD_OUT PASS')
 var shield=a.fixtures[-1]
 var inside=a.grid.logical_to_world(Vector2(1090,470))
 assert(e.test_move(Transform2D(0,p),inside-p))
 shield.receive_damage(999)
 shield.set_physics_process(true)
 for i in 3:await physics_frame
 assert(not e.test_move(Transform2D(0,p),inside-p))
 print('QA_ENEMY_SHIELD_BREAK PASS')
 var turret
 var warehouse
 for f in a.fixtures:
  if f.kind=='turret':turret=f
  if f.kind=='warehouse':warehouse=f
 e.position=turret.position+Vector2(150,0)
 for i in 2:await physics_frame
 assert(a.nearest_defense(e.position)==turret)
 assert(a.nearest_enemy(turret.position,360)==e)
 turret.data().capacitor={'energy':1.0,'capacity':60.0}
 a.state.base.energy_store.energy=0
 turret.set_physics_process(true)
 for i in 35:await physics_frame
 assert(turret.data().capacitor.energy==0)
 a.state.base.energy_store.energy=20
 for i in 5:await physics_frame
 assert(a.state.base.energy_store.energy<20)
 turret.set_physics_process(false)
 print('QA_TURRET_NEAREST_DRAIN_RECHARGE PASS')
 warehouse.data().durability=0
 var r=a.residents[0];r.position=a.station+a.grid.logical_vector_to_world(Vector2(0,90))
 r.set_physics_process(true)
 var energy=a.state.items[r.data().weapon_instance].energy
 for i in 60:await physics_frame
 assert(a.state.items[r.data().weapon_instance].energy==energy)
 assert(not a.player.wireless_station_active())
 print('QA_DESTROYED_STATION PASS')
 r.set_physics_process(false);r.data().hp=10
 a.queue.append({'id':'pending','type':'basic','position':[p.x,p.y]});a.spawn_timer=999
 a.hit(e,100000,{'penetration':10000.0})
 for i in 5:await physics_frame
 assert(a.running)
 a.queue.clear()
 for i in 5:await physics_frame
 assert(not a.running)
 assert(r.data().hp==r.data().max_hp)
 var snap=JSON.stringify(a.state)
 for i in 120:await physics_frame
 assert(snap==JSON.stringify(a.state))
 print('QA_QUEUE_ALL_CLEAR_HEAL_STABLE PASS')
 quit()
