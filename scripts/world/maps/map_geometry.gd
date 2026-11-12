extends Node2D
const StructureArt=preload('res://scripts/art/structure_visual.gd')
var arena:Node2D
var content:Dictionary
var projection:GridProjection
var roofs:Array=[]
var doors:Dictionary={}
var tiles:Dictionary={}
var box_visuals:Dictionary={}
func rect(a:Array)->Rect2:return Rect2(a[0],a[1],a[2],a[3])
func _ready():
 y_sort_enabled=true
 for pair in [['paving','dungeon',Rect2(0,0,16,16)],['grass','town',Rect2(0,0,16,16)],['flowers','town',Rect2(16,0,16,16)],['roof','town',Rect2(16,64,16,16)],['wall','dungeon',Rect2(32,48,16,16)],['road','town',Rect2(16,32,16,16)],['floor','dungeon',Rect2(0,64,16,16)],['crate','dungeon',Rect2(80,112,16,16)],['tree','town',Rect2(48,0,16,32)]]:
  var tex:=AtlasTexture.new();tex.atlas=load('res://assets/runtime/environment/'+pair[1]+'.png');tex.region=pair[2];tiles[pair[0]]=tex
 var w:float=content.size[0];var h:float=content.size[1]
 for r in [Rect2(0,0,w,24),Rect2(0,h-24,w,24),Rect2(0,0,24,h),Rect2(w-24,0,24,h)]:solid(r)
 for room in content.rooms:
  var r:=rect(room.rect);var d:=rect(room.door)
  for edge in [Rect2(r.position,Vector2(r.size.x,24)),Rect2(r.position,Vector2(24,r.size.y)),Rect2(r.end-Vector2(24,r.size.y),Vector2(24,r.size.y)),Rect2(r.position.x,r.end.y-24,d.position.x-r.position.x,24),Rect2(d.end.x,r.end.y-24,r.end.x-d.end.x,24)]:solid(edge)
  if room.locked and not arena.state.world.exploration.doors.has(content.id+':'+room.id):doors[room.id]=solid(d,false,Color('c7a865'))
  var roof:=StructureArt.roof(projection,r,content.id);add_child(roof)
  roofs.append({'rect':r,'node':roof})
 for r in content.barriers:solid(rect(r),true,Color('8d9988'))
 for p in content.trees:
  var pos:=Vector2(p[0],p[1]);var body:=solid(Rect2(pos-Vector2(8,8),Vector2(16,16)),false,Color('685343'))
  var tree:=Sprite2D.new();tree.texture=preload('res://scripts/art/art104_nature.gd').texture('tree',content.id,int(pos.x/48+pos.y/48)%4);tree.position=projection.logical_to_world(pos)-body.position;tree.offset=Vector2(0,-24);tree.scale=Vector2(3,3);tree.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;body.add_child(tree)
func texture_uv_pixels(tex:AtlasTexture)->PackedVector2Array:
 var r:=tex.region
 return PackedVector2Array([r.position,r.position+Vector2(r.size.x,0),r.end,r.position+Vector2(0,r.size.y)])
func solid(r:Rect2,low:=false,color:=Color('a0a9af'))->StaticBody2D:
 var points:=projection.rect_polygon(r)
 var body:=StaticBody2D.new();body.position=projection.logical_to_world(r.end);body.collision_layer=8 if low else 1;body.collision_mask=0
 var local:=PackedVector2Array()
 for point in points:local.append(point-body.position)
 var collision:=CollisionPolygon2D.new();collision.polygon=local;body.add_child(collision)
 var height:=Vector2(0,14 if low else 44)
 for i in [1,2]:
  var next: int=(i+1)%4
  var face:=StructureArt.polygon(PackedVector2Array([local[i]-height,local[next]-height,local[next],local[i]]),content.id,true,color*(Color(.75,.75,.8) if i==2 else Color.WHITE));body.add_child(face)
 var top:=Polygon2D.new();var raised:=PackedVector2Array()
 for point in local:raised.append(point-height)
 top.polygon=raised;top.color=color;body.add_child(top)
 if not low:
  var occ:=LightOccluder2D.new();var outline:=OccluderPolygon2D.new();outline.polygon=local;occ.occluder=outline;body.add_child(occ)
 add_child(body);return body
