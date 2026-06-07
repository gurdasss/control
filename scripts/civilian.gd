extends CharacterBody2D

# Movement Configs
@export var speed = 300.0
const JUMP_VELOCITY = -400.0
const DASH_speed = 700.0

@export var actions: Array[String] = ["jump", "move_left", "move_right"]
@export var detect_threshold: float = 150.0
@export var steal_threshold: float = 100.0

# Internal State & References
var player: CharacterBody2D = null
var is_dashing: bool = false
var dash_cooldown: float = 0.0

# --- Visual Config ---
@export var dot_y_offset: float = -60.0 # How high above the NPC the dots hover

func _ready() -> void:
	# Tell the engine to draw the initial dots as soon as the NPC spawns
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			push_warning("Civilian warning: No node found in 'player' group!")
			return

	if not is_on_floor():
		velocity += get_gravity() * delta
		_play_animation("jump_landing")

	if dash_cooldown > 0.0:
		dash_cooldown -= delta

	var distance_to_player = position.distance_to(player.position)

	# 1. CORE LOOP: Fleeing Logic
	if distance_to_player < detect_threshold:
		var target_direction = sign(position.x - player.position.x)
		target_direction = _apply_movement_constraints(target_direction)

		if not is_dashing:
			velocity.x = target_direction * speed
			_play_animation("run")

		_execute_abilities(distance_to_player)

		# 2. CORE LOOP: Catch/Steal Evaluation
		if distance_to_player < steal_threshold:
			steal_from_civilian()
			return
	else:
		is_dashing = false
		velocity.x = move_toward(velocity.x, 0, speed * delta)
		_play_animation("idle")

	move_and_slide()

# --- Custom Drawing: The Floating Dots ---
func _draw() -> void:
	if actions.is_empty():
		return # Draw nothing if they are an empty husk
		
	var dot_radius = 6.0
	var spacing = 20.0
	
	# Calculate total width so we can center the dots perfectly over their head
	var total_width = (actions.size() - 1) * spacing
	var start_x = -(total_width / 2.0)
	
	for i in range(actions.size()):
		var action = actions[i]
		if GameConstants.ABILITIES.has(action):
			var color = GameConstants.ABILITIES[action]["color"]
			var pos = Vector2(start_x + (i * spacing), dot_y_offset)
			
			# Draw the colored dot
			draw_circle(pos, dot_radius, color)
			# Draw a dark outline so the dot is visible even against bright backgrounds
			draw_arc(pos, dot_radius, 0.0, TAU, 12, Color(0.1, 0.1, 0.1, 0.8), 2.0)

# --- Ability Pipelines ---
func _apply_movement_constraints(dir: float) -> float:
	if not actions.has("move_left") and dir < 0: return 0.0
	if not actions.has("move_right") and dir > 0: return 0.0
	return dir

func _execute_abilities(distance: float) -> void:
	if actions.has("jump") and is_on_floor() and is_on_wall():
		velocity.y = JUMP_VELOCITY
		_play_animation("jump")

	if actions.has("dash") and not is_dashing and dash_cooldown <= 0.0:
		if distance < (detect_threshold * 0.8):
			_trigger_dash()

func _trigger_dash() -> void:
	is_dashing = true
	dash_cooldown = 2.0 
	var dash_direction = sign(position.x - player.position.x)
	velocity.x = dash_direction * DASH_speed
	get_tree().create_timer(0.3).timeout.connect(func(): is_dashing = false)

# --- Public API ---
func give_action() -> String:
	for i in range(actions.size() - 1, -1, -1):
		var action = actions[i]
		if not InputManager.is_action_registered(action):
			actions.remove_at(i)
			return action
	return ""

func steal_from_civilian() -> void:
	var stolen_action = give_action()

	if stolen_action == "":
		return

	if player and player.has_method("take_action"):
		player.take_action(stolen_action)
		
		# 1. Update the visual dots (this makes the stolen dot vanish instantly)
		queue_redraw()

func _play_animation(anim_name: String) -> void:
	pass
