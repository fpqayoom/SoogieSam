class_name PlayerStateIdle extends PlayerStateBase

func init() -> void:
	pass

func enter() -> void:
	player.anim.play("idle")
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
	if player.direction.x != 0:
		return run
	return next_state

func physics_process(_delta : float) -> PlayerStateBase:
	player.velocity.x = 0
	if not player.is_on_floor():
		return fall
	return next_state
