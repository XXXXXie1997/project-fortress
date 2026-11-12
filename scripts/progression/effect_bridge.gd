class_name ProgressionEffectBridge
extends RefCounted
var growth:=PlayerGrowth.new()
var balance:Dictionary=JSON.parse_string(FileAccess.get_file_as_string('res://scripts/ui/progression/balance.json'))
func apply(s:Dictionary,base:Dictionary)->Dictionary:
 var effects:=growth.effects(s)
 var p:Dictionary=s.player
 if not p.has('growth_baseline'):p.growth_baseline={'max_hp':p.vitals.max_hp,'max_stamina':base.max_stamina}
 p.vitals.max_hp=float(p.growth_baseline.max_hp)+effects.max_hp_bonus
 p.vitals.hp=minf(p.vitals.hp,p.vitals.max_hp)
 p.vitals.visual_accumulation_factor=effects.alert_accumulation_multiplier
 p.vitals.hurt_speed_talent=effects.hurt_speed_enabled
 if not effects.hurt_speed_enabled:p.combat.hurt_boost=0.0
 var cfg:=base.duplicate(true)
 cfg.max_stamina=float(p.growth_baseline.max_stamina)+effects.max_stamina_bonus
 p.combat.stamina=minf(p.combat.stamina,cfg.max_stamina)
 cfg.hurt_speed=effects.hurt_speed_multiplier;cfg.hurt_boost_duration=effects.hurt_speed_duration
 return cfg
func spread_factor(s:Dictionary)->float:return maxf(0.0,1.0-float(growth.effects(s).base_spread_reduction))
func reset(s:Dictionary,inv:InventoryService,quote:Dictionary,at_base:bool)->bool:
 if not at_base or not quote.get('ok',false):return false
 var t:=s.duplicate(true)
 var cost:Dictionary=quote.cost
 if t.base.energy_store.energy<float(cost.energy):return false
 if not inv.exchange(t,cost.materials,{}).ok:return false
 t.base.energy_store.energy-=float(cost.energy)
 if not growth.commit_reset(t,quote,at_base,true).ok:return false
 InventoryService.commit(s,t);return true
func storage_upgrade(s:Dictionary,buildings:BuildingService)->bool:
 var cap:=1
 var tech:=TechnologyService.new(buildings.inventory)
 for id in s.base.get('technology',{}):
  if tech.config.nodes.has(id):cap=maxi(cap,int(tech.config.nodes[id].effects.get('storage_level',1)))
 for b in s.base.get('buildings',{}).values():
  if b.type=='warehouse':
   if b.level>=cap:return false
   return buildings.upgrade(s,b.id)
 return false
func record_event(s:Dictionary,inv:InventoryService,kind:String,target:String,event_id:String,amount:int=1)->void:
 var q:=QuestService.new(inv)
 if kind in ['kill','reach']:q.record(s,kind,target,event_id)
 if kind in ['kill','survival']:growth.award(s,kind,amount,event_id)
func observe(s:Dictionary,inv:InventoryService)->void:
 var p:Dictionary=s.player
 var tracking:bool=p.has('growth_events')
 if not tracking:p.growth_events={'seen':{},'day':s.day}
 var events:Dictionary=p.growth_events
 var maps:Dictionary=s.expedition.get('maps',{})
 for map_id in maps:
  for id in maps[map_id].get('enemies',{}):
   var enemy:Dictionary=maps[map_id].enemies[id]
   var key:='kill:%s:%s:%s'%[stable_id(s.expedition.get('id','')),map_id,id]
   var dead:bool=enemy.get('dead',false) or enemy.get('ai',{}).get('vitals',{}).get('hp',1)<=0
   if dead and not events.seen.has(key):
    events.seen[key]=true
    if tracking:growth.award(s,'kill',int(balance.kill_xp),key)
 if int(s.day)>int(events.day):
  for day in range(int(events.day),int(s.day)):record_event(s,inv,'survival','', 'survival:day:%s'%day,int(balance.survival_day_xp))
  events.day=s.day




func stable_id(value:Variant)->String:
 return str(int(value)) if value is float or value is int else str(value)

