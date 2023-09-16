extends Control


# Variables
@export var num_controls := 4
@export var delay_alpha := 0.5
@export var delay_factor := 1.0
@export var duration_total := 1.0

var _controls := []
@onready var _container_controls: VBoxContainer = find_child("ContainerControls")
@onready var _slider_delay: Range = find_child("SliderDelay")
@onready var _slider_duration: Range = find_child("SliderDuration")
@onready var _text_edit_output: TextEdit = find_child("TextEditOutput")
@onready var _label_delay: Label = find_child("LabelDelay")
@onready var _label_duration: Label = find_child("LabelDuration")


# Built-in overrides
func _ready() -> void:
	_add_controls()
	_slider_delay.value = delay_factor
	_slider_duration.value = duration_total


# Public methods
func print_function(message: String) -> void:
	prints(message)


# Private methods
func _add_controls() -> void:
	for i in num_controls:
		var hbox_container := HBoxContainer.new()
		_set_size_flags(hbox_container)
		_container_controls.add_child(hbox_container)

		var button_pre_delay := _create_button(delay_alpha)
		hbox_container.add_child(button_pre_delay)

		var button_duration := _create_button()
		hbox_container.add_child(button_duration)

		var button_post_delay := _create_button(delay_alpha)
		hbox_container.add_child(button_post_delay)

		var label_sum := Label.new()
		label_sum.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label_sum.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_sum.size_flags_vertical = Control.SIZE_EXPAND_FILL
		label_sum.custom_minimum_size.x = 120
		hbox_container.add_child(label_sum)

		_controls.push_back({
			"pre_delay": button_pre_delay,
			"duration": button_duration,
			"post_delay": button_post_delay,
			"sum": label_sum,
		})


func _update_gui() -> void:
	var base_duration := duration_total / _controls.size()
	var output_lines := []
	var inv_delay_factor := 1.0 - delay_factor

	for _i in _controls.size():
		var i := _i as int
		var inv_i := _controls.size() - i
		var controls: Dictionary = _controls[i]

		var button_pre_delay: Button = controls["pre_delay"]
		var current_delay := i * delay_factor * base_duration
		_set_button_visual(button_pre_delay, current_delay)

		var button_duration: Button = controls["duration"]
		var current_duration := base_duration + base_duration * inv_delay_factor * 3
		_set_button_visual(button_duration, current_duration)

		var button_post_delay: Button = controls["post_delay"]
		var current_post_delay := duration_total - current_duration - current_delay
		_set_button_visual(button_post_delay, current_post_delay)

		var label_sum: Label = controls["sum"]
		var current_sum := current_delay + current_duration + current_post_delay
		label_sum.text = "Sum: %s" % str(current_sum)

		output_lines.push_back({
			"i": i,
			"delay": current_delay,
			"duration": current_duration,
			"post_delay": current_post_delay,
			"sum": current_sum,
		})

	_text_edit_output.text = "\n".join(output_lines)


func _set_button_visual(button: Button, value: float) -> void:
	button.text = str(value)
	button.tooltip_text = str(value)
	button.size_flags_stretch_ratio = clamp(value, 0.0, duration_total)


func _create_button(alpha := 1.0) -> Button:
	var button := Button.new()
	button.clip_text = true
	button.self_modulate.a = alpha
	button.focus_mode = Control.FOCUS_NONE
	_set_size_flags(button)
	return button


func _set_size_flags(control: Control) -> void:
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL


# Event handlers
func _on_SliderDelay_value_changed(value: float) -> void:
	delay_factor = value
	_label_delay.text = "Delay (%s):" % str(value)
	_update_gui()


func _on_SliderDuration_value_changed(value: float) -> void:
	duration_total = value
	_label_duration.text = "Duration (%s):" % str(value)
	_update_gui()


func _on_ButtonGoTo_pressed() -> void:
	var optional_callback := print_function.bind("Transition from Layout3 to Layout 1")
	GuiTransitions.go_to("Layout1", optional_callback)
