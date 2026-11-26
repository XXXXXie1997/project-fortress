extends HBoxContainer
var shell
func _ready():
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 custom_minimum_size=Vector2(290,30)
 add_theme_constant_override("separation",preload("res://scripts/ui/keeper_theme.gd").GAP_SMALL)
 preload("res://scripts/ui/keeper_backdrop.gd").attach(self)
 for entry in [["Tab","bag","背包"],["P","player","玩家"],["M","map","地图"],["J","quest","任务"],["T","talent","天赋"]]:
  var group:=HBoxContainer.new()
  group.mouse_filter=Control.MOUSE_FILTER_IGNORE
  add_child(group)
  var key:=Label.new()
  key.text=entry[0]
  key.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  key.add_theme_stylebox_override("normal",preload("res://scripts/ui/keeper_theme.gd").box("inset",2))
  key.add_theme_font_size_override("font_size",preload("res://scripts/ui/keeper_theme.gd").FONT_CAPTION)
  group.add_child(key)
  var icon:=TextureRect.new()
  icon.texture=load("res://assets/runtime/ui/wasteland/icon_"+entry[1]+".png")
  icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.custom_minimum_size=Vector2(24,24)
  icon.mouse_filter=Control.MOUSE_FILTER_PASS
  icon.tooltip_text=entry[2]+" · "+entry[0]
  group.add_child(icon)
func _process(_dt):
 visible=is_instance_valid(shell.arena) and not shell.interface_open() and not shell.mounting
 var factor:=preload("res://scripts/ui/pixel_layout.gd").ui_scale(get_viewport_rect().size)
 scale=Vector2.ONE*factor
 size=get_combined_minimum_size()
 position=Vector2(get_viewport_rect().size.x-(get_combined_minimum_size().x+24)*factor,get_viewport_rect().size.y-54*factor)
