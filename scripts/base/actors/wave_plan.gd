class_name BaseWavePlan
extends RefCounted
var config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string('res://data/base_waves.json'))
func ensure_plan(state:Dictionary,grid:GridProjection)->Dictionary:
 var night:Dictionary=state.get('cycle',{}).get('night',{})
 if night.get('mode','')!='manual' or not night.has('snapshot'):return {}
 var snapshot:Dictionary=night.snapshot
 var saved:Dictionary=state.base.get('wave_plan',{})
 if saved.get('id','')==snapshot.id:return saved.duplicate(true)
 var budget:=float(snapshot.enemy_power)
 if not is_finite(budget) or budget<0:return {}
 var rng:=RandomNumberGenerator.new();rng.state=int(state.rng_state)
 var initial_rng:String=state.rng_state
 var entries:Array=[]
 var remaining:=budget
 while remaining>0.0:
  var choices:Array=[]
  for type in config.types:
   if float(config.types[type].cost)<=remaining:choices.append(type)
  # 小于最便宜节点的尾数分配到最后一只，保持总成本精确等于冻结威胁。
  if choices.is_empty():
   if not entries.is_empty():entries.back().cost+=remaining
   else:entries.append(_entry(str(config.types.keys()[0]),remaining,0,str(snapshot.id),rng,grid))
   remaining=0
  else:
   var type:String=choices[rng.randi_range(0,choices.size()-1)]
   var cost:=float(config.types[type].cost)
   entries.append(_entry(type,cost,entries.size(),str(snapshot.id),rng,grid));remaining-=cost
 var plan:Dictionary={'id':snapshot.id,'version':config.version,'budget':budget,'health_exponent':config.health_exponent,'spawn_interval':config.spawn_interval,'entries':entries,'rng_before':initial_rng,'rng_after':str(rng.state)}
 state.base.wave_plan=plan.duplicate(true);state.rng_state=str(rng.state)
 return plan
func _entry(type:String,cost:float,index:int,night:String,rng:RandomNumberGenerator,grid:GridProjection)->Dictionary:
 var point:Array=config.spawn_logical[rng.randi_range(0,config.spawn_logical.size()-1)]
 return {'id':'%s:enemy:%d'%[night,index],'type':type,'cost':cost,'position':grid.project_array(point),'spawn_logical':point.duplicate()}
func remaining_power(plan:Dictionary,records:Dictionary)->float:
 var total:=0.0
 for entry in plan.entries:
  # 未入场按原成本全额计；已生成AI以真实HP比例折算，不重抽类型/成本。
  var record:Dictionary=records.get(entry.id,{})
  var factor:=1.0
  if record.has('ai'):
   var vitals:Dictionary=record.ai.vitals
   factor=pow(clampf(float(vitals.hp)/maxf(0.001,float(vitals.max_hp)),0,1),float(plan.health_exponent))
  elif record.get('dead',false):factor=0.0
  total+=float(entry.cost)*factor
 return total

