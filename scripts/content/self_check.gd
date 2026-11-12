extends SceneTree
func _initialize():
 var catalog=load('res://scripts/content/catalog.gd')
 assert(catalog.validate_references().is_empty(),str(catalog.validate_references()))
 assert(catalog.validate_sources().is_empty(),str(catalog.validate_sources()))
 var definitions:Dictionary=catalog.items()
 var inv:=InventoryService.new(definitions)
 var s:=WorldState.fresh();inv.setup(s)
 for id in catalog.weapons():
  var result:Dictionary=inv.spawn(s,id,'ground')
  assert(not result.is_empty())
  var item:Dictionary=s.items[result.id];item.energy=item.capacity
  assert(not WeaponRules.attack_parameters(item,catalog.weapons()[id]).is_empty(),id)
 var old:Dictionary=inv.spawn(s,'trade_blade','ground');s.items[old.id].definition_id='unique_blade'
 s.items[old.id].energy=12.0;s.items[old.id].durability=37.0
 var count:int=s.items.size();assert(catalog.migrate(s).ok)
 assert(s.items.size()==count and s.items[old.id].definition_id=='trade_blade' and s.items[old.id].energy==12.0 and s.items[old.id].durability==37.0)
 assert(catalog.migrate(s).ok and s.items.size()==count)
 print('CONTENT_INITIAL_SELF_CHECK_PASS');quit()



