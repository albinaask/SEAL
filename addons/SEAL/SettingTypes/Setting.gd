extends RefCounted

##Base class for settings, note that this class is ONLY meant to be inherited from. Using this class as it is, is undefined.
##Has common functions and variables that is used for all setting types.
##Also stores some info that is used during the visualisation process, but that needs to be serialized for use when the setting definitions are not available.

##For an example on how to set up a basic setting, see IntSetting
##For an example on how to set up a more complex setting with a non primitive type, see KeySetting
class_name Setting

##The name that the setting goes by in code and in GSON. 
##Note: this is the identifier for the setting name in the translation table if translating is enbled for the project.[br] 
##The translated name will then be visible in the settings interface.
var identifier:String

##Which visual setting group this setting should be grouped by when it is visualized for the end user.
##Note: this is the identifier for the setting group in the translation table if translating is enbled for the project.
var _group:String

##Internal variable that is unsafe. You should probably use set_value() and get_value() methods instead.
##Do not use unless you know what you are doing and using proper protection.
var _value

##Settings have a type that must be unique. See any of the built in settings for examples.
##Note: New settings must be registred during the startup sequence before any deserialization is done.
var setting_type:String

##The visual tooltip that should be shown in the settings dialog.
var tooltip:String

##Mostly internal value that is read only, set from the internal constructor.
##Should never be serialized and doing so causes bugs.
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


##Checks whether two values is equal to eachother in the context of this setting, mostly used for the color setting(WIP) since the equals operator on godot colors are fiddely. 
##Note: Can be overridden if needed, but has a default implementation that is generally working for mosttypes.
var values_are_equal_method := func(value1, value2)->bool: 
	return value1==value2

##Dictionary of String:Callable where the string is the 'setting_type' and the Callables takes a dict with GSON info and returns a valid, locked setting.
static var create_locked_collection_from_GSON_methods:={}

##Signal that is emitted whenever the setting is changed, either from code or visually.
signal on_setting_changed

##identifier: Should be internationally readable, UTF-8-coded and not using spaces since this is the identifier used in the GSON file. (See Setting.identidfier for more info)
##group: The visual group that this settings should be visualised alongside with in the settings dialog. E.g "Sounds", "Graphics", etc.
##tooltip: The visual tooltip that should be shown in the settings dialog.
##default_value: The default value that the setting should revert to visually and has initially when the setting is first created, setting value is set to this before any is loaded from a GSON file or the like, and if no value is serialized into this setting, it has this value until somebody changes it, either in code or visually.
##setting_type: The type of setting that should be used. See any of the built in settings for examples. Usually hidden by a sub class.
##__locked: Internal parameter for locking the setting. When a setting is loaded from a GSON only, we set this to true to make sure the program can't read settings that has not been validated. Usually nobydy should need to touch this ;)
func _init(identifier:String, group:String, tooltip:String, default_value, setting_type:String, _locked:=false):
	SEAL.logger.err_cond_false(get_method_list().any(func(dict:Dictionary):return dict["name"] == "serialize"), "Must have a serializer method.")
	SEAL.logger.err_cond_false(get_method_list().any(func(dict:Dictionary):return dict["name"] == "deserialize"), "Must have a deserializer method.")
	SEAL.logger.err_cond_false(get_method_list().any(func(dict:Dictionary):return dict["name"] == "is_value_valid"), "Must have a is_value_valid method.")
	SEAL.logger.err_cond_null(default_value, "Default value must be set in constructor.")
	var valid = call("is_value_valid", default_value)
	assert(valid is bool, "Return of method is_value_valid must be of type bool.")
	if !valid:
		SEAL.logger.fatal("Default value must be valid.")
	self.identifier = identifier
	self._group = group
	_value = default_value
	self.default_value = default_value
	self.tooltip = tooltip
	if !SEAL.valid_setting_types.has(setting_type):
		SEAL.logger.fatal("Setting is not of a type that has been registered to SEAL. Make sure this is done before settings are initialized.")
	else:
		self.setting_type = setting_type
	self._locked = _locked

