extends Setting

class_name Vector4Setting

const _TYPE = "Vector4Setting"

var max_value:Vector4
var min_value:Vector4
var unit:String

static func _static_init() -> void:
	create_from_GSON_methods[_TYPE] = func(raw_setting:Dictionary)->Vector4Setting:
		return Vector4Setting.new(raw_setting["identifier"], raw_setting["group"], raw_setting["tooltip"], raw_setting["default_value"], raw_setting["min_value"], raw_setting["max_value"], raw_setting["unit"], true)#lock the setting

##set min and max if range is desired
func _init(identifier:String, _group:String, tooltip:String, default_value:=Vector4(), min_value:=-Vector4.INF, max_value:=Vector4.INF, unit:="", _locked:=false) -> void:
	serializer_method = serialize
	deserializer_method = deserialize
	value_is_valid_method = is_value_valid
	self.min_value = min_value
	self.max_value = max_value
	
	self.unit = unit
	super(identifier, _group, tooltip, default_value, _TYPE, _locked)

func get_settings_painter_scene():
	return load("res://addons/SEAL/SettingTypes/Vector4SettingsPainter.tscn")

func is_value_valid(val)->bool:
	return val is Vector4 && val == val.clamp(min_value, max_value)

####Serialization

##Serializes this setting Vector4o a disctionary that can be stored as a GSON.
func serialize()->Dictionary:
	var dict  = {}
	dict["max_value"] = max_value
	dict["min_value"] = min_value
	dict["unit"] = unit
	return serialize_base(dict)

##Deserializes the setting values from the supplied dictionary. This is used in the case there is a 
func deserialize(dict:Dictionary)->void:
	max_value = dict["max_value"] if dict["max_value"] is Vector4 else Vector4.INF
	min_value = dict["min_value"] if dict["min_value"] is Vector4 else -Vector4.INF
	unit = dict["unit"] if dict["unit"] is String else ""
	deserialize_base(dict)
