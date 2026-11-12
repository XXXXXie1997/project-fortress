extends "res://scripts/world/enemies/enemy_arena.gd"
var grid:=GridProjection.new(48.0,Vector2(96,48),Vector2.ZERO)
const Perimeter = preload("res://scripts/base/base_geometry.gd")
var perimeter_walls: Array[StaticBody2D] = []
var perimeter_signature := ""
var base_navigation:=AStar2D.new()
var nav_timer:=0.0
var gate_logical:=Vector2(1152,470)
var wave_service:=BaseWavePlan.new()
var running:=false
var fixtures:Array=[]
var residents:Array=[]
var queue:Array=[]
var spawn_timer:=0.0
var cycle:DayCycle
var building:BuildingService
var elapsed:=0.0
var frame_samples:Array=[]
var peak_enemies:=0
var physics_usec:Array=[]
var frame_usec:Array=[]
var last_frame_us:=0
var status_label:Label
func _ready():
 if not session_context.is_empty():
  await preload('res://scripts/game/session/world_mount.gd').mount(self,'base')
  return
 y_sort_enabled=true
 super._ready()
 await get_tree().physics_frame
 for target in targets:target.set_physics_process(false);target.hide();target.queue_free()
 targets.clear()
 for child in get_children():
  if child is StaticBody2D:child.queue_free()
 state.expedition = {} # 独立基地夹具丢弃父场景的演示探索会话
 building=BuildingService.new(inventory,JSON.parse_string(FileAccess.get_file_as_string('res://data/buildings.json')))
 building.setup(state)
 var crop:Dictionary=JSON.parse_string(FileAccess.get_file_as_string('res://data/crops.json'))
 var trade:Dictionary=JSON.parse_string(FileAccess.get_file_as_string('res://data/trade.json'))
 inventory.definitions.merge(crop.item_definitions);inventory.definitions.merge(trade.item_definitions)
 cycle=DayCycle.new({'inventory':inventory,'building':building,'production':ProductionService.new(building,{}),'farming':FarmingService.new(building,crop.crops),'quests':QuestService.new(inventory),'trade':TradeService.new(inventory,trade),'exploration':exploration})
 state.base.shield={'energy':100.0,'capacity':100.0}
 state.base.energy_store.energy=800
 var resident_service=load('res://scripts/base/actors/resident_service.gd').new(inventory)
 resident_service.recruit(state,'fixture:resident:1');resident_service.recruit(state,'fixture:resident:2')
 # 独立演示场景的开局资源，随后所有发射和充电使用真实账。
 inventory.spawn(state,'scrap','warehouse',100)
 building.build(state,'turret',[4,8],Rect2i(0,0,24,18))
 for id in state.base.buildings:
  var b:Dictionary=state.base.buildings[id]
  var actor=load('res://scripts/base/actors/defense_fixture.gd').new();actor.arena=self;actor.id=id;actor.kind=b.type
  var size:Array=building.config.types[b.type].size
  actor.logical_rect=Rect2(Vector2(b.cell[0],b.cell[1])*48,Vector2(size[0],size[1])*48)
  actor.position=grid.logical_to_world(actor.logical_rect.get_center());add_child(actor);fixtures.append(actor)
  if b.type=='warehouse':station=actor.position
 var shield=load('res://scripts/base/actors/defense_fixture.gd').new();shield.arena=self;shield.kind='shield';shield.logical_rect=Rect2(1143,405,18,130);shield.position=grid.logical_to_world(gate_logical);add_child(shield);fixtures.append(shield)
 sync_perimeter()
 for i in state.base.residents.size():
  var actor=load('res://scripts/base/actors/resident_actor.gd').new();actor.arena=self;actor.id=state.base.residents[i].id;actor.position=grid.logical_to_world(Vector2(900,430+i*80));actor.post=actor.position;add_child(actor);residents.append(actor)
 player.position=grid.logical_to_world(Vector2(850,470));player.camera.enabled=true
 state.items[state.player.equipment.weapon_1].energy=60
 hud.visible=false
 # 原玩家无线充能未传真实仓库存活状态；基地场景通过子类覆盖隔离这条调用。
 player.tactical.queue_free();player.queue_free()
 player=load('res://scripts/base/actors/base_player.gd').new();player.arena=self;player.position=grid.logical_to_world(Vector2(850,470));add_child(player)
 status_label=Label.new();status_label.position=Vector2(20,20);var ui:=CanvasLayer.new();add_child(ui);ui.add_child(status_label)
 status_label.text='基地防守：Enter开始 / C准备阶段补盾 / WASD移动，鼠标射击'
 if '--base-auto' in OS.get_cmdline_user_args() or '--base-stress' in OS.get_cmdline_user_args():start_fixture_wave(100 if '--base-stress' in OS.get_cmdline_user_args() else 12)
