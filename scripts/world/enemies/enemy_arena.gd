extends "res://scripts/game/combat_arena.gd"
signal reinforcement_requested(event:Dictionary)
var telemetry:Dictionary={'perception':0,'moving':0,'engaged':0,'attacks_total':0,'navigation_total':0}
var loaded_session:=''
var loaded_map:=''
var darkness:=CanvasModulate.new()
var ai_config:Dictionary
var exploration:ExplorationService
var navigation:=AStarGrid2D.new()
var buckets:Dictionary={}
var ambient_brightness:=1.0
var calls_completed:=0
var sprint_noise_distance:=0.0
func _ready():
 if not session_context.is_empty():
  await preload('res://scripts/game/session/world_mount.gd').mount(self,'enemy')
  return
 super._ready()
 for target in targets:target.queue_free()
 targets.clear()
 ai_config=JSON.parse_string(FileAccess.get_file_as_string('res://data/enemies.json'))
 var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string('res://data/maps/exploration.json')).maps.duplicate(true)
 var definitions:Array=[]
 var types:Array=['basic','fast','armored','ranged','boss']
 var locations:Array=[[480,160],[1050,150],[1000,650],[420,760],[1180,800]]
 var amount:int=100 if '--stress' in OS.get_cmdline_user_args() else 5
 for i in range(amount):definitions.append({'id':'ai_%d'%i,'type':types[i%5] if amount==5 else types[i%4],'position':locations[i] if amount==5 else [750+(i%10)*52,100+int(i/10)*65]})
 catalog.suburbs.enemies=definitions
 exploration=ExplorationService.new(inventory,catalog)
 add_child(darkness)
 exploration.setup(state);exploration.start(state,'suburbs','south','day')
 loaded_session=str(state.expedition.id);loaded_map=state.expedition.map_id
 for definition in definitions:spawn_enemy(definition)
 await get_tree().physics_frame
 rebuild_navigation()
func spawn_enemy(definition:Dictionary):
 var id:String=definition.id
 if state.expedition.maps[state.expedition.map_id].enemies[id].get('dead',false):
  restore_blood_corpse(definition);return
 var spec:Dictionary=ai_config.types[definition.type]
 var record:Dictionary={'vitals':{'hp':spec.hp,'max_hp':spec.hp,'knockback_resistance':spec.resistance},'armor':{'durability':spec.armor,'rating':10.0},'action':ActionRules.fresh(config),'meter':0.0,'alerted':false,'mode':'idle','last_known':definition.position.duplicate(),'lost_time':0.0,'search_left':0.0,'called':false,'call_left':0.0,'call_retry':0.0,'call_position':[0,0],'attack_left':0.0,'attack_position':[0,0],'cooldown':0.0,'position':definition.position.duplicate()}
 if not state.expedition.maps[state.expedition.map_id].enemies[id].has('ai'):state.expedition.maps[state.expedition.map_id].enemies[id].ai=record
 else:record=state.expedition.maps[state.expedition.map_id].enemies[id].ai
 var enemy=load('res://scripts/world/enemies/infected_actor.gd').new();enemy.arena=self;enemy.enemy_id=id;enemy.kind=definition.type;enemy.spec=spec;enemy.position=Vector2(definition.position[0],definition.position[1]);enemy.home=enemy.position;enemy.position=Vector2(record.position[0],record.position[1]);add_child(enemy);targets.append(enemy)
func rebuild_navigation():
 navigation.region=Rect2i(0,0,30,20);navigation.cell_size=Vector2(48,48);navigation.offset=Vector2(24,24);navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;navigation.update()
 var shape:=CircleShape2D.new();shape.radius=16
 var query:=PhysicsShapeQueryParameters2D.new();query.shape=shape;query.collision_mask=9
 for y in range(20):
  for x in range(30):
   query.transform=Transform2D(0,Vector2(x*48+24,y*48+24))
   navigation.set_point_solid(Vector2i(x,y),not get_world_2d().direct_space_state.intersect_shape(query,1).is_empty())
