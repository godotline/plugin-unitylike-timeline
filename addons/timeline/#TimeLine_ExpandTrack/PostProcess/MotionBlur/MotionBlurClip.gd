# Unity: MotionBlurClip.cs
@tool
class_name MotionBlurClip
extends TimelineClip

## Unity: public MotionBlurBehaviour template = new(); ClipCaps.Blending.
const MotionBlurBehaviourScript: Script = preload("res://addons/timeline/#TimeLine_ExpandTrack/PostProcess/MotionBlur/MotionBlurBehaviour.gd")


func _init() -> void:
	template = MotionBlurBehaviourScript.new()
