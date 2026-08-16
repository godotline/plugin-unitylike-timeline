# Unity: BloomBehaviour.cs
@tool
class_name BloomBehaviour
extends TimelineBehaviour

## Unity: public BloomBehaviour — serialized clip data (Sirenix OdinInspector attrs
## are editor-only; Godot @export replaces them). Range hints from Unity:
## intensity 0~10, threshold 0~10, softKnee 0~1, diffusion 1~10.

@export var enableBloom: bool = true

@export_range(0.0, 10.0, 0.01) var intensity: float = 0.5
@export_range(0.0, 10.0, 0.01) var threshold: float = 1.0
@export_range(0.0, 1.0, 0.01) var softKnee: float = 0.5
@export_range(1.0, 10.0, 0.1) var diffusion: float = 7.0
