@tool
extends EditorPlugin

##Note that this needs to load AFTER Log.
func _enter_tree():
	assert(DirAccess.dir_exists_absolute("res://addons/logger"), "Log addon not found. Please make sure Log is installed and loaded before SEAL.")
	##Note that this autoload singleton has to be present at all times for SEAL to work at all.
	add_autoload_singleton("SEAL", "res://addons/SEAL/SEAL.gd")


func _exit_tree():
	remove_autoload_singleton("SEAL")
