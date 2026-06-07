@tool
extends StaticBody2D

# 1. Define available types that map to your GameConstants
@export_enum("none", "jump", "dash", "crouch", "move_left", "move_right") var ability_required: String = "none":
	set(value):
		ability_required = value
		_update_visuals()

@export var size: Vector2 = Vector2(100, 20):
	set(value):
		size = value
		_update_visuals()

func _ready() -> void:
	_update_visuals()

func _update_visuals() -> void:
	# Guard against scene tree state in @tool mode
	if not has_node("CollisionShape2D") or not has_node("ColorRect"):
		return
		
	# Update Shape
	if $CollisionShape2D.shape:
		$CollisionShape2D.shape.size = size
	
	# Update Rect
	$ColorRect.size = size
	$ColorRect.position = -size / 2
	
	# 2. Apply Color Logic
	if ability_required == "none":
		$ColorRect.color = GameConstants.GEOMETRY_COLOR
	elif GameConstants.ABILITIES.has(ability_required):
		# Tint the block with the ability color
		$ColorRect.color = GameConstants.ABILITIES[ability_required]["color"]
