class_name SaveService
extends RefCounted
const FORMAT := 1
const KINDS := ["latest","morning","failure"]
var root: String
var pending: Dictionary = {}
var transactions: Dictionary = {}
var failed_slots: Dictionary = {}
var elapsed := 0.0
var debounce_seconds := 1.0
var writes := 0
var requests := 0
var merged := 0
# Test injection affects a single write only; never changes existing final data.
var fail_next := ""
var worker: Thread
var sequence := 0
var last_timings: Dictionary = {}
var last_result: Dictionary = {"ok":true,"errors":[]}
func _init(directory: String = "user://saves") -> void:
 root = ProjectSettings.globalize_path(directory)
func valid_slot(slot: String) -> bool:
 if slot.is_empty() or slot.length() > 64: return false
 for c in slot:
  if not (c in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"): return false
 return true
func error(reason: String) -> Dictionary:
 return {"ok":false,"error":reason}
func safe_value(value: Variant) -> bool:
 match typeof(value):
  TYPE_NIL, TYPE_BOOL, TYPE_STRING, TYPE_STRING_NAME: return true
  TYPE_INT: return value >= -9007199254740991 and value <= 9007199254740991
  TYPE_FLOAT: return is_finite(value)
  TYPE_ARRAY:
   for v in value:
    if not safe_value(v): return false
   return true
  TYPE_DICTIONARY:
   for key in value:
    if not (key is String or key is StringName) or not safe_value(value[key]): return false
   return true
 return false
func begin_transaction(slot: String) -> bool:
 if not valid_slot(slot): return false
 transactions[slot] = int(transactions.get(slot,0))+1
 return true
func end_transaction(slot: String, committed_state: Dictionary) -> Dictionary:
 if int(transactions.get(slot,0)) <= 0: return error("no_transaction")
 transactions[slot] -= 1
 if transactions[slot] > 0: return {"ok":true,"deferred":true}
 return request(slot,committed_state)
func request(slot: String, state: Dictionary, kind: String = "latest") -> Dictionary:
 if not valid_slot(slot) or not kind in KINDS: return error("invalid_target")
 if int(transactions.get(slot,0)) > 0: return error("transaction_open")
 if kind == "latest" and (failed_slots.get(slot,false) or state.get("run_failed",false)): return error("failed_state_not_playable")
 var started := Time.get_ticks_usec()
 var captured := state.duplicate(true)
 var key := slot+"/"+kind
 requests += 1
 sequence += 1
 if pending.has(key): merged += 1
 pending[key] = {"slot":slot,"kind":kind,"state":captured,"version":sequence}
 last_timings.capture_us = Time.get_ticks_usec()-started
 return {"ok":true,"queued":true,"version":sequence,"validation_pending":true}
func capture_failure(slot: String, state: Dictionary) -> Dictionary:
 var result := request(slot,state,"failure")
 if result.ok:
  failed_slots[slot] = true
  # Preserve the previously accepted playable snapshot, even before first flush.
 return result
func resume_slot(slot: String) -> void:
 failed_slots.erase(slot)
func is_failure_locked(slot: String) -> bool:
 return bool(failed_slots.get(slot,false))
func set_failure_lock(slot: String, locked: bool) -> bool:
 if not valid_slot(slot): return false
 if locked: failed_slots[slot]=true
 else: failed_slots.erase(slot)
 return true
# Coordinator rollback only after join; never cancels a newer capture.
func cancel_pending_version(slot: String, kind: String, version: int) -> Dictionary:
 if not valid_slot(slot) or not kind in KINDS: return error("invalid_target")
 if worker != null: return error("worker_not_joined")
 var key:=slot+"/"+kind
 if not pending.has(key): return {"ok":true,"cancelled":false}
 if pending[key].version != version: return error("version_mismatch")
 pending.erase(key)
 return {"ok":true,"cancelled":true}
func tick(dt: float) -> Dictionary:
 if not is_finite(dt) or dt < 0: return error("invalid_delta")
 var polled := poll()
 if not polled.ok: return polled
 elapsed += dt
 if elapsed < debounce_seconds: return {"ok":true,"deferred":true}
 elapsed = 0
 return dispatch()
func dispatch() -> Dictionary:
 if worker != null: return {"ok":true,"busy":true}
 var batch: Array = []
 for key: String in pending:
  if int(transactions.get(pending[key].slot,0)) == 0:
   # This immutable capture has no mutable dictionaries shared with live state.
   batch.append({"key":key,"capture":pending[key]})
 if batch.is_empty(): return {"ok":true,"deferred":true}
 var injection := fail_next
 fail_next = ""
 worker = Thread.new()
 var code := worker.start(_write_batch.bind(batch,root,injection))
 if code != OK:
  worker = null
  last_result = {"ok":false,"errors":[{"error":"worker_start_failed"}],"pending":pending.size()}
  return last_result.duplicate(true)
 return {"ok":true,"started":true}
func _write_batch(batch: Array, directory: String, injection: String) -> Dictionary:
 var writer := SaveService.new(directory)
 writer.fail_next = injection
 var results: Array = []
 for job: Dictionary in batch:
  var snap: Dictionary = job.capture
  var started := Time.get_ticks_usec()
  var result: Dictionary
  if not writer.safe_value(snap.state) or not WorldState.valid(snap.state):
   result = error("invalid_snapshot")
  else:
   var payload := JSON.stringify(snap.state)
   var encoded := Time.get_ticks_usec()
   result = writer.write_payload(directory.path_join(snap.slot).path_join(snap.kind+".json"),payload,"world")
   result.encode_validate_us = encoded-started
   result.disk_us = Time.get_ticks_usec()-encoded
  results.append({"key":job.key,"version":snap.version,"result":result})
 return {"results":results,"writes":writer.writes}
func collect() -> Dictionary:
 var completed: Dictionary = worker.wait_to_finish()
 worker = null
 writes += completed.writes
 var errors: Array = []
 for job: Dictionary in completed.results:
  if job.result.ok:
   if pending.has(job.key) and pending[job.key].version == job.version: pending.erase(job.key)
  else: errors.append({"target":job.key,"version":job.version,"error":job.result.error})
  last_timings.merge(job.result,true)
 last_result = {"ok":errors.is_empty(),"errors":errors,"pending":pending.size()}
 return last_result
func poll() -> Dictionary:
 if worker != null and not worker.is_alive(): return collect()
 if not last_result.ok:
  var failure := last_result.duplicate(true)
  failure.busy = worker != null
  failure.retrying = worker != null
  failure.pending = pending.size()
  return failure
 return {"ok":true,"busy":worker != null,"pending":pending.size()}
# Blocking only at explicit save/exit. Joins every launched worker before release.
func flush() -> Dictionary:
 if worker != null:
  var joined := collect()
  if not joined.ok: return joined
 while not pending.is_empty():
  var kicked := dispatch()
  if not kicked.ok: return kicked
  if worker == null: return error("transaction_open")
  var completed := collect()
  if not completed.ok: return completed
 last_result = {"ok":true,"errors":[],"pending":0}
 return last_result.duplicate(true)
func shutdown() -> Dictionary:
 return flush()
func packet(payload: String, type: String) -> String:
 return JSON.stringify({"format":FORMAT,"type":type,"sha256":payload.sha256_text(),"payload":payload})
func read_packet(path: String, type: String) -> Dictionary:
 if not FileAccess.file_exists(path): return error("missing")
 var file := FileAccess.open(path,FileAccess.READ)
 if file == null: return error("read_failed")
 var raw := file.get_as_text()
 file.close()
 var envelope: Variant = JSON.parse_string(raw)
 if not envelope is Dictionary or envelope.get("format") != FORMAT or envelope.get("type") != type: return error("format_or_type")
 if not envelope.get("payload") is String or envelope.get("sha256") != envelope.payload.sha256_text(): return error("checksum")
 var state: Variant = JSON.parse_string(envelope.payload)
 if not state is Dictionary or not safe_value(state): return error("payload")
 if type == "world" and not WorldState.valid(state): return error("world_schema")
 return {"ok":true,"state":state}
func write_payload(path: String, payload: String, type: String) -> Dictionary:
 var failure := fail_next
 fail_next = ""
 if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK: return error("mkdir_failed")
 if failure == "write": return error("injected_write_failure")
 var temporary := path+".tmp"
 var backup := path+".bak"
 var file := FileAccess.open(temporary,FileAccess.WRITE)
 if file == null: return error("open_temporary_failed")
 file.store_string(packet(payload,type))
 file.flush()
 var status := file.get_error()
 file.close()
 if status != OK or not read_packet(temporary,type).ok: return error("temporary_validation_failed")
 if failure == "before_replace": return error("injected_replace_failure")
 if FileAccess.file_exists(path):
  if not read_packet(path,type).ok: return error("existing_corrupt_preserved")
  if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup) != OK: return error("backup_remove_failed")
  if DirAccess.rename_absolute(path,backup) != OK: return error("backup_rename_failed")
 if failure == "after_backup": return error("injected_interruption")
 if DirAccess.rename_absolute(temporary,path) != OK: return error("replace_failed")
 writes += 1
 return {"ok":true}
func load_snapshot(slot: String, kind: String = "latest") -> Dictionary:
 if not valid_slot(slot) or not kind in KINDS: return error("invalid_target")
 var path := root.path_join(slot).path_join(kind+".json")
 var current := read_packet(path,"world")
 if current.ok: return current
 var recovery := read_packet(path+".bak","world")
 if recovery.ok:
  recovery.recovered = true
  recovery.warning = current.error
  return recovery
 return error("load_failed:"+current.error)
func save_tutorial(completed: Array) -> Dictionary:
 for id in completed:
  if not id is String: return error("invalid_tutorial")
 return write_payload(root.path_join("tutorial.json"),JSON.stringify({"completed":completed}),"tutorial")
func load_tutorial() -> Dictionary:
 var path := root.path_join("tutorial.json")
 var result := read_packet(path,"tutorial")
 if result.ok: return result
 var backup := read_packet(path+".bak","tutorial")
 if backup.ok:
  backup.recovered = true
  return backup
 return result
func reset_tutorial() -> Dictionary:
 return save_tutorial([])