##Main method for getting the value of this setting. Should always return a valid value of the type that you expect from the setting subclass that's inherited.
func get_value():
	SEAL.logger.err_cond_false(!_locked, "Setting value is locked since it is not properly validated and should not be used.")
	assert(call("is_value_valid", _value), "Value is invalid.")
	return _value

##Main method for setting the value of this setting. Should always return a valid value of the type that you expect from the setting subclass that's inherited.
func set_value(val):
	if call("is_value_valid", val):
		_value = val
	else:
		SEAL.logger.err("Value is invalid, skipping.")

#--Serialization--#

##Helper method for serializing the values every setting has, meant to be called from the "serializer_method" of inherited classes.
##dict - the dictionary that should be serialized.
##serialize_value - whether the value should be serialized automatically or whether it should be serialized manually.
##Returns the same dictionary.
func serialize_base(dict:Dictionary, serialize_value:=true)->Dictionary:
	dict["identifier"] = identifier
	dict["group"] = _group
	#Should in theory always be valid...but we check anyways.
	if serialize_value:
		dict["default_value"] = default_value
		if call("is_value_valid", _value):
			dict["value"] = _value
	dict["setting_type"] = setting_type if setting_type != "" && SEAL.valid_setting_types.has(setting_type) else "null"
	dict["tooltip"] = tooltip
	return dict

##Helper method for deserializing the values every setting has, meant to be called from "deserializer_method" of inherited classes
##dict - the dictionary that should be deserialized.
##serialize_value - whether the value should be serialized automatically, if not, this method acts mostly as a check to see if there are any issues in the GSON.
func deserialize_base(dict:Dictionary, serialize_value:=true)->void:
	if !check_types_in_settings_dict(dict):
		SEAL.logger.info("Setting had type issues, skipping deserialization")
		return
	if dict["identifier"] != identifier:
		SEAL.logger.warn("Serialized setting identifier didn't match the preset, skipping. Do the key for the dict match the identifier? Did we get the wrong setting dict?")
		return
	if dict["setting_type"] != setting_type: #Settings has been changed on disk by somebody or there is a bug, either way we warn.
		SEAL.logger.warn("Serialized setting with identifier '" + identifier + "'has a setting type that differs from from the preset, Skipping.")
		return
	if serialize_value && !call("is_value_valid", dict["value"]): #Make sure we don't set the value to some corrupt or tampered value.
		SEAL.logger.warn("Serialized setting with name '" + identifier + "' has a value that isn't valid. Using predefined value.")
		return
	if serialize_value && dict["default_value"] != default_value: #Settings has been changed on disk by somebody or there is a bug, either way we warn.
		SEAL.logger.warn("Serialized setting with name '" + identifier + "' has a default value that differs from the preset. Using predefined value.")
		return
	if serialize_value:
		set_value(dict["value"])

##Method that checks that core values in the passed dict that adheres to the standard set in the serialization API is present and of right type.
static func check_types_in_settings_dict(dict:Dictionary)->bool:
	if !parameter_is_valid(dict, "identifier", TYPE_STRING, "?"):
		return false
	if !parameter_is_valid(dict, "group", TYPE_STRING, dict["identifier"]):
		return false
	if !parameter_is_valid(dict, "setting_type", TYPE_STRING, dict["identifier"]):
		return false
	##Can't check value and default value since not all setting types have those...
	return true

##Method that checks if the parameter exists, and is valid, and if not, logs a warning.
static func parameter_is_valid(dict:Dictionary, param_name:String, value_type:Variant.Type, identifier:String)->bool:
	if !dict.has(param_name):
		SEAL.logger.warn("Serialized setting with name '" + identifier + "' didn't have key '" + param_name + "'")
		return false
	elif typeof(dict[param_name]) != value_type:
		SEAL.logger.warn("Serialized setting with name '" + identifier + "' has an invalid value type of the '" + param_name + "' parameter.")
		return false
	else:
		return true

