class_name GridProjection
extends RefCounted
## Geometry conversion only. Logical positions use the existing 48-unit cell space.
## World positions are the actual Godot physics/render space. Never project them twice.
var logical_cell:float
var tile_size:Vector2
var origin:Vector2
func _init(cell_units:=48.0,diamond_size:=Vector2(96,48),world_origin:=Vector2.ZERO):
 assert(cell_units>0 and diamond_size.x>0 and diamond_size.y>0)
 logical_cell=cell_units;tile_size=diamond_size;origin=world_origin
func logical_to_world(point:Vector2)->Vector2:
 var cell:=point/logical_cell
 return origin+Vector2((cell.x-cell.y)*tile_size.x*.5,(cell.x+cell.y)*tile_size.y*.5)
func world_to_logical(point:Vector2)->Vector2:
 var relative:=point-origin
 var sum:=relative.y/(tile_size.y*.5)
 var difference:=relative.x/(tile_size.x*.5)
 return Vector2((sum+difference)*.5,(sum-difference)*.5)*logical_cell
func cell_to_world(cell:Vector2i,center:=true)->Vector2:
 return logical_to_world((Vector2(cell)+Vector2(.5,.5) if center else Vector2(cell))*logical_cell)
func world_to_cell(point:Vector2)->Vector2i:
 return Vector2i((world_to_logical(point)/logical_cell).floor())
func rect_polygon(rect:Rect2)->PackedVector2Array:
 return PackedVector2Array([logical_to_world(rect.position),logical_to_world(rect.position+Vector2(rect.size.x,0)),logical_to_world(rect.end),logical_to_world(rect.position+Vector2(0,rect.size.y))])
func world_bounds(logical_bounds:Rect2)->Rect2:
 var corners:=rect_polygon(logical_bounds)
 var result:=Rect2(corners[0],Vector2.ZERO)
 for point in corners:result=result.expand(point)
 return result
func project_array(point:Array)->Array:
 var world:=logical_to_world(Vector2(point[0],point[1]));return [world.x,world.y]
func logical_vector_to_world(direction:Vector2)->Vector2:
 return logical_to_world(direction)-origin
