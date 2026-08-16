@tool
# Unity: BloomTrack.cs
class_name BloomTrack
extends TimelineTrack


func _init() -> void:
	track_color = Color(0.9, 0.9, 0.3)


## Unity: [TrackClipType(typeof(BloomClip))]
func get_clip_class() -> Script:
	return preload("res://addons/timeline/#TimeLine_ExpandTrack/PostProcess/Bloom/BloomClip.gd")


## Unity: CreateTrackMixer -> ScriptPlayable<BloomMixerBehaviour>
func has_mixer() -> bool:
	return true


func create_mixer() -> TimelineMixer:
	return preload("res://addons/timeline/#TimeLine_ExpandTrack/PostProcess/Bloom/BloomMixer.gd").new()


func get_display_name() -> String:
	return "Bloom"


## Unity: [TrackBindingType(typeof(PostProcessVolume))] -> Godot camera/env.
func validate_binding(bound: Object) -> bool:
	return bound == null or bound is Camera3D or bound is WorldEnvironment
