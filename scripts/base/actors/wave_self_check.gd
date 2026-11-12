extends SceneTree
func _initialize():
 var wave=load('res://scripts/base/actors/wave_plan.gd').new()
 var grid:=GridProjection.new()
 var s:Dictionary={'rng_state':'123','base':{},'cycle':{'night':{'mode':'manual','snapshot':{'id':'night:7','enemy_power':10.25}}}}
 var plan:Dictionary=wave.ensure_plan(s,grid)
 var total:=0.0;var seen:Dictionary={}
 for entry in plan.entries:
  total+=entry.cost;assert(not seen.has(entry.id));seen[entry.id]=true
 assert(is_equal_approx(total,10.25))
 var saved:=JSON.stringify(s)
 assert(wave.ensure_plan(s,grid)==plan)
 assert(JSON.stringify(s)==saved)
 var restored:Dictionary=JSON.parse_string(saved)
 var rng:String=restored.rng_state
 var again:Dictionary=wave.ensure_plan(restored,grid)
 assert(restored.rng_state==rng and again.entries.size()==plan.entries.size())
 var records:Dictionary={}
 var first:Dictionary=plan.entries[0]
 records[first.id]={'ai':{'vitals':{'hp':50,'max_hp':100}}}
 assert(is_equal_approx(wave.remaining_power(plan,records),10.25-float(first.cost)*0.5))
 for entry in plan.entries:records[entry.id]={'ai':{'vitals':{'hp':0,'max_hp':100}}}
 assert(wave.remaining_power(plan,records)==0)
 var typed:Dictionary={'health_exponent':1.0,'entries':[{'id':'basic','cost':1.0},{'id':'armored','cost':3.0}]}
 assert(wave.remaining_power(typed,{'armored':{'ai':{'vitals':{'hp':50,'max_hp':100}}}})==2.5)
 print('DEV402 WAVE BUDGET SAVE RNG RESIDUAL PASS')
 quit()
