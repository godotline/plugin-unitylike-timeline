# Unity: MotionBlurBehaviour.cs
@tool
class_name MotionBlurBehaviour
extends TimelineBehaviour

## Unity: public MotionBlurBehaviour — serialized clip data. Ranges from Unity:
## shutterAngle 0~360, sampleCount 4~32.

@export var enableMotionBlur: bool = true

@export_range(0.0, 360.0, 1.0) var shutterAngle: float = 270.0
@export_range(4, 32, 1) var sampleCount: int = 8
