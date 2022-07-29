extends Control


func _on_ButtonUpdate_pressed() -> void:
	GuiTransitions.update()


func _on_ButtonHide_pressed() -> void:
	GuiTransitions.hide("Layout1")


func _on_ButtonGoTo_pressed() -> void:
	GuiTransitions.go_to("Layout2")
