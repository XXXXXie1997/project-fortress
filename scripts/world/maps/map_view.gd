extends Control
var arena:Node2D
var bounds:=Rect2()
var factor:=1.0
var labels:Array=[]
var label_rects:Array=[]
var recommended_regions:Array=[]
func refresh_recommended_regions():
 recommended_regions.clear()
 var counts:Dictionary={}
 for q in arena.state.quests.active.values():
  var definition:Dictionary=arena.services.quests.config.definitions.get(q.definition,{})
  if definition.get('kind','')!='daily':continue
  if q.get('deadline',0)>0 and arena.state.day>=q.deadline:continue
  var region:String=definition.get('region','')
  if region.is_empty() or not arena.catalog.has(region):continue
  counts[region]=counts.get(region,0)+1
 for region in counts:
  recommended_regions.append({'region':region,'count':counts[region],'name':{'suburbs':'郊区','city':'城区','armory':'武器库'}.get(region,region)})
func map_point(world:Vector2)->Vector2:return (world-bounds.position)*factor+Vector2(6,6)
func rect_shape(rect:Array)->PackedVector2Array:
 var result:=PackedVector2Array()
 for world in arena.projection.rect_polygon(Rect2(rect[0],rect[1],rect[2],rect[3])):result.append(map_point(world))
 return result
func _draw():
 labels.clear();label_rects.clear()
 recommended_regions.clear()
 draw_rect(Rect2(Vector2.ZERO,size),Color('151919'))
 if not arena.state.expedition.get('active',false):return
 var id:String=arena.state.expedition.map_id;var content:Dictionary=arena.catalog[id]
 bounds=arena.projection.world_bounds(Rect2(Vector2.ZERO,Vector2(content.size[0],content.size[1])))
 factor=minf((size.x-(242 if size.x>400 else 12))/bounds.size.x,(size.y-12)/bounds.size.y)
 if size.x>400:
  refresh_recommended_regions()
  for region in recommended_regions:
   if region.region==id:
    # Current quest definitions recommend the whole map, never a fabricated loot point.
    var area:=rect_shape([0,0,content.size[0],content.size[1]])
    draw_colored_polygon(area,Color(.25,.65,.5,.16))
    var outline:=area.duplicate();outline.append(area[0])
    draw_polyline(outline,Color('7edbc8'),2)
 for road in content.roads:draw_colored_polygon(rect_shape(road),Color('596258'))
 for room in content.rooms:draw_colored_polygon(rect_shape(room.rect),Color('8d9692'))
 for obstacle in content.barriers:draw_colored_polygon(rect_shape(obstacle),Color('9c8b68'))
 for key in content.points:
  var p:Dictionary=content.points[key]
  if p.kind=='spawn' and not key in arena.state.world.exploration.spawns[id]:continue
  if p.kind=='travel' and not arena.state.world.exploration.travel.has(id+':'+key):continue
  var colors={'spawn':Color('7edbc8'),'extraction':Color('82c95e'),'travel':Color('51a8e7'),'exit':Color('e4bd69')}
  var pos:=map_point(Vector2(p.position[0],p.position[1]));draw_circle(pos,4,colors[p.kind])
  if size.x>400:labels.append({'point':pos,'text':{'spawn':'出生','extraction':'撤离','travel':'传送','exit':'出口'}[p.kind]+' · '+p.label,'color':colors[p.kind]})
 for objective in content.objectives:
  for q in arena.state.quests.active.values():
   if arena.services.quests.config.definitions[q.definition].target==objective.quest_target:
    var pos:=map_point(Vector2(objective.position[0],objective.position[1]));draw_circle(pos,5,Color.YELLOW)
    if size.x>400:labels.append({'point':pos,'text':'目标 · '+objective.label,'color':Color.YELLOW})
 for box in arena.state.world.exploration.death_bags.values():
  if box.map_id==id:draw_circle(map_point(Vector2(box.position[0],box.position[1])),5,Color.ORANGE)
 for enemy in arena.targets:
  if arena.enemy_visible_to_player(enemy):draw_circle(map_point(enemy.position),3,Color.RED)
 draw_circle(map_point(arena.player.position),4,Color.WHITE)

 if size.x>400:draw_labels()
func draw_labels():
 var font:Font=preload('res://scripts/ui/wasteland_theme.gd').get_theme().default_font
 var x:float=size.x-224
 draw_rect(Rect2(x-6,6,224,size.y-12),Color(.04,.08,.1,.98))
 draw_string(font,Vector2(x+5,27),'地点索引 · 引线对应地图点',HORIZONTAL_ALIGNMENT_LEFT,214,14,Color.WHITE)
 for i in range(labels.size()):
  var entry:Dictionary=labels[i]
  var y:float=42+i*36
  var area:=Rect2(x,y,214,30);label_rects.append(area)
  draw_rect(area,Color(.12,.19,.22))
  var number:=str(i+1)
  var pos:Vector2=entry.point
  draw_line(pos,Vector2(x-10,y+15),Color(entry.color,.65),1)
  draw_circle(pos,3,entry.color)
  draw_string(font,Vector2(x+5,y+20),number+'  '+entry.text,HORIZONTAL_ALIGNMENT_LEFT,204,14,entry.color)
 if not recommended_regions.is_empty():
  var top:float=size.y-18-recommended_regions.size()*48-26
  draw_string(font,Vector2(x+5,top+18),'委托推荐区域',HORIZONTAL_ALIGNMENT_LEFT,204,14,Color('7edbc8'))
  for i in range(recommended_regions.size()):
   var region:Dictionary=recommended_regions[i]
   var y:float=top+26+i*48
   draw_rect(Rect2(x,y,214,44),Color(.08,.22,.19))
   draw_string(font,Vector2(x+5,y+18),'%s · %d项委托'%[region.name,region.count],HORIZONTAL_ALIGNMENT_LEFT,204,14,Color('7edbc8'))
   draw_string(font,Vector2(x+5,y+36),'范围：整片区域，无精确目标点',HORIZONTAL_ALIGNMENT_LEFT,204,12,Color.WHITE)

