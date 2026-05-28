@tool
extends EditorPlugin

var main_panel_instance: Control
var editor_container: MarginContainer
var menu_box: VBoxContainer
var btn_return: Button
var status_label: Label
var original_parent: Node
var stolen_editor: Control

func _enter_tree():
	main_panel_instance = Control.new()
	main_panel_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var bg = ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.12)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_panel_instance.add_child(bg)
	
	editor_container = MarginContainer.new()
	editor_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor_container.add_theme_constant_override("margin_bottom", 120)
	editor_container.add_theme_constant_override("margin_top", 60)
	main_panel_instance.add_child(editor_container)

	# --- The Menu Box ---
	menu_box = VBoxContainer.new()
	menu_box.set_anchors_preset(Control.PRESET_CENTER)
	menu_box.add_theme_constant_override("separation", 20)
	main_panel_instance.add_child(menu_box)
	
	var btn_tilemap = Button.new()
	btn_tilemap.text = "1. Open Level Painter (TileMap)"
	btn_tilemap.custom_minimum_size = Vector2(350, 60)
	btn_tilemap.pressed.connect(_grab_tilemap)
	menu_box.add_child(btn_tilemap)

	var btn_tileset = Button.new()
	btn_tileset.text = "2. Open Collisions Setup (TileSet)"
	btn_tileset.custom_minimum_size = Vector2(350, 60)
	btn_tileset.pressed.connect(_grab_tileset)
	menu_box.add_child(btn_tileset)
	
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_box.add_child(status_label)
	
	# --- The Return Button ---
	btn_return = Button.new()
	btn_return.text = "Save Selection & Return to 2D Tab to Paint"
	btn_return.custom_minimum_size = Vector2(0, 50)
	btn_return.set_anchors_preset(Control.PRESET_TOP_WIDE)
	btn_return.pressed.connect(_return_editor)
	btn_return.visible = false # Hidden until you actually open a tool
	main_panel_instance.add_child(btn_return)

	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	_make_visible(false)

func _exit_tree():
	_return_editor()
	if main_panel_instance:
		main_panel_instance.queue_free()

func _grab_tilemap():
	_steal(["TileMapLayerEditor", "TileMapEditor"])

func _grab_tileset():
	_steal(["TileSetEditor"])

func _steal(class_names: Array) -> void:
	_return_editor() # Ensure nothing is held
	
	var editor_root = EditorInterface.get_base_control()
	var target = null
	
	# Hunt for the specific tools
	for c_name in class_names:
		target = _find_specific_editor(editor_root, c_name)
		if target: break
	
	if target:
		original_parent = target.get_parent()
		original_parent.remove_child(target)
		
		editor_container.add_child(target)
		target.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		target.visible = true
		
		stolen_editor = target
		
		# Swap UI state
		menu_box.visible = false
		btn_return.visible = true
		status_label.text = ""
	else:
		status_label.text = "Failed! Ensure the Node is selected in the 2D tab first."

func _return_editor():
	if stolen_editor and original_parent:
		stolen_editor.get_parent().remove_child(stolen_editor)
		original_parent.add_child(stolen_editor)
		
		# CRITICAL FIX: We MUST leave this visible so Godot knows to keep the Paint Tool active!
		stolen_editor.visible = true 
		stolen_editor = null
	
	# Restore the menu UI
	if menu_box: menu_box.visible = true
	if btn_return: btn_return.visible = false
	
	# NEW: Automatically throw the user back into the 2D viewport to start painting!
	EditorInterface.set_main_screen_editor("2D")

func _find_specific_editor(current_node: Node, target_class: String) -> Node:
	if current_node.get_class() == target_class:
		return current_node
		
	for child in current_node.get_children():
		var found = _find_specific_editor(child, target_class)
		if found: return found
			
	return null

# --- Main Screen Overrides ---
func _has_main_screen(): return true
func _make_visible(visible): if main_panel_instance: main_panel_instance.visible = visible
func _get_plugin_name(): return "Tile Workspace"
func _get_plugin_icon(): return EditorInterface.get_editor_theme().get_icon("TileSet", "EditorIcons")
