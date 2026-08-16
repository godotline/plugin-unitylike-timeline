@tool
# Unity: DepthOfFieldTrack.cs
class_name DepthOfFieldTrack
extends TimelineTrack


func _init() -> void:
	track_color = Color(0.3, 0.3, 0.3)


## Unity: [TrackClipType(typeof(DepthOfFieldClip))]
func get_clip_class() -> Script:
	return preload("res://addons/timeline/#TimeLine_ExpandTrack/PostProcess/DepthOfField/DepthOfFieldClip.gd")


## Unity: CreateTrackMixer -> ScriptPlayable<DepthOfFieldMixerBehaviour>
func has_mixer() -> bool:
	return true


func create_mixer() -> TimelineMixer:
	return preload("res://addons/timeline/#TimeLine_ExpandTrack/PostProcess/DepthOfField/DepthOfFieldMixer.gd").new()


func get_display_name() -> String:
	return "DepthOfField"


## Unity: [TrackBindingType(typeof(PostProcessVolume))] -> Godot camera/env.
func validate_binding(bound: Object) -> bool:
	return bound == null or bound is Camera3D or bound is WorldEnvironment
