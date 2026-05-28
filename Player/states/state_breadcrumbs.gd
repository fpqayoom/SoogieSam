@icon("res://icon.svg")
class_name StateVisualizer extends Node2D

@export_category("Target Setup")
@export var target_node: Node 
@export var state_property_name: String = "current_state" 

@export_category("Visuals")
@export var history_length: int = 120
@export var line_width: float = 4.0
@export var font_size: int = 15
@export var fade_trail: bool = true

@export_category("Advanced Features")
@export var show_velocity_arrow: bool = true
@export var show_live_log: bool = true
@export var show_collision_shape: bool = true

@export_category("NPC & AI Debugging")
@export var use_blackboard: bool = false
@export var blackboard_property: String = "blackboard" 
@export var show_attack_range: bool = false
@export var attack_range_property: String = "attack_range" 
@export var show_vision_range: bool = false
@export var vision_range_property: String = "vision_range" 
@export var show_target_line: bool = false
@export var ai_target_property: String = "current_target" 
@export var show_nav_path: bool = false
@export var nav_agent_property: String = "nav_agent" 

@export_category("Colors")
@export var custom_colors: Dictionary = {
	"idle": Color.GREEN,
	"run": Color.BLUE,
	"jump": Color.YELLOW,
	"fall": Color.RED,
	"crouch": Color.BLACK
}

var history: Array[Dictionary] = []
var state_log: Array[String] = []

func _ready() -> void:
	top_level = true
	
	if not target_node:
		target_node = get_parent()
		if not target_node:
			push_error("VISUALIZER ERROR: Target Node is empty! Assign it in the Inspector.")

func _input(event: InputEvent) -> void:
	# F12 on/off
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		visible = not visible

func _physics_process(_delta: float) -> void:
	if not visible or not target_node:
		return
		
	var current_state_obj = target_node.get(state_property_name)
	if not current_state_obj:
		return
		
	var current_state_name = ""
	if typeof(current_state_obj) == TYPE_STRING:
		current_state_name = current_state_obj.to_lower()
	elif "name" in current_state_obj:
		current_state_name = current_state_obj.name.to_lower()
	
	if history.size() > 0 and history[0].state != current_state_name:
		var log_text = history[0].state.to_upper() + " ➔ " + current_state_name.to_upper()
		state_log.push_front(log_text)
		
		# State log
		if state_log.size() > 5:
			state_log.pop_back()
			
	var frame_data = {
		"position": target_node.global_position,
		"state": current_state_name
	}
	
	history.push_front(frame_data)
	while history.size() > history_length:
		history.pop_back()
	queue_redraw()

func get_state_color(state_name: String) -> Color:
	if custom_colors.has(state_name):
		return custom_colors[state_name]
		
	var hash_val = state_name.hash()
	var hue = float(hash_val % 1000) / 1000.0
	var new_color = Color.from_hsv(hue, 0.8, 0.9)
	custom_colors[state_name] = new_color 
	return new_color

func _get_ai_property(prop_name: String) -> Variant:
	if use_blackboard and blackboard_property in target_node:
		var bb = target_node.get(blackboard_property)
		if bb is Dictionary and bb.has(prop_name):
			return bb[prop_name]
		elif typeof(bb) == TYPE_OBJECT and prop_name in bb:
			return bb.get(prop_name)
			
	if prop_name in target_node:
		return target_node.get(prop_name)
		
	return null

