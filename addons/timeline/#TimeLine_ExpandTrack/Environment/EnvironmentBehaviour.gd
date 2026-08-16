# Unity: EnvironmentBehaviour.cs
@tool
class_name EnvironmentBehaviour
extends TimelineBehaviour

## Unity: public enum RenderMode { Color, Trilight } (Unity Gradient replaced by
## Trilight three-color mode). Trilight has no direct Godot equivalent, so the
## mixer averages Sky/Equator/Ground into the single ambient color.
enum RenderMode { COLOR, TRILIGHT }

## Unity: public RenderMode mode = RenderMode.Color
@export var mode: RenderMode = RenderMode.COLOR

# --- Color mode parameters ---
## Unity: [ColorUsage(false, true)] public Color Ambient_Color = new(0.2f, 0.4f, 0.8f)
## Godot Color natively supports HDR (values above 1.0), no ColorUsage needed.
@export var Ambient_Color: Color = Color(0.2, 0.4, 0.8)

# --- Trilight (former Gradient) mode parameters ---
## Unity: [ColorUsage(false, true)] public Color Sky_HDR = Color.cyan
## (RenderSettings.ambientSkyColor)
@export var Sky_HDR: Color = Color(0.0, 1.0, 1.0)

## Unity: [ColorUsage(false, true)] public Color Equator_HDR = Color.gray
## (RenderSettings.ambientEquatorColor)
@export var Equator_HDR: Color = Color(0.5, 0.5, 0.5)

## Unity: [ColorUsage(false, true)] public Color Ground_HDR = Color.black
## (RenderSettings.ambientGroundColor)
@export var Ground_HDR: Color = Color(0.0, 0.0, 0.0)
