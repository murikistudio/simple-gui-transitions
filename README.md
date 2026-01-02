<p align="center">
  <img height="128" alt="Simple GUI Transitions" src="addons/simple-gui-transitions/icon.png">
</p>
<h1 align="center">Godot's Simple GUI Transitions</h1>

*"Simple GUI transitions to swap menus elegantly."*

This plugin gives access to the `GuiTransition` node which allows to transition multiple GUI layouts easily.
Designed for **Godot 4.x** (3.x version available [here](https://github.com/murikistudio/simple-gui-transitions/tree/godot-3)).
See the example scene on `addons/simple-gui-transitions/example` to see this plugin in action.

[Download it on Godot Asset Library](https://godotengine.org/asset-library/asset/2134)

## Index
- [Index](#index)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
    - [Node Configuration](#node-configuration)
    - [Triggering Transitions](#triggering-transitions)
    - [Known Limitations](#known-limitations)
- [Global Settings](#global-settings)
- [Node `GuiTransition`](#node-guitransition)
    - [Properties](#properties)
- [Singleton `GuiTransitions`](#singleton-guitransitions)
    - [Signals](#signals)
    - [Public Methods](#public-methods)


## Installation
- Install the plugin through the [AssetLib](https://godotengine.org/asset-library/asset/2134) **or** copy the plugin `addons` folder to your project's directory
- Enable the plugin on `Project > Project Settings > Plugins`
- Reload your current project

## Basic Usage
### Node Configuration
After installing the plugin, enabling it on `Project > Project Settings > Plugins`
and reloading your project, you can instance the node `GuiTransition` in your scene.
See the properties in the next section to learn how to configure it properly, but pay attention to the required properties:

- `Layout`: The main layout node. It will be hidden and shown accordingly. Should be the topmost node of the current GUI layout, usually the scene root. If you don't set the `Layout ID` property, this node's name will be assumed as the layout ID. **Always required!**
- `Controls`: An array of nodes that will be animated in sequence.
- `Group`: A node with children controls to be animated in sequence.

**Notes:**
- If you don't set both `Controls` and `Group`, the `Layout` itself will be animated.
In this case, the `Delay` property will not be used.
- If you set both `Controls` and `Group`, only `Controls` will be animated and `Group` will be ignored.

### Triggering Transitions
After setting up its properties, the layout should at least be shown with a transition at startup.
After that you can use code to trigger the transitions. For example:

```gdscript
func _on_button_pressed() -> void:
    GuiTransitions.hide("Hud")
```

This will hide the layout with the layout ID `Hud`.
Keep in mind that you can have multiple layouts with the same ID, so you can
add different transitions to specific parts of the interface, for example,
the health and mana bars in the top of the screen would slide upwards and the
equipment list in the bottom would slide downwards. In that example, you would
have two `GuiTransition` nodes in the scene with the same `Layout ID` (`Hud`) and
different `Controls`/`Group` and `Animation Enter`/`Animation Leave` properties.
This way, you can have different transitions for each part of the interface and
trigger all parts with a single command.

You can change to another layout with the `go_to` method.
For example, you may want to hide the HUD and show the pause menu.
To achieve this, the HUD must be visible and the pause menu must be hidden.
The following code will hide the HUD and show the pause menu.

```gdscript
func _on_button_pause_pressed() -> void:
    GuiTransitions.go_to("Pause")
```

You can even pass a Callable as the second argument of the `go_to` method if you want to execute a function in between the transitions.
However, if you like a more explicit code, other common operation is waiting
for the layout to finish its transition and triggering the next layout afterwards.
This can be easily done with the following code:

```gdscript
func _on_button_pause_pressed() -> void:
    prints("Hud will now hide")
    GuiTransitions.hide("Hud")
    await GuiTransitions.hide_completed
    prints("Hud hidden, will now show Pause")
    GuiTransitions.show("Pause")
```

Another common operation is to not allow controls to be interacted when the
layout is transitioning. The plugin actually do not allow buttons and other
interactable nodes to be interacted during the transition, but only if the nodes
affected by the transition (the `Controls` or `Group`) are interactable, that is:
buttons and other interactable nodes. In the case you the transition is affecting
an container or any other node that is not interactable, the interaction will not
be blocked. In such cases, you may check if a transition is currently in progress
with the `in_transition` method:

```gdscript
func _on_button_increase_strength_pressed() -> void:
    if not GuiTransitions.in_transition():
        strength += 10
        GuiTransitions.go_to("Hud")
```

That way, you avoid the player clicking the button during the transition and
increasing the player's strength multiple times.

Simple GUI Transitions is exactly that: simple to set up and use.
Check the detailed documentation below to learn more.

### Known Limitations
- No support for changing properties at runtime. This means that you can't
add controls to `Controls` and `Group` at runtime, and changing other properties
will have unknown side effects.
Maybe the support for this will be added in the future,
but this plugin was designed for static menus and interfaces, after all.
- No support for slide animations on containers.
The slide animations will work on visible controls
(such as buttons and other interactable nodes)
and the layout (if it is using anchors).
This is due to the fact that the slide transition on controls work through a shader,
and it can't animate the children of a container.
The layout transition, in the other hand, works through anchor tweening,
so make sure the layout is using anchors to be sized on the screen.

## Global Settings
The default transition settings can be set on `Project > Project Settings > GUI Transitions > Config` (you may need to enable `Advanced Settings` to see this section).
Those settings will be applied on top of any `Default` property on the node `GuiTransition`. This is useful to increase or decrease the speed of transitions on the whole project, for example. See each property description below.

## Node `GuiTransition`
The node `GuiTransition` is responsible for transitioning a specific layout.

### Properties
#### Auto Start
If the current layout will trigger its transition at startup automatically. Enabled by default.

#### Fade Layout
If enabled, will fade the *whole layout* along with the selected animation of individual controls. The fade duration is based on the `Duration` property. Enabled by default.

#### Animation Enter
The animation type of the controls when entering the screen. The available animations are:

- Fade
- Slide left, right, up and down
- Scale vertical, horizontal and both

#### Animation Leave
The animation type of the controls when leaving the screen. The available animations are:

- Fade
- Slide left, right, up and down
- Scale vertical, horizontal and both

#### Duration
The total animation duration in seconds. A negative value such as the default `-0.01` will make the transition use the default value set in `Project Settings`.

#### Delay
Delay ratio between transitions for each node contained in `Group` or `Controls`.
The default value is `0.5`.

- A negative value such as the default `-0.01` will make the transition use the default value set in `Project Settings`.
- A delay of `0.0` means no delay, that is, all controls will start and finish their animations at the same time.
- A delay of `1.0` will make each control wait for the previous one to finish its animation to start its own.
- A delay between `0.0` and `1.0` will make controls intertwine animations, giving a smoother effect.

**Note:** See `addons/simple-gui-transitions/example/layout_3.tscn` for an interactive and visual representation of different delay ratios.

#### Layout ID
Optional ID of layout to trigger changes on the singleton `GuiTransitions` (at method parameters named `id`).
If empty, will be assumed as the `Layout` node name.

#### Layout
**Required!** The main layout node. It will be hidden and shown accordingly. Should be the topmost node of the current layout. If your don't set `Controls` or `Group`, the `Layout` itself will be animated.

#### Controls
Array of individual nodes to be animated.
The order will be taken in account to apply the animation `Delay`.

#### Group
A node with children controls to be animated in sequence.
The order will be taken in account to apply the animation `Delay`.
Example: a `HBoxContainer` or `VBoxContainer` with several buttons as children will allow to animate all buttons one by one.

#### Center Pivot
When `Animation Enter` or `Animation Leave` is one of the scale animations, it will center the control's `pivot_offset` property.

#### Transition Type
Transition curve of the animations. Same as `Tween.TransitionType`.

#### Ease Type
Ease curve of the animations. Same as `Tween.EaseType`.

## Singleton `GuiTransitions`
The singleton `GuiTransitions` allows to trigger the transitions globally and swap GUI layouts.

### Signals
#### show_started
Emitted when a layout is about to be shown.

#### show_completed
Emitted after a layout has been shown.

#### hide_started
Emited when a layout is about to be hidden.

#### hide_completed
Emitted after a layout has been hidden.

#### transition_started
Emmited when a layout is about to be shown or hidden.

#### transition_completed
Emited after a layout has been shown or hidden.

### Public Methods
**Note**: Optional arguments in the methods below are suffixed with `?` (e.g. `function?`).

#### go_to(id: String, function?: Callable)
The method `go_to` hides the current layout and shows the layout with the given `id`.
If `function` (optional) is passed in, the `function` will be executed halfway through.
Both signals `hide_completed` and `show_completed` are emitted accordingly.

#### update(function?: Callable)
The method `update` hides and shows the current layout.
If `function` (optional) is passed in, the `function` will be executed halfway through.
Both signals `hide_completed` and `show_completed` are emited accordingly.

#### show(id?: String)
The method `show` shows the layout with the given `id`, or all hidden layouts if no `id` is passed in.
Emits the signal `show_completed` on completion.

#### hide(id?: String, function?: Callable)
The method `hide` hides the layout with the given `id`, or all visible layouts if no `id` is passed in.
Emits the signal `hide_completed` on completion.

#### is_shown(id: String)
The method `is_shown` returns if the layout with the given `id` is currently visible.

#### is_hidden(id: String)
The method `is_hidden` returns if the layout with the given `id` is currently hidden.

#### in_transition(id?: String)
The method `in_transition` returns if any layout or one with the given `id` is currently transitioning.