func _draw() -> void:
	if history.size() < 2 or not target_node:
		return
		
	var default_font = ThemeDB.fallback_font
	var drawn_labels: Array[Rect2] = [] 
	var current_pos = target_node.global_position
	
	# --- BASE VISUALIZER ---
	for i in range(history.size() - 1):
		var newer = history[i]
		var older = history[i + 1]
		var color = get_state_color(newer.state)
		var alpha = 1.0
		if fade_trail:
			alpha = 1.0 - (float(i) / float(history.size()))
			color.a *= alpha
		draw_line(older.position, newer.position, color, line_width)
		
		# Draw the exact coordinate marker and text when states change
		if older.state != newer.state:
			draw_circle(newer.position, line_width * 2.0, Color(1, 1, 1, alpha))
			
			var text = newer.state.to_upper()
			var text_size = default_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			var target_pos = newer.position + Vector2(20, -20)
			var bg_rect = Rect2(target_pos.x - 4, target_pos.y - text_size.y - 2, text_size.x + 8, text_size.y + 6)
			
			var is_overlapping = true
			var safety_loop = 0
			while is_overlapping and safety_loop < 15:
				is_overlapping = false
				for existing_rect in drawn_labels:
					if bg_rect.intersects(existing_rect.grow(2)):
						is_overlapping = true
						target_pos.y -= (text_size.y + 8) 
						bg_rect.position.y -= (text_size.y + 8)
						break 
				safety_loop += 1
				
			drawn_labels.append(bg_rect)
			var box_corner = Vector2(bg_rect.position.x, bg_rect.position.y + bg_rect.size.y)
			draw_line(newer.position, box_corner, Color(1, 1, 1, 0.5 * alpha), 1.0)
			draw_rect(bg_rect, Color(0.1, 0.1, 0.1, 0.85 * alpha)) 
			draw_string(default_font, target_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, alpha))

	if show_live_log and state_log.size() > 0:
		var log_pos = current_pos + Vector2(60, -90) 
		draw_string(default_font, log_pos, "STATE HISTORY", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.YELLOW)
		
		for i in range(state_log.size()):
			var entry = state_log[i]
			var log_alpha = 1.0 - (float(i) * 0.15) 
			draw_string(default_font, log_pos + Vector2(0, (i + 1) * (font_size + 6)), entry, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, log_alpha))

	if show_velocity_arrow and "velocity" in target_node:
		var vel: Vector2 = target_node.velocity
		if vel.length() > 5.0:
			var arrow_end = current_pos + (vel * 0.15) 
			draw_line(current_pos, arrow_end, Color.MAGENTA, 3.0)
			draw_circle(arrow_end, 4.0, Color.WHITE)

	if show_collision_shape:
		for child in target_node.get_children():
			if child is CollisionShape2D and child.shape:
				var offset = child.global_position
				if child.shape is RectangleShape2D:
					var size = child.shape.size
					var rect = Rect2(offset - (size / 2.0), size)
					draw_rect(rect, Color.CYAN, false, 2.0)
				elif child.shape is CircleShape2D:
					draw_arc(offset, child.shape.radius, 0, TAU, 32, Color.CYAN, 2.0)
				elif child.shape is CapsuleShape2D:
					var size = Vector2(child.shape.radius * 2, child.shape.height)
					var rect = Rect2(offset - (size / 2.0), size)
					draw_rect(rect, Color.CYAN, false, 2.0)
					
	# --- AI & NPC DEBUGGING ---
	if show_attack_range:
		var atk_range = _get_ai_property(attack_range_property)
		if atk_range != null and typeof(atk_range) in [TYPE_FLOAT, TYPE_INT]:
			draw_arc(current_pos, atk_range, 0, TAU, 32, Color(1, 0.2, 0.2, 0.6), 2.0)
			
	if show_vision_range:
		var vis_range = _get_ai_property(vision_range_property)
		if vis_range != null and typeof(vis_range) in [TYPE_FLOAT, TYPE_INT]:
			draw_arc(current_pos, vis_range, 0, TAU, 32, Color(1, 0.8, 0.2, 0.5), 2.0)
			
	if show_target_line:
		var ai_target = _get_ai_property(ai_target_property)
		if is_instance_valid(ai_target) and ai_target is Node2D:
			draw_dashed_line(current_pos, ai_target.global_position, Color.ORANGE_RED, 2.0, 10.0)
			draw_circle(ai_target.global_position, 6.0, Color.ORANGE_RED)
			
	if show_nav_path:
		var nav_agent = _get_ai_property(nav_agent_property)
		if is_instance_valid(nav_agent) and nav_agent is NavigationAgent2D:
			var path = nav_agent.get_current_navigation_path()
			if path.size() > 1:
				for i in range(path.size() - 1):
					draw_line(path[i], path[i+1], Color.AQUA, 2.0)
				draw_circle(path[-1], 5.0, Color.AQUA) 
