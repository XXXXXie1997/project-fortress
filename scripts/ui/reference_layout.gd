extends RefCounted
const ThemeStyle=preload("res://scripts/ui/wasteland_theme.gd")

static func column(parent:Node, width:float)->VBoxContainer:
 var frame:=PanelContainer.new();frame.custom_minimum_size=Vector2(width,400)
 frame.add_theme_stylebox_override("panel",ThemeStyle.box("panel_inset"));parent.add_child(frame)
 var scroll:=ScrollContainer.new();scroll.custom_minimum_size.x=width-16;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;frame.add_child(scroll)
 var rows:=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_theme_constant_override("separation",16);scroll.add_child(rows)
 return rows

static func header(rows:VBoxContainer,heading:Control,close:Control=null,subtitle:String=""):
 var line:=HBoxContainer.new();rows.add_child(line);rows.move_child(line,0)
 heading.reparent(line);heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 if close!=null:close.reparent(line)
 var note:=Label.new();note.text=subtitle;note.add_theme_color_override("font_color",Color("a6aaa0"));rows.add_child(note);rows.move_child(note,1)

static func move(node:Control,to:Node):
 node.reparent(to);node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 node.size=Vector2.ZERO
 if node is Label:
  node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 if node is Button:
  node.custom_minimum_size.y=44;node.custom_minimum_size.x=maxf(120,to.get_parent().custom_minimum_size.x-16);node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

static func management(rows:VBoxContainer,title:String):
 if not is_instance_valid(rows) or rows.get_child_count()<2:return
 if not rows.get_child(0) is Label:return
 if rows.has_meta("arranged") and rows.get_meta("arranged")==rows.get_child(0).get_instance_id():return
 rows.set_meta("arranged",rows.get_child(0).get_instance_id())
 var children:=rows.get_children()
 var heading:Label=children[0];heading.add_theme_font_size_override("font_size",32);heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var close:Button=children[1];close.text="关闭面板 · 继续游戏";close.autowrap_mode=TextServer.AUTOWRAP_OFF;close.size_flags_horizontal=Control.SIZE_SHRINK_END;close.size_flags_vertical=Control.SIZE_SHRINK_BEGIN;close.custom_minimum_size=Vector2(224,36);close.size=Vector2.ZERO
 header(rows,heading,close,"基地 / 准备阶段 / 关闭后继续操作")
 if rows.get_meta("reference_custom",false):return
 if title.begins_with("贸易"):
  return
 var strip:=HBoxContainer.new();strip.add_theme_constant_override("separation",24);rows.add_child(strip)
 var left:=column(strip,320);var right:=column(strip,760)
 for i in range(2,children.size()):
  var node:Control=children[i]
  move(node,right if node is Label else left)
 if right.get_child_count()==0:
  var hint:=Label.new();hint.text="选择左侧操作\n\n整备物资，准备下一次行动。\n确认前请留意成本、当前状态与容量。";right.add_child(hint)

static func session(rows:VBoxContainer,mode:String):
 if not is_instance_valid(rows) or rows.get_child_count()<2 or mode=="start":return
 if not rows.get_child(0) is Label:return
 var children:=rows.get_children()
 children[0].add_theme_font_size_override("font_size",32)
 if rows.has_meta("arranged") and rows.get_meta("arranged")==children[0].get_instance_id():return
 rows.set_meta("arranged",children[0].get_instance_id())
 header(rows,children[0],null,"世界已暂停" if mode in ["pause","settings","tutorial","failure"] else "选择操作 / Esc返回")
 if mode=="failure":
  var cards:=GridContainer.new();cards.columns=2;cards.add_theme_constant_override("h_separation",24);cards.add_theme_constant_override("v_separation",24);rows.add_child(cards)
  for n in children:
   if n is Button:
    move(n,cards);n.custom_minimum_size=Vector2(536,154);n.add_theme_font_size_override("font_size",26)
  return
 var body:=HBoxContainer.new();body.add_theme_constant_override("separation",32);rows.add_child(body)
 var left:=column(body,360);var right:=column(body,720)
 for i in range(1,children.size()):
  var n:Control=children[i]
  move(n,left if n is Button else right)
 if right.get_child_count()==0:
  var label:=Label.new();label.text="世界已暂停" if mode=="pause" else "选择操作";label.add_theme_font_size_override("font_size",24);right.add_child(label)

static func tutorial_diagram(page:int)->HBoxContainer:
 var panels=[[["player","W A S D","移动 / 鼠标瞄准"],["energy","R 充电","电池 → 武器"],["health","Shift / 空格","冲刺 / 闪避"]],[["bag","Tab 背包","拖拽 / 双击转移"],["player","装备","拖入 / 拖出装备槽"],["unknown","搜刮","逐项揭示物品"]],[["map","F / M","互动 / 地图"],["quest","J / T","任务 / 天赋"],["seed","B 基地","生产 / 农业"]],[["check","Esc 保存","暂停 / 保存进度"],["bag","普通死亡","背包掉落 / 装备保留"],["warning","基地失守","读取 / 重开 / 继承"]]]
 var diagram:=HBoxContainer.new();diagram.custom_minimum_size=Vector2(680,180);diagram.add_theme_constant_override("separation",16)
 for entry in panels[page]:
  var frame:=PanelContainer.new();frame.custom_minimum_size=Vector2(212,180);frame.add_theme_stylebox_override("panel",ThemeStyle.box("panel_inset"));diagram.add_child(frame)
  var items:=VBoxContainer.new();frame.add_child(items)
  var icon:=TextureRect.new();icon.texture=load("res://assets/runtime/ui/wasteland/icon_"+entry[0]+".png");icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(64,64);items.add_child(icon)
  for line in [entry[1],entry[2]]:
   var label:=Label.new();label.text=line;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_color_override("font_color",Color("c5a065") if line==entry[1] else Color("ddd9cc"));items.add_child(label)
 return diagram
