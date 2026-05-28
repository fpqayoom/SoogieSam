class_name PlayerStateBase extends Node

@onready var idle : PlayerStateBase = %Idle
@onready var run :  PlayerStateBase = %Run
@onready var jump :  PlayerStateBase = %Jump
@onready var fall :  PlayerStateBase = %Fall
@onready var crouch :  PlayerStateBase = %Crouch
var player : Player
var next_state : PlayerStateBase
 

func init() -> void:
	pass

func enter() -> void:
	pass

func exit() -> void:
	pass
	
func input_handle(_event : InputEvent) -> PlayerStateBase:
	return next_state

func process(_delta : float) -> PlayerStateBase:
	return next_state

func physics_process(_delta : float) -> PlayerStateBase:
	return next_state


