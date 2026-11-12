extends RefCounted
# All consumers receive independent dictionaries; no fixture augmentation.
static var _cache:Dictionary={}
static func reload_cache():
 _cache.clear()
static func read(path:String)->Dictionary:
 if not _cache.has(path):_cache[path]=JSON.parse_string(FileAccess.get_file_as_string('res://'+path))
 return _cache[path].duplicate(true)
static func items()->Dictionary:
 return read('data/content/items.json').items
static func weapons()->Dictionary:
 return read('data/content/weapons.json').weapons
static func item_name(id:String)->String:
 if not _cache.has('data/content/items.json'):read('data/content/items.json')
 return _cache['data/content/items.json'].items.get(id,{}).get('name',id)
static func migrate(state:Dictionary)->Dictionary:
 # Rewrite type references only. Never spawn, destroy, reset energy or replace IDs.
 var trial:Dictionary=state.duplicate(true)
 if not _migrate_worlds(trial):return {'ok':false,'reason':'conflicting_legacy_registry'}
 trial['content_version']=1
 state.clear();state.merge(trial,true)
 return {'ok':true}
static func validate()->Array:
 var errors:Array=[]
 var definitions:Dictionary=items()
 var specs:Dictionary=weapons()
 for id in definitions:
  if definitions[id].get('category') in ['ranged','melee'] and not specs.has(id):errors.append('missing_attack:'+id)
 for source in ['data/recipes.json','data/equipment_recipes.json']:
  for recipe:Dictionary in read(source).recipes.values():
   for field in ['cost','output']:
    for id in recipe.get(field,{}):
     if not definitions.has(id):errors.append(source+':'+id)
 for stock:Dictionary in read('data/trade.json').stock:
  for field in ['item','plugin']:
   if stock.has(field) and not definitions.has(stock[field]):errors.append('trade:'+stock[field])
 return errors
static func equipment()->Dictionary:
 return read('data/content/equipment.json')
static func recipes()->Dictionary:
 var result:Dictionary=read('data/recipes.json').recipes
 for id in equipment().recipes:
  assert(not result.has(id),'Conflicting recipe ID: '+id)
  result[id]=equipment().recipes[id]
 return result
static func maps()->Dictionary:
 var result:Dictionary={}
 for id in ['suburbs','armory','city']:result[id]=read('data/maps/content/'+id+'.json')
 return result
static func validate_references()->Array:
 var errors:Array=validate()
 var definitions:Dictionary=items()
 for collection in [recipes(),read('data/crops.json').crops]:
  for entry:Dictionary in collection.values():
   for field in ['cost','output']:
    for id in entry.get(field,{}):
     if not definitions.has(id):errors.append('resource:'+id)
 for quest:Dictionary in read('data/quests.json').definitions.values():
  for resources in [quest.get('materials',{}),quest.get('reward',{}).get('materials',{})]:
   for id in resources:
    if not definitions.has(id):errors.append('quest:'+id)
 for tech:Dictionary in read('data/technology.json').nodes.values():
  for id in tech.get('materials',{}):
   if not definitions.has(id):errors.append('technology:'+id)
 for id in starting_loadout().equipment.values():
  if not definitions.has(id):errors.append('starting_equipment:'+id)
 for item in starting_loadout().supplies:
  if not definitions.has(item.definition_id):errors.append('starting_supply:'+str(item.definition_id))
 for map:Dictionary in maps().values():
  _scan_loot(map,definitions,errors)
  for id in map.get('doors',{}).values():
   if not definitions.has(id):errors.append('door:'+id)
 return errors
static func _scan_loot(value:Variant,definitions:Dictionary,errors:Array):
 if value is Dictionary:
  if value.has('definition_id') and not definitions.has(value.definition_id):errors.append('map:'+str(value.definition_id))
  for child in value.values():_scan_loot(child,definitions,errors)
 elif value is Array:
  for child in value:_scan_loot(child,definitions,errors)
static func validate_sources()->Array:
 var errors:Array=[]
 var definitions:Dictionary=items()
 var seen:Dictionary={}
 for source in ['data/items.json','data/crops.json','data/equipment_recipes.json','data/trade.json']:
  var data:Dictionary=read(source)
  for id in data.get('items',data.get('item_definitions',{})):
   if seen.has(id):errors.append('duplicate_source_id:'+id)
   seen[id]=source
   var definition:Dictionary=data.get('items',data.get('item_definitions',{}))[id]
   for field in definition:
    if definitions.get(id,{}).get(field)!=definition[field]:errors.append('definition_conflict:'+id+':'+field)
 return errors

static func _migrate_worlds(value:Variant)->bool:
 if value is Dictionary:
  if value.has_all(['items','containers','player','unique_items']):
   if not _migrate_one(value):return false
  for child in value.values():
   if not _migrate_worlds(child):return false
 elif value is Array:
  for child in value:
   if not _migrate_worlds(child):return false
 return true
static func _migrate_one(state:Dictionary)->bool:
 for item:Dictionary in state.get('items',{}).values():
  if item.get('definition_id')=='unique_blade':item.definition_id='trade_blade'
 for i in range(state.get('player',{}).get('quick',[]).size()):
  if state.player.quick[i]=='unique_blade':state.player.quick[i]='trade_blade'
 var registry:Dictionary=state.get('unique_items',{})
 if registry.has('unique_blade'):
  if registry.has('trade_blade') and registry.trade_blade!=registry.unique_blade:return false
  registry.trade_blade=registry.unique_blade;registry.erase('unique_blade')
 return InventoryService.new(items()).repair_battery_metadata(state)
static func validate_upgrades()->Array:
 var errors:Array=[]
 var definitions:Dictionary=items();var tiers:Dictionary=equipment().tiers
 var families:Dictionary={}
 for id in tiers:
  if not definitions.has(id):errors.append('upgrade_target:'+id)
  var tier:Dictionary=tiers[id]
  if not families.has(tier.family):families[tier.family]=[]
  if tier.level in families[tier.family]:errors.append('duplicate_family_level:'+id)
  families[tier.family].append(tier.level)
  for resource in tier.materials:
   if not definitions.has(resource):errors.append('upgrade_material:'+resource)
 for family in families:
  families[family].sort()
  for i in families[family].size():
   if int(families[family][i])!=i+1:errors.append('upgrade_gap:'+family)
 return errors
static func starting_loadout()->Dictionary:
 return read('data/content/start.json')
