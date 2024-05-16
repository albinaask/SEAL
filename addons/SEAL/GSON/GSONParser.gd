extends RefCounted

##This Class implements a system for storing resources as a JSON derivate called GSON, 
##the only difference being that primitive types like the Vector2 is stored as 
##[x,y] in JSON format, and is therefore indistinguishable from an array containing 
##those same values, so determining the type at deserialization is therefore impossible,
##which is unacceptable. So instead we store the vector as "Vector2(x,y)" to make the distinction.
##The reason why this is useful is that .res & .tres files can contain malicious scripts if for example downloaded.
##using this format that vunerability is adressed.
##Note: NOT thread safe
class_name GSONParser

##Valid types that are considered safe and may be serialized. 
##The reason these are considered safe is that they do not contain any classes or scripts,
##making the file safer to share without the risk for someone injecting a script into the shared 
##resource that contain malicious code to alter the game behaviour or install malware.
##Note: we don't include arrays and dicts here, since they are only valid if all members are valid, use 'validate_type' to find out...
const valid_types = {
		"int":TYPE_INT,
		"float":TYPE_FLOAT,
		"bool":TYPE_BOOL,
		"String":TYPE_STRING,
		"Vector2":TYPE_VECTOR2,
		"Vector2i":TYPE_VECTOR2I,
		"Rect2":TYPE_RECT2,
		"Rect2i":TYPE_RECT2I,
		"Vector3":TYPE_VECTOR3,
		"Vector3i":TYPE_VECTOR3I,
		"Transform2D":TYPE_TRANSFORM2D,
		"Vector4":TYPE_VECTOR4,
		"Vector4i":TYPE_VECTOR4I,
		"Plane":TYPE_PLANE,
		"Quaternion":TYPE_QUATERNION,
		"AABB":TYPE_AABB,
		"Basis":TYPE_BASIS,
		"Transform3D":TYPE_TRANSFORM3D,
		"Projection":TYPE_PROJECTION,
		"Color":TYPE_COLOR}

#internal counter variable used during GSON loading.
static var _current_index := 0
#internal variable holding the file contence, used during GSON loading.
static var _gson_string := ""


##Saves the passed dict to a file in GSON format.
static func save_to_GSON(path:String, dict:Dictionary):
	var file = FileAccess.open(path, FileAccess.WRITE)
	Log.err_cond_not_ok(FileAccess.get_open_error(), "Couldn't open '" + path  + "'. Inside of res:// in exported build? No access? No HD space?")
	file.store_string(save_to_string(dict))

##Converts the passed dict to a string in GSON format.
static func save_to_string(dict:Dictionary)->String:
	SEAL.logger.err_cond_false(validate_type(dict), "GSONParser.save_to_string() was passed an invalid dict.")
	return var_to_str(dict)

##Method for checking if the passed value is of a valid type for storing in GSON (aka only containing types that are stored in the 'valid_types' or arrays as well as dictionaries soley consisting thereof).
static func validate_type(val)->bool:
	if valid_types.values().has(typeof(val)):
		return true
	elif val is Dictionary:
		var valid = true
		for v in val.keys():
			valid = valid && validate_type(v)
		for v in val.values():
			valid = valid && validate_type(v)
		return valid
	elif val is Array:
		var valid = true
		for v in val:
			valid = valid && validate_type(v)
		return valid
	else:
		SEAL.logger.info("Value: " + str(val) + " is not of a valid type.")
		var type = typeof(val)
		return false


##Read the file at the path that contains GSON information and retrun it as a dict.
static func load_from_GSON(path:String)->Dictionary:
	if !FileAccess.file_exists(path):
		Log.err("Couldn't find file '" + path + "'")
		return {}
	return load_from_string(FileAccess.get_file_as_string(path))


##Convert the passed text string in GSON format to the corresponding dict.
static func load_from_string(string)->Dictionary:
	_current_index = 0
	_gson_string = string
	if _gson_string.is_empty():
		Log.warn("GSON string is empty")
		return {}
	if !_gson_string.begins_with("{"):
		Log.warn("GSON files must start with '{'")
		return {}
	if !_gson_string.ends_with("}"):
		Log.warn("GSON files must end with '}'")
		return {}
	_skip_whitespace()
	return _parse_value()


