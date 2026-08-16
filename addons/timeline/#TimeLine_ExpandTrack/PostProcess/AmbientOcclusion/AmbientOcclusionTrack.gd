@tool
# Unity: AmbientOcclusionTrack.cs
class_name AmbientOcclusionTrack
extends TimelineTrack


func _init() -> void:
	track_color = Color(0.2, 0.2, 0.2)


## Unity: [TrackClipType(typeof(AmbientOcclusionClip))]
func get_clip_class() -> Script:
	return preload("res://addons/timeline/#TimeLine_ExpandTrack/PostProcess/AmbientOcclusion/AmbientOcclusionClip.gd")


## Unity: CreateTrackMixer -> ScriptPlayable<AmbientOcclusionMixerBehaviour>
func has_mixer() -> bool:
	return true


func create_mixer() -> TimelineMixer:
	return preload("res://addons/timeline/#TimeLine_ExpandTrack/PostProcess/AmbientOcclusion/AmbientOcclusionMixer.gd").new()


func get_display_name() -> String:
	return "AmbientOcclusion"


## Unity: [TrackBindingType(typeof(PostProcessVolume))] -> Godot camera/env.
func validate_binding(bound: Object) -> bool:
	return bound == null or bound is Camera3D or bound is WorldEnvironment
