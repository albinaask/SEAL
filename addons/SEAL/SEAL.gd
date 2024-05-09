extends Node

##Logger for all things SEAL. See https://github.com/albinaask/Log for reference
var logger := LogStream.new("Settings"):
	set(val):
		logger.err("can't set this variable since it is read-only")

##Add your custom setting type to this array to make it visible to SEAL. 
##Note that this MUST get the reference from inside the class, so the static constructor is invoked
var valid_setting_types:Array[String] = []:
	set(val):
		logger.err("can't set this variable since it is read-only")

##Adding the SEAL internal types, custom types can go anywhere, just make sure they are in the array before any settings of that type is constructed, either manually or from the SettingsCollection.create_locked_collection_from_GSON([path])
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
	
	valid_setting_types.append(StringSetting._TYPE)
	valid_setting_types.append(ColorSetting._TYPE)
	valid_setting_types.append(KeySetting._TYPE)
	valid_setting_types.append(MultiChoiceSetting._TYPE)
