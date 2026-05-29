extends CanvasLayer

signal load_scene_started
signal new_scene_ready(target_name: String, offset: Vector2)
signal load_scene_finished

func scene_transition(new_scene: String, target_area: String, player_offest: Vector2, direction: String) -> void:
	load_scene_started.emit()
	# Animation Fade out
	get_tree().change_scene_to_file(new_scene)
	await get_tree().scene_changed
	new_scene_ready.emit(target_area, player_offest)
	# Animation fade in
	load_scene_finished.emit()
	pass