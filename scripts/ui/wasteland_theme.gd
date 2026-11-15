extends RefCounted
# Compatibility API: all screens share the approved pixel component theme.
const PixelTheme=preload("res://scripts/ui/keeper_theme.gd")
const FONT_TITLE=24
const FONT_SECTION=24
const FONT_BODY=24
const FONT_CAPTION=24
const FONT_NUMBER=24
const TEXT=PixelTheme.TEXT
const MUTED=PixelTheme.MUTED
const DISABLED=PixelTheme.DISABLED
const ACCENT=PixelTheme.ACCENT
const HOVER=PixelTheme.TEXT
const WARNING=PixelTheme.WARNING
const DANGER=PixelTheme.DANGER
const SUCCESS=Color("9bb58f")
const GAP_SMALL=8
const GAP=16
const GAP_SECTION=24
const PANEL_PADDING=16
const BUTTON_HEIGHT=PixelTheme.BUTTON_HEIGHT
const COMPACT_HEIGHT=PixelTheme.COMPACT_HEIGHT
static func box(asset:String,margin:int=8)->StyleBoxTexture:
 if asset.begins_with("button_"):
  var names={"button_default":"button","button_hover":"hover","button_pressed":"pressed","button_focus":"focus","button_selected":"selected","button_disabled":"disabled"}
  return PixelTheme.button_box(names.get(asset,"button"))
 return PixelTheme.box(asset,margin)
static func get_theme()->Theme:
 return PixelTheme.get_theme()
static func apply(control:Control):
 PixelTheme.apply(control)
