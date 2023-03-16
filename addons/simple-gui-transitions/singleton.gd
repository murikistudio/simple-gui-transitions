extends Node


# Signals
signal show_completed
signal hide_completed


# Variables
var _layouts := {}


# Public methods
# Hide the current layout and show the layout with the given id.
func go_to(id: String, function: FuncRef = null, args := []):
	_for_each_layout("_go_to", [id, function, args])


# Hide and show the current layout.
func update(function: FuncRef = null, args := []):
	_for_each_layout("_update", [function, args])


# Show the layout with the given id.
func show(id := ""):
	_for_each_layout("_show", [id])


# Hide the layout with the given id, or all visible layouts if no id is passed in.
func hide(id := "", function: FuncRef = null, args := []):
	_for_each_layout("_hide", [id, function, args])


# Returns if layout with the given id is visible.
func is_shown(id: String) -> bool:
	if not _layouts.has(id):
		push_error("Layout with given id does not exist: " + str(id))
		return false

	for layout in _layouts[id]:
		if not layout._is_shown:
			return false

	return true


# Returns if layout with the given id is hidden.
func is_hidden(id: String) -> bool:
	if not _layouts.has(id):
		push_error("Layout with given id does not exist: " + str(id))
		return true

	for layout in _layouts[id]:
		if layout._is_shown:
			return false

	return true


# Private methods
# Run method with arguments on each layout reference.
func _for_each_layout(method: String, args := []) -> void:
	for layout_name in _layouts.keys():
		for layout in _layouts[layout_name]:
			layout.callv(method, args)
