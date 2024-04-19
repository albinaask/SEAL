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
	return val is bool

#----Serialization----#

##Serializes this setting into a disctionary that can be stored as a GSON.
func serialize()->Dictionary:
	#Since MultiChoiceSetting does not need to store any additional data, we need no more than this.
	return serialize_base({})

##Deserializes the setting values from the supplied dictionary. This is used in the case there is a 
func deserialize(dict:Dictionary)->void:
	#Since MultiChoiceSetting does not contain any additional data, we need no more than this.
	deserialize_base(dict)
