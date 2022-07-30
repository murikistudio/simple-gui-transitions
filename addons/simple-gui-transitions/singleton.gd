extends Node


signal show_completed
signal hide_completed


func go_to(id := "", function: FuncRef = null, args := []):
	self.get_tree().call_group(GuiTransition.DEFAULT_GROUP, "_go_to", id, function, args)


func update(function: FuncRef = null, args := []):
	self.get_tree().call_group(GuiTransition.DEFAULT_GROUP, "_update", function, args)


func show(id := ""):
	self.get_tree().call_group(GuiTransition.DEFAULT_GROUP, "_show", id)


func hide(id := "", function: FuncRef = null, args := []):
	self.get_tree().call_group(GuiTransition.DEFAULT_GROUP, "_hide", id, function, args)
