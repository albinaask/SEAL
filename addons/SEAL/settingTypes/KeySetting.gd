extends Setting

class_name KeySetting

const _TYPE = "KeySetting"

static func _static_init() -> void:
	create_locked_collection_from_GSON_methods[_TYPE] = func(raw_setting:Dictionary)->KeySetting:
		##We don't need to set any other members, but this can be done as needed.
		##TODO: Check whether these exist, an put null values otherwise...
		var default_value = InputEventKey.new()
		default_value.keycode = raw_setting["default_value_key_code"]
		default_value.shift_pressed = raw_setting["default_value_requires_shift"]
		default_value.ctrl_pressed = raw_setting["default_value_requires_ctrl"]
		default_value.alt_pressed = raw_setting["default_value_requires_alt"]
		return KeySetting.new(raw_setting["identifier"], raw_setting["group"], raw_setting["tooltip"], default_value, true)#lock the setting


func _init(identifier:String, group:String, tooltip:String, default_value:=InputEventKey.new(), _locked:=false) -> void:
	
	values_are_equal_method = func (value1, value2):return value1.get_keycode_with_modifiers() == value2.get_keycode_with_modifiers()
	
	super(identifier, group, tooltip, default_value, _TYPE, _locked)

func get_settings_painter_scene():
	return load("res://addons/SEAL/painters/KeySettingsPainter.tscn")

func is_value_valid(val)->bool:
	return val is InputEventKey

#----Serialization----#

##Serializes this setting into a dictionary that can be stored as a GSON.
##Since we can't store the key event as in a GSON we store its constituents.
func serialize()->Dictionary:
	var dict = serialize_base({}, false)
	dict["value_key_code"]= _value.keycode
	dict["value_requires_shift"]= _value.shift_pressed
	dict["value_requires_ctrl"]= _value.ctrl_pressed
	dict["value_requires_alt"]= _value.alt_pressed
	
	#Since we can't store the key event as in a GSON we store its constituents.
	dict["default_value_key_code"]= _value.keycode
	dict["default_value_requires_shift"]= _value.shift_pressed
	dict["default_value_requires_ctrl"]= _value.ctrl_pressed
	dict["default_value_requires_alt"]= _value.alt_pressed
	return dict

##Deserializes the setting values from the supplied dictionary. This is used in the case there is a 
func deserialize(dict:Dictionary)->void:
	var event = InputEventKey.new()
	event.keycode = dict["value_key_code"]
	event.shift_pressed = dict["value_requires_shift"]
	event.ctrl_pressed = dict["value_requires_ctrl"]
	event.alt_pressed = dict["value_requires_alt"]
	set_value(event)
	#We don't set the default value here, since we are in a locked context.
	deserialize_base(dict, false)
