class_name PlayerStateFall extends PlayerStateBase

## Note: i skipped to add velocity base jump and fall, 
## i will add later 

var fall_gravity_multipilter : float = 1.126
var coyote_time : float = 0.125
var coyote_timer : float = 0.0

func init() -> void:
	pass

func enter() -> void:
	player.anim.play("fall")
	player.gravity_multipiler = fall_gravity_multipilter
	if player.prev_state == jump:
		coyote_timer = 0.0
	else:
		coyote_timer = coyote_time
	pass

func exit() -> void:
	player.gravity_multipiler = 1.0
	pass
	
func input_handle(event : InputEvent) -> PlayerStateBase:
	if event.is_action_pressed("jump"):
		if coyote_timer >0:
			return jump
	return next_state

func process(_delta : float) -> PlayerStateBase:
	return next_state

func physics_process(delta : float) -> PlayerStateBase:
	coyote_timer -= delta
	player.velocity.x = player.direction.x * player.move_speed
	if player.is_on_floor():
		if player.direction.x == 0:
			return idle
		else:
			return run
	return next_state