func spawn_enemy(definition:Dictionary):
 super.spawn_enemy(definition)
 if targets.is_empty():return
 var old=targets.pop_back()
 var enemy=load('res://scripts/base/actors/base_enemy.gd').new()
 for key in ['arena','enemy_id','kind','spec','home','position']:enemy.set(key,old.get(key))
 old.set_physics_process(false);old.hide();old.queue_free();add_child(enemy);enemy.collision_mask=1+2+4+16+32+64;targets.append(enemy)
func start_fixture_wave(count:int=12):
 var plan:Array=[]
 for i in count:
  var type:String=['basic','fast','armored','ranged'][i%4]
  plan.append({'id':'fixture:%d'%i,'type':type,'cost':wave_service.config.types[type].cost,'position':grid.project_array([1450+(i%5)*45,360+(i%6)*42])})
 start_wave(plan)
func start_wave(fixture_plan:Array=[]):
 if running:return
 if state.phase=='morning' and not cycle.to_dusk(state):return
 if state.phase=='dusk' and not cycle.begin_night(state,'manual').ok:return
 if state.phase!='night' or state.cycle.night.get('mode','')!='manual':return
 var plan:Dictionary=wave_service.ensure_plan(state,grid)
 if plan.is_empty():return
 if not fixture_plan.is_empty():
  plan.entries=fixture_plan.duplicate(true);plan.fixture=true
  state.base.wave_plan=plan.duplicate(true)
 var saved:Dictionary=state.base.get('defense_runtime',{})
 var restoring:bool=saved.get('plan_id','')==plan.id
 if not restoring:
  state.expedition={'active':false,'id':plan.id,'map_id':'base','maps':{'base':{'enemies':{}}}}
  queue=plan.entries.duplicate(true);spawn_timer=0.0
 else:
  queue=saved.queue.duplicate(true);spawn_timer=float(saved.spawn_timer)
  for record in state.expedition.maps.base.enemies.values():
   if record.get('ai',{}).get('vitals',{}).get('hp',0)>0:spawn_enemy(record)
 if is_instance_valid(blood_visual):blood_visual.clear_effects()
 if restoring:
  for record in state.expedition.maps.base.enemies.values():
   if record.get('ai',{}).get('vitals',{}).get('hp',1)<=0:restore_blood_corpse(record)
 loaded_session=plan.id;loaded_map='base'
 state.base.defense_runtime={'plan_id':plan.id,'queue':queue.duplicate(true),'spawn_timer':spawn_timer}
 running=true
func remaining_enemy_power()->float:
 return wave_service.remaining_power(state.base.wave_plan,state.expedition.maps.base.enemies)
func _unhandled_input(event):
 if event is InputEventKey and event.pressed and event.keycode==KEY_ENTER:start_wave()
 if event is InputEventKey and event.pressed and event.keycode==KEY_C and not running:EnergyService.transfer(state.base.energy_store,state.base.shield,100)