static func _skip_whitespace():
	while _current_index < _gson_string.length() && (_gson_string[_current_index] == ' ' || _gson_string[_current_index] == '\n' ||_gson_string[_current_index] == '\t' || _gson_string[_current_index] == '\r'):
		_current_index += 1
	#TODO: also remove comments once implemented

#parses the next value in the GSON string. The main recursive method.
static func _parse_value() -> Variant:
	var char = _gson_string[_current_index]
	var identifier := ""
	
	#build an identifier.
	if char == "[" || char == "{": #AKA object or array
		identifier = char
	elif char == "\"": #AKA string
		while true:
			identifier += char
			_current_index += 1
			char = _gson_string[_current_index]
			if char == "\"":
				identifier += char
				_current_index += 1
				break
	else:#AKA anything else
		identifier = _parse_identifier()
	
	#match the identifier to a type.
	match identifier:
		"null":
			return null
		"true":
			return true
		"false":
			return false
		"{":#aka we've found an object/dict.
			return _parse_object()
		"[":#aka we've found an array
			return _parse_array()
		"inf": return INF#Godot don't like to parse these as floats by default, so we have to do it manually.
		"inf_neg": return -INF
		"nan": return NAN
		"Array": return _parse_typed_array()
		_:#we can't easily parse this as a static string thing, we need to do more work.
			if identifier.begins_with("\"") && identifier.ends_with("\""):#We've found a string.
				return identifier.trim_prefix("\"").trim_suffix("\"") #remove surrounding "
			elif identifier.is_valid_int():#We've found an int.
				return int(identifier)
			elif identifier.is_valid_float():#We've found a float.
				return float(identifier)
			elif valid_types.keys().has(identifier): #It's a basic type.
				var data_length := 0
				var data_str := ""
				char = _gson_string[_current_index]
				while char != ")":
					data_length += 1
					_current_index += 1
					data_str += char
					char = _gson_string[_current_index]
				_current_index += 1 #move past )
				return str_to_var(identifier + data_str + ")")
			elif ClassDB.class_exists(identifier): #It's a type that GSON doesn't allow.
				Log.err("Non-builtin types are not permitted to store in GSON. Can't parse '" + identifier + "'")
				return null
			else:#We don't know what this is.
				Log.err("Invalid identifier: '" + identifier + "'")
				return null


static func _parse_identifier() -> String:
	var char = _gson_string[_current_index]
	var identifier := ""
	while (char>="A" && char<="Z") || (char>="a" && char<="z") || (char>="0" && char<="9") || char == "-" || char == "_" || char == ".":
		identifier += char
		_current_index += 1
		char = _gson_string[_current_index]
	return identifier


#Parses a dictionary.
static func _parse_object() -> Dictionary:
	_current_index += 1 # Move past opening brace
	var obj := {}
	while _gson_string[_current_index] != "}":
		_skip_whitespace()
		var key = _parse_value()
		_skip_whitespace()
		var char = _gson_string[_current_index]
		if char != ":":
			Log.err("invalid object format")
		_current_index += 1 # Move past colon
		_skip_whitespace()
		var value = _parse_value()
		obj[key] = value
		_skip_whitespace()
		if _gson_string[_current_index] == ",":
			_current_index += 1 # Move past value comma
	_current_index += 1#skipping closing brace
	return obj

#Parses an array.
static func _parse_array() -> Array:
	_current_index += 1 # Move past opening bracket
	var array: Array = []
	while _gson_string[_current_index] != "]":
		_skip_whitespace()
		var value: Variant = _parse_value()
		array.append(value)
		_skip_whitespace()
		if _gson_string[_current_index] == ",":
			_current_index += 1 # Move past comma
	_current_index += 1 # Move past closing bracket
	return array

#Parses a typed array.
static func _parse_typed_array() -> Array:
	_current_index += 1#Move past '['
	var array_type = _parse_identifier()
	_current_index += 1#Move past ']'
	_current_index += 1#Move past '('
	var array = _parse_array()
	_current_index += 1#Move past ')'
	
	for obj in array:
		if !valid_types.values().has(typeof(obj)):
			Log.err("Invalid type in typed array: " + str(obj))
			array.erase(obj)
	return array
