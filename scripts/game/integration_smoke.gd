extends SceneTree
var errors:=0
func check(value:bool,label:String):
 print(('PASS ' if value else 'FAIL ')+label)
 if not value:errors+=1
func _initialize():call_deferred('run')
func frames(n:int):
 for i in range(n):await physics_frame
func key(action:String):
 var event=InputEventAction.new();event.action=action;event.pressed=true
 Input.parse_input_event(event)
 await frames(1)
 event=InputEventAction.new();event.action=action;event.pressed=false;Input.parse_input_event(event)
func run():
 var scene=load('res://scenes/main.tscn').instantiate();root.add_child(scene);await frames(4)
 var actor=scene.player
 var start:Vector2=actor.position
 Input.action_press('move_right');await frames(12);Input.action_release('move_right')
 check(actor.position.x>start.x,'real movement')
 await key('charge');await frames(60)
 check(actor.item().energy>0 and scene.inventory.items_in(scene.state,'bag')[0].energy<100,'actual battery transfer')
 await key('charge')
 var old:float=actor.item().energy
 await key('weapon_next');check(actor.slot==2 and not scene.state.player.combat.charging,'switch actual slot')
 await key('weapon_previous');check(actor.item().energy==old,'switch preserves energy')
 await key('inventory');var slot:int=actor.slot;await key('weapon_next');check(actor.slot==slot and not paused,'panel input blocked no world pause');await key('cancel')
 await key('cancel');var stamina:float=scene.state.player.combat.stamina;await frames(4);check(paused and scene.state.player.combat.stamina==stamina,'pause freezes simulation');await key('cancel')
 actor.position=Vector2(610,400);Input.action_press('move_right');await key('dodge');await frames(30);Input.action_release('move_right');check(actor.position.x<639,'dodge cannot cross wall')
 actor.position=Vector2(850,400)
 var bullet=load('res://scripts/game/projectile.gd').new();bullet.arena=scene;bullet.position=Vector2(850,400);bullet.direction=Vector2.RIGHT;scene.add_child(bullet)
 await frames(20);check(scene.targets[1].get_meta('hp')<100,'physical projectile damages target')
 actor.position=Vector2(180,280);await frames(2)
 actor.tactical.toggle();await frames(2)
 check(actor.tactical.light.enabled,'actual cone light enabled')
 actor.tactical.install_next_fixture();await frames(2)
 check(actor.tactical.battery().definition_id=='tactical_laser' and actor.tactical.mode==1,'actual laser plugin installed')
 actor.tactical.install_next_fixture();await frames(2)
 check(actor.tactical.battery().definition_id=='tactical_launcher' and actor.tactical.mode==2,'actual launcher plugin installed')
 actor.position=Vector2(600,400);await frames(2)
 check(actor.tactical.clamp_landing(Vector2(800,400)).x<650,'high wall clips launcher destination')
 actor.position=Vector2(920,550);await frames(2)
 check(actor.tactical.clamp_landing(Vector2(920,690)).y>600,'launcher arcs over low obstacle')
 check(not scene.clear_line(Vector2(920,550),Vector2(920,690)),'low obstacle blocks explosion')
 actor.position=Vector2(320,360);await frames(2)
 actor.tactical.landing=Vector2(500,360);actor.item().energy=40.0
 check(actor.tactical.fire() and actor.item().energy==25.0,'launcher consumes actual capacitor')
 await frames(40)
 check(actor.tactical.flight<=0,'launcher resolves flight')
 await frames(3)
 if DisplayServer.get_name()!='headless':
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png('res://scenes/game/dev102-interaction.png')
 print('FAILURES ',errors);quit(1 if errors else 0)

