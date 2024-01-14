extends RefCounted

class_name Setting

var identifier:String
var value
var settings_type:String

##Read only
##Never serialized
var default_value:
	set(val):
		SEAL.logger.err("can't set this variable since it is read-only")

##Must return a dict 
var serializer_method:Callable

##Must take a dict as only parameter
var deserializer_method:Callable

##must take any value and return a bool
var value_is_valid_method:Callable

func _init(_identifier:String, _default_value, _settings_type:String):
	SEAL.logger.err_cond_false(serializer_method.is_valid(), "must have a serializer method")
	SEAL.logger.err_cond_false(deserializer_method.is_valid(), "must have a deserializer method")
	SEAL.logger.err_cond_false(value_is_valid_method.is_valid(), "must have a value_is_valid method")
	SEAL.logger.err_cond_null(default_value, "Default value must be set in constructor.")
	var valid = value_is_valid_method.call(_default_value)
	if !valid is bool:
		SEAL.logger.err("value_is_valid_method must return bool")
	elif !valid:
		SEAL.logger.fatal("default value must be valid")
	value = _default_value
	default_value = _default_value
	identifier = _identifier
	settings_type = _settings_type if SEAL.valid_setting_type_dict.has(_settings_type) else ""

func serialize_base(dict:Dictionary):
	dict["identifier"] = identifier
	dict["value"] = value if value_is_valid_method.call() else default_value
	dict["settings_type"] = settings_type
	dict["settings_type"] = SEAL.valid_setting_type_dict.find_key(settings_type) if settings_type != "" else "null"

func deserialize_base(dict:Dictionary):
	identifier = dict["identifier"] if dict.has("identifier") else identifier
	value = dict["identifier"] if dict.has("value") else default_value
	var settings_painter_key = dict["settings_painter"]
	if SEAL.settings_painter_dict.has(settings_painter_key):
		settings_type = settings_painter_key
	else:
		settings_type = ""
		SEAL.logger.err("invalid setting type of setting_identifier: " + identifier)
