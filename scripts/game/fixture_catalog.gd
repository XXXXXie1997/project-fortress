extends RefCounted
# Integration fixture content; move into the content catalog during DEV-500.
static func weapon_specs(config:Dictionary)->Dictionary:
 var specs:Dictionary={}
 specs.rifle_basic=config.weapons.rifle.duplicate(true)
 specs.knife_basic=config.weapons.knife.duplicate(true)
 specs.energy_blade=config.weapons.energy_blade.duplicate(true)
 specs.unique_blade=config.weapons.energy_blade.duplicate(true)
 specs.unique_blade.passive='pending_design_D001'
 specs.scatter_basic=config.weapons.rifle.duplicate(true)
 specs.scatter_basic.merge({'damage':8.0,'pellets':6,'base_spread':0.2,'energy_cost':8.0,'interval':0.7,'visual':1},true)
 specs.sniper_basic=config.weapons.rifle.duplicate(true)
 specs.sniper_basic.merge({'damage':60.0,'penetration':20.0,'base_spread':0.015,'energy_cost':10.0,'interval':1.0,'visual':2},true)
 for id in specs:
  var melee:bool=specs[id].kind=='melee'
  if not specs[id].has('interval'):specs[id].interval=0.45 if melee else 0.15
  if not specs[id].has('visual'):specs[id].visual=3 if melee else 0
  specs[id].degrade_threshold=20.0;specs[id].degraded_factor=0.65
  if melee:specs[id].range=100.0;specs[id].stamina_cost=12.0
 return specs
static func augment(definitions:Dictionary):
 definitions.medical_needle.heal={'cast_time':0.6,'instant':25.0,'interrupt_cast':true,'interrupt_hot':false}
 for id in ['scatter_basic','sniper_basic']:
  definitions[id]=definitions.rifle_basic.duplicate(true)
 for id in ['energy_blade','unique_blade']:
  definitions[id]=definitions.knife_basic.duplicate(true);definitions[id].capacity=50.0