func nearest_cell(point:Vector2)->Vector2i:
 var cell:=Vector2i(clampi(int(point.x/48),0,29),clampi(int(point.y/48),0,19))
 for radius in range(4):
  for y in range(-radius,radius+1):
   for x in range(-radius,radius+1):
    var test:=cell+Vector2i(x,y)
    if navigation.region.has_point(test) and not navigation.is_point_solid(test):return test
 return cell
func find_path(start:Vector2,goal:Vector2)->PackedVector2Array:
 telemetry.navigation_total+=1
 if navigation.is_dirty():return PackedVector2Array()
 return navigation.get_point_path(nearest_cell(start),nearest_cell(goal))
func _physics_process(_dt):
 telemetry.perception=0;telemetry.moving=0;telemetry.engaged=0
 var view_brightness:float=ambient_brightness
 for slot in state.player.equipment:
  if slot.begins_with('extra_'):
   var item:Dictionary=state.items.get(state.player.equipment[slot],{})
   if item.get('definition_id','')=='nightvision' and item.get('energy',0)>0:view_brightness=maxf(view_brightness,0.6)
 darkness.color=Color(view_brightness,view_brightness,view_brightness)
 if exploration==null:return
 var current_map:String=state.expedition.get('map_id','') if state.expedition.get('active',false) else ''
 var session:String=str(state.expedition.get('id',''))
 if current_map!=loaded_map or session!=loaded_session:
  clear_map_effects()
  if session==loaded_session:
   var departed:Dictionary=state.expedition.get('maps',{}).get(loaded_map,{}).get('enemies',{})
   for enemy in targets:
    var saved:Dictionary=departed.get(enemy.enemy_id,{})
    if enemy.spec.get('boss',false) and not saved.get('dead',false) and saved.has('ai'):
     enemy.reset_boss(saved.ai)
  for enemy in targets:enemy.set_physics_process(false);enemy.set_process(false);enemy.queue_free()
  targets.clear();loaded_map=current_map;loaded_session=session
  if not current_map.is_empty():
   for definition in state.expedition.maps[current_map].enemies.values():spawn_enemy(definition)
 if current_map.is_empty():return
 buckets.clear()
 for enemy in targets:
  if enemy.get_meta('hp')<=0:continue
  var cell:=Vector2i(enemy.position/72)
  if not buckets.has(cell):buckets[cell]=[]
  buckets[cell].append(enemy)
func separation(enemy:Node2D)->Vector2:
 var force:=Vector2.ZERO
 var cell:=Vector2i(enemy.position/72)
 for y in range(-1,2):
  for x in range(-1,2):
   for other in buckets.get(cell+Vector2i(x,y),[]):
    if other==enemy:continue
    var offset:Vector2=enemy.position-other.position
    var desired:float=enemy.spec.radius+other.spec.radius+4
    if offset.length()<desired:force+=offset.normalized()*(1.0-offset.length()/desired)
 return force.limit_length(1.0)
func emit_player_noise(action:String,source:Vector2):
 var loudness:float=ai_config.get('player_noise',{}).get(action,0.0)
 if loudness>0.0:emit_sound(source,loudness)
func emit_player_movement_noise(source:Vector2,distance:float,sprinting:bool):
 if not sprinting:
  sprint_noise_distance=0.0
  return
 if distance<=0.001:return
 sprint_noise_distance+=distance
 var stride:float=maxf(1.0,ai_config.get('sprint_noise_stride',48.0))
 if sprint_noise_distance>=stride:
  sprint_noise_distance=fmod(sprint_noise_distance,stride)
  emit_player_noise('sprint',source)
func emit_sound(source:Vector2,loudness:float=1.0):
 for enemy in targets:
  if enemy.position.distance_to(source)<ai_config.hearing_range*loudness:enemy.hear(source)
