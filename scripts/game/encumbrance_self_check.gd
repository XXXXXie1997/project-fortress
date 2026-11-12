extends SceneTree
const Rule=preload('res://scripts/game/encumbrance_rules.gd')
func _init():
 var cfg:Dictionary=JSON.parse_string(FileAccess.get_file_as_string('res://data/combat.json'))
 assert(Rule.factors(8,10,cfg).speed_factor==1)
 var last_speed:=1.0;var last_cost:=1.0
 for step in range(101):
  var f:Dictionary=Rule.factors(step*.1,10,cfg)
  assert(f.speed_factor<=last_speed and f.stamina_factor>=last_cost)
  last_speed=f.speed_factor;last_cost=f.stamina_factor
 assert(is_equal_approx(last_speed,.7) and is_equal_approx(last_cost,1.5))
 for capacity in [0.0,-1.0,INF]:
  for weight in [0.0,1.0,NAN]:
   var f:Dictionary=Rule.factors(weight,capacity,cfg);assert(is_finite(f.speed_factor) and f.speed_factor>0)
 var factor:float=Rule.factors(10,10,cfg).stamina_factor*cfg.exoskeleton_factor
 var s:Dictionary=ActionRules.fresh(cfg);ActionRules.tick(s,1,cfg,false,true,true,false,factor);assert(is_equal_approx(s.stamina,82))
 s=ActionRules.fresh(cfg);assert(ActionRules.dodge(s,Vector2.RIGHT,Vector2.RIGHT,cfg,factor));assert(is_equal_approx(s.stamina,73))
 s=ActionRules.fresh(cfg);assert(ActionRules.start_melee(s,20*factor,cfg));assert(is_equal_approx(s.stamina,77.5))
 print('DEV504 independent-rule self check PASS (not player integration)');quit()
