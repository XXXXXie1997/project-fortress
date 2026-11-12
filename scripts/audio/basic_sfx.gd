extends Node
## Presentation only: never emits gameplay/AI noise events.
const EVENTS = ["shot_rifle", "shot_smg", "shot_heavy", "weapon_switch", "charge_in", "charge_out", "footstep", "dodge", "hit_health", "hit_armor", "hit_enemy", "melee_swing", "melee_hit", "explosion", "ui_confirm"]
var voices: Array[AudioStreamPlayer] = []
var loop := AudioStreamPlayer.new()
var cache := {}
var listener := Vector2.ZERO
var level := 0.7
var paused := false
var charging := false
var last := {}
var gains := {}
var priorities := {}
var charge_starts := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	add_child(loop)
	for event in EVENTS:
		cache[event] = load("res://assets/runtime/sfx/%s.wav" % event)
	var sound: AudioStreamWAV = load("res://assets/runtime/sfx/charge_loop.wav").duplicate()
	sound.loop_mode = AudioStreamWAV.LOOP_FORWARD
	sound.loop_end = sound.data.size() / 2
	loop.stream = sound
	apply_levels()

func set_listener(position: Vector2) -> void:
	listener = position

func set_level(value: float) -> void:
	level = clampf(value, 0.0, 1.0)
	apply_levels()
	if level == 0.0:
		for voice in voices: voice.stop()
		loop.stop()
	elif charging and not loop.playing:
		loop.play()
		loop.stream_paused = paused

func apply_levels() -> void:
	for voice in voices:
		voice.volume_linear = level * float(gains.get(voice.get_instance_id(), 1.0))
	loop.volume_linear = level * 0.35

func set_paused(value: bool) -> void:
	paused = value
	for voice in voices: voice.stream_paused = value
	loop.stream_paused = value

func emit_event(event: String, world_pos := Vector2.ZERO, spatial := false, variant := 0, source_id := "player") -> bool:
	if paused or level <= 0.0 or not cache.has(event): return false
	var key: String = event + ":" + str(source_id)
	var now := Time.get_ticks_msec()
	var cooldown := 100 if event in ["ui_confirm", "footstep", "hit_enemy"] else 35
	if now - int(last.get(key, -10000)) < cooldown: return false
	var gain := maxf(0.0, 1.0 - listener.distance_to(world_pos) / 900.0) if spatial else 1.0
	if gain <= 0.0: return false
	var selected: AudioStreamPlayer = null
	# Reserve four slots for combat; low-priority feedback cannot steal voices.
	var limit := 4 if event in ["footstep", "ui_confirm", "weapon_switch"] else 8
	for i in range(limit):
		if not voices[i].playing:
			selected = voices[i]
			break
	if selected == null and limit == 8:
		for voice in voices:
			if int(priorities.get(voice.get_instance_id(), 0)) == 0:
				selected = voice
				selected.stop()
				break
	if selected == null: return false
	priorities[selected.get_instance_id()] = 0 if limit == 4 else 1
	last[key] = now
	gains[selected.get_instance_id()] = gain
	selected.stream = cache[event]
	selected.pitch_scale = 1.0 + float(posmod(variant, 3) - 1) * 0.025
	selected.volume_linear = level * gain
	selected.play()
	return true

func set_charge(active: bool, is_paused: bool, restoring := false) -> void:
	set_paused(is_paused)
	if active == charging: return
	charging = active
	if active:
		if level > 0.0:
			loop.play()
			loop.stream_paused = paused
		charge_starts += 1
		if not restoring: emit_event("charge_in")
	else:
		loop.stop()
		if not restoring: emit_event("charge_out")

func shutdown_audio() -> void:
	charging = false
	for voice in voices: voice.stop()
	loop.stop()
	last.clear()

func _exit_tree() -> void:
	shutdown_audio()


