class_name PlayerStateJump extends PlayerStateBase
## Note: i skipped to add velocity base jump and fall, 
## i will add later 
@export var jump_force : float = -550

func init() -> void:
	pass

func enter() -> void:
	player.anim.play("jump")
	player.velocity.y = jump_force
	pass

func exit() -> void:
	pass
	
func input_handle(_event : InputEvent) -> PlayerStateBase:
	return next_state

func process(_delta : float) -> PlayerStateBase:
	return next_state

func physics_process(_delta : float) -> PlayerStateBase:
	player.velocity.x = player.direction.x * player.move_speed
	if player.velocity.y >= 0:
		return fall
	return next_state
