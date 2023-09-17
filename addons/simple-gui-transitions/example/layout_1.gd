extends Control


# Public methods
func print_function(message: String) -> void:
	prints(message)


# Signal handlers
func _on_ButtonUpdate_pressed() -> void:
	var optional_callback := print_function.bind("Layout1 update callback")
	GuiTransitions.update(optional_callback)
	await GuiTransitions.show_completed
	prints("Layout1 after update")


func _on_ButtonHide_pressed() -> void:
	var optional_callback := print_function.bind("Layout1 hidden")
	GuiTransitions.hide("Layout1", optional_callback)


func _on_ButtonGoTo_pressed() -> void:
	var optional_callback := print_function.bind("Transition from Layout1 to Layout 2")
	GuiTransitions.go_to("Layout2", optional_callback)
