@tool
# Unity: FogTrack.cs
class_name FogTrack
extends TimelineTrack


func _init() -> void:
	track_color = Color(0.984, 0.855, 0.725)


## Unity: [TrackClipType(typeof(FogClip))]
func get_clip_class() -> Script:
	return preload("res://#Template/[Scripts]/TimeLineExpand/Fog/FogClip.gd")


## Unity: CreateTrackMixer -> ScriptPlayable<FogMixerBehaviour>
func has_mixer() -> bool:
	return true


func create_mixer() -> TimelineMixer:
	return preload("res://#Template/[Scripts]/TimeLineExpand/Fog/FogMixer.gd").new()


func get_display_name() -> String:
	return "Fog"
