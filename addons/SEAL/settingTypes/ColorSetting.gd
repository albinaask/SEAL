extends Setting

class_name ColorSetting

const _TYPE = "ColorSetting"
var use_alpha:bool

static func _static_init() -> void:
	create_locked_collection_from_GSON_methods[_TYPE] = func(raw_setting:Dictionary)->ColorSetting:
		##We don't need to set any other members, but this can be done as needed.
		##TODO: Check whether these exist, an put null values otherwise...
		return ColorSetting.new(raw_setting["identifier"], raw_setting["group"], raw_setting["tooltip"], raw_setting["default_value"], raw_setting["use_alpha"], true)#lock the setting


func _init(identifier:String, group:String, tooltip:String, default_value:=Color.BLACK, use_alpha:=false, _locked:=false) -> void:
	self.use_alpha = use_alpha
	values_are_equal_method = func(val1:Color, val2:Color):return val1.is_equal_approx(val2)
	
	super(identifier, group, tooltip, default_value, _TYPE, _locked)
	#Colors are weird in godot.
	

func get_settings_painter_scene():
	return load("res://addons/SEAL/painters/ColorSettingsPainter.tscn")

func is_value_valid(val)->bool:
	return val is Color

#----Serialization----#

##Serializes this setting into a dictionary that can be stored as a GSON.
func serialize()->Dictionary:
	var dict = {}
	dict["use_alpha"] = use_alpha
	return serialize_base(dict)

##Deserializes the setting values from the supplied dictionary. This is used in the case there is a 
func deserialize(dict:Dictionary)->void:
	use_alpha = dict["use_alpha"]
	deserialize_base(dict)
