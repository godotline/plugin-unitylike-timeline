# Unity: DepthOfFieldClip.cs
@tool
class_name DepthOfFieldClip
extends TimelineClip

## Unity: public DepthOfFieldBehaviour template = new(); ClipCaps.Blending.
const DepthOfFieldBehaviourScript: Script = preload("res://#Template/[Scripts]/TimeLineExpand/PostProcess/DepthOfField/DepthOfFieldBehaviour.gd")


func _init() -> void:
	template = DepthOfFieldBehaviourScript.new()
