@tool
class_name AudioTrack
extends TimelineTrack

## Unity AudioTrack analog: drives an AudioStreamPlayer or AudioStreamPlayer3D
## bound to the track, seeking it to the clip's source time during playback.

var _original_streams: Dictionary = {}
var _original_volumes: Dictionary = {}
var _original_pitches: Dictionary = {}


func _init() -> void:
	track_color = Color(0.25, 0.75, 0.65)


func get_clip_class() -> Script:
	return preload("res://addons/timeline/tracks/audio_clip.gd")


func get_display_name() -> String:
	return "Audio"


func validate_binding(bound: Object) -> bool:
	return bound != null and (bound is AudioStreamPlayer or bound is AudioStreamPlayer3D)


func on_clip_entered(clip: TimelineClip, bound: Object) -> void:
	if bound == null or not is_instance_valid(bound):
		return
	var behaviour: AudioBehaviour = clip.template as AudioBehaviour
	if behaviour == null:
		return
	var instance_id: int = bound.get_instance_id()
	if not _original_streams.has(instance_id):
		_original_streams[instance_id] = bound.get("stream")
		_original_volumes[instance_id] = float(bound.get("volume_db"))
		_original_pitches[instance_id] = float(bound.get("pitch_scale"))
	bound.set("stream", behaviour.stream)
	bound.set("volume_db", behaviour.volume_db)
	bound.set("pitch_scale", behaviour.pitch_scale)
	if behaviour.stream != null:
		bound.call("play")
	elif bound.has_method("is_playing") and bool(bound.call("is_playing")):
		bound.call("stop")


func process_clip(clip: TimelineClip, clip_time: float, delta: float, bound: Object) -> void:
	if bound == null or not is_instance_valid(bound) or clip == null:
		return
	if not bool(bound.call("is_playing")):
		return
	var behaviour: AudioBehaviour = clip.template as AudioBehaviour
	var target_time: float = clip_time
	if behaviour != null and behaviour.loop:
		var stream: AudioStream = bound.get("stream") as AudioStream
		if stream != null and stream.get_length() > 0.0:
			target_time = fposmod(clip_time, stream.get_length())
	bound.call("seek", target_time)


func on_clip_exited(clip: TimelineClip, bound: Object) -> void:
	if bound == null or not is_instance_valid(bound):
		return
	var behaviour: AudioBehaviour = clip.template as AudioBehaviour
	if behaviour == null or behaviour.stop_on_exit:
		bound.call("stop")


func on_playable_destroy(bound: Object) -> void:
	if bound == null or not is_instance_valid(bound):
		return
	var instance_id: int = bound.get_instance_id()
	if _original_streams.has(instance_id):
		bound.set("stream", _original_streams[instance_id])
		bound.set("volume_db", _original_volumes[instance_id])
		bound.set("pitch_scale", _original_pitches[instance_id])
		_original_streams.erase(instance_id)
		_original_volumes.erase(instance_id)
		_original_pitches.erase(instance_id)
	if bound.has_method("is_playing") and bool(bound.call("is_playing")):
		bound.call("stop")
