extends Setting

class_name MultiChoiceSetting

const _TYPE = "MultiChoiceSetting"

##The allowed values of this setting, set in the constructor.
var allowed_values:Array[String] = []

static func _static_init() -> void:
	create_locked_collection_from_GSON_methods[_TYPE] = func(raw_setting:Dictionary)->MultiChoiceSetting:
		return MultiChoiceSetting.new(raw_setting["identifier"], raw_setting["group"], raw_setting["tooltip"], raw_setting["default_value"], raw_setting["allowed_values"], true)#lock the setting

##default value must be one of the allowed values, allowed values is an array of strings. For other values, see the Setting.gd constructor.
func _init(identifier:String, group:String, tooltip:String, default_value:String, allowed_values:Array[String],  _locked:=false) -> void:
	self.allowed_values = allowed_values
	super(identifier, group, tooltip, default_value, _TYPE, _locked)

#Supply a MultiChoiceSettingsPainter scene that will be used to paint this setting.
func get_settings_painter_scene():
	return load("res://addons/SEAL/painters/MultiChoiceSettingsPainter.tscn")

#Returns whether the supplied value is valid for this setting, aka is a string and one of the allowed values.
func is_value_valid(val)->bool:
	return val is String && allowed_values.has(val)

#----Serialization----#

##Serializes this setting into a dictionary that can be stored as a GSON.
func serialize()->Dictionary:
	return serialize_base({"allowed_values":allowed_values})#Allowed values are added to the storage dictionary.

##Deserializes the setting values from the supplied dictionary.
func deserialize(dict:Dictionary)->void:
	#The allowed values are read from disk.
	deserialize_base(dict)
