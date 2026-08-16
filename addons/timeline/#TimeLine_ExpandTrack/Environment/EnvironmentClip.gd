# Unity: EnvironmentClip.cs
@tool
class_name EnvironmentClip
extends TimelineClip

## Unity: public EnvironmentBehaviour template = new(); ClipCaps.Blending | ClipCaps.Extrapolation
const EnvironmentBehaviourScript: Script = preload("res://addons/timeline/#TimeLine_ExpandTrack/Environment/EnvironmentBehaviour.gd")


func _init() -> void:
	template = EnvironmentBehaviourScript.new()
