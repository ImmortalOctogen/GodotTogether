@tool
extends EditorPlugin
class_name GodotTogether

const version = "1.0.0"
const compatibility_version = 1
const ignored_dirs = [".godot", ".import", ".vscode", "addons"]

var client = GodotTogetherClient.new()
var server = GodotTogetherServer.new()
var dual = GodotTogetherDual.new()
var change_detector = GodotTogetherChangeDetector.new()

var menu: GodotTogetherMainMenu = load("res://addons/GodotTogether/src/scenes/GUI/MainMenu/MainMenu.tscn").instantiate()
var button = Button.new()

func _enter_tree():
	name = "GodotTogether"
	
	change_detector.main = self
	change_detector.name = "change_detector"
	add_child(change_detector)
	
	client.main = self
	client.name = "client"
	add_child(client)
	
	server.main = self
	server.name = "server"
	add_child(server)
	
	dual.main = self
	dual.name = "dual"
	add_child(dual)
	
	menu.main = self
	add_child(menu)
	
	menu.visible = false
	button.text = "Godot Together"
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, button)
	button.get_parent().move_child(button,button.get_index()-5)
	button.pressed.connect(menu.popup)
	

func _exit_tree():
	close_connection()
	button.queue_free()

func get_files(path: String) -> Array[String]:
	var res: Array[String] = []
	
	var dir = DirAccess.open(path)
	assert(dir, "Failed to open " + path)
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if !dir.current_is_dir():
			res.append(file_name)
		
		file_name = dir.get_next()
		
	return res

func get_dirs(path: String) -> Array[String]:
	var res: Array[String] = []
	
	var dir = DirAccess.open(path)
	assert(dir, "Failed to open " + path)
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			res.append(file_name)
		
		file_name = dir.get_next()
		
	return res

func get_fs_hash(path := "res://") -> int:
	var res = 0
	
	var dir = DirAccess.open(path)
	assert(dir, "Failed to open " + path)
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			var ignored = false
			# TODO: Check absolute paths
			for ignored_dir in ignored_dirs:
				if path + ignored_dir == "res://" + ignored_dir:
					ignored = true
					break
			if ignored: 
				file_name = dir.get_next()
				continue
			
			res += get_fs_hash(path + "/" + file_name)
		else:
			var f = FileAccess.open(path + "/" + file_name, FileAccess.READ)
			res += hash(f.get_buffer(f.get_length()))
			f.close()
		
		res += file_name.hash()
		file_name = dir.get_next()
	
	return res

func is_session_active():
	return multiplayer.has_multiplayer_peer() and Engine.is_editor_hint() and (
		client.peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED or 
		server.peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
	)

func close_connection():
	if not multiplayer.multiplayer_peer: return
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	
	user_2d_markers = []
	user_3d_markers = []