func broadcast_call(caller:Node2D,source:Vector2):
 calls_completed+=1
 if caller.spec.get('reinforcement_event',false):reinforcement_requested.emit({'caller':caller.enemy_id,'source':[source.x,source.y]})
 for enemy in targets:
  if enemy!=caller and enemy.position.distance_to(caller.position)<ai_config.call_radius:enemy.hear(source)
func illumination_at(point:Vector2)->float:
 var brightness:float=ambient_brightness
 if player.tactical!=null and player.tactical.light.enabled and clear_line(player.position,point,1):
  var offset:Vector2=point-player.position
  var aim:Vector2=(player.get_global_mouse_position()-player.position).normalized()
  if offset.length()<280 and (offset.length()<20 or aim.dot(offset.normalized())>cos(0.35)):brightness=maxf(brightness,1.0)
 return brightness

func combat_context()->String:
 if not state.expedition.get('active',false):return ''
 return str(state.expedition.get('id',''))+'|'+state.expedition.get('map_id','')

func combat_map_ready()->bool:
 return combat_context()==loaded_session+'|'+loaded_map and not loaded_map.is_empty()

var blood_visual:Node2D
func blood_layer():
 if not is_instance_valid(blood_visual):
  blood_visual=load('res://scripts/art/blood_effects.gd').new();blood_visual.arena=self;add_child(blood_visual)
 return blood_visual
func show_blood(hp_loss:float,point:Vector2,direction:Vector2=Vector2.ZERO):
 if hp_loss>0:blood_layer().show_hit(hp_loss,point,direction)
func restore_blood_corpse(definition:Dictionary):
 var p:Array=definition.get('ai',{}).get('position',definition.position)
 blood_layer().restore_dead(str(definition.id),Vector2(p[0],p[1]),definition.type)
func clear_map_effects():
 if is_instance_valid(blood_visual):blood_visual.clear_effects()
 # Projectiles from either team have map-local lifetimes, not exploration data.
 for effect in get_tree().get_nodes_in_group('combat_map_transients'):
  if is_ancestor_of(effect):
   effect.set_physics_process(false);effect.set_process(false);effect.queue_free()
 if is_instance_valid(player) and is_instance_valid(player.tactical):player.tactical.reset_map_effects()
func hit(target:Node2D,damage:float,attack:Dictionary={},direction:Vector2=Vector2.ZERO):
 if not target.has_method('record'):super.hit(target,damage,attack,direction);return
 var record:Dictionary=target.record()
 if record.vitals.hp<=0:return
 var packet:Dictionary=attack.duplicate();packet.damage=damage
 var result:Dictionary=DamageRules.hit(record.vitals,record.action,record.armor,packet,config,'enemy')
 if result.hp_loss>0 or result.armor_loss>0:emit_sfx('melee_hit' if packet.get('sfx_melee',false) else 'hit_enemy',target.position,true,target.enemy_id)
 show_blood(result.hp_loss,target.position,direction)
 var source:Array=packet.get('source_position',[player.position.x,player.position.y])
 target.struck(Vector2(source[0],source[1]));target.push+=direction.normalized()*result.knockback
 target.set_meta('hp',record.vitals.hp)
 if record.vitals.hp<=0:
  blood_layer().show_death(target.enemy_id,target.position)
  target.collision_layer=0;target.collision_mask=0
  var runtime:Dictionary=state.expedition.maps[state.expedition.map_id].enemies[target.enemy_id]
  runtime.position=[target.position.x,target.position.y]
  if exploration.kill(state,target.enemy_id):exploration.enemy_loot(state,target.enemy_id,[{'definition_id':'scrap','quantity':2}])

func perceived_brightness(point:Vector2)->float:
 var brightness:float=illumination_at(point)
 for slot in state.player.equipment:
  if not slot.begins_with('extra_'):continue
  var item:Dictionary=state.items.get(state.player.equipment[slot],{})
  if item.get('definition_id','')=='nightvision' and item.get('energy',0)>0:brightness=maxf(brightness,0.6)
 return brightness





