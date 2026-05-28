class_name PlayerStateCrouch extends PlayerStateBase

var crouch_speed : float = 2
var crouch_force : float = 0.5


func init() -> void:
	pass

func enter() -> void:
	player.anim.play("crouch")
	player.Coli_crouch.disabled = false
	player.Coli_stand.disabled = true
	pass

func exit() -> void:
	player.Coli_crouch.disabled = true
	player.Coli_stand.disabled = false
	pass
	
func input_handle(event : InputEvent) -> PlayerStateBase:
	if event.is_action_pressed("jump"):
		player.ShapeCast.force_shapecast_update()
		if player.ShapeCast.is_colliding() == true:
			player.position.y += 10
			return fall
		return jump

	if event.is_action_released("down"):
		var input_dir = Input.get_axis("ui_left", "ui_right")
		return run if abs(input_dir) > 0.1 else idle
	return next_state


func process(_delta : float) -> PlayerStateBase:
	return next_state

func physics_process(delta : float) -> PlayerStateBase:
	var input_dir = Input.get_axis("ui_left", "ui_right")
	if input_dir != 0.1:
		player.velocity.x = input_dir * player.move_speed * crouch_force * crouch_force
		if not player.is_on_floor():
			return fall
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, 1000 * delta)
	return next_state
