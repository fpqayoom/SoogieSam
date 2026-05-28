@tool
extends EditorPlugin

var main_panel: Control
var vbox: VBoxContainer
var btn_steal: Button
var log_label: RichTextLabel
var scroll_container: ScrollContainer
var stolen_editor: Control
var original_parent: Node

func _enter_tree():
	main_panel = Control.new()
	main_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var bg = ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.12)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_panel.add_child(bg)
	
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10) 
	main_panel.add_child(margin)
	
	vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)

	btn_steal = Button.new()
	btn_steal.text = "RIP NATIVE ANIMATION TOOL"
	btn_steal.custom_minimum_size = Vector2(0, 60)
	btn_steal.pressed.connect(_do_steal)
	vbox.add_child(btn_steal)

	log_label = RichTextLabel.new()
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.text = "Ready.\n\n1. Select Animation node in 2D.\n2. Open this menu.\n3. Click Rip Native Tool."
	vbox.add_child(log_label)

	# --- THE SCROLL FIX ---
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll_container.hide() # Hidden until we actually steal the tool
	vbox.add_child(scroll_container)

	add_control_to_bottom_panel(main_panel, "Anim Workspace")

func _exit_tree():
	_do_return()
	if main_panel:
		remove_control_from_bottom_panel(main_panel)
		main_panel.queue_free()

func _do_steal():
	_do_return()
	log_label.text = "Hunting for Native Godot Animation UI...\n"
	var base = EditorInterface.get_base_control()
	var target = _find_anim_tool(base)

	if target:
		log_label.text += "SUCCESS: Found " + target.get_class() + "!\n"
		original_parent = target.get_parent()
		original_parent.remove_child(target)
		
		# Put the tool inside our new scroll container
		scroll_container.add_child(target)
		
		target.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		target.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		# Force the tool to be wide so the scrollbar activates
		target.custom_minimum_size = Vector2(1000, 300) 
		target.visible = true
		
		stolen_editor = target
		btn_steal.hide()
		log_label.hide()
		scroll_container.show()
	else:
		log_label.text += "\nFAILED: Could not find Godot's native tool.\n"
		log_label.text += "Make sure the AnimatedSprite2D or AnimationPlayer is selected in the 2D view first!"

func _do_return():
	if stolen_editor and original_parent:
		stolen_editor.get_parent().remove_child(stolen_editor)
		original_parent.add_child(stolen_editor)
		
		# Reset the size override so we don't break the native UI when returned
		stolen_editor.custom_minimum_size = Vector2(0, 0)
		stolen_editor.visible = false
		stolen_editor = null
	
	if is_instance_valid(btn_steal): btn_steal.show()
	if is_instance_valid(scroll_container): scroll_container.hide()
	if is_instance_valid(log_label): 
		log_label.show()
		log_label.text = "Tool returned to engine."

func _find_anim_tool(node: Node) -> Node:
	var c = node.get_class()
	if "SpriteFramesEditor" in c or "AnimationPlayerEditor" in c or "AnimationTreeEditor" in c:
		return node
	for child in node.get_children():
		var f = _find_anim_tool(child)
		if f: return f
	return null
