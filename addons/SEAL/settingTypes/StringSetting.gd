extends Setting

##Setting that holds a String.
class_name StringSetting

const _TYPE = "StringSetting"

##Refer to readme.md under the 'Advanced topics/making custom setting types/The setting' for an explanation of this madness.
static func _static_init() -> void:
	create_locked_collection_from_GSON_methods[_TYPE] = func(raw_setting:Dictionary)->StringSetting:
		return StringSetting.new(raw_setting["identifier"], raw_setting["group"], raw_setting["tooltip"], raw_setting["default_value"], true)#lock the setting

##default value must be a string. For other values, see the Setting.gd constructor.
func _init(identifier:String, _group:String, tooltip:String, default_value:="", _locked:=false) -> void:
	super(identifier, _group, tooltip, default_value, _TYPE, _locked)

##Supply a StringSettingsPainter scene that will be used to paint this setting.
func get_settings_painter_scene():
	return load("res://addons/SEAL/painters/StringSettingsPainter.tscn")

#Returns whether the supplied value is valid for this setting, aka is a string.
func is_value_valid(val)->bool:
	return val is String

#----Serialization----#

##Serializes this setting Stringo a dictionary that can be stored on disk.
func serialize()->Dictionary:
	return serialize_base({})

##Deserializes the setting values from the supplied dictionary.
func deserialize(dict:Dictionary)->void:
	deserialize_base(dict)
