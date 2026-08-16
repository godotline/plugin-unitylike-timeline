@tool
# Unity: VignetteTrack.cs
class_name VignetteTrack
extends TimelineTrack


func _init() -> void:
	track_color = Color(0.5, 0.1, 0.5)


## Unity: [TrackClipType(typeof(VignetteClip))]
func get_clip_class() -> Script:
	return preload("res://#Template/[Scripts]/TimeLineExpand/PostProcess/Vignette/VignetteClip.gd")


## Unity: CreateTrackMixer -> ScriptPlayable<VignetteMixerBehaviour>
func has_mixer() -> bool:
	return true


func create_mixer() -> TimelineMixer:
	return preload("res://#Template/[Scripts]/TimeLineExpand/PostProcess/Vignette/VignetteMixer.gd").new()


func get_display_name() -> String:
	return "Vignette"


## Unity: [TrackBindingType(typeof(PostProcessVolume))] -> Godot camera/env.
func validate_binding(bound: Object) -> bool:
	return bound == null or bound is Camera3D or bound is WorldEnvironment
