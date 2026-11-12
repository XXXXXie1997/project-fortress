extends SceneTree
func _initialize():
 var defs:Dictionary=JSON.parse_string(FileAccess.get_file_as_string('res://data/items.json')).items
 var inv:=InventoryService.new(defs)
 var building:=BuildingService.new(inv,JSON.parse_string(FileAccess.get_file_as_string('res://data/buildings.json')))
 var exploration:=ExplorationService.new(inv,JSON.parse_string(FileAccess.get_file_as_string('res://data/maps/exploration.json')).maps)
 var restart:=RunRestart.new(inv,building,exploration,QuestService.new(inv))
 var fresh:Dictionary=restart.new_game(42)
 assert(fresh.ok)
 var old:Dictionary=fresh.state
 old.cycle.failed=true
 old.base.energy_store.energy=123.5
 old.base.buildings.qa_order={'type':'workstation','durability':4,'order':{'recipe':'medical','remaining':2,'produced':7}}
 var buildings_before=JSON.stringify(old.base.buildings)
 old.base.wave_plan={'id':'night:1','budget':999.0,'entries':[{'id':'old_enemy'}]}
 old.base.defense_runtime={'running':true,'queue':[{'id':'old_enemy'}]}
 var original:String=JSON.stringify(old)
 var result:Dictionary=restart.plus(old)
 assert(result.ok)
 assert(result.state.base.energy_store.energy==123.5)
 assert(JSON.stringify(result.state.base.buildings)==buildings_before)
 assert(JSON.stringify(old)==original)
 assert(not result.state.base.has('wave_plan'))
 assert(not result.state.base.has('defense_runtime'))
 result.state.cycle.night={'mode':'manual','snapshot':{'id':'night:1','enemy_power':4.5}}
 var planner:=BaseWavePlan.new()
 var plan:Dictionary=planner.ensure_plan(result.state,GridProjection.new())
 assert(plan.budget==4.5)
 var total:float=0
 for entry in plan.entries:
  assert(entry.id!='old_enemy')
  total+=entry.cost
 assert(is_equal_approx(total,4.5))
 var rng:String=result.state.rng_state
 assert(planner.ensure_plan(result.state,GridProjection.new())==plan)
 assert(result.state.rng_state==rng)
 print('QA_NG_PLUS_WAVE_RESET_ENERGY_BUILDINGS_ORDER_PASS')
 quit(0)

