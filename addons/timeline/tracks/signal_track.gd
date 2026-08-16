@tool
class_name SignalTrack
extends TimelineTrack

## Demo custom track: fires a method on the bound object when the playhead enters the clip.
## Third-party track types are added purely by writing a subclass of TimelineTrack like this.

const SignalBehaviourScript: Script = preload("res://addons/timeline/tracks/signal_behaviour.gd")
const SignalClipScript: Script = preload("res://addons/timeline/tracks/signal_clip.gd")


func _init() -> void:
	track_color = Color(0.2, 0.8, 0.6)


func get_clip_class() -> Script:
	return SignalClipScript


func get_display_name() -> String:
	return "Signal Call"


func on_clip_entered(clip: TimelineClip, bound: Object) -> void:
	if clip == null or bound == null:
		return
	var behaviour: SignalBehaviour = clip.template as SignalBehaviour
	if behaviour == null or behaviour.method_name.is_empty():
		return
	if bound.has_method(behaviour.method_name):
		bound.call(behaviour.method_name, behaviour.arg)
	else:
		push_warning("SignalTrack: %s 没有方法 %s" % [bound.name, behaviour.method_name])


func process_clip(clip: TimelineClip, clip_time: float, delta: float, bound: Object) -> void:
	pass
