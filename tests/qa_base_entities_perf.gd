extends SceneTree
func _initialize():
 var a=load('res://scenes/base/base_defense.tscn').instantiate();root.add_child(a)
 for i in 20:await physics_frame
 a.start_wave()
 a.queue.clear()
 for i in 100:
  var p=a.grid.logical_to_world(Vector2(1450+(i%5)*45,360+(i%6)*42))
  a.queue.append({'id':'perf:%d'%i,'type':['basic','fast','armored','ranged'][i%4],'position':[p.x,p.y]})
 var start=Time.get_ticks_msec()
 var moved={};var prev={};var maxlive=0;var attacks=0;var frames=[];var last=Time.get_ticks_usec()
 while Time.get_ticks_msec()-start<25000:
  await process_frame
  var now=Time.get_ticks_usec();frames.append(now-last);last=now
  maxlive=max(maxlive,a.targets.size())
  for e in a.targets:
   if prev.has(e.enemy_id) and e.position.distance_to(prev[e.enemy_id])>0.01:moved[e.enemy_id]=true
   prev[e.enemy_id]=e.position
   if e.record().attack_left>0:attacks+=1
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png('res://docs/testing/DEV-402-qa-render.png')
 frames.sort();var sum=0.0
 for f in frames:sum+=f
 print('QA_PERF live_peak=',maxlive,' moved=',moved.size(),' attack_frame_observations=',attacks,' fps_average=',frames.size()*1000000.0/sum,' p95_ms=',frames[int(frames.size()*0.95)]/1000.0,' p99_ms=',frames[int(frames.size()*0.99)]/1000.0)
 quit()
