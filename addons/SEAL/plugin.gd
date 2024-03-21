@tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton("SEAL", "res://addons/SEAL/SEAL.gd")
	pass


func _exit_tree():
	pass
	SEAL.valid_setting_types.erase(BoolSetting.TYPE)
	remove_autoload_singleton("SEAL")
