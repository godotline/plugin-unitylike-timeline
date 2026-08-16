# Unity: VignetteClip.cs
@tool
class_name VignetteClip
extends TimelineClip

## Unity: public VignetteBehaviour template = new(); ClipCaps.Blending.
const VignetteBehaviourScript: Script = preload("res://#Template/[Scripts]/TimeLineExpand/PostProcess/Vignette/VignetteBehaviour.gd")


func _init() -> void:
	template = VignetteBehaviourScript.new()
