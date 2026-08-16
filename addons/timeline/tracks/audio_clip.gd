@tool
class_name AudioClip
extends TimelineClip

## Unity AudioTrack clip: template is an AudioBehaviour.

const AudioBehaviourScript: Script = preload("res://addons/timeline/tracks/audio_behaviour.gd")


func _init() -> void:
	template = AudioBehaviourScript.new()
