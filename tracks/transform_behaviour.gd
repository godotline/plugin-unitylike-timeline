@tool
class_name TransformBehaviour
extends TimelineBehaviour

## Demo custom track behaviour: interpolates position / rotation (euler degrees) /
## scale of a Node3D over the clip's duration in the director's process loop.

@export var start_pos: Vector3 = Vector3.ZERO
@export var end_pos: Vector3 = Vector3.ZERO
@export var start_rot: Vector3 = Vector3.ZERO
@export var end_rot: Vector3 = Vector3.ZERO
@export var start_scale: Vector3 = Vector3.ONE
@export var end_scale: Vector3 = Vector3.ONE
@export var trans_type: Tween.TransitionType = Tween.TransitionType.TRANS_LINEAR
@export var ease_type: Tween.EaseType = Tween.EaseType.EASE_IN_OUT
## Recorded keyframes: [{time: float 0..1, pos: Vector3, rot: Vector3, scale: Vector3}].
## When at least two keyframes exist they take priority over start/end fields.
@export var keyframes: Array[Dictionary] = []
