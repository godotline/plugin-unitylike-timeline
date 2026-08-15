@tool
class_name ControlTrack
extends TimelineTrack

## Unity Control Track analog: binds a TimelineDirector node and plays a
## sub-timeline while the clip is active.

var _previous_timelines: Dictionary = {}
var _previous_times: Dictionary = {}


func _init() -> void:
	track_color = Color(0.75, 0.45, 0.9)


func get_clip_class() -> Script:
	return preload("res://addons/timeline/tracks/control_clip.gd")


func validate_binding(bound: Object) -> bool:
	return bound is TimelineDirector


func on_clip_entered(clip: TimelineClip, bound: Object) -> void:
	if bound == null or not (bound is TimelineDirector):
		return
	var director: TimelineDirector = bound as TimelineDirector
	var behaviour: ControlBehaviour = clip.template as ControlBehaviour
	if behaviour == null or behaviour.sub_timeline == null:
		return
	var instance_id: int = director.get_instance_id()
	if not _previous_timelines.has(instance_id):
		_previous_timelines[instance_id] = director.timeline
		_previous_times[instance_id] = director.time
	director.timeline = behaviour.sub_timeline
	if behaviour.autoplay:
		director.play(0.0)
	else:
		director.seek(0.0)


func on_clip_exited(clip: TimelineClip, bound: Object) -> void:
	if bound == null or not (bound is TimelineDirector):
		return
	var director: TimelineDirector = bound as TimelineDirector
	var instance_id: int = director.get_instance_id()
	if _previous_timelines.has(instance_id):
		if director.playing:
			director.stop()
		director.timeline = _previous_timelines[instance_id]
		director.time = float(_previous_times.get(instance_id, 0.0))
		_previous_timelines.erase(instance_id)
		_previous_times.erase(instance_id)


func on_playable_destroy(bound: Object) -> void:
	if bound == null or not (bound is TimelineDirector):
		return
	var director: TimelineDirector = bound as TimelineDirector
	var instance_id: int = director.get_instance_id()
	if _previous_timelines.has(instance_id):
		if director.playing:
			director.stop()
		director.timeline = _previous_timelines[instance_id]
		director.time = float(_previous_times.get(instance_id, 0.0))
		_previous_timelines.erase(instance_id)
		_previous_times.erase(instance_id)


func process_clip(clip: TimelineClip, clip_time: float, delta: float, bound: Object) -> void:
	if bound == null or not (bound is TimelineDirector):
		return
	var director: TimelineDirector = bound as TimelineDirector
	var behaviour: ControlBehaviour = null
	if clip != null and clip.template != null:
		behaviour = clip.template as ControlBehaviour
	if behaviour == null or behaviour.sub_timeline == null:
		return
	if director.timeline != behaviour.sub_timeline:
		return
	director.seek(clip_time)
	if behaviour.autoplay and not director.playing:
		director.play(clip_time)
