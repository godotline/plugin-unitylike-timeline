@tool
class_name ActivationClip
extends TimelineClip

## Unity ActivationTrack clip: template is an ActivationBehaviour.

const ActivationBehaviourScript: Script = preload("res://addons/timeline/tracks/activation_behaviour.gd")


func _init() -> void:
	template = ActivationBehaviourScript.new()
