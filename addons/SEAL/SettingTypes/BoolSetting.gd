extends Setting

class_name BoolSetting

const _TYPE = "BoolSetting"

#Refer to readme.md under the 'Advanced topics/making custom setting types/The setting' for an explanation of this madness.
static func _static_init() -> void:
	create_locked_collection_from_GSON_methods[_TYPE] = func(raw_setting:Dictionary)->BoolSetting:
		return BoolSetting.new(raw_setting["identifier"], raw_setting["group"], raw_setting["tooltip"], raw_setting["default_value"], true)#lock the setting
	

#Constructs a setting of this type. See the Setting.gd constructor for more information.
func _init(identifier:String, group:String, tooltip:String, default_value:=false, _locked:=false) -> void:
	super(identifier, group, tooltip, default_value, _TYPE, _locked)

#Supply a boolSettingsPainter scene that will be used to paint this setting.
func get_settings_painter_scene():
	return load("res://addons/SEAL/painters/BoolSettingsPainter.tscn")

#Returns whether the supplied value is valid for this setting.
func is_value_valid(val)->bool:
	return val is bool

#----Serialization----#

##Serializes this setting into a dictionary that can be stored on disk.
func serialize()->Dictionary:
	#Since boolSetting does not need to store any additional data, no custom serialization is needed.
	return serialize_base({})

##Deserializes the setting values from the supplied dictionary.
func deserialize(dict:Dictionary)->void:
	#Since boolSetting does not contain any additional data, no custom serialization is needed.
	deserialize_base(dict)
