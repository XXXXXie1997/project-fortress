extends Node2D
const Enemy=preload('res://scripts/art/enemy_visual.gd')
var actors:Array=[]
var elapsed:=0.0
var status:=Label.new()
var manual:=-1
func _ready():
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 RenderingServer.set_default_clear_color(Color('1c292e'))
 var kinds=['basic','fast','armored','ranged','boss']
 var directions=[Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT,Vector2.UP]
 for row in 4:
  var label:=Label.new();label.text=['DOWN','LEFT','RIGHT','UP'][row];label.position=Vector2(25,100+row*150);add_child(label)
  for col in 5:
   var actor=Enemy.new();actor.kind=kinds[col];actor.facing=directions[row];actor.position=Vector2(260+200*col,165+150*row);add_child(actor);actors.append(actor)
   if row==0:
    var title:=Label.new();title.text=kinds[col];title.position=Vector2(225+200*col,20);add_child(title)
 status.position=Vector2(25,680);add_child(status)
func _process(dt):
 elapsed+=dt
 var phase:int=int(elapsed/1.2)%5 if manual<0 else manual
 var action:String=['idle','walk','windup','strike','dead'][phase]
 for actor in actors:actor.action=action
 status.text='STATE '+action+' | 1-5 hold state, 0 resume cycle | all four directions, shared foot baseline'
func _unhandled_key_input(event):
 if event.is_pressed() and not event.is_echo():
  if event.physical_keycode==KEY_0:manual=-1
  elif event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_5:manual=event.physical_keycode-KEY_1
