extends Node2D
# Godot retains these canvas commands until this map-owned node is freed.
# No player/visibility state: floor materials and geometry depend only on content.
var content:Dictionary
var projection:GridProjection
var draw_count:=0
func rect(a:Array)->Rect2:return Rect2(a[0],a[1],a[2],a[3])
func texture_uv_pixels(tex:AtlasTexture)->PackedVector2Array:
 var r:=tex.region
 return PackedVector2Array([r.position,r.position+Vector2(r.size.x,0),r.end,r.position+Vector2(0,r.size.y)])
func ground_tile(type:String,r:Rect2,tint:=Color.WHITE):
 var tex:AtlasTexture=preload('res://scripts/art/art104_nature.gd').texture(type,'armory' if type=='floor' else content.id);var uv:=texture_uv_pixels(tex)
 for i in range(uv.size()):uv[i]/=tex.atlas.get_size()
 draw_polygon(projection.rect_polygon(r),PackedColorArray([Color.WHITE]),uv,tex.atlas)
func _draw():
 draw_count+=1
 for y in range(0,int(content.size[1]),48):
  for x in range(0,int(content.size[0]),48):
   var type:String='paving' if content.id=='city' else ('floor' if content.id=='armory' else ('flowers' if (x/48+y/48*3)%19==0 else 'grass'))
   ground_tile(type,Rect2(x,y,48,48),Color(.55,.65,.55) if content.id=='suburbs' else Color(.55,.6,.65))
 for road in content.roads:
  var r:=rect(road)
  for y in range(int(r.position.y),int(r.end.y),48):
   for x in range(int(r.position.x),int(r.end.x),48):ground_tile('road',Rect2(x,y,minf(48,r.end.x-x),minf(48,r.end.y-y)),Color(.55,.55,.45))
  if r.size.x>r.size.y:
   for x in range(int(r.position.x)+24,int(r.end.x)-24,96):draw_line(projection.logical_to_world(Vector2(x,r.get_center().y)),projection.logical_to_world(Vector2(x+40,r.get_center().y)),Color('847650'),2)
  else:
   for y in range(int(r.position.y)+24,int(r.end.y)-24,96):draw_line(projection.logical_to_world(Vector2(r.get_center().x,y)),projection.logical_to_world(Vector2(r.get_center().x,y+40)),Color('847650'),2)
 for room in content.rooms:
  var r:=rect(room.rect)
  for y in range(int(r.position.y),int(r.end.y),48):
   for x in range(int(r.position.x),int(r.end.x),48):ground_tile('floor',Rect2(x,y,minf(48,r.end.x-x),minf(48,r.end.y-y)),Color(.6,.65,.65))
