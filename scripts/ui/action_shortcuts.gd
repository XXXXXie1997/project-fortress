extends HBoxContainer
var shell
func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_theme_constant_override("separation",10)
 for entry in [["背包","TAB"],["玩家","P"],["地图","M"],["任务","J"],["天赋","T"]]:
  var column:=VBoxContainer.new();column.mouse_filter=Control.MOUSE_FILTER_IGNORE
  column.custom_minimum_size.x=48;column.add_theme_constant_override("separation",3);add_child(column)
  var icon:=TextureRect.new();var atlas:=AtlasTexture.new()
  atlas.atlas=load("res://assets/runtime/ui/action_icons.png");atlas.region=Rect2((get_child_count()-1)*24,0,24,24)
  icon.texture=atlas;icon.custom_minimum_size=Vector2(48,48);icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
  icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(icon)
  var title:=Label.new();title.text=entry[0];title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",13);title.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(title)
  var key:=Label.new();key.text="["+entry[1]+"]";key.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;key.add_theme_color_override("font_color",Color("e8c070"));key.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_child(key)
func _process(_dt):
 visible=is_instance_valid(shell.arena) and not shell.interface_open() and not shell.mounting
 position=Vector2(get_viewport_rect().size.x-get_combined_minimum_size().x-24,get_viewport_rect().size.y-180)
