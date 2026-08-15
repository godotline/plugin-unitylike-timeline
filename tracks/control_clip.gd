@tool
class_name ControlClip
extends TimelineClip

## Clip for ControlTrack. The template carries the sub-timeline resource.

const ControlBehaviourScript: Script = preload("res://addons/timeline/tracks/control_behaviour.gd")


func _init() -> void:
	clip_name = "Control"
	template = ControlBehaviourScript.new()
