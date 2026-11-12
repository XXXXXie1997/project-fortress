extends SceneTree
func _initialize():call_deferred('run')
func run():
 var catalog=load('res://scripts/content/catalog.gd')
 var inv:=InventoryService.new(catalog.items());var s:=WorldState.fresh();inv.setup(s)
 var buildings:=BuildingService.new(inv,catalog.read('data/buildings.json'));buildings.setup(s)
 var station:=''
 for id in s.base.buildings:
  if s.base.buildings[id].type=='workstation':station=id
 s.base.energy_store.energy=900.0;s.base.technology={'storage':true}
 inv.spawn(s,'scrap','warehouse',100);inv.spawn(s,'boss_core','warehouse',2)
 var production:=ProductionService.new(buildings,catalog.recipes())
 var work:=WorkstationService.new(production,catalog.equipment())
 assert(work.craft(s,station,'rifle_basic',1));assert(production.settle(s,'content-craft'))
 var rifle:=''
 for item in s.items.values():
  if item.definition_id=='rifle_basic':rifle=item.id
 assert(not rifle.is_empty());s.items[rifle].energy=11.0
 var plugin:Dictionary=inv.spawn(s,'scope_basic','warehouse')
 assert(work.modify(s,station,rifle,'install',plugin.id))
 assert(work.modify(s,station,rifle,'upgrade','rifle_advanced'))
 assert(s.items[rifle].energy==11.0 and s.items[rifle].plugins.scope==plugin.id)
 assert(not WeaponRules.attack_parameters(s.items[rifle],catalog.weapons().rifle_advanced).is_empty())
 var trade:=TradeService.new(inv,catalog.read('data/trade.json'));assert(trade.refresh(s,3))
 var blade:=''
 for item in inv.items_in(s,'shop'):
  if item.definition_id=='trade_blade':blade=item.id
 assert(not blade.is_empty());assert(trade.transact(s,[],[blade],'warehouse').ok)
 assert(not WeaponRules.attack_parameters(s.items[blade],catalog.weapons().trade_blade).is_empty())
 var file:=FileAccess.open('res://.godot-local/content-roundtrip.json',FileAccess.WRITE);file.store_string(WorldState.encode(s));file.close()
 var restored:=WorldState.decode(FileAccess.get_file_as_string('res://.godot-local/content-roundtrip.json'))
 assert(not restored.is_empty());assert(catalog.migrate(restored).ok)
 assert(restored.items[rifle].plugins.scope==plugin.id and restored.items[rifle].energy==11.0)
 assert(not WeaponRules.attack_parameters(restored.items[blade],catalog.weapons().trade_blade).is_empty())
 print('CONTENT_TRANSACTION_SELF_CHECK_PASS');quit()
