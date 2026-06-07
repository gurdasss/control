extends CharacterBody2D
class_name ControlItem

@export var action_name: String = ""
@export var key_event: InputEventKey

# Store a reference to the scene itself
const PACKED_SCENE = preload("res://scenes/control.tscn")

# The static factory method handles creation and data assignment
static func create(action: String) -> ControlItem:
	var control_item = PACKED_SCENE.instantiate() as ControlItem
	# WARNING: I'm going with the assumption that the action will be GameConstant consistent
	control_item.action_name = action
	control_item.key_event = GameConstants.get_key_event(action)
	print_debug("A brand new action was spawned to the world")
	return control_item

func _physics_process(delta: float) -> void:
	# Apply gravity to create the throw arc
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Apply friction so it slides to a stop when it hits the ground
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, 800 * delta)

	move_and_slide()

# Connected to child Area2D's body_entered signal
func _on_pickup_area_body_entered(body: Node2D) -> void:
	# Check if it's the player and they don't already own this action
	if body.is_in_group("player") and not InputManager.is_action_registered(action_name):
		InputManager.register_action(action_name, key_event)
		queue_free()

func _on_timer_timeout() -> void:
	queue_free()
