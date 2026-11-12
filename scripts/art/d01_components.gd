extends SceneTree
func _initialize():
 for kind in ['basic','fast','armored','ranged','boss']:
  var size:=40 if kind=='boss' else 32
  var im:=Image.load_from_file('res://assets/runtime/enemies/'+kind+'.png')
  for row in 4:
   for col in 6:
    var visited:Dictionary={};var areas:Array=[]
    for y in size:
     for x in size:
      var p:=Vector2i(x,y)
      if visited.has(p) or im.get_pixel(col*size+x,row*size+y).a<.5:continue
      var todo:Array[Vector2i]=[p];visited[p]=true;var area:=0
      while not todo.is_empty():
       var q:Vector2i=todo.pop_back();area+=1
       for dy in range(-1,2):
        for dx in range(-1,2):
         var n:=q+Vector2i(dx,dy)
         if n.x<0 or n.y<0 or n.x>=size or n.y>=size or visited.has(n):continue
         if im.get_pixel(col*size+n.x,row*size+n.y).a>=.5:visited[n]=true;todo.append(n)
      areas.append(area)
      if area<10:print(kind," small row=",row," col=",col," start=",p," area=",area)
    areas.sort();areas.reverse()
    if areas.size()>1:print(kind,' row=',row,' col=',col,' components=',areas)
 quit()

