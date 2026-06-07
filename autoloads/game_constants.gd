extends Node

# --- Ability Registry ---
# Single source of truth for all ability definitions in the game
# Each ability has: key binding, color, and display name
const ABILITIES = {
	"move_left": {
		"key": KEY_LEFT,
		"color": Color(0.2, 0.5, 0.9),
		"display_name": "Move Left",
		"icon": "<" 
	},
	"move_right": {
		"key": KEY_RIGHT,
		"color": Color(0.2, 0.5, 0.9),
		"display_name": "Move Right",
		"icon": ">"
	},
	"jump": {
		"key": KEY_SPACE,
		"color": Color(0.2, 0.8, 0.2),
		"display_name": "Jump",
		"icon": "^"
	},
	"dash": {
		"key": KEY_SHIFT,
		"color": Color(0.9, 0.5, 0.1),
		"display_name": "Dash",
		"icon": ">>" # Lightning bolt for dash!
	},
	"crouch": {
		"key": KEY_CTRL,
		"color": Color(0.9, 0.85, 0.1),
		"display_name": "Crouch",
		"icon": "▼"
	}
}

# --- Geometry Colors ---
const GEOMETRY_COLOR = Color(0.35, 0.35, 0.35)
const BACKGROUND_COLOR = Color(0.05, 0.05, 0.1)

# Since Autoloads are global objects designed to hold persistent data,
# their functions do not need to be static.

# --- Helper: Get key event for an action ---
func get_key_event(action_name: String) -> InputEventKey:
	var event = InputEventKey.new()
	if ABILITIES.has(action_name):
		event.keycode = ABILITIES[action_name]["key"]
	else:
		push_warning("GameConstants: unknown action '" + action_name + "'")
		event.keycode = KEY_NONE
	return event

# --- Helper: Get color for an action ---
func get_color(action_name: String) -> Color:
	if ABILITIES.has(action_name):
		return ABILITIES[action_name]["color"]
	return Color.WHITE

# --- Helper: Get display name for an action ---
func get_display_name(action_name: String) -> String:
	if ABILITIES.has(action_name):
		return ABILITIES[action_name]["display_name"]
	return action_name
