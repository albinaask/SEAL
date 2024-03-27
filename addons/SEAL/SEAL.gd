extends Node

var logger := LogStream.new("Settings"):
	set(val):
		logger.err("can't set this variable since it is read-only")

##Should only contain Strings of valid setting types.
var valid_setting_types := []:
	set(val):
		logger.err("can't set this variable since it is read-only")

func _init():
	valid_setting_types.append(BoolSetting._TYPE)
	
	valid_setting_types.append(FloatSetting._TYPE)
	valid_setting_types.append(Vector2Setting._TYPE)
	valid_setting_types.append(Vector3Setting._TYPE)
	valid_setting_types.append(Vector4Setting._TYPE)
	
	valid_setting_types.append(IntSetting._TYPE)
	valid_setting_types.append(Vector2iSetting._TYPE)
	valid_setting_types.append(Vector3iSetting._TYPE)
	valid_setting_types.append(Vector4iSetting._TYPE)
