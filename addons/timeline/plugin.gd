@tool
extends EditorPlugin

const InspectorPluginClass := preload("res://addons/timeline/editor/timeline_inspector_plugin.gd")

var _dock: Control = null
var _inspector_plugin: EditorInspectorPlugin = null


func _enter_tree() -> void:
	var dock: Control = load("res://addons/timeline/editor/timeline_dock.tscn").instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_BOTTOM, dock)
	_dock = dock
	_inspector_plugin = InspectorPluginClass.new()
	add_inspector_plugin(_inspector_plugin)
	TimelineRegistry.discover_editor(EditorInterface.get_resource_filesystem())


func _exit_tree() -> void:
	if is_instance_valid(_dock):
		remove_control_from_docks(_dock)
		_dock.queue_free()
	if is_instance_valid(_inspector_plugin):
		remove_inspector_plugin(_inspector_plugin)
	_dock = null
	_inspector_plugin = null
