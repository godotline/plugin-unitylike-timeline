@tool
# Unity: ColorGradingTrack.cs
class_name ColorGradingTrack
extends TimelineTrack


func _init() -> void:
	track_color = Color(0.8, 0.3, 0.3)


## Unity: [TrackClipType(typeof(ColorGradingClip))]
func get_clip_class() -> Script:
	return preload("res://#Template/[Scripts]/TimeLineExpand/PostProcess/ColorGrading/ColorGradingClip.gd")


## Unity: CreateTrackMixer -> ScriptPlayable<ColorGradingMixerBehaviour>
func has_mixer() -> bool:
	return true


func create_mixer() -> TimelineMixer:
	return preload("res://#Template/[Scripts]/TimeLineExpand/PostProcess/ColorGrading/ColorGradingMixer.gd").new()


func get_display_name() -> String:
	return "ColorGrading"


## Unity: [TrackBindingType(typeof(PostProcessVolume))] -> Godot camera/env.
func validate_binding(bound: Object) -> bool:
	return bound == null or bound is Camera3D or bound is WorldEnvironment
