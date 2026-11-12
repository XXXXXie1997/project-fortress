extends SceneTree
func _initialize():
 var c=load('res://scripts/content/catalog.gd');assert(c.validate_upgrades().is_empty())
 var inv:=InventoryService.new(c.items());var s:=WorldState.fresh();inv.setup(s)
 var b:=BuildingService.new(inv,c.read('data/buildings.json'));b.setup(s)
 s.base.energy_store.energy=900.;s.base.technology={'storage':true};inv.spawn(s,'scrap','warehouse',100)
 var p:=ProductionService.new(b,c.recipes());var w:=WorkstationService.new(p,c.equipment());var station:=''
 for id in s.base.buildings:
  if s.base.buildings[id].type=='workstation':station=id
 var gun:Dictionary=inv.spawn(s,'rifle_basic','warehouse')
 for type in ['scope_basic','muzzle_basic','capacitor_basic','tactical_light']:
  var plugin:Dictionary=inv.spawn(s,type,'warehouse')
  assert(w.modify(s,station,gun.id,'install',plugin.id))
  var target:String=type.replace('_basic','')+'_advanced'
  var charge:float=minf(7.,s.items[plugin.id].capacity);s.items[plugin.id].energy=charge
  assert(w.modify(s,station,plugin.id,'upgrade',target))
  assert(s.items[plugin.id].energy==charge and plugin.id in s.items[gun.id].plugins.values())
 var bag:Dictionary=inv.spawn(s,'backpack_small','warehouse')
 var width:int=s.containers.bag.width
 assert(w.modify(s,station,bag.id,'upgrade','backpack_large'))
 assert(s.containers.bag.width==width)
 assert(inv.equip(s,bag.id,'backpack',true).ok and s.containers.bag.width==8)
 var second:Dictionary=inv.spawn(s,'rifle_basic','warehouse')
 var plugin_id:String=s.items[gun.id].plugins.scope
 s.items[second.id].plugins.scope=plugin_id
 assert(not w.owned(s,plugin_id))
 var before:=JSON.stringify(s)
 assert(not w.modify(s,station,plugin_id,'upgrade','scope_advanced') and JSON.stringify(s)==before)
 s.items[second.id].plugins.clear()
 for location in ['shop','ground','resident:1']:
  s.items[gun.id].container_id=location
  assert(not w.owned(s,plugin_id))
 s.items[gun.id].container_id='warehouse'
 assert(w.owned(s,plugin_id))
 var low:Dictionary=inv.spawn(s,'tactical_laser','warehouse');s.items[low.id].energy=90.
 inv.definitions.tactical_laser_advanced.capacity=50.
 before=JSON.stringify(s)
 assert(not w.modify(s,station,low.id,'upgrade','tactical_laser_advanced') and JSON.stringify(s)==before)
 # Full resource cost rollback when InventoryService rejects capacity.
 print('CONTENT_UPGRADE_ATOMIC_PASS');quit()
