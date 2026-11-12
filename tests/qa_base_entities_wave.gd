extends SceneTree
func _initialize():
 var planner=BaseWavePlan.new();var grid=GridProjection.new()
 for budget in [0.0,0.000001,0.1,0.99999,1.0,1.25,4.75,39.125,10000.125]:
  var s=WorldState.fresh();s.cycle={'night':{'mode':'manual','snapshot':{'id':'night:q','enemy_power':budget}}}
  var p=planner.ensure_plan(s,grid);var ids={};var total=0.0
  for e in p.entries:
   assert(not ids.has(e.id));ids[e.id]=true;total+=e.cost
  assert(is_equal_approx(total,budget))
  var rng=s.rng_state;var saved=JSON.parse_string(JSON.stringify(s))
  assert(planner.ensure_plan(saved,grid)==p);assert(saved.rng_state==rng)
  var records={};var expected=0.0
  for i in p.entries.size():
   var e=p.entries[i]
   if i%3==0:records[e.id]={'ai':{'vitals':{'hp':25.0,'max_hp':100.0}}};expected+=e.cost*0.25
   elif i%3==1:records[e.id]={'dead':true}
   else:expected+=e.cost
  assert(is_equal_approx(planner.remaining_power(p,records),expected))
  for e in p.entries:records[e.id]={'dead':true}
  assert(planner.remaining_power(p,records)==0)
  s.cycle.night.snapshot={'id':'night:next','enemy_power':2.125}
  var next=planner.ensure_plan(s,grid);assert(next.id=='night:next' and next.budget==2.125)
 for invalid in [-1.0,INF,NAN]:
  var s=WorldState.fresh();s.cycle={'night':{'mode':'manual','snapshot':{'id':'bad','enemy_power':invalid}}}
  var rng=s.rng_state
  assert(planner.ensure_plan(s,grid).is_empty());assert(s.rng_state==rng)
 print('QA_WAVE_BUDGET_FRACTIONS_10000_RNG_JSON_RESIDUAL_NEXT PASS')
 var a=load('res://scenes/base/base_defense.tscn').instantiate();root.add_child(a)
 for i in 20:await physics_frame
 a.start_wave()
 for i in 25:await physics_frame
 var expected=a.remaining_enemy_power()
 var first=a.targets[0];var cost=0.0
 for e in a.state.base.wave_plan.entries:
  if e.id==first.enemy_id:cost=e.cost
 first.record().vitals.hp=first.record().vitals.max_hp*0.25
 assert(is_equal_approx(a.remaining_enemy_power(),expected-cost*0.75))
 a.running=false
 for e in a.targets:e.set_physics_process(false);e.queue_free()
 a.targets.clear()
 a.state=JSON.parse_string(JSON.stringify(a.state));var rng=a.state.rng_state
 var expected_live=0
 for e in a.state.expedition.maps.base.enemies.values():
  if e.ai.vitals.hp>0:expected_live+=1
 a.start_wave();assert(a.targets.size()==expected_live);assert(a.state.rng_state==rng)
 a.start_wave();assert(a.targets.size()==expected_live)
 var ids={}
 for e in a.targets:assert(not ids.has(e.enemy_id));ids[e.enemy_id]=true
 a.state.player.vitals.hp=0
 for i in 5:await physics_frame
 assert(not a.running)
 var state_json=JSON.stringify(a.state)
 for i in 120:await physics_frame
 assert(JSON.stringify(a.state)==state_json)
 print('QA_WAVE_REAL_ENTITY_RESTORE_UNIQUE_RESIDUAL_IDEMPOTENT PASS')
 quit()

