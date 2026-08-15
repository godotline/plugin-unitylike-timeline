@tool
class_name AnimationTrack
extends TimelineTrack

## Demo custom track: plays and seeks an AnimationPlayer bound to this track.

const AnimationBehaviourScript: Script = preload("res://addons/timeline/tracks/animation_behaviour.gd")
const AnimationClipScript: Script = preload("res://addons/timeline/tracks/animation_clip.gd")


func _init() -> void:
	track_color = Color(0.9, 0.5, 0.2)


func get_clip_class() -> Script:
	return AnimationClipScript


func get_display_name() -> String:
	return "Animation"


func _get_player(bound: Object) -> AnimationPlayer:
	if bound == null or not (bound is Node):
		return null
	if bound is AnimationPlayer:
		return bound
	var child: Node = (bound as Node).get_node_or_null("AnimationPlayer")
	if child is AnimationPlayer:
		return child
	return null


func on_clip_entered(clip: TimelineClip, bound: Object) -> void:
	var player: AnimationPlayer = _get_player(bound)
	if player == null or clip == null:
		return
	var behaviour: AnimationBehaviour = clip.template as AnimationBehaviour
	if behaviour == null or behaviour.anim_name.is_empty():
		return
	apply_track_offset(bound)
	player.play(behaviour.anim_name)
	player.speed_scale = behaviour.speed_scale


func process_clip(clip: TimelineClip, clip_time: float, delta: float, bound: Object) -> void:
	var player: AnimationPlayer = _get_player(bound)
	var behaviour: AnimationBehaviour = null
	if clip != null:
		behaviour = clip.template as AnimationBehaviour
	if player == null or behaviour == null:
		return
	if player.is_playing() and player.current_animation == behaviour.anim_name:
		var anim: Animation = player.get_animation(behaviour.anim_name)
		if behaviour.loop and anim != null and anim.length > 0.0:
			player.seek(fposmod(clip_time, anim.length), true)
		else:
			player.seek(clip_time, true)


func on_clip_exited(clip: TimelineClip, bound: Object) -> void:
	if bound == null or not is_instance_valid(bound):
		return
	restore_track_offset(bound)
	var player: AnimationPlayer = _get_player(bound)
	var behaviour: AnimationBehaviour = null
	if clip != null and clip.template != null:
		behaviour = clip.template as AnimationBehaviour
	if player != null and (behaviour == null or behaviour.stop_on_exit):
		player.stop()


func on_playable_destroy(bound: Object) -> void:
	if bound == null or not is_instance_valid(bound):
		return
	restore_track_offset(bound)
	var player: AnimationPlayer = _get_player(bound)
	if player != null:
		player.stop()
