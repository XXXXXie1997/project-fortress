extends SceneTree
func _initialize():call_deferred('run')
func run():
 var a=load('res://scenes/maps/exploration.tscn').instantiate();root.add_child(a)
 for i in 15:await physics_frame
 var catalog=load('res://scripts/content/catalog.gd')
 var inv:InventoryService=a.inventory
 a.state.base.energy_store.energy=900.;a.state.base.technology={'storage':true}
 inv.spawn(a.state,'scrap','warehouse',80);inv.spawn(a.state,'boss_core','warehouse',1)
 var station:=''
 for id in a.state.base.buildings:
  if a.state.base.buildings[id].type=='workstation':station=id
 var production:=ProductionService.new(a.services.building,catalog.recipes())
 var work:=WorkstationService.new(production,catalog.equipment())
 assert(work.craft(a.state,station,'rifle_basic',1));assert(production.settle(a.state,'map-content-craft'))
 var gun_id:=''
 for item in inv.items_in(a.state,'warehouse'):
  if item.definition_id=='rifle_basic':gun_id=item.id
 var plugin:Dictionary=inv.spawn(a.state,'scope_basic','warehouse')
 assert(work.modify(a.state,station,gun_id,'install',plugin.id))
 assert(work.modify(a.state,station,gun_id,'upgrade','rifle_advanced'))
 a.state.trade.day=-1;assert(a.services.trade.refresh(a.state,3))
 var blade_id:=''
 for item in inv.items_in(a.state,'shop'):
  if item.definition_id=='trade_blade':blade_id=item.id
 assert(a.services.trade.transact(a.state,[],[blade_id],'warehouse').ok)
 assert(inv.equip(a.state,gun_id,'weapon_1',true).ok)
 assert(inv.equip(a.state,blade_id,'weapon_2',true).ok)
 await a.depart('suburbs','south')
 for i in 15:await physics_frame
 for enemy in a.targets:enemy.set_physics_process(false)
 var p=a.player;var enemy=a.targets[0]
 enemy.position=p.position+Vector2(70,0)
 var gun:Dictionary=a.state.items[gun_id]
 a.state.items[gun.id].energy=50.;p.slot=1
 var point:Vector2=a.get_canvas_transform()*enemy.global_position
 var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;Input.parse_input_event(motion)
 var before:float=enemy.record().vitals.hp
 var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.global_position=point;event.pressed=true;Input.parse_input_event(event.duplicate())
 for i in 30:await physics_frame
 event.pressed=false;Input.parse_input_event(event.duplicate())
 assert(enemy.record().vitals.hp<before,'Actual map projectile must damage target')
 assert(a.state.items[gun.id].energy<50.)
 p.slot=2;p.cooldown=0
 enemy.position=p.position+Vector2(45,0)
 point=a.get_canvas_transform()*enemy.global_position
 motion.position=point;motion.global_position=point;Input.parse_input_event(motion)
 before=enemy.record().vitals.hp
 event.position=point;event.global_position=point;event.pressed=true;Input.parse_input_event(event.duplicate())
 for i in 4:await physics_frame
 event.pressed=false;Input.parse_input_event(event.duplicate())
 assert(enemy.record().vitals.hp<before,'Purchased blade must hit in map')
 assert(a.state.items[gun_id].plugins.scope==plugin.id)
 print('CONTENT_MAP_INPUT_ATTACK_PASS');quit()

