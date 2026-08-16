# Unity: VignetteClip.cs
@tool
class_name VignetteClip
extends TimelineClip

## Unity: public VignetteBehaviour template = new(); ClipCaps.Blending.
const VignetteBehaviourScript: Script = preload("res://addons/timeline/#TimeLine_ExpandTrack/PostProcess/Vignette/VignetteBehaviour.gd")


func _init() -> void:
	template = VignetteBehaviourScript.new()
