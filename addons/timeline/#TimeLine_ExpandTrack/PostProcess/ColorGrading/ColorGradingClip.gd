# Unity: ColorGradingClip.cs
@tool
class_name ColorGradingClip
extends TimelineClip

## Unity: public ColorGradingBehaviour template = new(); ClipCaps.Blending.
const ColorGradingBehaviourScript: Script = preload("res://addons/timeline/#TimeLine_ExpandTrack/PostProcess/ColorGrading/ColorGradingBehaviour.gd")


func _init() -> void:
	template = ColorGradingBehaviourScript.new()
