@tool
extends EditorPlugin

var panel: Control = null
var active_tileset: TileSet = null

func _enter_tree():
	var scene = load("res://addons/qutiler/main.tscn")
	if scene:
		panel = scene.instantiate()
		add_control_to_bottom_panel(panel, "qutiler")

func _exit_tree():
	if panel:
		remove_control_from_bottom_panel(panel)
		panel.queue_free()
		panel = null

func _handles(obj):
	return obj is TileSet

func _edit(obj):
	if obj is TileSet:
		active_tileset = obj
		if panel and panel.has_method("set_tileset"):
			panel.set_tileset(active_tileset)
