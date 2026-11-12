extends "res://scripts/game/combat_arena.gd"
func _ready():
 super._ready()
 var buildings:=BuildingService.new(inventory,JSON.parse_string(FileAccess.get_file_as_string('res://data/buildings.json')))
 buildings.setup(state)
 inventory.spawn(state,'scrap','warehouse',50)
 var rng:=RandomNumberGenerator.new();rng.state=int(state.rng_state)
 QuestService.new(inventory).refresh(state,rng)
 player.growth_bridge.growth.award(state,'quest',900,'demo_fixture')
 await get_tree().process_frame
 player.progression_panel.permission=func():return true
 player.progression_panel.open_view('talents')
func _process(_dt):queue_redraw()
