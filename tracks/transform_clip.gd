@tool
class_name TransformClip
extends TimelineClip

## Demo custom track clip: template is a TransformBehaviour.

const TransformBehaviourScript: Script = preload("res://addons/timeline/tracks/transform_behaviour.gd")


func _init() -> void:
	template = TransformBehaviourScript.new()
