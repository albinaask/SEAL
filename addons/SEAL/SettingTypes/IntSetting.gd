extends Setting

class_name IntSetting

##Unique identifier for this class and thus the IntSetting type.
const _TYPE = "IntSetting"

##since INF isn't really a fan of being casted to int, we use this instead.
const BOUNDS = 1e8

##Max valid setting value this setting can have, set in the constructor. If not, this is just set to BOUNDS.
var max_value:=BOUNDS:
	set(val):
		assert(val >= min_value)
		max_value = val
		if _value != null:
			_value = clampi(_value, min_value, max_value)

##Max valid setting value this setting can have, set in the constructor. If not, this is just set to -BOUNDS.
var min_value:=-BOUNDS:
	set(val):
		assert(val <= max_value)
		min_value = val
		if _value != null:
			_value = clampi(_value, min_value, max_value)

##Can be any string and is shown as a suffix of this setting in the dialog.
var unit:String

#Refer to readme.md under the 'Advanced topics/making custom setting types/The setting' for an explanation of this madness.
static func _static_init() -> void:
	#All settings provide a similar lambda as part of the settings API. We link the setting type to a Packed scene that can be instansiated to show the setting in the dialog.
	create_locked_collection_from_GSON_methods[_TYPE] = func(raw_setting:Dictionary)->IntSetting:
		##All properties are in this case set as part of the constructor in all cases in SEAL, but this can be done however you like.
		return IntSetting.new(raw_setting["identifier"], raw_setting["group"], raw_setting["tooltip"], raw_setting["default_value"], raw_setting["min_value"], raw_setting["max_value"], raw_setting["unit"], true)

##See the Setting documentation for property descriptions. Note that only the three first arguments are required, all others are optional and has default values.
func _init(identifier:String, _group:String, tooltip:String, default_value:=0, min_value:int=-BOUNDS, max_value:int=BOUNDS, unit:="", _locked:=false) -> void:
	#Setting values that are not part of the base class.
	self.min_value = min_value
	self.max_value = max_value
	self.unit = unit
	super(identifier, _group, tooltip, default_value, _TYPE, _locked)

#Supply an IntSettingsPainter scene that will be used to paint this setting.
func get_settings_painter_scene():
	return load("res://addons/SEAL/painters/IntSettingsPainter.tscn")

##API method that checks if the supplied value is valid for this setting.
func is_value_valid(val)->bool:
	return val is int && val <= max_value && val >= min_value

#----Serialization----#

##API method that serializes this setting into a dictionary which can be passed to the GSON parser to be stored on disk.
func serialize()->Dictionary:
	var dict  = {}
	#The extra parameters are added to the storage dictionary.
	dict["max_value"] = max_value
	dict["min_value"] = min_value
	dict["unit"] = unit
	return serialize_base(dict)

##Deserializes the setting values from the supplied dictionary. This method is used when the setting is created normally, and not as part of the SettingsCollection.create_locked_collection_from_GSON([path]). 
func deserialize(dict:Dictionary)->void:
	deserialize_base(dict)
