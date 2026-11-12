extends "res://scripts/world/enemies/enemy_arena.gd"
signal returned_to_base(result:Dictionary)
signal base_failed(result:Dictionary)
var projection:=GridProjection.new()
var logical_catalog:Dictionary={}
var catalog:Dictionary={}
var geometry:Node2D
var services:Dictionary
var cycle:DayCycle
var ready_world:=false
var message:=''
var map_size:=Vector2(2400,1920)
func _ready():
 if not session_context.is_empty():
  await preload('res://scripts/game/session/world_mount.gd').mount(self,'map')
  return
 await super._ready()
 for child in get_children():
  if child is StaticBody2D:child.collision_layer=0;child.queue_free()
 clear_map_effects()
 for target in targets:target.set_physics_process(false);target.queue_free()
 targets.clear()
 exploration.cleanup_session(state);state.expedition={};state.world.erase('exploration');loaded_map='';loaded_session=''
 for id in ['suburbs','armory','city']:
  logical_catalog[id]=JSON.parse_string(FileAccess.get_file_as_string('res://data/maps/content/'+id+'.json'))
  catalog[id]=project_content(logical_catalog[id])
 navigation=load('res://scripts/world/grid/projected_navigation.gd').new();navigation.projection=projection
 y_sort_enabled=true
 exploration=ExplorationService.new(inventory,catalog.duplicate(true));exploration.setup(state)
 services=preload('res://scripts/world/maps/service_factory.gd').create(self)
 cycle=DayCycle.new(services);cycle.setup(state);services.quests.accept(state,'main_1',true)
 hud.queue_free();hud=load('res://scripts/world/maps/map_hud.gd').new();hud.arena=self;add_child(hud)
 station=Vector2(-10000,-10000);player.position=Vector2(240,1700)
 ready_world=true;hud.show_departure()
func depart(map_id:String,spawn_id:String,night:=false,confirmed:=false)->bool:
 if state.expedition.get('active',false) or state.phase!=('dusk' if night else 'morning'):return false
 var next_rng:String=state.rng_state
 exploration.maps=catalog.duplicate(true)
 if night:
  var rng:=RandomNumberGenerator.new();rng.state=int(state.rng_state)
  for m in exploration.maps.values():
   m.enemies.append_array(m.night_enemies)
   if rng.randf()<0.7:m.containers[-1].loot.append({'definition_id':'catalyst','quantity':1})
  next_rng=str(rng.state)
 var ok:bool=cycle.begin_night(state,'explore',confirmed,map_id,spawn_id).ok if night else cycle.depart_day(state,map_id,spawn_id)
 if ok:
  state.rng_state=next_rng;player.inventory_movement_locked=false
  await rebuild_map();hud.close_menu()
 else:message='当前阶段不能出发，或该时段已探索过'
 return ok
func rebuild_map():
 if geometry!=null:
  for child in geometry.get_children():
   if child is StaticBody2D:child.collision_layer=0
  geometry.queue_free()
 var id:String=state.expedition.map_id;var data:Dictionary=catalog[id]
 map_size=Vector2(data.size[0],data.size[1]);geometry=load('res://scripts/world/maps/map_geometry.gd').new();geometry.arena=self;geometry.content=logical_catalog[id];geometry.projection=projection;add_child(geometry)
 var p:Array=data.points[state.expedition.point_id].position;player.position=Vector2(p[0],p[1]);player.velocity=Vector2.ZERO
 ambient_brightness=.13 if state.expedition.period=='night' else 1.0
 await get_tree().physics_frame
 rebuild_navigation()
 if not session_context.is_empty():preload('res://scripts/game/session/world_mount.gd').mount_encounters(self)
func rebuild_navigation():
 navigation.region=Rect2i(0,0,int(map_size.x/48),int(map_size.y/48));navigation.cell_size=Vector2(48,48);navigation.offset=Vector2(24,24);navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;navigation.update()
 var shape:=CircleShape2D.new();shape.radius=16
 var query:=PhysicsShapeQueryParameters2D.new();query.shape=shape;query.collision_mask=9
 for y in range(navigation.region.size.y):
  for x in range(navigation.region.size.x):
   query.transform=Transform2D(0,projection.cell_to_world(Vector2i(x,y)));navigation.set_point_solid(Vector2i(x,y),not get_world_2d().direct_space_state.intersect_shape(query,1).is_empty())
func nearest_cell(point:Vector2)->Vector2i:
 var picked:=projection.world_to_cell(point)
 var cell:=Vector2i(clampi(picked.x,0,navigation.region.size.x-1),clampi(picked.y,0,navigation.region.size.y-1))
 for radius in range(4):
  for y in range(-radius,radius+1):
   for x in range(-radius,radius+1):
    var test:=cell+Vector2i(x,y)
    if navigation.region.has_point(test) and not navigation.is_point_solid(test):return test
 return cell
func _physics_process(dt):
 if not ready_world:return
 super._physics_process(dt)
 if not state.expedition.get('active',false):
  player.inventory_movement_locked=true
  var warehouse:Dictionary=cycle.facility(state,'warehouse')
  ChargingService.wireless(state,dt,15,true,warehouse.get('durability',0)>0,false)
  return
 if state.player.vitals.hp<=0:finish(true);return
 for id in catalog[state.expedition.map_id].points:
  var p:Dictionary=catalog[state.expedition.map_id].points[id]
  if p.kind=='spawn' and player.position.distance_to(Vector2(p.position[0],p.position[1]))<90:exploration.discover(state,id)
