## TimelineDirector — runtime playback node for the timeline plugin.
## Unity analog: PlayableDirector. Drives a TimelineAsset: advances the playhead,
## computes per-clip blend weights, tracks clip enter/exit, and dispatches each
## frame to per-track mixers (or the non-mixer clip path).
@tool
class_name TimelineDirector
extends Node

## The asset to play back. Assignable in the inspector or swapped at runtime.
@export var timeline: TimelineAsset = null
## If true, playback starts automatically in _ready().
@export var autoplay: bool = false
## If true, playback wraps back to 0.0 when reaching the end of the timeline.
@export var loop: bool = false
enum WrapMode { NONE, HOLD, LOOP, PINGPONG }
enum UpdateMode { PROCESS, MANUAL }
@export var wrap_mode: WrapMode = WrapMode.NONE
@export var update_mode: UpdateMode = UpdateMode.PROCESS
@export var play_range_enabled: bool = false
@export var play_range_start: float = 0.0
@export var play_range_end: float = 0.0

## Whether playback is currently advancing (true after play(), false after pause()/stop()).
var playing: bool = false
## Current playhead position in seconds. This director keeps its OWN per-director
## clock; tracks may also read LevelManager.anim_time (the game's canonical
## timeline clock, static float on the RefCounted LevelManager) for game-sync.
var time: float = 0.0
## Playback rate multiplier applied to the frame delta in _process().
var speed: float = 1.0
var _last_time: float = 0.0
var _marker_fired: Dictionary = {}
var _pingpong_forward: bool = true
## Lazily created mixers keyed by TimelineTrack (Unity: CreateTrackMixer).
var _mixers: Dictionary = {}
## Enter/exit tracking keyed by TimelineTrack -> Dictionary[TimelineClip, bool].
var _active_clips: Dictionary = {}


func _ready() -> void:
	if autoplay and timeline != null:
		play()


func _process(delta: float) -> void:
	if update_mode == UpdateMode.MANUAL or not playing or timeline == null:
		return
	_advance(delta * speed)
	_evaluate(delta)


func evaluate(delta: float = 0.0) -> void:
	## Manual-update equivalent of PlayableDirector.Evaluate.
	if timeline == null:
		return
	_advance(delta)
	_evaluate(delta)


func _advance(delta: float) -> void:
	var range_start: float = get_play_range_start()
	var range_end: float = get_play_range_end()
	if range_end <= range_start:
		time = range_start
		return
	_last_time = time
	time += delta
	var mode: WrapMode = wrap_mode
	if loop and mode == WrapMode.NONE:
		mode = WrapMode.LOOP
	if time < range_start:
		time = range_start
	if time <= range_end:
		return
	match mode:
		WrapMode.LOOP:
			time = range_start + fposmod(time - range_start, range_end - range_start)
		WrapMode.PINGPONG:
			var distance: float = time - range_start
			var span: float = range_end - range_start
			var cycle: float = fposmod(distance, span * 2.0)
			time = range_start + (cycle if cycle <= span else span * 2.0 - cycle)
			_pingpong_forward = cycle <= span
		WrapMode.HOLD:
			time = range_end
			_evaluate(0.0)
			playing = false
		WrapMode.NONE:
			time = range_end
			_evaluate(0.0)
			_restore_and_stop()


## Starts playback. If from_time >= 0.0, the playhead jumps there first.
func play(from_time: float = -1.0) -> void:
	if timeline == null:
		return
	if from_time >= 0.0:
		time = from_time
	_last_time = time
	_marker_fired.clear()
	playing = true


## Pauses playback without resetting the playhead.
func pause() -> void:
	playing = false


## Stops playback and restores target defaults (Unity OnPlayableDestroy semantics):
## calls on_playable_destroy() on every active mixer so animated targets revert
## to the values cached on first frame, then clears all runtime state.
func stop() -> void:
	_restore_and_stop()


## Jumps to target_time (clamped to [0, duration]) and immediately evaluates
## the frame. This keeps editor scrubbing and paused frame stepping live.
func seek(target_time: float) -> void:
	time = clampf(target_time, get_play_range_start(), get_play_range_end())
	if timeline != null:
		_last_time = time
		_evaluate(0.0)


func get_duration() -> float:
	return timeline.get_duration() if timeline != null else 0.0


func get_play_range_start() -> float:
	if play_range_enabled:
		return play_range_start
	if timeline != null and timeline.play_range_enabled:
		return timeline.play_range_start
	return 0.0


func get_play_range_end() -> float:
	if play_range_enabled and play_range_end > get_play_range_start():
		return play_range_end
	if timeline != null:
		return timeline.get_play_range_end()
	return get_duration()


## Resolves a track's bound_path relative to this director (empty path -> null).
func get_bound(track: TimelineTrack) -> Object:
	if track == null or track.bound_path.is_empty():
		return null
	return get_node_or_null(track.bound_path)


