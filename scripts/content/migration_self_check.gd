extends SceneTree
func _initialize():
 var c=load('res://scripts/content/catalog.gd')
 var inv:=InventoryService.new(c.items());var s:=WorldState.fresh();inv.setup(s)
 var old:Dictionary=inv.spawn(s,'trade_blade','ground');s.items[old.id].definition_id='unique_blade'
 var modern:Dictionary=inv.spawn(s,'trade_blade','ground')
 s.items[old.id].energy=9.;s.items[old.id].durability=44.
 s['run_start_snapshot']=s.duplicate(true)
 s['description']='unique_blade'
 assert(c.migrate(s).ok)
 assert(s.items.size()==2 and s.items.has(modern.id) and s.items.has(old.id))
 assert(s.run_start_snapshot.items[old.id].definition_id=='trade_blade')
 assert(s.items[old.id].energy==9. and s.items[old.id].durability==44.)
 assert(s.description=='unique_blade')
 var once:=JSON.stringify(s);assert(c.migrate(s).ok and JSON.stringify(s)==once)
 var first:Dictionary=c.items();first.trade_blade.name='污染';assert(c.item_name('trade_blade')=='独特能量刀')
 s.run_start_snapshot.unique_items={'unique_blade':old.id,'trade_blade':modern.id}
 once=JSON.stringify(s);assert(not c.migrate(s).ok and JSON.stringify(s)==once)
 print('CONTENT_MIGRATION_CACHE_PASS');quit()
