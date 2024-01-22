@tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton("SEAL", "res://addons/SEAL/SEAL.gd")
	##It is crucial that the Setting type that is to be added as valid is brought into scope here. Otherwise it will not work! AKA, this must reference the value in the setting class
	SEAL.valid_setting_types.append(BoolSetting.TYPE)


func _exit_tree():
	remove_autoload_singleton("SEAL")
	SEAL.valid_setting_types.erase(BoolSetting.TYPE)