## Blend weight of a clip at time_value: 1.0 inside the clip, linearly ramped by
## blend_in at the start and blend_out at the end, and 0.0 for disabled clips or
## times outside the clip range.
func _clip_weight(clip: TimelineClip, time_value: float) -> float:
	if clip == null or not clip.enabled:
		return 0.0
	if not clip.supports_extrapolation(time_value):
		return 0.0
	if not clip.contains_time(time_value):
		return 1.0
	var weight: float = 1.0
	var ease_in: float = maxf(clip.blend_in, clip.ease_in_duration)
	var ease_out: float = maxf(clip.blend_out, clip.ease_out_duration)
	if ease_in > 0.0:
		weight = minf(weight, clampf((time_value - clip.start) / ease_in, 0.0, 1.0))
	if ease_out > 0.0:
		weight = minf(weight, clampf((clip.get_end() - time_value) / ease_out, 0.0, 1.0))
	if clip.blend_curve != null:
		weight = clip.blend_curve.sample_baked(clampf(weight, 0.0, 1.0))
	return weight


## Evaluates every enabled, non-muted track at the current playhead.
## delta is the frame delta forwarded to mixers and process_clip.
func _evaluate(delta: float) -> void:
	for track: TimelineTrack in timeline.get_all_tracks():
		if track.is_group:
			continue
		if not track.enabled or track.muted:
			continue
		var bound: Object = get_bound(track)
		var inputs: Array = []
		for clip: TimelineClip in track.clips:
			var weight: float = _clip_weight(clip, time)
			if weight > 0.0:
				var clip_time: float = clip.get_extrapolated_time(time)
				inputs.append({"clip": clip, "behaviour": clip.template, "weight": weight, "clip_time": clip_time, "mix_mode": clip.mix_mode})
		var track_active: Dictionary = _active_clips.get_or_add(track, {})
		for clip: TimelineClip in track.clips:
			var is_active: bool = clip.enabled and clip.contains_time(time)
			var was_active: bool = track_active.get(clip, false)
			if is_active and not was_active:
				track.on_clip_entered(clip, bound)
				if clip.template != null:
					clip.template.on_clip_start(bound)
			elif was_active and not is_active:
				track.on_clip_exited(clip, bound)
				if clip.template != null:
					clip.template.on_clip_end(bound)
			track_active[clip] = is_active
		if track.has_mixer():
			var mixer: TimelineMixer = _mixers.get(track)
			if mixer == null:
				mixer = track.create_mixer()
				if mixer == null:
					continue
				_mixers[track] = mixer
			mixer.bound = bound
			if not mixer._first_frame_done:
				mixer.on_first_frame()
				mixer._first_frame_done = true
			mixer.process_frame(inputs, time, delta)
		else:
			for entry: Dictionary in inputs:
				track.process_clip(entry.clip, entry.clip_time, delta, bound)
	_evaluate_markers()


func _evaluate_markers() -> void:
	if timeline == null:
		return
	var forward: bool = time >= _last_time
	for marker: TimelineMarker in timeline.markers:
		if marker == null or not marker.enabled:
			continue
		var crossed: bool = marker.time >= _last_time and marker.time <= time if forward else marker.time <= _last_time and marker.time >= time
		if not crossed:
			continue
		if marker.trigger_once and _marker_fired.get(marker, false):
			continue
		fire_marker(marker)
		_marker_fired[marker] = true


## Fires a single marker immediately. Signal emitters are routed to a
## TimelineReceiver; template-based markers keep their on_marker callback.
func fire_marker(marker: TimelineMarker) -> void:
	if marker == null:
		return
	if marker is TimelineSignalEmitter:
		var emitter: TimelineSignalEmitter = marker as TimelineSignalEmitter
		if emitter.signal_asset != null:
			var receiver: TimelineReceiver = _resolve_signal_receiver(emitter)
			if receiver != null:
				receiver.emit_timeline_signal(emitter.signal_asset.signal_name, emitter.arg)
			else:
				push_warning("TimelineDirector: 信号 %s 没有可用接收器" % emitter.signal_asset.signal_name)
	marker.on_marker(get_marker_bound(marker))


func _resolve_signal_receiver(emitter: TimelineSignalEmitter) -> TimelineReceiver:
	if emitter == null:
		return null
	if not emitter.receiver_path.is_empty():
		var node: Node = get_node_or_null(emitter.receiver_path)
		return node as TimelineReceiver
	if get_tree() != null:
		var first: Node = get_tree().get_first_node_in_group(&"TimelineReceivers")
		return first as TimelineReceiver
	return null


func get_marker_bound(marker: TimelineMarker) -> Object:
	return self


## Restores target defaults on every active mixer and evaluated non-mixer track
## (Unity OnPlayableDestroy), then clears runtime state and resets the playhead.
func _restore_and_stop() -> void:
	for mixer: TimelineMixer in _mixers.values():
		mixer.on_playable_destroy()
	for track: TimelineTrack in _active_clips.keys():
		track.on_playable_destroy(get_bound(track))
	_mixers.clear()
	_active_clips.clear()
	_marker_fired.clear()
	_last_time = 0.0
	time = 0.0
	playing = false


## Mirrors Unity's OnPlayableDestroy: when the director node is freed (e.g. scene
## teardown or script reload), restore target defaults so bound objects are not
## left in a blended state. stop() performs the same restore for explicit calls.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		stop()
