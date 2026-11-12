extends SceneTree
func _initialize():call_deferred('run')
func run():
 var hits:=0
 for seed_value in range(1,9):
  var a=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(a)
  for i in range(8):await physics_frame
  a.cycle.to_dusk(a.state)
  var rng:=RandomNumberGenerator.new();rng.seed=seed_value;a.state.rng_state=str(rng.state)
  await a.depart('suburbs','south',true,true)
  for i in range(3):await physics_frame
  var box=a.exploration.box(a.state,a.catalog.suburbs.containers[-1].id)
  var count:=0
  for item in a.inventory.items_in(a.state,box.container_id):
   if item.definition_id=='catalyst':count+=int(item.quantity)
  print('SEED ',seed_value,' NIGHT_CATALYST ',count)
  if count>0:hits+=1
  a.queue_free()
  for i in range(3):await physics_frame
 print('NIGHT CATALYST HITS ',hits)
 quit(0 if hits>0 and hits<8 else 1)
