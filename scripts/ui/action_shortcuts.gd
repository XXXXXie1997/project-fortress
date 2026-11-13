extends HBoxContainer
var shell
func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 custom_minimum_size=Vector2(290,30)
 add_theme_constant_override("separation",10)
 preload("res://scripts/ui/hud_backdrop.gd").attach(self)
 for entry in ["TAB背包","P玩家","M地图","J任务","T天赋"]:
  var title:=Label.new();title.text=entry;title.add_theme_font_size_override("font_size",13);title.add_theme_color_override("font_color",Color("a6aaa0"));title.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(title)
func _process(_dt):
 visible=is_instance_valid(shell.arena) and not shell.interface_open() and not shell.mounting
 position=Vector2(get_viewport_rect().size.x-get_combined_minimum_size().x-24,get_viewport_rect().size.y-54)
