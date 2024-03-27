extends Setting

class_name Vector2Setting

const _TYPE = "Vector2Setting"

var max_value:Vector2
var min_value:Vector2
var unit:String

static func _static_init() -> void:
	create_from_GSON_methods[_TYPE] = func(raw_setting:Dictionary)->Vector2Setting:
		return Vector2Setting.new(raw_setting["identifier"], raw_setting["group"], raw_setting["tooltip"], raw_setting["default_value"], raw_setting["min_value"], raw_setting["max_value"], raw_setting["unit"], true)#lock the setting

##set min and max if range is desired
func _init(identifier:String, _group:String, tooltip:String, default_value:=Vector2(), min_value:=-Vector2.INF, max_value:=Vector2.INF, unit:="", _locked:=false) -> void:
	serializer_method = serialize
	deserializer_method = deserialize
	value_is_valid_method = is_value_valid
	self.min_value = min_value
	self.max_value = max_value
	
	self.unit = unit
	super(identifier, _group, tooltip, default_value, _TYPE, _locked)

func get_settings_painter_scene():
	return load("res://addons/SEAL/SettingTypes/Vector2SettingsPainter.tscn")

func is_value_valid(val)->bool:
	return (val is Vector2 && 
		val.x <= max_value.x && val.x >= min_value.x &&
		val.y <= max_value.y && val.y >= min_value.y)

####Serialization

##Serializes this setting Vector2o a disctionary that can be stored as a GSON.
func serialize()->Dictionary:
	var dict  = {}
	dict["max_value"] = max_value
	dict["min_value"] = min_value
	dict["unit"] = unit
	return serialize_base(dict)

##Deserializes the setting values from the supplied dictionary. This is used in the case there is a 
func deserialize(dict:Dictionary)->void:
	max_value = dict["max_value"] if dict["max_value"] is Vector2 else Vector2.INF
	min_value = dict["min_value"] if dict["min_value"] is Vector2 else -Vector2.INF
	unit = dict["unit"] if dict["unit"] is String else ""
	deserialize_base(dict)
