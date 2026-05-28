@tool
@icon("res://generels/icons/level_transition.svg")

class_name LevelTransition extends Node2D

enum SIDE {LEFT, RIGHT, TOP, BOTTOM}
@export_range(2, 16, 1,"or_greater") var size = 2 : 
	set (value):
		size = value
		apply_area_settings()
	

@export var location : SIDE = SIDE.LEFT :
	set (value):
		location = value
		apply_area_settings()

@export_file("*.tscn") var Target_level : String = ""
@export var Target_area : String = "LevelTransition"

@onready var area_2d : Area2D = $Area2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	scenemanager.new_scene_ready.connect(_on_scene_ready)
	scenemanager.load_scene_finished.connect(_on_scene_finished)
	area_2d.body_entered.connect(_on_player_entered)
	pass

func _on_scene_ready(target_name: String, offset: Vector2) -> void:
	pass

func _on_scene_finished() -> void:
	pass
	
func _on_player_entered(_n: Node2D) -> void:
	scenemanager.test()
	pass


func apply_area_settings() -> void:
	area_2d = get_node_or_null("Area2D")
	if not area_2d:
		return
	if location == SIDE.LEFT or location == SIDE.RIGHT:
		area_2d.scale.y = size
		if location == SIDE.LEFT:
			area_2d.scale.x = -1
		else:
			area_2d.scale.x = 1
	else:
		area_2d.scale.x = size
		if location == SIDE.TOP:
			area_2d.scale.y = 1
		else:
			area_2d.scale.y = -1
	pass
