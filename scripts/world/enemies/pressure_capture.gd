extends SceneTree
func _initialize():call_deferred('run')
func run():
 root.size=Vector2i(1280,720)
 var scene=load('res://scenes/enemies/enemy_arena.tscn').instantiate();root.add_child(scene)
 for i in range(90):await process_frame
 scene.player.position=Vector2(780,480);scene.player.camera.force_update_scroll()
 for enemy in scene.targets:enemy.hear(scene.player.position,true)
 var samples:Array=[];var activity:Array=[];var previous:=Time.get_ticks_usec()
 var sample_start:=Time.get_ticks_usec()
 var i:=0
 while Time.get_ticks_usec()-sample_start<10000000:
  scene.state.player.vitals.hp=100.0
  if i%30==0:scene.emit_sound(scene.player.position)
  await process_frame
  var current:=Time.get_ticks_usec();samples.append((current-previous)/1000.0);previous=current
  activity.append(scene.telemetry.duplicate())
  i+=1
 if DisplayServer.get_name()!='headless':
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png('res://scenes/enemies/pressure.png')
 var sorted:Array=samples.duplicate();sorted.sort()
 var total:=0.0;var engaged:=0.0;var moving:=0.0;var sensing:=0.0
 for index in range(samples.size()):total+=samples[index];engaged+=activity[index].engaged;moving+=activity[index].moving;sensing+=activity[index].perception
 var report:Dictionary={'enemies':scene.targets.size(),'renderer':RenderingServer.get_video_adapter_name(),'cpu':OS.get_processor_name(),'samples':samples.size(),'mean_ms':total/samples.size(),'p50_ms':sorted[int(sorted.size()*0.50)],'p95_ms':sorted[int(sorted.size()*0.95)],'p99_ms':sorted[int(sorted.size()*0.99)],'mean_engaged':engaged/samples.size(),'mean_moving':moving/samples.size(),'mean_perception':sensing/samples.size(),'attacks_total':scene.telemetry.attacks_total,'navigation_total':scene.telemetry.navigation_total,'memory_bytes':OS.get_static_memory_usage(),'frame_ms':samples,'activity':activity,'fixture_note':'player HP restored each frame to sustain combat; historical shot noises every 30 render frames; real AI movement/pathfinding/attacks remain enabled'}
 var file=FileAccess.open('res://scenes/enemies/pressure.json',FileAccess.WRITE);file.store_string(JSON.stringify(report,'  '));file.close()
 print('PRESSURE count=',report.enemies,' mean_ms=',report.mean_ms,' p95_ms=',report.p95_ms,' engaged=',report.mean_engaged,' moving=',report.mean_moving,' attacks=',report.attacks_total,' nav=',report.navigation_total)
 quit()

