extends RefCounted


class_name GSONParser
##NOT thread safe

##valid types that are considered safe and may be serialized. 
##The reason these are considered safe is that they do not contain any classes or scripts,
##making the file safer to share without the risk for someone injecting a script into the shared 
##resource that contain malicious code to alter the game behaviour or install malware.
##Note: do not include arrays and dicts since they are only valid if all members are valid, use is_var_valid to find out...
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
	file.store_string(var_to_str(dict))

##get the file containing the GSON information as a dict.
static func load_from_GSON(path:String)->Dictionary:
	if !FileAccess.file_exists(path):
		Log.err("Couldn't find file '" + path + "'")
		return {}
	return load_from_string(FileAccess.get_file_as_string(path))


##Convert the passed text string in GSON_format to the corresponding dict
static func load_from_string(string)->Dictionary:
	_current_index = 0
	_gson_string = string
	if _check_problems():
		return {}
	_skip_whitespace()
	return _parse_value()
	
##returns whether error
static func _check_problems()->bool:
	if _gson_string.is_empty():
		Log.err("File access failed or is empty")
		return true
	if !_gson_string.begins_with("{"):
		Log.err("GSON files must start with '{'")
		return true
	if !_gson_string.ends_with("}"):
		Log.err("GSON files must end with '}'")
		return true
	return false

static func _skip_whitespace():
	while _current_index < _gson_string.length() && (_gson_string[_current_index] == ' ' || _gson_string[_current_index] == '\n' ||_gson_string[_current_index] == '\t' || _gson_string[_current_index] == '\r'):
		_current_index += 1
	#also remove comments

static func _parse_value() -> Variant:
	var char = _gson_string[_current_index]
	var identifier := ""
	
	if char == "[" || char == "{":
		identifier = char
	else:
		var allowed_special_chars = ["\"", "-", ".", "_", " "]
		while (char>="A" && char<="Z") || (char>="a" && char<="z") || (char>="0" && char<="9") || allowed_special_chars.has(char):
			identifier += char
			_current_index += 1
			char = _gson_string[_current_index]
	
	match identifier:
		"null":
			return null
		"true":
			return true
		"false":
			return false
		"{":
			return _parse_object()
		"[":
			return _parse_array()
		_:
			if identifier.begins_with("\"") && identifier.ends_with("\""):
				return identifier.trim_prefix("\"").trim_suffix("\"") #remove surrounding "
			elif identifier.is_valid_int():
				return int(identifier)
			elif identifier.is_valid_float():
				return float(identifier)
			elif valid_types.keys().has(identifier):
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
			elif identifier == "inf":
				return INF
			elif identifier == "inf_neg":
				return -INF
			elif identifier == "nan":
				return NAN
			else:
				Log.err("Invalid identifier: '" + identifier + "'")
				return null

static func _parse_object() -> Variant:
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

static func _parse_array() -> Variant:
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
