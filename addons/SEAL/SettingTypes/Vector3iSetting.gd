extends Setting

##A setting that holds a Vector3i value.
class_name Vector3iSetting

const _TYPE = "Vector3iSetting"

##Max valid setting value this setting can have, set in the constructor. If not, this is just set to Vector3i.MAX.
var max_value:Vector3i
##Min valid setting value this setting can have, set in the constructor. If not, this is just set to Vector3i.MIN.
var min_value:Vector3i
##Can be any string and is shown as a suffix of this setting in the dialog.
var unit:String

##Refer to readme.md under the 'Advanced topics/making custom setting types/The setting' for an explanation of this madness.
static func _static_init() -> void:
	create_locked_collection_from_GSON_methods[_TYPE] = func(raw_setting:Dictionary)->Vector3iSetting:
		return Vector3iSetting.new(raw_setting["identifier"], raw_setting["group"], raw_setting["tooltip"], raw_setting["default_value"], raw_setting["min_value"], raw_setting["max_value"], raw_setting["unit"], true)#lock the setting

##set min and max if range is desired, unit if Desired. For other values, see the Setting.gd constructor.
func _init(identifier:String, _group:String, tooltip:String, default_value:=Vector3i(), min_value:=Vector3i.MIN, max_value:=Vector3i.MAX, unit:="", _locked:=false) -> void:
	self.min_value = min_value
	self.max_value = max_value
	
	self.unit = unit
	super(identifier, _group, tooltip, default_value, _TYPE, _locked)

##Supply a Vector3iSettingsPainter scene that will be used to paint this setting.
func get_settings_painter_scene():
	return load("res://addons/SEAL/painters/Vector3iSettingsPainter.tscn")

##Returns whether the supplied value is valid for this setting, aka if it is a Vector3i and in the range.
func is_value_valid(val)->bool:
	return val is Vector3i && val == val.clamp(min_value, max_value)


#----Serialization----#

##Serializes this setting into a dictionary that can be stored on disk.
func serialize()->Dictionary:
	var dict  = {}
	dict["max_value"] = max_value
	dict["min_value"] = min_value
	dict["unit"] = unit
	return serialize_base(dict)

##Deserializes the setting values from the supplied dictionary.
func deserialize(dict:Dictionary)->void:
	deserialize_base(dict)
