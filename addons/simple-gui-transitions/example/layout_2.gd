extends Control


func _on_ButtonUpdate_pressed() -> void:
	GuiTransition.update(self)


func _on_ButtonHide_pressed() -> void:
	GuiTransition.hide(self, "Layout2")


func _on_ButtonGoTo_pressed() -> void:
	GuiTransition.go_to(self, "Layout1")
