extends SceneTree
func _initialize() -> void:
 normalize("res://assets/runtime/characters/survivor-source.png","res://assets/runtime/characters/survivor.png",4,4,Vector2i(24,24),Vector2i(14,22),true)
 normalize("res://assets/runtime/weapons/equipment-source.png","res://assets/runtime/weapons/equipment.png",4,3,Vector2i(24,16),Vector2i(22,12),false)
 quit()
func normalize(src: String,dst: String,cols: int,rows: int,cell: Vector2i,body: Vector2i,foot: bool) -> void:
 var im := Image.load_from_file(src)
 var output := Image.create(cell.x*cols,cell.y*rows,false,Image.FORMAT_RGBA8)
 for y in rows:
  for x in cols:
   var img := im.get_region(Rect2i(x*im.get_width()/cols,y*im.get_height()/rows,im.get_width()/cols,im.get_height()/rows))
   for py in img.get_height():
    for px in img.get_width():
     var color := img.get_pixel(px,py)
     if color.a<0.5: img.set_pixel(px,py,Color.TRANSPARENT)
   var bounds := img.get_used_rect()
   print(src, ' cell ', x, ',', y, ' bounds ', bounds)
   img=img.get_region(bounds)
   var ratio := minf(float(body.x)/img.get_width(),float(body.y)/img.get_height())
   var w := maxi(1,roundi(img.get_width()*ratio))
   var h := maxi(1,roundi(img.get_height()*ratio))
   img.resize(w,h,Image.INTERPOLATE_NEAREST)
   var at := Vector2i(x*cell.x+(cell.x-w)/2,y*cell.y+(cell.y-h if foot else (cell.y-h)/2))
   output.blit_rect(img,Rect2i(0,0,w,h),at)
 print(dst," result ",output.save_png(dst))

