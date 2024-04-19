extends Setting

##Setting that holds a String.
class_name StringSetting

const _TYPE = "StringSetting"

static func _static_init() -> void:
	create_locked_collection_from_GSON_methods[_TYPE] = func(raw_setting:Dictionary)->StringSetting:
		return StringSetting.new(raw_setting["identifier"], raw_setting["group"], raw_setting["tooltip"], raw_setting["default_value"], true)#lock the setting

##set min and max if range is desired
func _init(identifier:String, _group:String, tooltip:String, default_value:="", _locked:=false) -> void:
	super(identifier, _group, tooltip, default_value, _TYPE, _locked)

func get_settings_painter_scene():
	return load("res://addons/SEAL/painters/StringSettingsPainter.tscn")

func is_value_valid(val)->bool:
	return val is String

#----Serialization----#

##Serializes this setting Stringo a disctionary that can be stored as a GSON.
func serialize()->Dictionary:
	return serialize_base({})

##Deserializes the setting values from the supplied dictionary. This is used in the case there is a 
func deserialize(dict:Dictionary)->void:
	deserialize_base(dict)
