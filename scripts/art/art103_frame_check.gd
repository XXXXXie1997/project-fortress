extends SceneTree
func _initialize():
 var failures:=[]
 for kind in ["basic","fast","armored","ranged","boss"]:
  var im:=Image.load_from_file("res://assets/runtime/enemies/"+kind+".png")
  var size:=40 if kind=="boss" else 32
  var count:=0
  for y in 4:
   for x in 6:
    var frame:=im.get_region(Rect2i(x*size,y*size,size,size))
    var bounds:=frame.get_used_rect()
    if bounds.size==Vector2i.ZERO:failures.append(kind+str([x,y])+" empty")
    if bounds.position.x<1 or bounds.end.x>=size:failures.append(kind+str([x,y])+" horizontal bleed")
    if bounds.end.y!=size:failures.append(kind+str([x,y])+" foot anchor")
    for py in size:
     for px in size:
      var alpha:=frame.get_pixel(px,py).a
      if alpha>0 and alpha<1 and not failures.has(kind+" fractional alpha"):failures.append(kind+" fractional alpha")
    count+=1
  print("ART103_FRAMES ",kind," ",count)
 print("ART103_FRAME_FAILURES ",failures)
 quit(0 if failures.is_empty() else 1)
