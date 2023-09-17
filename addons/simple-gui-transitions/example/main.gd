extends Control


func _on_ButtonShow_pressed() -> void:
	GuiTransitions.show("Layout1")
	await GuiTransitions.show_completed
	prints("Layout1 after show")