func _process(_dt):
 if arena.state.expedition.get('active',false) and arena.state.expedition.map_id==content.id:
  for enemy in arena.targets:enemy.visible=arena.enemy_visible_to_player(enemy)
  var boxes:Dictionary=arena.state.expedition.maps[content.id].containers.duplicate()
  for id in arena.state.world.exploration.death_bags:
   var box:Dictionary=arena.state.world.exploration.death_bags[id]
   if box.map_id==content.id:boxes[id]=box
  for id in boxes:
   if not box_visuals.has(id):
    var anchor:=Node2D.new();anchor.position=Vector2(boxes[id].position[0],boxes[id].position[1]);add_child(anchor)
    var sprite:=Sprite2D.new();sprite.texture=tiles.crate;sprite.scale=Vector2(2.5,2.5);sprite.position.y=-16;sprite.modulate=Color(1,.7,.4) if id.begins_with('death_') else Color.WHITE;anchor.add_child(sprite);box_visuals[id]=anchor
  for id in box_visuals.keys():
   if not boxes.has(id):box_visuals[id].queue_free();box_visuals.erase(id)
 for roof in roofs:roof.node.modulate.a=0.06 if roof.rect.grow(8).has_point(projection.world_to_logical(arena.player.position)) else 1.0
 queue_redraw()
func ground_tile(type:String,r:Rect2,tint:=Color.WHITE):
 var tex:AtlasTexture=preload('res://scripts/art/art104_nature.gd').texture(type,'armory' if type=='floor' else content.id);var uv:=texture_uv_pixels(tex)
 for i in range(uv.size()):uv[i]/=tex.atlas.get_size()
 draw_polygon(projection.rect_polygon(r),PackedColorArray([Color.WHITE]),uv,tex.atlas)
func _draw():
 if tiles.is_empty():return
 var view:=Rect2(arena.player.position-Vector2(1600,1000),Vector2(3200,2000))
 for y in range(0,int(content.size[1]),48):
  for x in range(0,int(content.size[0]),48):
   if view.has_point(projection.logical_to_world(Vector2(x,y))):
    var type:String='paving' if content.id=='city' else ('floor' if content.id=='armory' else ('flowers' if (x/48+y/48*3)%19==0 else 'grass'))
    ground_tile(type,Rect2(x,y,48,48),Color(.55,.65,.55) if content.id=='suburbs' else Color(.55,.6,.65))
 for road in content.roads:
  var r:=rect(road)
  for y in range(int(r.position.y),int(r.end.y),48):
   for x in range(int(r.position.x),int(r.end.x),48):ground_tile('road',Rect2(x,y,minf(48,r.end.x-x),minf(48,r.end.y-y)),Color(.55,.55,.45))
  if r.size.x>r.size.y:
   for x in range(int(r.position.x)+24,int(r.end.x)-24,96):draw_line(projection.logical_to_world(Vector2(x,r.get_center().y)),projection.logical_to_world(Vector2(x+40,r.get_center().y)),Color('b9ac74'),2)
  else:
   for y in range(int(r.position.y)+24,int(r.end.y)-24,96):draw_line(projection.logical_to_world(Vector2(r.get_center().x,y)),projection.logical_to_world(Vector2(r.get_center().x,y+40)),Color('b9ac74'),2)
 for room in content.rooms:
  var r:=rect(room.rect)
  for y in range(int(r.position.y),int(r.end.y),48):
   for x in range(int(r.position.x),int(r.end.x),48):ground_tile('floor',Rect2(x,y,minf(48,r.end.x-x),minf(48,r.end.y-y)),Color(.6,.65,.65))
 if not arena.state.expedition.get('active',false):return
 for p in arena.catalog[content.id].points.values():
  var colors={'spawn':Color('7edbc8'),'extraction':Color('82c95e'),'travel':Color('51a8e7'),'exit':Color('e4bd69')}
  var pos:=Vector2(p.position[0],p.position[1]);draw_circle(pos,25,colors[p.kind]*Color(1,1,1,.25));draw_arc(pos,25,0,TAU,24,colors[p.kind],3)
 for objective in arena.catalog[content.id].objectives:draw_circle(Vector2(objective.position[0],objective.position[1]),14,Color('e8d766'))
