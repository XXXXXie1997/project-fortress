extends SceneTree
var events:Array=[]
var audio_ok:=0
var audio_player:Node
func _initialize():call_deferred('run')
func event(name:String,p:Vector2,spatial:bool,id:String):
 events.append(name)
 if audio_player.emit_event(name,p,spatial,0,id):audio_ok+=1
func run():
 root.size=Vector2i(1280,720)
 var a=load('res://scenes/base/base_defense.tscn').instantiate();root.add_child(a)
 for i in 6:await physics_frame
 a.set_physics_process(false);a.player.set_physics_process(false)
 for r in a.residents:r.set_physics_process(false)
 for f in a.fixtures:f.set_physics_process(false)
 a.start_fixture_wave(1)
 var d:Dictionary=a.queue.pop_front();a.state.expedition.maps.base.enemies[d.id]=d.duplicate(true);a.spawn_enemy(d)
 var e=a.targets.back();e.set_physics_process(false);e.position=a.player.position+Vector2(90,0)
 audio_player=load('res://scripts/audio/basic_sfx.gd').new();root.add_child(audio_player);audio_player.set_listener(a.player.position)
 a.presentation_sound.connect(event)
 a.hit(e,1)
 assert(events==['hit_enemy'] and a.blood_visual.bursts.size()==1)
 assert(audio_ok==1)
 a.blood_visual.clear_effects();events.clear()
 e.record().action.dodge_left=1;a.hit(e,20)
 assert(events.is_empty() and a.blood_visual.bursts.is_empty());e.record().action.dodge_left=0
 # Controlled zero residual lower bound exercises a pure armor loss result without changing production config.
 var old:float=a.config.minimum_damage_fraction;a.config.minimum_damage_fraction=0
 e.record().armor={'durability':100.0,'rating':100.0}
 a.hit(e,1,{'penetration':0,'sfx_melee':true})
 assert(events==['melee_hit'] and a.blood_visual.bursts.is_empty());a.config.minimum_damage_fraction=old
 events.clear();a.hit(e,10000,{'penetration':10000})
 assert(events==['hit_enemy'] and a.blood_visual.stains.size()==1)
 var count:int=events.size();a.hit(e,10000);assert(events.size()==count)
 var resident=a.residents[0];resident.receive_damage(3)
 assert(a.blood_visual.bursts.size()==2)
 var bursts:int=a.blood_visual.bursts.size();resident.receive_damage(3);assert(a.blood_visual.bursts.size()==bursts)
 a.state.player.combat.hurt_iframe=0
 var result:Dictionary=a.player.receive_attack({'damage':3,'penetration':100})
 print('player result ',result,' bursts ',bursts,' -> ',a.blood_visual.bursts.size())
 assert(result.hp_loss>0 and a.blood_visual.bursts.size()==bursts+1)
 var before:String=WorldState.encode(a.state)
 for i in 100:a.blood_visual.restore_dead('stress'+str(i),Vector2(-3000,-3000),'basic')
 assert(a.blood_visual.corpses.size()==64 and a.blood_visual.stains.size()==64)
 assert(WorldState.encode(a.state)==before)
 if DisplayServer.get_name()!='headless':
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png('res://docs/art/integration/ART-107-base-hit.png')
 # Restore same manual-night saved runtime via existing start_wave; no alive replacement path.
 for target in a.targets:target.queue_free()
 a.targets.clear();await process_frame
 a.state.base.defense_runtime.queue=a.queue.duplicate(true);a.running=false;a.start_wave()
 assert(a.targets.is_empty() and a.blood_visual.corpses.size()==1 and a.blood_visual.stains.size()==1)
 # Finish true wave through existing coordinator; lifecycle clear must run.
 a._physics_process(0.0)
 assert(not a.running and a.blood_visual.stains.is_empty() and a.blood_visual.corpses.is_empty())
 audio_player.shutdown_audio();audio_player.queue_free();a.queue_free();await process_frame;await process_frame
 print('PASS base damage / single sound / armor-only / blocked / repeat death / resident / player / 100 bound / state equality / wave cleanup; audio backend accepted=',audio_ok)
 quit()