func _physics_process(dt):
 var tick_start:=Time.get_ticks_usec()
 if cycle==null:return
 sync_perimeter()
 elapsed+=dt;frame_samples.append(dt)
 nav_timer-=dt
 if nav_timer<=0:rebuild_base_navigation();nav_timer=1.0
 buckets.clear()
 for enemy in targets:
  if enemy.record().vitals.hp<=0:continue
  var cell:=Vector2i(enemy.position/72)
  if not buckets.has(cell):buckets[cell]=[]
  buckets[cell].append(enemy)
 if running:
  spawn_timer-=dt
  if not queue.is_empty() and spawn_timer<=0:
   var definition:Dictionary=queue.pop_front();state.expedition.maps.base.enemies[definition.id]=definition.duplicate(true);spawn_enemy(definition);spawn_timer=0.0 if '--base-stress' in OS.get_cmdline_user_args() else float(state.base.wave_plan.spawn_interval)
  state.base.defense_runtime={'plan_id':state.base.wave_plan.id,'queue':queue.duplicate(true),'spawn_timer':spawn_timer}
  var left:=0
  for enemy in targets:
   if enemy.record().vitals.hp>0:left+=1
  peak_enemies=maxi(peak_enemies,left)
  status_label.text='剩余敌人 %d + 入场队列 %d | 护盾 %.0f | 能源 %.0f' % [left,queue.size(),state.base.shield.energy,state.base.energy_store.energy]
  if (left==0 and queue.is_empty()) or state.player.vitals.hp<=0:
   state.expedition.active=false
   var result:Dictionary=cycle.finish_night(state,{'enemy_power':remaining_enemy_power()},left==0 and queue.is_empty()) if session_context.is_empty() else session_context.coordinator.finish_night({'enemy_power':remaining_enemy_power()},left==0 and queue.is_empty())
   if result.ok:
    running=false;queue.clear();state.base.defense_runtime.queue=[]
    if is_instance_valid(blood_visual):blood_visual.clear_effects()
    for enemy in targets:enemy.set_physics_process(false);enemy.collision_layer=0;enemy.collision_mask=0;enemy.hide();enemy.queue_free()
    targets.clear()
    for node in get_children():
     if node.get_script()==load('res://scripts/base/actors/base_projectile.gd'):node.set_physics_process(false);node.queue_free()
    if state.player.vitals.hp<=0:player.set_physics_process(false)
    status_label.text='守夜结算：'+str(result.held)
    if not session_context.is_empty():session_context.shell.queue_mount()
 physics_usec.append(Time.get_ticks_usec()-tick_start)
 if '--base-stress' in OS.get_cmdline_user_args() and elapsed>15:
  frame_usec.sort();physics_usec.sort();print('BASE_STRESS peak=',peak_enemies,' rendered_fps=',Engine.get_frames_per_second(),' coordinator_p95_us=',physics_usec[int(physics_usec.size()*0.95)],' frame_p95_us=',frame_usec[int(frame_usec.size()*0.95)],' gpu=',RenderingServer.get_video_adapter_name());get_tree().quit()
 if '--base-capture' in OS.get_cmdline_user_args() and elapsed>8:
  set_physics_process(false)
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png('res://scenes/base/defense-preview.png');get_tree().quit()
func nearest_defense(point:Vector2)->Node2D:
 for fixture in fixtures:
  if fixture.kind=='shield' and state.base.shield.energy>0:return fixture
 var best:Node2D=player if state.player.vitals.hp>0 else null
 var distance:float=point.distance_to(player.position) if best!=null else INF
 for candidate in fixtures+residents:
  if candidate in fixtures and (candidate.kind=='shield' or candidate.data().durability<=0):continue
  if candidate in residents and candidate.data().hp<=0:continue
  if point.distance_to(candidate.position)<distance:best=candidate;distance=point.distance_to(candidate.position)
 return best
func station_active()->bool:
 for f in fixtures:
  if f.kind=='warehouse':return f.data().durability>0
 return false
func nearest_enemy(point:Vector2,distance:float)->Node2D:
 var best:Node2D=null
 for enemy in targets:
  if enemy.record().vitals.hp<=0:continue
  var length:=point.distance_to(enemy.position)
  var ray:=PhysicsRayQueryParameters2D.create(point,enemy.position,33)
  if length<distance and get_world_2d().direct_space_state.intersect_ray(ray).is_empty():best=enemy;distance=length
 return best
func fire_base(from:Vector2,to:Vector2,damage:float,hostile:bool):
 var shot=load('res://scripts/base/actors/base_projectile.gd').new();shot.arena=self;shot.position=from;shot.direction=from.direction_to(to);shot.damage=damage;shot.hostile=hostile;add_child(shot)
func hit(target:Node2D,damage:float,attack:Dictionary={},direction:Vector2=Vector2.ZERO):
 if not target.has_method('record'):return
 var r:Dictionary=target.record();var packet:=attack.duplicate();packet.damage=damage
 var result:Dictionary=DamageRules.hit(r.vitals,r.action,r.armor,packet,config,'enemy');target.set_meta('hp',r.vitals.hp)
 show_blood(result.hp_loss,target.position,direction)
 if result.hp_loss>0 or result.armor_loss>0:emit_sfx('melee_hit' if packet.get('sfx_melee',false) else 'hit_enemy',target.position,true,target.enemy_id)
 if r.vitals.hp<=0:blood_layer().show_death(target.enemy_id,target.position)
 if r.vitals.hp<=0:target.collision_layer=0;target.collision_mask=0
func combat_context()->String:return 'base'
func combat_map_ready()->bool:return true
func _process(_dt):
 var now:=Time.get_ticks_usec()
 if last_frame_us>0:frame_usec.append(now-last_frame_us)
 last_frame_us=now
 queue_redraw()










