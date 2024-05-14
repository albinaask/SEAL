extends Setting

##Setting that holds a float.
class_name FloatSetting

const _TYPE = "floatSetting"
##The max valid setting value this setting can have, set in the constructor. If not, this is just set to INF.
var max_value:=INF:
	set(val):
		assert(val >= min_value)
		max_value = val
		if _value != null:
			_value = clampf(_value, min_value, max_value)

##The min valid setting value this setting can have, set in the constructor. If not, this is just set to -INF.
var min_value:=-INF:
	set(val):
		assert(val <= max_value)
		min_value = val
		if _value != null:
			_value = clampi(_value, min_value, max_value)

##Can be any string and is shown as a suffix of this setting in the dialog, set in the constructor.
var unit:String

#Refer to readme.md under the 'Advanced topics/making custom setting types/The setting' for an explanation of this madness.
static func _static_init() -> void:
	create_locked_collection_from_GSON_methods[_TYPE] = func(raw_setting:Dictionary)->FloatSetting:
		return FloatSetting.new(raw_setting["identifier"], raw_setting["group"], raw_setting["tooltip"], raw_setting["default_value"], raw_setting["min_value"], raw_setting["max_value"], raw_setting["unit"], true)#lock the setting

##Set min and max if range is desired, a unit if desired and refer to the Setting.gd constructor for info on the other params.
func _init(identifier:String, _group:String, tooltip:String, default_value:=float(), min_value:=-INF, max_value:=INF, unit:="", _locked:=false) -> void:
	self.min_value = min_value
	self.max_value = max_value
	self.unit = unit
	super(identifier, _group, tooltip, default_value, _TYPE, _locked)

#Supply a floatSettingsPainter scene that will be used to paint this setting.
func get_settings_painter_scene():
	return load("res://addons/SEAL/painters/FloatSettingsPainter.tscn")

#Returns whether the supplied value is valid for this setting, aka a float and within the min and max.
func is_value_valid(val)->bool:
	return val is float && val <= max_value && val >= min_value

#----Serialization----#

##Serializes this setting into a dictionary that can be stored on disk.
func serialize()->Dictionary:
	var dict  = {}
	#The extra parameters are added to the storage dictionary.
	dict["max_value"] = max_value
	dict["min_value"] = min_value
	dict["unit"] = unit
	return serialize_base(dict)

##Deserializes the setting values from the supplied dictionary.
func deserialize(dict:Dictionary)->void:
	deserialize_base(dict)
