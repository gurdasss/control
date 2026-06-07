extends Control

const TITLE = "MISSION COMPLETE"
const MESSAGE = "You were able to infiltrate swiftly\nand got the information you needed."
const PROMPT = "[ PRESS ENTER TO RESTART ]"
@export_file("*.tscn") var return_to: String = ""

func _ready() -> void:
		$RichTextLabel.text = "[center][color=#44ff44][b]" + TITLE + "[/b][/color]\n\n[color=#ffffff]" + MESSAGE + "[/color]\n\n[color=#888888]" + PROMPT + "[/color][/center]"

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().change_scene_to_file(return_to)
