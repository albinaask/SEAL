@tool
extends EditorPlugin


func _enter_tree():
	##Note that this autoload singleton has to be present at all times for SEAL to work at all.
	add_autoload_singleton("SEAL", "res://addons/SEAL/SEAL.gd")


func _exit_tree():
	remove_autoload_singleton("SEAL")
