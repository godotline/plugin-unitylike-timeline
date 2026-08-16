# Unity: DepthOfFieldClip.cs
@tool
class_name DepthOfFieldClip
extends TimelineClip

## Unity: public DepthOfFieldBehaviour template = new(); ClipCaps.Blending.
const DepthOfFieldBehaviourScript: Script = preload("res://addons/timeline/#TimeLine_ExpandTrack/PostProcess/DepthOfField/DepthOfFieldBehaviour.gd")


func _init() -> void:
	template = DepthOfFieldBehaviourScript.new()
