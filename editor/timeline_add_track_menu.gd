@tool
extends PopupMenu

## Builds the "Add Track" menu from TimelineRegistry.get_registered_tracks(),
## grouped into submenus by category. Emits track_chosen(entry) on selection.

signal track_chosen(entry: Dictionary)

var _entries: Array = []


func _init() -> void:
	id_pressed.connect(_on_id_pressed)


func build_from_registry() -> void:
	clear()
	_entries.clear()
	add_item("轨道组", -2)
	var cats: Dictionary = {}
	for entry: Variant in TimelineRegistry.get_registered_tracks():
		var e: Dictionary = entry as Dictionary
		var cat: String = e["category"] as String
		if not cats.has(cat):
			cats[cat] = []
		(cats[cat] as Array).append(e)
	for cat_key: Variant in cats.keys():
		var sub: PopupMenu = PopupMenu.new()
		sub.name = "Sub%d" % sub.get_instance_id()
		add_child(sub)
		for entry2: Variant in (cats[cat_key] as Array):
			var e2: Dictionary = entry2 as Dictionary
			_entries.append(e2)
			sub.add_item(e2["display_name"] as String, _entries.size() - 1)
		sub.id_pressed.connect(_on_sub_id_pressed)
		add_submenu_item(cat_key as String, sub.name)
	if cats.size() == 0:
		add_item("(no tracks)", -1)


func _on_sub_id_pressed(id: int) -> void:
	if id >= 0 and id < _entries.size():
		track_chosen.emit(_entries[id] as Dictionary)


func _on_id_pressed(id: int) -> void:
	if id == -2:
		track_chosen.emit({"script": null, "display_name": "轨道组", "category": "组"})
