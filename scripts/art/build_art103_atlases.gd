extends SceneTree
# Source-sheet gutters are not perfectly uniform in the generated frames.
# Explicit reviewed frame bounds exclude right-neighbour limbs, not detached attack pixels.
const RIGHT_GUTTER={"enemies/fast:3:1":16,"enemies/ranged:4:3":16}
func _initialize()->void:
 bake("environment_iso/facilities",4,3,Vector2i(64,64),Vector2i(60,60),false)
 bake("environment_iso/crops",3,2,Vector2i(64,48),Vector2i(60,44),true)
 bake("items/items",4,4,Vector2i(20,20),Vector2i(18,18),false)
 bake("items/attachments",2,1,Vector2i(20,20),Vector2i(18,18),false)
 for kind in ["basic","fast","armored","ranged","boss"]:
  var cell:=Vector2i(40,40) if kind=="boss" else Vector2i(32,32)
  var target:=Vector2i(36,36) if kind=="boss" else Vector2i(28,28)
  bake("enemies/"+kind,6,4,cell,target,true)
 quit()
func bake(name:String,cols:int,rows:int,cell:Vector2i,target:Vector2i,constant:bool)->void:
 var input:=Image.load_from_file("res://assets/runtime/"+name+"-source.png")
 var frames:Array[Image]=[]
 var maximum:=Vector2i.ONE
 for y in rows:
  for x in cols:
   var inset:int=RIGHT_GUTTER.get(name+':'+str(x)+':'+str(y),0)
   var img:=input.get_region(Rect2i(x*input.get_width()/cols,y*input.get_height()/rows,input.get_width()/cols-inset,input.get_height()/rows))
   for py in img.get_height():
    for px in img.get_width():
     var color:=img.get_pixel(px,py)
     color.a=0.0 if color.a<0.5 else 1.0
     img.set_pixel(px,py,color)
   img=img.get_region(img.get_used_rect());frames.append(img)
   maximum=maximum.max(img.get_size())
 var result:=Image.create(cell.x*cols,cell.y*rows,false,Image.FORMAT_RGBA8)
 for i in frames.size():
  var img:=frames[i]
  var bounds:=maximum if constant else img.get_size()
  var ratio:=minf(float(target.x)/bounds.x,float(target.y)/bounds.y)
  img.resize(maxi(1,roundi(img.get_width()*ratio)),maxi(1,roundi(img.get_height()*ratio)),Image.INTERPOLATE_NEAREST)
  img=img.get_region(img.get_used_rect())
  var pos:=Vector2i((i%cols)*cell.x+(cell.x-img.get_width())/2,(i/cols)*cell.y+cell.y-img.get_height())
  result.blit_rect(img,Rect2i(Vector2i.ZERO,img.get_size()),pos)
 print(name," ",result.save_png("res://assets/runtime/"+name+".png"))
