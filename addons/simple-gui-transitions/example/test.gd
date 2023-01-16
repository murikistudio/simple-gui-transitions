extends Control


# Variables
onready var _button: Button = find_node("Button")
onready var _button_2: Button = find_node("Button2")


# Built-in overrides
func _ready() -> void:
	pass


# Event handlers
func _on_Button_pressed() -> void:
	var _tween := get_tree().create_tween().parallel()
	var _controls := [_button, _button_2]

	for i in range(_controls.size()):
		var control: Control = _controls[i]
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var delay := 0.15 * i

		_tween.set_ease(Tween.EASE_IN_OUT)
		_tween.set_trans(Tween.TRANS_CUBIC)
		_tween.tween_method(
			self, "_set_param_slide",
			Vector2.ZERO,  Vector2(get_viewport().size.x * 1.5, 0),
			1.0 + delay, [control]
		)
		_tween.parallel()

	yield(_tween, "finished")

	_tween = get_tree().create_tween().parallel()

	for i in range(_controls.size()):
		var control: Control = _controls[i]
		var delay := 0.15 * i

		_tween.set_ease(Tween.EASE_IN_OUT)
		_tween.set_trans(Tween.TRANS_CUBIC)
		_tween.tween_method(
			self, "_set_param_slide",
			Vector2(-get_viewport().size.y * 1.5, 0), Vector2.ZERO,
			1.0 + delay, [control]
		)
		_tween.parallel()

	yield(_tween, "finished")

	for i in range(_controls.size()):
		var control: Control = _controls[i]
		control.mouse_filter = Control.MOUSE_FILTER_STOP



func _set_param_slide(value: Vector2, control: Control) -> void:
	(control.material as ShaderMaterial).set_shader_param("slide", value)
