extends RefCounted
static func create(arena:Node2D)->Dictionary:
 var crops:Dictionary=JSON.parse_string(FileAccess.get_file_as_string('res://data/crops.json'))
 var trade:Dictionary=JSON.parse_string(FileAccess.get_file_as_string('res://data/trade.json'))
 arena.inventory.definitions=preload('res://scripts/content/catalog.gd').items()
 var buildings:=BuildingService.new(arena.inventory,JSON.parse_string(FileAccess.get_file_as_string('res://data/buildings.json')))
 buildings.setup(arena.state)
 var recipes:Dictionary=preload('res://scripts/content/catalog.gd').recipes()
 var deps:Dictionary={'inventory':arena.inventory,'building':buildings,'production':ProductionService.new(buildings,recipes.get('recipes',recipes)),'farming':FarmingService.new(buildings,crops.crops),'quests':QuestService.new(arena.inventory),'trade':TradeService.new(arena.inventory,trade),'exploration':arena.exploration}
 deps.quests.setup(arena.state)
 var rng:=RandomNumberGenerator.new();rng.state=int(arena.state.rng_state);deps.quests.refresh(arena.state,rng)
 deps.trade.refresh(arena.state,1)
 return deps


