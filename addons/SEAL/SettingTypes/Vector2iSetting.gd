extends Setting

##A setting that holds a Vector2i value.
class_name Vector2iSetting

const _TYPE = "Vector2iSetting"

##Max valid setting value this setting can have, set in the constructor. If not, this is just set to Vector2i.MAX.
var max_value:Vector2i

##Min valid setting value this setting can have, set in the constructor. If not, this is just set to Vector2i.MIN.
var min_value:Vector2i

##Can be any string and is shown as a suffix of this setting in the dialog.
var unit:String

##Refer to readme.md under the 'Advanced topics/making custom setting types/The setting' for an explanation of this madness.
static func _static_init() -> void:
	create_locked_collection_from_GSON_methods[_TYPE] = func(raw_setting:Dictionary)->Vector2iSetting:
		return Vector2iSetting.new(raw_setting["identifier"], raw_setting["group"], raw_setting["tooltip"], raw_setting["default_value"], raw_setting["min_value"], raw_setting["max_value"], raw_setting["unit"], true)#lock the setting

##Set min and max if range is desired, unit if Desired. For other values, see the Setting.gd constructor.
func _init(identifier:String, _group:String, tooltip:String, default_value:=Vector2i(), min_value:=Vector2i.MIN, max_value:=Vector2i.MAX, unit:="", _locked:=false) -> void:
	self.min_value = min_value
	self.max_value = max_value
	self.unit = unit
	super(identifier, _group, tooltip, default_value, _TYPE, _locked)

#Supply a Vector2iSettingsPainter scene that will be used to paint this setting.
func get_settings_painter_scene():
	return load("res://addons/SEAL/painters/Vector2iSettingsPainter.tscn")

#Returns whether the supplied value is valid for this setting, aka if it is a Vector2i and in the range.
func is_value_valid(val)->bool:
	return val is Vector2i && val == val.clamp(min_value, max_value)

#----Serialization----#

##Serializes this setting Vector2io a dictionary that can be stored on disk.
func serialize()->Dictionary:
	var dict  = {}
	dict["max_value"] = max_value
	dict["min_value"] = min_value
	dict["unit"] = unit
	return serialize_base(dict)

##Deserializes the setting values from the supplied dictionary.
func deserialize(dict:Dictionary)->void:
	deserialize_base(dict)
