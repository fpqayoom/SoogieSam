class_name PlayerStateRun extends PlayerStateBase

func init() -> void:
	pass

func enter() -> void:
	player.anim.play("run")
	pass

func exit() -> void:
	pass
	
func input_handle(event : InputEvent) -> PlayerStateBase:
	if event.is_action_pressed("jump"):
		return jump
	if event.is_action_pressed("down"):
		return crouch
	return next_state

func process(_delta : float) -> PlayerStateBase:
	if player.direction.x == 0:
		return idle
	return next_state

func physics_process(_delta : float) -> PlayerStateBase:
	player.velocity.x = player.direction.x * player.move_speed
	return next_state
