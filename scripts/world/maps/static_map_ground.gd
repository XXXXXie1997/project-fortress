extends Node2D
# Godot retains these canvas commands until this map-owned node is freed.
# No player/visibility state: floor materials and geometry depend only on content.
var content:Dictionary
var projection:GridProjection
var draw_count:=0
func rect(a:Array)->Rect2:return Rect2(a[0],a[1],a[2],a[3])
func _draw():
 draw_count+=1
 var material:String="asphalt" if content.id=="city" else ("concrete" if content.id=="armory" else "soil")
 preload("res://scripts/art/continuous_ground.gd").paint(self,projection,Rect2(0,0,content.size[0],content.size[1]),material)
 for road in content.roads:
  var r:=rect(road)
  preload("res://scripts/art/continuous_ground.gd").paint(self,projection,r,"asphalt")
  if r.size.x>r.size.y:
   for x in range(int(r.position.x)+24,int(r.end.x)-24,96):draw_line(projection.logical_to_world(Vector2(x,r.get_center().y)),projection.logical_to_world(Vector2(x+40,r.get_center().y)),Color('847650'),2)
  else:
   for y in range(int(r.position.y)+24,int(r.end.y)-24,96):draw_line(projection.logical_to_world(Vector2(r.get_center().x,y)),projection.logical_to_world(Vector2(r.get_center().x,y+40)),Color('847650'),2)
 for room in content.rooms:
  var r:=rect(room.rect)
  preload("res://scripts/art/continuous_ground.gd").paint(self,projection,r,"concrete")
