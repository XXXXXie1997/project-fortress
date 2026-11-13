extends RefCounted
const MATERIALS={"base":preload("res://assets/runtime/environment/continuous/base.png"),"soil":preload("res://assets/runtime/environment/continuous/soil.png"),"asphalt":preload("res://assets/runtime/environment/continuous/asphalt.png"),"concrete":preload("res://assets/runtime/environment/continuous/concrete.png")}
static func paint(canvas:Node2D,projection:GridProjection,r:Rect2,material:String):
 canvas.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
 canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 var uv:=PackedVector2Array([r.position,r.position+Vector2(r.size.x,0),r.end,r.position+Vector2(0,r.size.y)])
 for i in range(uv.size()):uv[i]/=128.0
 canvas.draw_polygon(projection.rect_polygon(r),PackedColorArray([Color.WHITE]),uv,MATERIALS[material])
