class_name InputBindings
extends RefCounted

const KEYS := {"move_up": KEY_W, "move_down": KEY_S, "move_left": KEY_A, "move_right": KEY_D,
	"charge": KEY_R, "sprint": KEY_SHIFT, "tactical": KEY_V, "weapon_previous": KEY_Q,
	"weapon_next": KEY_E, "interact": KEY_F, "inventory": KEY_TAB, "map": KEY_M,
	"dodge": KEY_SPACE, "quests": KEY_J, "talents": KEY_T, "cancel": KEY_ESCAPE,
	"quick_1": KEY_1, "quick_2": KEY_2, "quick_3": KEY_3, "quick_4": KEY_4, "quick_5": KEY_5, "quick_6": KEY_6}

static func install() -> void:
	for action: String in KEYS:
		var event := InputEventKey.new()
		event.physical_keycode = KEYS[action]
		bind(action, event)
	for pair: Array in [["fire", MOUSE_BUTTON_LEFT], ["aim", MOUSE_BUTTON_RIGHT], ["weapon_previous", MOUSE_BUTTON_WHEEL_UP], ["weapon_next", MOUSE_BUTTON_WHEEL_DOWN]]:
		var event := InputEventMouseButton.new()
		event.button_index = pair[1]
		bind(pair[0], event)

static func bind(action: String, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
