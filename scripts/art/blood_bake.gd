extends SceneTree
func _initialize():
 var source:=Image.load_from_file('res://assets/source/art107/blood-adapted.png')
 var output:=Image.create(32,32,false,Image.FORMAT_RGBA8)
 for index in 4:
  var tile:=source.get_region(Rect2i((index%2)*640,(index/2)*640,640,640))
  var bounds:=Rect2i()
  var found:=false
  for y in tile.get_height():
   for x in tile.get_width():
    if tile.get_pixel(x,y).a>0.5:
     if not found:bounds=Rect2i(x,y,1,1);found=true
     else:bounds=bounds.merge(Rect2i(x,y,1,1))
  tile=tile.get_region(bounds)
  tile.resize(12,10 if index<2 else 7,Image.INTERPOLATE_NEAREST);tile.convert(Image.FORMAT_RGBA8)
  var cell:=Image.create(16,16,false,Image.FORMAT_RGBA8)
  cell.blit_rect(tile,Rect2i(0,0,tile.get_width(),tile.get_height()),Vector2i(2,(16-tile.get_height())/2))
  tile=cell
  output.blit_rect(tile,Rect2i(0,0,16,16),Vector2i((index%2)*16,(index/2)*16))
 print('blood atlas save ',output.save_png('res://assets/runtime/effects/blood/blood.png'))
 quit()
