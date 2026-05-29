extends CharacterBody2D
class_name Player

@onready var shape : Sprite2D = $Sprite2D
@onready var Coli_stand : CollisionShape2D = %CollisionStand
@onready var Coli_crouch : CollisionShape2D = %CollisionCrouch
@onready var ShapeCast : ShapeCast2D = %ShapeCast
@onready var anim : AnimatedSprite2D = %AnimatedSprite2D
@export var move_speed : float = 300

## State Variable
var states : Array[PlayerStateBase]

var current_state : PlayerStateBase :
	get : return states.front()
		
var prev_state : PlayerStateBase :
	get : return states[1]

## local variables 
var direction : Vector2 = Vector2.ZERO
var gravity : float = 980.0
var gravity_multipiler : float = 1.0

func _ready() -> void:
	initialiaze_state()
	pass
	
func _unhandled_input(event: InputEvent) -> void:	
	var new_state = current_state.input_handle(event) 
	if new_state != null:
		change_state(new_state)
	pass
	
func _process(delta: float) -> void:
	var new_state = current_state.process(delta)
	if new_state != null:
		change_state(new_state)
	pass
	
func _physics_process(_delta: float) -> void:
	change_direction()
	velocity.y += gravity * _delta * gravity_multipiler
	var new_state = current_state.physics_process(_delta)
	if new_state != null:
		change_state(new_state)
	move_and_slide()
	pass
	
func initialiaze_state() -> void:
	states = []
	for node_state in $States.get_children():
		states.append(node_state)
		node_state.player = self
	pass
	 
	if states.size() == 0:
		return
	
	for state in states:
		state.init()
	change_state(current_state) # <- in tutorial
	current_state.enter()
	pass
	

func change_state(new_state : PlayerStateBase) -> void:
	if new_state == null:
		return
	if new_state == current_state:
		return
	if current_state:
		current_state.exit()
	
	states.push_front(new_state)
	current_state.enter()
	states.resize(3)
	pass
	

func change_direction() -> void:
	var x = 	Input.get_axis("ui_left", "ui_right")
	var y = Input.get_axis("ui_down", "ui_down")
	direction = Vector2(x, y)
	
	if direction.x != 0:
		anim.flip_h = (direction.x < 0)
	pass
