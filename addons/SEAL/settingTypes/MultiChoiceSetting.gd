extends Setting

class_name MultiChoiceSetting

const _TYPE = "MultiChoiceSetting"

var allowed_values:Array[String] = []

static func _static_init() -> void:
	create_locked_collection_from_GSON_methods[_TYPE] = func(raw_setting:Dictionary)->MultiChoiceSetting:
		##We don't need to set any other members, but this can be done as needed.
		##TODO: Check whether these exist, an put null values otherwise...
		return MultiChoiceSetting.new(raw_setting["identifier"], raw_setting["group"], raw_setting["tooltip"], raw_setting["default_value"], raw_setting["allowed_values"], true)#lock the setting


func _init(identifier:String, group:String, tooltip:String, default_value:String, allowed_values:Array[String],  _locked:=false) -> void:
	super(identifier, group, tooltip, default_value, _TYPE, _locked)

func get_settings_painter_scene():
	return load("res://addons/SEAL/painters/MultiChoiceSettingsPainter.tscn")

func is_value_valid(val)->bool:
	return val is String && allowed_values.has(val)

#----Serialization----#

##Serializes this setting into a dictionary that can be stored as a GSON.
func serialize()->Dictionary:
	
	return serialize_base({"allowed_values":allowed_values})


func deserialize(dict:Dictionary)->void:
	allowed_values = dict["allowed_values"]
	deserialize_base(dict)
