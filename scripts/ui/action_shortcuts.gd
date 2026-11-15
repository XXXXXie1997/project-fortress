extends VBoxContainer
var shell
func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 custom_minimum_size=Vector2(150,30)
 add_theme_constant_override("separation",preload("res://scripts/ui/keeper_theme.gd").GAP_SMALL)
 preload("res://scripts/ui/keeper_backdrop.gd").attach(self)
 for entry in ["TAB  背包","M  地图","J  任务"]:
  var title:=Label.new();title.text=entry;title.add_theme_font_size_override("font_size",preload("res://scripts/ui/keeper_theme.gd").FONT_CAPTION);title.add_theme_color_override("font_color",preload("res://scripts/ui/keeper_theme.gd").MUTED);title.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(title)
func _process(_dt):
 visible=is_instance_valid(shell.arena) and not shell.interface_open() and not shell.mounting
 var factor:=preload("res://scripts/ui/pixel_layout.gd").ui_scale(get_viewport_rect().size)
 scale=Vector2.ONE*factor
 position=Vector2(get_viewport_rect().size.x-(get_combined_minimum_size().x+24)*factor,32*factor)
