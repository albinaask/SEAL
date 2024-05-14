extends Setting

##A setting that holds a Vector3 value.
class_name Vector3Setting

const _TYPE = "Vector3Setting"

##Max valid setting value this setting can have, set in the constructor. If not, this is just set to Vector3.INF.
var max_value:Vector3

##Min valid setting value this setting can have, set in the constructor. If not, this is just set to -Vector3.INF.
var min_value:Vector3

##Can be any string and is shown as a suffix of this setting in the dialog.
var unit:String

##Refer to readme.md under the 'Advanced topics/making custom setting types/The setting' for an explanation of this madness.
static func _static_init() -> void:
	create_locked_collection_from_GSON_methods[_TYPE] = func(raw_setting:Dictionary)->Vector3Setting:
		return Vector3Setting.new(raw_setting["identifier"], raw_setting["group"], raw_setting["tooltip"], raw_setting["default_value"], raw_setting["min_value"], raw_setting["max_value"], raw_setting["unit"], true)#lock the setting

##set min and max if range is desired, unit if Desired. For other values, see the Setting.gd constructor.
func _init(identifier:String, _group:String, tooltip:String, default_value:=Vector3(), min_value:=-Vector3.INF, max_value:=Vector3.INF, unit:="", _locked:=false) -> void:
	self.min_value = min_value
	self.max_value = max_value
	self.unit = unit
	super(identifier, _group, tooltip, default_value, _TYPE, _locked)

##Returns the settings painter scene.
func get_settings_painter_scene():
	return load("res://addons/SEAL/painters/Vector3SettingsPainter.tscn")

##Returns if the supplied value is valid for this setting, aka is a Vector3 and within the min and max.
func is_value_valid(val)->bool:
	return val is Vector3 && val == val.clamp(min_value, max_value)

#----Serialization----#

##Serializes this setting Vector3o a dictionary that can be stored on disk.
func serialize()->Dictionary:
	var dict  = {}
	dict["max_value"] = max_value
	dict["min_value"] = min_value
	dict["unit"] = unit
	return serialize_base(dict)

##Deserializes the setting values from the supplied dictionary.
func deserialize(dict:Dictionary)->void:
	deserialize_base(dict)
