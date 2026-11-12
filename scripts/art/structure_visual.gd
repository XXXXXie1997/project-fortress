extends RefCounted
const Art=preload("res://scripts/art/fortress_art.gd")
# All geometry is supplied by GridProjection. No collision or room state lives here.
static func surface(theme:String,wall:bool)->AtlasTexture:
 var index:int={"suburbs":0,"armory":1,"city":2}.get(theme,0)
 return Art.region("res://assets/runtime/environment_iso/surfaces.png",index+(3 if wall else 0),3,Vector2i(16,16))
static func polygon(points:PackedVector2Array,theme:String,wall:bool,tint:=Color.WHITE)->Polygon2D:
 var p:=Polygon2D.new();p.polygon=points
 var tex:=surface(theme,wall);p.texture=tex.atlas
 var r:=tex.region
 p.uv=PackedVector2Array([r.position,r.position+Vector2(r.size.x,0),r.end,r.position+Vector2(0,r.size.y)])
 p.color=tint;p.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 return p
static func roof(projection:GridProjection,rect:Rect2,theme:String,height:=44.0)->Node2D:
 var node:=Node2D.new();node.z_index=20
 # Preserve world pixel density; surfaces contain broad seams, not random speckles.
 for y in range(int(rect.position.y),int(rect.end.y),48):
  for x in range(int(rect.position.x),int(rect.end.x),48):
   var points:=projection.rect_polygon(Rect2(x,y,minf(48,rect.end.x-x),minf(48,rect.end.y-y)))
   for i in points.size():points[i].y-=height
   node.add_child(polygon(points,theme,false))
 return node
