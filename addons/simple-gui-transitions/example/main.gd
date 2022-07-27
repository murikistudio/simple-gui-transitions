extends Control


func _on_ButtonShow_pressed() -> void:
	GuiTransition.show(self, "Layout1")
