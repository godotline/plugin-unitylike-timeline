@tool
# Unity: EnvironmentTrack.cs
class_name EnvironmentTrack
extends TimelineTrack


func _init() -> void:
	track_color = Color(0.4, 0.7, 0.9)


## Unity: [TrackClipType(typeof(EnvironmentClip))]
func get_clip_class() -> Script:
	return preload("res://#Template/[Scripts]/TimeLineExpand/Environment/EnvironmentClip.gd")


## Unity: CreateTrackMixer -> ScriptPlayable<EnvironmentMixerBehaviour>
func has_mixer() -> bool:
	return true


func create_mixer() -> TimelineMixer:
	return preload("res://#Template/[Scripts]/TimeLineExpand/Environment/EnvironmentMixer.gd").new()


func get_display_name() -> String:
	return "Environment"
