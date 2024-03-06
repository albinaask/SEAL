extends Setting

class_name BoolSetting

const TYPE = "BoolSetting"


static func _static_init() -> void:
	create_from_GSON_methods[TYPE] = func(raw_setting:Dictionary)->BoolSetting:
		##We don't need to set any other members, but this can be done as needed.
		return BoolSetting.new(raw_setting["identifier"], raw_setting["default_value"], true)#lock the setting


func _init(identifier:String, _group:String, default_value:=false, _locked:=false) -> void:
	serializer_method = serialize
	deserializer_method = deserialize
	value_is_valid_method = is_value_valid
	super(identifier, _group, default_value, TYPE, _locked)

func get_settings_painter_scene():
	return load("res://addons/SEAL/SettingTypes/BoolSettingPainter.tscn")

func is_value_valid(val)->bool:
	return val is bool

####Serialization

##Serializes this setting into a disctionary that can be stored as a GSON.
func serialize()->Dictionary:
	#Since boolSetting does not need to store any additional data, we need no more than this.
	return serialize_base({})

##Deserializes the setting values from the supplied dictionary. This is used in the case there is a 
func deserialize(dict:Dictionary)->void:
	#Since boolSetting does not contain any additional data, we need no more than this.
	deserialize_base(dict)
