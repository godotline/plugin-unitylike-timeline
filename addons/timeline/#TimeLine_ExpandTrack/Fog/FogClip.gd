# Unity: FogClip.cs
@tool
class_name FogClip
extends TimelineClip

const FogBehaviourScript: Script = preload("res://#Template/[Scripts]/TimeLineExpand/Fog/FogBehaviour.gd")


## Unity: public FogBehaviour template = new FogBehaviour(); ClipCaps.Blending is
## handled by the director via blend_in/blend_out on TimelineClip.
func _init() -> void:
	template = FogBehaviourScript.new()