func sync_perimeter() -> void:
 if not state.get('base',{}).has('bounds'):return
 var signature:=str(state.base.bounds)
 if signature==perimeter_signature:return
 perimeter_signature=signature
 for old in perimeter_walls:
  if not is_instance_valid(old):continue
  old.collision_layer=0
  remove_child(old)
  old.queue_free()
 perimeter_walls.clear()
 for rect in Perimeter.wall_rects(state.base.bounds):perimeter_walls.append(wall(rect))
 nav_timer=0.0
 queue_redraw()

func wall(rect:Rect2,low:bool=false)->StaticBody2D:
 var node:=StaticBody2D.new();node.collision_layer=8 if low else 1
 var points:=grid.rect_polygon(rect)
 node.position=grid.logical_to_world(rect.get_center())
 var local:=PackedVector2Array()
 for point in points:local.append(point-node.position)
 var shape:=CollisionPolygon2D.new();shape.polygon=local;node.add_child(shape)
 # Keep the long collision intact; sort visual strips locally rather than at the wall midpoint.
 var horizontal:=rect.size.x>rect.size.y
 var length:float=rect.size.x if horizontal else rect.size.y
 for offset in range(0,int(length),48):
  var part:=Rect2(rect.position+(Vector2(offset,0) if horizontal else Vector2(0,offset)),Vector2(minf(48,length-offset),rect.size.y) if horizontal else Vector2(rect.size.x,minf(48,length-offset)))
  var visual:=Polygon2D.new();visual.position=grid.logical_to_world(part.get_center());visual.color=Color('465360')
  var strip:=PackedVector2Array()
  for point in grid.rect_polygon(part):strip.append(point-visual.position)
  visual.polygon=strip;add_child(visual);node.tree_exiting.connect(visual.queue_free)
 var occluder:=LightOccluder2D.new();var polygon:=OccluderPolygon2D.new();polygon.polygon=local;occluder.occluder=polygon;node.add_child(occluder);add_child(node)
 return node
func placement_polygon(cell:Vector2i,type:String)->PackedVector2Array:
 var size:Array=building.config.types[type].size
 return grid.rect_polygon(Rect2(Vector2(cell)*48,Vector2(size[0],size[1])*48))
func mouse_build_cell()->Vector2i:return grid.world_to_cell(get_global_mouse_position())
func _draw():
 var area:=Perimeter.bounds_rect(state.base.get('bounds',[0,0,24,18]))
 for y in range(int(area.position.y/48),int(area.end.y/48)):
  for x in range(int(area.position.x/48),int(area.end.x/48)+10):
   var poly:=grid.rect_polygon(Rect2(x*48,y*48,48,48))
   draw_colored_polygon(poly,Color('77734f') if (x+y)%2==0 else Color('6d6948'))
   draw_polyline(PackedVector2Array([poly[0],poly[1],poly[2],poly[3],poly[0]]),Color('585c46'),1)
 if building!=null and not running:
  var poly:=placement_polygon(mouse_build_cell(),'turret')
  draw_colored_polygon(poly,Color(0.2,0.8,0.8,0.35))

func rebuild_base_navigation():
 base_navigation.clear()
 var shape:=CircleShape2D.new();shape.radius=13
 var query:=PhysicsShapeQueryParameters2D.new();query.shape=shape;query.collision_mask=1+32
 var region:=Perimeter.navigation_rect(state.base.bounds)
 var columns:=int(ceil(region.size.x/24.0))
 var rows:=int(ceil(region.size.y/24.0))
 for y in range(rows):
  for x in range(columns):
   var point:=grid.logical_to_world(region.position+Vector2(x*24+12,y*24+12))
   query.transform=Transform2D(0,point)
   if get_world_2d().direct_space_state.intersect_shape(query,1).is_empty():base_navigation.add_point(y*columns+x,point)
 for id in base_navigation.get_point_ids():
  var x:=int(id)%columns;var y:=int(id)/columns
  for offset in [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(-1,1)]:
   var next:Vector2i=Vector2i(x,y)+offset
   if next.x<0 or next.x>=columns or next.y>=rows:continue
   var target:int=next.y*columns+next.x
   if base_navigation.has_point(target) and clear_line(base_navigation.get_point_position(id),base_navigation.get_point_position(target),33):base_navigation.connect_points(id,target)
func walk_direction(point:Vector2,goal:Vector2)->Vector2:
 if clear_line(point,goal,33):return point.direction_to(goal)
 if base_navigation.get_point_count()==0:return Vector2.ZERO
 var path:=base_navigation.get_point_path(base_navigation.get_closest_point(point),base_navigation.get_closest_point(goal))
 for next in path:
  if point.distance_to(next)>10:return point.direction_to(next)
 return Vector2.ZERO





