@tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton("SEAL", "res://addons/SEAL/SEAL.gd")


func _exit_tree():
	remove_autoload_singleton("SEAL")
	SEAL.valid_setting_types.erase(BoolSetting.TYPE)
