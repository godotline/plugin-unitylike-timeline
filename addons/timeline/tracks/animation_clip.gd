@tool
class_name AnimationClip
extends TimelineClip

## Animation track clip: template is an AnimationBehaviour.

const AnimationBehaviourScript: Script = preload("res://addons/timeline/tracks/animation_behaviour.gd")


func _init() -> void:
	template = AnimationBehaviourScript.new()
