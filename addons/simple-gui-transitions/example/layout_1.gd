extends Control


# Variables
@onready var gui_transition: GuiTransition = $GuiTransition
@onready var label_animation_enter: Label = %LabelAnimationEnter
@onready var label_animation_leave: Label = %LabelAnimationLeave
@onready var slider_animation_enter: HSlider = %SliderAnimationEnter
@onready var slider_animation_leave: HSlider = %SliderAnimationLeave


# Built-in overrides
func _ready() -> void:
	_update_gui()


# Public methods
func print_function(message: String) -> void:
	prints(message)


# Private methods
func _update_gui() -> void:
	var animation_enter := String(GuiTransition.Anim.find_key(gui_transition.animation_enter)).capitalize()
	var animation_leave := String(GuiTransition.Anim.find_key(gui_transition.animation_leave)).capitalize()
	label_animation_enter.text = "Animation Enter: %s" % animation_enter
	label_animation_leave.text = "Animation Leave: %s" % animation_leave
	slider_animation_enter.set_value_no_signal(gui_transition.animation_enter)
	slider_animation_leave.set_value_no_signal(gui_transition.animation_leave)


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


func _on_slider_animation_enter_value_changed(value: float) -> void:
	gui_transition.animation_enter = int(value) as GuiTransition.Anim
	_update_gui()


func _on_slider_animation_leave_value_changed(value: float) -> void:
	gui_transition.animation_leave = int(value) as GuiTransition.Anim
	_update_gui()
