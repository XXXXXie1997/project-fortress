extends SceneTree
func _initialize():
 var arena=load('res://scenes/base/base_defense.tscn').instantiate();root.add_child(arena)
 for i in 10:await physics_frame
 assert(arena.fixtures.size()>=8)
 assert(arena.residents.size()==2)
 var energy:float=arena.state.base.energy_store.energy
 arena.start_fixture_wave()
 assert(arena.running)
 assert(not arena.queue.is_empty())
 for i in 900:await physics_frame
 assert(arena.queue.is_empty())
 assert(arena.state.base.shield.energy<100)
 var charged:=false
 for resident in arena.state.base.residents:
  if arena.state.items[resident.weapon_instance].energy>0:charged=true
 assert(charged)
 assert(arena.state.base.energy_store.energy<energy+100)
 for enemy in arena.targets:arena.hit(enemy,100000,{'penetration':10000.0})
 for i in 5:await physics_frame
 assert(not arena.running)
 assert(arena.state.day==2)
 print('DEV402 ENTITY SELF CHECK PASS')
 quit()

