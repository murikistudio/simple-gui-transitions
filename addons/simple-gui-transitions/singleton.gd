extends Node


# Signals
signal show_completed
signal hide_completed


# Public methods
# Hide the current layout and show the layout with the given id.
func go_to(id := "", function: FuncRef = null, args := []):
	self.get_tree().call_group(GuiTransition.DEFAULT_GROUP, "_go_to", id, function, args)


# Hide and show the current layout.
func update(function: FuncRef = null, args := []):
	self.get_tree().call_group(GuiTransition.DEFAULT_GROUP, "_update", function, args)


# Show the layout with the given id.
func show(id := ""):
	self.get_tree().call_group(GuiTransition.DEFAULT_GROUP, "_show", id)


# Hide the layout with the given id, or all visible layouts if no id is passed in.
func hide(id := "", function: FuncRef = null, args := []):
	self.get_tree().call_group(GuiTransition.DEFAULT_GROUP, "_hide", id, function, args)
