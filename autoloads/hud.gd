extends CanvasLayer

# Updated to match the new horizontal container
@onready var h_box_container: HBoxContainer = $HBoxContainer

var player: Node2D
var _card_registry: Dictionary = {}

func _ready() -> void:
	InputManager.action_registered.connect(_on_action_registered)
	InputManager.action_unregistered.connect(_on_action_unregistered)
	_rebuild_controls_list()

func _process(_delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if player:
			player.dash_cooldown_changed.connect(_on_dash_cooldown_changed)
			return

func _rebuild_controls_list() -> void:
	_card_registry.clear()
	for child in h_box_container.get_children():
		child.queue_free()
	
	for action in InputManager.unlocked_actions:
		if not GameConstants.ABILITIES.has(action): continue
			
		var data = GameConstants.ABILITIES[action]
		
		# --- Compact Square Card ---
		var card = ColorRect.new()
		card.custom_minimum_size = Vector2(60, 60)
		card.color = Color(0.08, 0.08, 0.12, 0.9) # Slightly transparent stealth background
		
		# --- Colored Bottom Border Accent ---
		var color_strip = ColorRect.new()
		color_strip.custom_minimum_size = Vector2(60, 4)
		color_strip.color = data["color"]
		color_strip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		card.add_child(color_strip)
		
		# --- Massive Center Icon ---
		var icon_label = Label.new()
		icon_label.text = data["icon"]
		icon_label.add_theme_font_size_override("font_size", 32)
		icon_label.add_theme_color_override("font_color", data["color"])
		icon_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		card.add_child(icon_label)
		
		# --- Tiny Keybind Text (Top Left) ---
		var key_label = Label.new()
		# FIX: Explicitly cast the integer back to a Key enum
		key_label.text = OS.get_keycode_string(data["key"] as Key) 
		key_label.add_theme_font_size_override("font_size", 10)
		key_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		# FIX: Use strict enum and set the 4px padding manually
		key_label.set_anchors_preset(Control.LayoutPreset.PRESET_TOP_LEFT) 
		key_label.position = Vector2(4, 4) 
		card.add_child(key_label)
		
		# Register the specific nodes so we can manipulate them for cooldowns
		_card_registry[action] = {
			"card": card,
			"icon": icon_label,
			"key_label": key_label
		}
		
		h_box_container.add_child(card)

func _on_action_registered(_action_name: String, _key_event: InputEventKey) -> void:
	_rebuild_controls_list()

func _on_action_unregistered(_action_name: String) -> void:
	_rebuild_controls_list()

func _on_dash_cooldown_changed(value: float) -> void:
	if _card_registry.has("dash"):
		var ui_elements = _card_registry["dash"]
		if is_instance_valid(ui_elements["key_label"]):
			if value > 0.0:
				# Show timer and dim the icon
				ui_elements["key_label"].text = str(snapped(value, 0.1)) + "s"
				ui_elements["key_label"].add_theme_color_override("font_color", Color(1, 0.3, 0.3)) # Red timer
				ui_elements["icon"].modulate = Color(0.3, 0.3, 0.3) # Dimout
			else:
				# Restore normal state
				ui_elements["key_label"].text = OS.get_keycode_string(GameConstants.ABILITIES["dash"]["key"] as Key)
				ui_elements["key_label"].add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
				ui_elements["icon"].modulate = Color(1, 1, 1) # Full bright

@onready var timer_label: Label = $TimerLabel

func update_timer(time_remaining: float) -> void:
	if time_remaining <= 0.0:
		timer_label.text = "CAPTURED"
		timer_label.modulate = Color.RED
		return
	
	var total_seconds: int = int(time_remaining)
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
	if time_remaining < 15.0:
		timer_label.modulate = Color.RED
	else:
		timer_label.modulate = Color.WHITE

func hide_timer() -> void:
	timer_label.visible = false

func show_timer() -> void:
	timer_label.visible = true
