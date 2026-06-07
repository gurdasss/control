extends Node

signal action_registered(action_name: String, key_event: InputEventKey)
signal action_unregistered(action_name: String)

# Stores a list of active actions the player currently owns (e.g., ["jump", "dash"])
var unlocked_actions: Array[String] = []

# Maps action names to their InputEventKey for restoration and drop-spawning
var bound_events: Dictionary = {}

func register_action(action_name: String, key_event: InputEventKey) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	else:
		# If the action already exists, clear its old events first
		InputMap.action_erase_events(action_name)

	InputMap.action_add_event(action_name, key_event)

	if not unlocked_actions.has(action_name):
		unlocked_actions.append(action_name)
	bound_events[action_name] = key_event

	action_registered.emit(action_name, key_event)

func unregister_action(action_name: String) -> void:
	if not unlocked_actions.has(action_name):
		return

	# Strip bindings from Godot's engine — Input.is_action_pressed() safely returns false
	if InputMap.has_action(action_name):
		InputMap.action_erase_events(action_name)
		
	unlocked_actions.erase(action_name)
	bound_events.erase(action_name)

	action_unregistered.emit(action_name)

func is_action_registered(action_name: String) -> bool:
	return unlocked_actions.has(action_name)
