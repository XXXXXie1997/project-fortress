extends Node2D
const Actor = preload("res://scripts/art/survivor_visual.gd")
var hero: Node2D
var t := 0.0
func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 RenderingServer.set_default_clear_color(Color("14202b"))
 text("SURVIVOR / FOUR DIRECTIONS + LAYERED EQUIPMENT",Vector2(40,20),24)
 for i in 4:
  var actor := Actor.new()
  actor.position=Vector2(150+i*280,210)
  actor.scale=Vector2(4,4)
  actor.fixed_direction=i
  actor.aim=[Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT,Vector2.UP][i]
  actor.moving=true
  actor.charging=true
  actor.weapon_index=i%3
  actor.attachment_index=i%3
  add_child(actor)
  text(["DOWN","LEFT","RIGHT","UP / rear layer"][i],Vector2(80+i*280,230),18)
 for i in 12:
  var s := Sprite2D.new()
  s.texture=load("res://assets/runtime/weapons/equipment.png")
  s.hframes=4;s.vframes=3;s.frame=i;s.scale=Vector2(3,3)
  s.position=Vector2(140+(i%6)*200,335+(i/6)*100)
  add_child(s)
  text(["Rifle","Scatter","Sniper","Forearm","Knife","Energy blade","Unique blade","Battery","Light","Laser","Launcher","Forearm B"][i],s.position+Vector2(-65,25),16)
 hero=Actor.new();hero.position=Vector2(620,600);hero.scale=Vector2(3,3);add_child(hero)
 text("Mouse aim / WASD move / Q,E weapon / V attachment / R charge / Space dodge (visual test)",Vector2(40,665),17)
 if "--capture" in OS.get_cmdline_user_args():
  await get_tree().create_timer(0.4).timeout
  await RenderingServer.frame_post_draw
  print("ACTOR_CAPTURE ",get_viewport().get_texture().get_image().save_png("res://docs/art/integration/ART-102-render.png"))
  get_tree().quit()
func _process(delta: float) -> void:
 t+=delta
 hero.aim=(get_global_mouse_position()-hero.position).normalized()
 var move := Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
 hero.moving=move.length()>0
 hero.position+=move.normalized()*120*delta
 hero.dodging=Input.is_physical_key_pressed(KEY_SPACE)
func _unhandled_key_input(event: InputEvent) -> void:
 if not event.is_pressed() or event.is_echo(): return
 if event.physical_keycode==KEY_R: hero.charging=not hero.charging
 if event.physical_keycode==KEY_E: hero.weapon_index=(hero.weapon_index+1)%6
 if event.physical_keycode==KEY_Q: hero.weapon_index=(hero.weapon_index+5)%6
 if event.physical_keycode==KEY_V: hero.attachment_index=(hero.attachment_index+1)%3
func text(value: String,at: Vector2,size: int) -> void:
 var l:=Label.new();l.text=value;l.position=at;l.add_theme_font_size_override("font_size",size);add_child(l)
