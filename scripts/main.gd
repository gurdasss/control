extends Node

@export var player_scene: PackedScene
@export var reset_player_actions: bool = false
@export var level_time: float = 0.0  # 0 means no timer (Level 0)

var time_remaining: float = 0.0
var timer_active: bool = false

func _ready() -> void:
	_spawn_player()
	if level_time > 0.0:
		time_remaining = level_time
		timer_active = true
		HUD.show()
		HUD.show_timer()


func _process(delta: float) -> void:
	if not timer_active:
		return
	
	time_remaining -= delta
	HUD.update_timer(time_remaining)
	
	if time_remaining <= 0.0:
		timer_active = false
		HUD.hide_timer()
		game_over()


func _spawn_player() -> void:
	if not player_scene:
		push_warning("Main: player_scene not assigned in Inspector!")
		return
	
	var player = player_scene.instantiate()
	# Pass level-specific config to player before adding to scene tree
	player.reset_actions_on_ready = reset_player_actions
	add_child(player)
	
	var spawn = get_node_or_null("SpawnPoint")
	if spawn:
		player.global_position = spawn.global_position

func game_over() -> void:
	timer_active = false
	get_tree().call_deferred("reload_current_scene")
