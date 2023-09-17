extends Control


# Public methods
func print_function(message: String) -> void:
	prints(message)


# Signal handlers
func _on_ButtonUpdate_pressed() -> void:
	var optional_callback := print_function.bind("Layout2 updated")
	GuiTransitions.update(optional_callback)
	await GuiTransitions.show_completed
	prints("Layout2 after update")


func _on_ButtonHide_pressed() -> void:
	var optional_callback := print_function.bind("Layout2 hidden")
	GuiTransitions.hide("Layout2", optional_callback)


func _on_ButtonGoTo_pressed() -> void:
	var optional_callback := print_function.bind("Transition from Layout2 to Layout 3")
	GuiTransitions.go_to("Layout3")
