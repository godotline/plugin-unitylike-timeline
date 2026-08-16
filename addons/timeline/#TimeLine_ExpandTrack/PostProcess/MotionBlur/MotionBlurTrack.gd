@tool
# Unity: MotionBlurTrack.cs
class_name MotionBlurTrack
extends TimelineTrack


func _init() -> void:
	track_color = Color(0.1, 0.2, 0.5)


## Unity: [TrackClipType(typeof(MotionBlurClip))]
func get_clip_class() -> Script:
	return preload("res://addons/timeline/#TimeLine_ExpandTrack/PostProcess/MotionBlur/MotionBlurClip.gd")


## Unity: CreateTrackMixer -> ScriptPlayable<MotionBlurMixerBehaviour>
func has_mixer() -> bool:
	return true


func create_mixer() -> TimelineMixer:
	return preload("res://addons/timeline/#TimeLine_ExpandTrack/PostProcess/MotionBlur/MotionBlurMixer.gd").new()


func get_display_name() -> String:
	return "MotionBlur"


## Unity: [TrackBindingType(typeof(PostProcessVolume))] -> Godot camera/env.
func validate_binding(bound: Object) -> bool:
	return bound == null or bound is Camera3D or bound is WorldEnvironment
