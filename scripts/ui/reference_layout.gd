extends RefCounted
const ThemeStyle=preload("res://scripts/ui/wasteland_theme.gd")

static func column(parent:Node, width:float)->VBoxContainer:
 var frame:=PanelContainer.new();frame.custom_minimum_size=Vector2(width,400)
 frame.add_theme_stylebox_override("panel",ThemeStyle.box("panel_inset"));parent.add_child(frame)
 var scroll:=ScrollContainer.new();scroll.custom_minimum_size.x=width-20;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;frame.add_child(scroll)
 var rows:=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_theme_constant_override("separation",preload("res://scripts/ui/wasteland_theme.gd").GAP);scroll.add_child(rows)
 return rows

static func header(rows:VBoxContainer,heading:Control,close:Control=null,subtitle:String="",badge:Texture2D=null):
 var line:=HBoxContainer.new();rows.add_child(line);rows.move_child(line,0)
 if badge!=null:
  var stamp:=TextureRect.new()
  stamp.texture=badge
  stamp.custom_minimum_size=Vector2(30,30)
  stamp.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  stamp.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  stamp.mouse_filter=Control.MOUSE_FILTER_IGNORE
  line.add_child(stamp)
 heading.reparent(line);heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 if close!=null:close.reparent(line)
 var note:=Label.new();note.text=subtitle;note.add_theme_color_override("font_color",preload("res://scripts/ui/wasteland_theme.gd").MUTED);rows.add_child(note);rows.move_child(note,1)

static func move(node:Control,to:Node):
 node.reparent(to);node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 node.size=Vector2.ZERO
 if node is Label:
  node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 if node is Button:
  node.custom_minimum_size.y=preload("res://scripts/ui/wasteland_theme.gd").BUTTON_HEIGHT;node.custom_minimum_size.x=0;node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

static func management(rows:VBoxContainer,title:String):
 if not is_instance_valid(rows) or rows.get_child_count()<2:return
 if not rows.get_child(0) is Label:return
 if rows.has_meta("arranged") and rows.get_meta("arranged")==rows.get_child(0).get_instance_id():return
 rows.set_meta("arranged",rows.get_child(0).get_instance_id())
 var children:=rows.get_children()
 var heading:Label=children[0];heading.add_theme_font_size_override("font_size",preload("res://scripts/ui/wasteland_theme.gd").FONT_TITLE);heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var close:Button=children[1]
 preload("res://scripts/ui/keeper_theme.gd").icon_button(close,"close","关闭 · Esc")
 close.size_flags_horizontal=Control.SIZE_SHRINK_END
 close.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
 header(rows,heading,close,"基地整备",preload("res://scripts/ui/keeper_theme.gd").symbol("station"))
 if rows.get_meta("reference_custom",false):return
 if title.begins_with("贸易"):
  return
 var strip:=HBoxContainer.new();strip.add_theme_constant_override("separation",preload("res://scripts/ui/wasteland_theme.gd").GAP_SECTION);rows.add_child(strip)
 var left:=column(strip,320);var right:=column(strip,760)
 for i in range(2,children.size()):
  var node:Control=children[i]
  move(node,left if node is Button else right)

static func session(rows:VBoxContainer,mode:String):
 if not is_instance_valid(rows) or rows.get_child_count()<2 or mode=="start":return
 if not rows.get_child(0) is Label:return
 var children:=rows.get_children()
 children[0].add_theme_font_size_override("font_size",preload("res://scripts/ui/wasteland_theme.gd").FONT_TITLE)
 if rows.has_meta("arranged") and rows.get_meta("arranged")==children[0].get_instance_id():return
 rows.set_meta("arranged",children[0].get_instance_id())
 var glyph:String={"pause":"defense","settings":"repair","failure":"defense","tutorial":"signal","player":"heart"}.get(mode,"signal")
 header(rows,children[0],null,"世界已暂停" if mode in ["pause","settings","tutorial","failure"] else "Esc 返回",preload("res://scripts/ui/keeper_theme.gd").symbol(glyph))
 if mode=="failure":
  var cards:=GridContainer.new();cards.columns=2;cards.add_theme_constant_override("h_separation",preload("res://scripts/ui/wasteland_theme.gd").GAP_SECTION);cards.add_theme_constant_override("v_separation",preload("res://scripts/ui/wasteland_theme.gd").GAP_SECTION);rows.add_child(cards)
  for n in children:
   if n is Button:
    move(n,cards);n.custom_minimum_size=Vector2(536,154);n.add_theme_font_size_override("font_size",preload("res://scripts/ui/wasteland_theme.gd").FONT_SECTION)
  return
 var body:=HBoxContainer.new();body.add_theme_constant_override("separation",preload("res://scripts/ui/wasteland_theme.gd").GAP_SECTION);rows.add_child(body)
 var left:=column(body,360);var right:=column(body,720)
 for i in range(1,children.size()):
  var n:Control=children[i]
  move(n,left if n is Button else right)


static func tutorial_diagram(page:int)->HBoxContainer:
 var panels=[[["player","W A S D","移动 / 鼠标瞄准"],["energy","R 充电","电池 → 武器"],["health","Shift / 空格","冲刺 / 闪避"]],[["bag","Tab 背包","拖拽 / 双击转移"],["player","装备","拖入 / 拖出装备槽"],["unknown","搜刮","逐项揭示物品"]],[["map","F / M","互动 / 地图"],["quest","J / T","任务 / 天赋"],["seed","B 基地","生产 / 农业"]],[["check","Esc 保存","暂停 / 保存进度"],["bag","普通死亡","背包掉落 / 装备保留"],["warning","基地失守","读取 / 重开 / 继承"]]]
 var diagram:=HBoxContainer.new();diagram.custom_minimum_size=Vector2(680,180);diagram.add_theme_constant_override("separation",preload("res://scripts/ui/wasteland_theme.gd").GAP)
 for entry in panels[page]:
  var frame:=PanelContainer.new();frame.custom_minimum_size=Vector2(212,180);frame.add_theme_stylebox_override("panel",ThemeStyle.box("panel_inset"));diagram.add_child(frame)
  var items:=VBoxContainer.new();frame.add_child(items)
  var icon:=TextureRect.new();icon.texture=preload("res://scripts/ui/keeper_theme.gd").symbol("battery") if entry[0]=="energy" else load("res://assets/runtime/ui/wasteland/icon_"+entry[0]+".png");icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(64,64);items.add_child(icon)
  for line in [entry[1],entry[2]]:
   var label:=Label.new();label.text=line;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_color_override("font_color",preload("res://scripts/ui/wasteland_theme.gd").ACCENT if line==entry[1] else preload("res://scripts/ui/wasteland_theme.gd").TEXT);items.add_child(label)
 return diagram
