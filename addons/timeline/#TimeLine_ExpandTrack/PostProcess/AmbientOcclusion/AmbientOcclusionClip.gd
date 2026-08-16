# Unity: AmbientOcclusionClip.cs
@tool
class_name AmbientOcclusionClip
extends TimelineClip

## Unity: public AmbientOcclusionBehaviour template = new(); ClipCaps.Blending.
const AmbientOcclusionBehaviourScript: Script = preload("res://#Template/[Scripts]/TimeLineExpand/PostProcess/AmbientOcclusion/AmbientOcclusionBehaviour.gd")


func _init() -> void:
	template = AmbientOcclusionBehaviourScript.new()
