extends CharacterBody2D

signal dash_cooldown_changed(value: float)

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
@onready var glitch_sfx: AudioStreamPlayer2D = $GlitchSFX
@onready var dash_sfx: AudioStreamPlayer2D = $DashSFX

# For dashing
const DASH_SPEED = 700.0
var is_dashing: bool = false
var dash_cooldown: float = 0.0:
	set(value):
		dash_cooldown = value
		dash_cooldown_changed.emit(value)

@export var reset_actions_on_ready: bool = false

# 1. TRACK STATE: Keep a record of where we are looking (1.0 is right, -1.0 is left)
var facing_direction: float = 1.0 

func _ready() -> void:
	# Reset all actions if this level requires a fresh start (e.g. Level 1)
	if reset_actions_on_ready:
		for action in InputManager.unlocked_actions.duplicate():
			InputManager.unregister_action(action)

	# Only register defaults if this is a fresh start
	if InputManager.unlocked_actions.is_empty():
		InputManager.register_action("move_left", GameConstants.get_key_event("move_left"))
		InputManager.register_action("move_right", GameConstants.get_key_event("move_right"))
	else:
		# INFO: Because the scene tranisition method I use change_scene_to_file for scene transition
		# Re-apply existing actions to InputMap
		# Autoload state survives scene changes but InputMap resets — re-stitch them
		for action in InputManager.unlocked_actions:
			var event = GameConstants.get_key_event(action)
			if not InputManager.is_action_registered(action):
				InputManager.register_action(action, event)
			print_debug("Actions were remapped")
	
	InputManager.action_unregistered.connect(spawn_dropped_input)
	

func take_action(action: String) -> void:
	# WARNING: This is statement is going with an assumption that all the action will match with GameConstants.gd's keys.
	InputManager.register_action(action, GameConstants.get_key_event(action))
	
	shake(5.0, 0.1)
	_apply_hitstop(0.5)
	glitch_sfx.play()
	# CRITICAL: We pass `true` as the 4th argument so this timer ignores the engine being paused!
	get_tree().create_timer(0.1, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)

func _apply_hitstop(duration: float) -> void:
	# 1. Halt the engine
	Engine.time_scale = 0.0
	
	# 2. Create a timer that ignores the engine's time scale
	# Arguments: (time, process_always, ignore_time_scale)
	var timer = get_tree().create_timer(duration, false, true)
	
	# 3. Wait for the timer to finish, then restore time
	await timer.timeout
	Engine.time_scale = 1.0

func _physics_process(delta: float) -> void:
	
	#animated_sprite_2d.flip_h = false if facing_direction == 1 else true
	if not is_on_floor():
		velocity += get_gravity() * delta
		_play_animation("jump")

	if Input.is_action_just_pressed("ui_home"):
		take_damage()

	# Jump
	if InputManager.is_action_registered("jump") and Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		_play_animation("jump")

	# Dash cooldown
	if dash_cooldown > 0.0:
		dash_cooldown -= delta

	# Read direction FIRST
	var direction := 0.0
	if InputManager.is_action_registered("move_left") and Input.is_action_pressed("move_left"):
		direction -= 1.0
	if InputManager.is_action_registered("move_right") and Input.is_action_pressed("move_right"):
		direction += 1.0

	# Update facing before dash so it bursts the right way
	if direction != 0.0:
		facing_direction = sign(direction)

	# Dash trigger
	if InputManager.is_action_registered("dash") and Input.is_action_just_pressed("dash") and not is_dashing and dash_cooldown <= 0.0:
		is_dashing = true
		dash_cooldown = 1.0
		velocity.x = facing_direction * DASH_SPEED
		_play_animation("dash")
		dash_sfx.play()
		get_tree().create_timer(0.2).timeout.connect(func(): is_dashing = false)

	# Movement — only if not dashing
	if not is_dashing:
		if direction != 0.0:
			velocity.x = direction * SPEED
			_play_animation("run")
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			_play_animation("idle")

	move_and_slide()

func take_damage() -> void:
	if InputManager.unlocked_actions.is_empty():
		return
	
	var action_to_lose = InputManager.unlocked_actions[randi() % InputManager.unlocked_actions.size()]
	InputManager.unregister_action(action_to_lose)
	print("Player LOST action: ", action_to_lose)
	
	if InputManager.unlocked_actions.is_empty():
		# Player has no controls left — inform Main
		get_tree().get_first_node_in_group("main").game_over()

func spawn_dropped_input(action_name: String) -> void:
	var dropped_item = ControlItem.create(action_name)
	
	# 3. REVERSE DIRECTION: Multiply facing_direction by -1 to get the opposite side
	var throw_direction = -facing_direction
	
	# Spawn safely offset to the opposite side
	dropped_item.global_position = global_position + Vector2(throw_direction * 80, -40)
	
	# 4. THE THROW (Optional Polish): If your pickup is a CharacterBody2D or RigidBody2D 
	# with a velocity variable, this gives it an actual physical arc up and away from you!
	if "velocity" in dropped_item:
		dropped_item.velocity = Vector2(throw_direction * 250, -300)
	
	get_parent().call_deferred("add_child", dropped_item)


func _play_animation(anim_name: String) -> void:
	#if animated_sprite_2d.animation == anim_name:
		#return
	#animated_sprite_2d.stop()
	#animated_sprite_2d.play(anim_name)
	pass
	
	
	

# Add these variables at the top of your Player script
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
@onready var camera: Camera2D = $Camera2D

# Add this to your _process(delta) function
func _process(delta: float) -> void:
	if shake_duration > 0:
		shake_duration -= delta
		# Randomly offset the camera
		camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	else:
		# Reset camera to center when shake ends
		camera.offset = Vector2.ZERO

# Add this helper function
func shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_duration = duration
