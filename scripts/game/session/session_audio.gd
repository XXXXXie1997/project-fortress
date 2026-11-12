extends Node
var music := AudioStreamPlayer.new()
var ambience := AudioStreamPlayer.new()
var sfx = preload("res://scripts/audio/basic_sfx.gd").new()
var charge_loop: AudioStreamPlayer:
	get: return sfx.loop
var charging: bool:
	get: return sfx.charging
var background_enabled := false # User amendment: BGM/ambient background work is deferred.
var charge_starts: int:
	get: return sfx.charge_starts
var context := ""
var suspended := false
var sources := {"base": "res://assets/runtime/audio/base.ogg", "field": "res://assets/runtime/audio/field.mp3", "battle": "res://assets/runtime/audio/battle.ogg", "click": "res://assets/runtime/audio/ui.ogg", "shot":"res://assets/runtime/audio/shot.ogg"}
var levels := {"music": 0.5, "ambience": 0.5, "effects": 0.7}
var transition: Tween
var cache := {}
func _ready():
	for player in [music, ambience]: add_child(player)
	add_child(sfx)
	apply_levels()
func apply_levels():
	music.volume_db = linear_to_db(maxf(0.0001,float(levels.music))) + (-7.4 if context == "battle" else 0.0)
	ambience.volume_db = linear_to_db(maxf(0.0001,float(levels.ambience)))
	sfx.set_level(float(levels.effects))
func stream(path: String) -> AudioStream:
	if path.is_empty(): return null
	if not cache.has(path):
		var imported: AudioStream = load(path)
		cache[path] = imported.duplicate(true) if imported != null else null
	return cache[path]
func play_context(next: String):
	if not background_enabled:
		context = next
		music.stop(); ambience.stop()
		return
	if next == context: return
	context = next
	if transition != null: transition.kill()
	transition = create_tween()
	transition.set_parallel(true)
	transition.tween_property(music,"volume_db",-60.0,0.3)
	transition.tween_property(ambience,"volume_db",-60.0,0.3)
	transition.chain().tween_callback(func():
		music.stop(); ambience.stop()
		var player: AudioStreamPlayer = ambience if next == "field" else music
		player.stream = stream(sources.get(next,""))
		if player.stream != null:
			if player.stream is AudioStreamOggVorbis or player.stream is AudioStreamMP3: player.stream.loop = true
			player.play()
		var target := linear_to_db(maxf(0.0001,float(levels.ambience if next == "field" else levels.music))) + (-7.4 if next == "battle" else 0.0)
		create_tween().tween_property(player,"volume_db",target,0.7))
func click():
	if not suspended:sfx.emit_event("ui_confirm")
func receive_event(event: String, point: Vector2, spatial: bool, source_id: String):
	if not suspended:sfx.emit_event(event, point, spatial, 0, source_id)
func set_charge(active: bool, paused: bool, restoring := false) -> void:
	if not suspended:sfx.set_charge(active, paused, restoring)

func resume_audio() -> void:
	suspended = false

func shutdown_audio() -> void:
	suspended = true
	if transition != null: transition.kill()
	sfx.set_paused(false)
	sfx.shutdown_audio()
	for player in [music, ambience]:
		player.stream_paused = false
		player.stop()
		player.stream = null
	cache.clear()

func _exit_tree() -> void:
	shutdown_audio()
