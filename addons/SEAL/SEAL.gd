extends Node

var logger := LogStream.new("Settings"):
	set(val):
		logger.err("can't set this variable since it is read-only")

##Should only contain Strings of valid setting types.
var valid_setting_types := []:
	set(val):
		logger.err("can't set this variable since it is read-only")

func _init():
	valid_setting_types.append(BoolSetting.TYPE)
