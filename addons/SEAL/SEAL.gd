extends Node

var logger := LogStream.new("Settings"):
	set(val):
		logger.err("can't set this variable since it is read-only")

##type_string:setting_painter_packed_scene
var valid_setting_type_dict := {}:
	set(val):
		logger.err("can't set this variable since it is read-only")

var global_setting_singletons := [] :
	set(val):
		logger.err("can't set this variable since it is read-only")
