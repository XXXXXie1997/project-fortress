extends RefCounted
## Stateless: callers query the current bag after inventory transactions.
static func factors(weight:float,maximum:float,config:Dictionary)->Dictionary:
 var rules:Dictionary=config.get('encumbrance',{})
 var ratio:float=clampf(finite_value(rules.get('comfort_ratio',0.8),0.8),0.0,0.999)
 var minimum:float=clampf(finite_value(rules.get('minimum_speed_factor',0.7),0.7),0.01,1.0)
 var maximum_cost:float=maxf(1.0,finite_value(rules.get('maximum_stamina_factor',1.5),1.5))
 var load:=maxf(0.0,finite_value(weight,0.0))
 var amount:=0.0
 if is_finite(maximum) and maximum>=0:
  if maximum==0:amount=1.0 if load>0 else 0.0
  else:amount=clampf((load/maximum-ratio)/(1.0-ratio),0.0,1.0)
 return {'speed_factor':lerpf(1.0,minimum,amount),'stamina_factor':lerpf(1.0,maximum_cost,amount),'load_fraction':amount}
static func current(state:Dictionary,inventory:InventoryService,config:Dictionary)->Dictionary:
 return factors(inventory.weight(state,'bag'),float(state.containers.bag.maximum_weight),config)
static func finite_value(value:float,fallback:float)->float:
 return value if is_finite(value) else fallback
