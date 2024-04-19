extends Setting

class_name BoolSetting

const _TYPE = "BoolSetting"


static func _static_init() -> void:
	create_locked_collection_from_GSON_methods[_TYPE] = func(raw_setting:Dictionary)->BoolSetting:
		##We don't need to set any other members, but this can be done as needed.
		##TODO: Check whether these exist, an put null values otherwise...
		return BoolSetting.new(raw_setting["identifier"], raw_setting["group"], raw_setting["tooltip"], raw_setting["default_value"], true)#lock the setting


func _init(identifier:String, group:String, tooltip:String, default_value:=false, _locked:=false) -> void:
	super(identifier, group, tooltip, default_value, _TYPE, _locked)

func get_settings_painter_scene():
	return load("res://addons/SEAL/painters/BoolSettingsPainter.tscn")

func is_value_valid(val)->bool:
	return val is bool

#----Serialization----#

##Serializes this setting into a disctionary that can be stored as a GSON.
func serialize()->Dictionary:
	#Since boolSetting does not need to store any additional data, we need no more than this.
	return serialize_base({})

##Deserializes the setting values from the supplied dictionary. This is used in the case there is a 
func deserialize(dict:Dictionary)->void:
	#Since boolSetting does not contain any additional data, we need no more than this.
	deserialize_base(dict)
