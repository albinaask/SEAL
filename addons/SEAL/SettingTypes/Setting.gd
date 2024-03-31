extends RefCounted

class_name Setting
## Base class for settings, note that this class is ONLY meant to be inherited from. Using this class as it is is undefined.

##the name that the setting goes by in code and in GSON. 
##Note: this is the identifier for the setting name in the translation table if translating is enbled for the project.
var identifier:String

##Which visual setting group this setting should be grouped by when it is visualized for the end user.
##Note: this is the identifier for the setting group in the translation table if translating is enbled for the project.
var _group:String

var value:
	set(val):
		if !value_is_valid_method.call(val):
			SEAL.logger.err("Value is not valid, unable to set.")
		elif _locked:
			SEAL.logger.err("Setting is locked. It shouldn't be used.")
		else:
			value = val
			on_setting_changed.emit()
	get:
		if _locked:
			SEAL.logger.err("Setting is locked, using this value is unsafe and is only used internally.")
		else:
			return value

var setting_type:String
var tooltip:String

##Read only, set from the internal constructor
##Never serialized
var _locked:
	set(val):
		if _locked != null:
			SEAL.logger.err("_locked is read only.")
		_locked = val

##Read only, set from the internal constructor
##Never serialized
var default_value:
	set(val):
		if default_value != null:
			SEAL.logger.err("default value can only be set from the constructor.")
		default_value = val

##Must return a dict 
var serializer_method:Callable

##Must take a dict as only parameter
var deserializer_method:Callable

##Must take any value and return a bool
var value_is_valid_method:Callable

##Must return a PackedScene with the root node is of type SettingsPainter
var get_painter_method:Callable

##Checks whether another setting value is equal to the one that is the current value. 
##Note: Can be overridden if needed, but has a default solution that is generally working for basic types except color for which is_approx_equal() must be used.
var values_are_equal_method := func(value1, value2)->bool: 
	return value1==value2

##Dictionary of String:Callable where the string is the 'setting_type' and the Callables takes a dict with GSON info and returns valid, locked settings.
static var create_from_GSON_methods:={}

##Signal that is emitted whenever the setting is changed, either from code or visually.
signal on_setting_changed

##identifier: Should be internationally readable since this is the identifier used in the GSON file.
##
##__locked: Internal method. When a setting is loaded from a GSON only, we set this to true to make sure the program can't read settings that has not been validated.
func _init(identifier:String, _group:String, tooltip:String, default_value, setting_type:String, _locked:=false):
	SEAL.logger.err_cond_false(serializer_method.is_valid(), "Must have a serializer method.")
	SEAL.logger.err_cond_false(deserializer_method.is_valid(), "Must have a deserializer method.")
	SEAL.logger.err_cond_false(value_is_valid_method.is_valid(), "Must have a value_is_valid method.")
	SEAL.logger.err_cond_null(default_value, "Default value must be set in constructor.")
	var valid = value_is_valid_method.call(default_value)
	if !valid is bool:
		SEAL.logger.fatal("value_is_valid_method must return bool.")
	elif !valid:
		SEAL.logger.fatal("Default value must be valid.")
	self.identifier = identifier
	self._group = _group
	self.value = default_value
	self.default_value = default_value
	self.tooltip = tooltip
	if !SEAL.valid_setting_types.has(setting_type):
		SEAL.logger.fatal("Setting is not of a type that has been registered to SEAL. Make sure this is done before settings are initialized.")
	else:
		self.setting_type = setting_type
	self._locked = _locked

##Helper method for serializing the core values of a setting, meant to be called from the "serializer_method" of inherited classes
##Returns the same dictionary
func serialize_base(dict:Dictionary)->Dictionary:
	dict["identifier"] = identifier
	dict["group"] = _group
	#Should in theory always be valid...
	dict["value"] = value if value_is_valid_method.call(value) else default_value
	dict["setting_type"] = setting_type if setting_type != "" && SEAL.valid_setting_types.has(setting_type) else "null"
	dict["default_value"] = default_value
	dict["tooltip"] = tooltip
	return dict

##Helper method for deserializing the core values of a setting, meant to be called from "deserializer_method" of inherited classes
##Note: This method cannot be called if the setting is in locked state.
func deserialize_base(dict:Dictionary):
	if _locked:#See addon instructions for reference
		SEAL.logger.err("This method can only be used when setting is validated")
		return
	if !_check_types_in_settings_dict(identifier, dict):
		SEAL.logger.info("Setting had type issues, skipping deserialization")
		return
	if dict["identifier"] != identifier:
		SEAL.logger.warn("serialized setting identifier didn't match the preset, skipping. Do the key for the dict match the identifier? Did we get the wrong setting dict?")
		return
	if dict["setting_type"] != setting_type: #Settings has been changed on disk by somebody or there is a bug, either way we warn.
		SEAL.logger.warn("Serialized setting with identifier '" + identifier + "'has a setting type that differs from from the preset, Skipping.")
		return
	if !dict.has("value") ||dict["value"] != value_is_valid_method.call(dict["value"]): #Make sure we don't set the value to some corrupt or tampered value.
		SEAL.logger.warn("Serialized setting with name '" + identifier + "' didn't have key 'value', or serialized value wasn't valid. Using predefined value.")
		return
	if dict["default_value"] != default_value: #Settings has been changed on disk by somebody or there is a bug, either way we warn.
		SEAL.logger.warn("Serialized setting with name '" + identifier + "' has a default value that differs from the preset. Using predefined value.")
		return
	value = dict["value"]

static func _check_types_in_settings_dict(setting_name:String, dict:Dictionary)->bool:
	if !_parameter_is_valid(dict, "identifier", TYPE_STRING, setting_name):
		return false
	if !_parameter_is_valid(dict, "group", TYPE_STRING, setting_name):
		return false
	if !_parameter_is_valid(dict, "setting_type", TYPE_STRING, setting_name):
		return false
	if !dict.has("default_value"):
		SEAL.logger.warn("Serialized setting with name '" + setting_name + "' didn't have key 'default_value'.")
		return false
	if !dict.has("value"):
		SEAL.logger.warn("Serialized setting with name '" + setting_name + "' didn't have key 'value'.")
		return false
	
	return true

static func _parameter_is_valid(dict:Dictionary, param_name:String, value_type:Variant.Type, setting_name:String)->bool:
	if !dict.has(param_name):
		SEAL.logger.warn("Serialized setting with name '" + setting_name + "' didn't have key '" + param_name + "'")
		return false
	elif typeof(dict[param_name]) != value_type:
		SEAL.logger.warn("Serialized setting with name '" + setting_name + "' has an invalid value type of the '" + param_name + "' parameter.")
		return false
	else:
		return true

##Internal method for overriding the _locked state of the setting.[BR]
##Warning: Using this method can cause cause vunerabilities in your code since settings that aren't checked to be valid can alter your code flow in unexpected or malicious ways if you rely on them. Only use this if you know what you are doing and you implement your own fail safes.
func _froce_get():
	return value

##Internal method for overriding the _locked state of the setting.[BR]
##Warning: Using this method can cause cause vunerabilities in your code since settings that aren't checked to be valid can alter your code flow in unexpected or malicious ways if you rely on them. Only use this if you know what you are doing and you implement your own fail safes.
func _force_set(val):
	value = val