func nearby()->Dictionary:
 if not state.expedition.get('active',false):return {}
 var content:Dictionary=catalog[state.expedition.map_id]
 for box_id in state.expedition.maps[content.id].containers.keys()+state.world.exploration.death_bags.keys():
  var box:Dictionary=exploration.box(state,box_id)
  if not box.is_empty() and player.position.distance_to(Vector2(box.position[0],box.position[1]))<64:return {'kind':'box','id':box_id,'label':'搜刮 '+box_id}
 for room in content.rooms:
  if geometry.doors.has(room.id) and player.position.distance_to(projection.logical_to_world(Rect2(room.door[0],room.door[1],room.door[2],room.door[3]).get_center()))<85:return {'kind':'door','id':room.id,'label':'消耗钥匙打开封锁门'}
 for o in content.objectives+content.events:
  if player.position.distance_to(Vector2(o.position[0],o.position[1]))<70:return {'kind':'objective' if o.has('quest_target') else 'event','id':o.id,'label':o.label,'data':o}
 for id in content.points:
  var p:Dictionary=content.points[id]
  if player.position.distance_to(Vector2(p.position[0],p.position[1]))<70:return {'kind':p.kind,'id':id,'label':p.label}
 return {}
func interact():
 var entry:=nearby()
 if entry.is_empty():return
 var before_session:String=WorldState.encode(state) if not session_context.is_empty() else ''
 var id:String=entry.id
 match entry.kind:
  'box':hud.open_inventory(id)
  'exit':
   if exploration.exit_map(state,id):await rebuild_map()
   else:message='该区域尚未解锁：完成主线并到次日生效'
  'extraction':finish(false,id)
  'spawn':exploration.discover(state,id);message='已发现出生点'
  'travel':
   if exploration.repair_travel(state,id,{'scrap':3}):hud.show_travel(id)
   else:message='修复需要背包中 3 废料'
  'door':
   if exploration.unlock_door(state,id,catalog[state.expedition.map_id].doors[id]):
    geometry.doors[id].collision_layer=0;geometry.doors[id].queue_free();geometry.doors.erase(id);await get_tree().physics_frame;rebuild_navigation();message='门已永久解锁'
   else:message='缺少附近的专用钥匙'
  'objective':services.quests.record(state,'reach',entry.data.quest_target,id);message='调查已记录，返回基地交付主线'
  'event':cycle.threat.schedule(state,id,true,state.expedition.period=='night');message='异常广播已触发：怪潮强度按此刻冻结'
 if not session_context.is_empty() and before_session!=WorldState.encode(state):session_context.coordinator.request_save.call_deferred()
func finish(died:bool,exit_id:=''):
 if not session_context.is_empty():
  var outcome:Dictionary=session_context.coordinator.finish_exploration(died,[player.position.x,player.position.y],exit_id)
  if outcome.get('ok',false):session_context.shell.queue_mount()
  else:message='撤离或结算失败：未改变世界，请重试'
  return
 var result:Dictionary=exploration.finish(state,died,[player.position.x,player.position.y],3,exit_id)
 if not result.get('ok',false):return
 var settled:Dictionary={'ok':true}
 if state.phase=='day':settled={'ok':cycle.to_dusk(state)}
 else:settled=cycle.finish_night(state)
 if not settled.get('ok',false):message='阶段结算失败：保留状态等待恢复，不能再次出发'
 if state.cycle.failed:base_failed.emit(settled)
 returned_to_base.emit(settled)
 sync_unlocks();ambient_brightness=1;hud.show_departure()
func _draw():pass
func _process(_dt):pass
func sync_unlocks():
 if state.threat.stage>=2:exploration.unlock_map(state,'city')
func hit(target:Node2D,damage:float,attack:Dictionary={},direction:Vector2=Vector2.ZERO):
 var alive:bool=target.get_meta('hp',0)>0
 super.hit(target,damage,attack,direction)
 if alive and target.get_meta('hp',0)<=0:
  services.quests.record(state,'kill','infected',str(state.expedition.id)+':'+target.enemy_id)
  if target.kind=='boss':
   var box:Dictionary=exploration.box(state,'loot_'+target.enemy_id)
   if not box.is_empty():inventory.spawn(state,'boss_core',box.container_id,1)
  if not session_context.is_empty():session_context.coordinator.request_save.call_deferred()

func project_content(source:Dictionary)->Dictionary:
 var result:=source.duplicate(true)
 for key in ['enemies','night_enemies','containers','objectives','events']:
  for entry in result[key]:entry.position=projection.project_array(entry.position)
 for point in result.points.values():point.position=projection.project_array(point.position)
 return result
func find_path(start:Vector2,goal:Vector2)->PackedVector2Array:
 telemetry.navigation_total+=1
 var path:=PackedVector2Array()
 if navigation.is_dirty():return path
 for cell in navigation.get_id_path(nearest_cell(start),nearest_cell(goal)):path.append(projection.cell_to_world(cell))
 return path
func enemy_visible_to_player(enemy:Node2D)->bool:
 if not enemy.visible_to_player():return false
 var enemy_point:=projection.world_to_logical(enemy.position)
 var player_point:=projection.world_to_logical(player.position)
 for room in logical_catalog[state.expedition.map_id].rooms:
  var bounds:=Rect2(room.rect[0],room.rect[1],room.rect[2],room.rect[3])
  if bounds.has_point(enemy_point) and not bounds.grow(8).has_point(player_point):return false
 return true
