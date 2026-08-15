@tool
class_name SignalClip
extends TimelineClip

## Signal track clip: template is a SignalBehaviour.

const SignalBehaviourScript: Script = preload("res://addons/timeline/tracks/signal_behaviour.gd")


func _init() -> void:
	template = SignalBehaviourScript.new()
