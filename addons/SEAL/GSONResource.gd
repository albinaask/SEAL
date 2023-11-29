extends Resource

class_name GSONResource
##This Class implements a system for storing resources as a JSON derivate called GSON, 
##the only difference being that primitive types like the Vector2 is stored as 
##[x,y] in JSON format, and is therefore indistinguishable from an array containing 
##those same values, so determining the type at deserialization is therefore impossible,
##which is unacceptable. So instead we store the vector as "Vector2(x,y)" to make the distinction.
##The reason why this is useful is that .res & .tres files can contain malicious scripts if for example downloaded.
##using this format that vunerability is adressed.
##Note: Using non static variables, the type will be determined by the GSON file. This can potentially be exploited and requires you to handle this.
##Note: There is no guard against you storing for example source code as a string that is then read in and you running it as part of your code. 
##Doing that will return all the vunerabilities that this class aim to prevent. 
##Note: To see an example of how to use this class, refer to [URL].

##TODO: fix URL.

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
var _current_index := 0
#internal variable holding the file contence, used during GSON loading.
var _gson_string := ""

##Saves the properties in this object to a GSON file, see class description for a definition of GSON.
func save_as_GSON(path:String, name_black_list:=[]):
	var properties = get_property_list()
	name_black_list.append_array(["resource_local_to_scene", "resource_path", "resource_name", "script"])
	properties = properties.filter(
		func(property)->bool: 
			var usage_flag = property["usage"]
			if (usage_flag & PROPERTY_USAGE_EDITOR) && !name_black_list.has(property["name"]):
				var allowed = is_var_allowed(get(property["name"]))
				if !allowed:
					Log.dbg("Property '{prop}' of {obj} is not considered simple, or has members that aren't why it is unsafe to store these externally, skipping property.".format({"prop":property["name"], "obj":get(property["name"])}))
				return allowed
			else:
				return false
			)
	var name_value_dict = Dictionary()
	for property in properties:
		var prop_name = property["name"]
		name_value_dict[prop_name] = get(prop_name)
	var file = FileAccess.open(path, FileAccess.WRITE)
	Log.err_cond_not_ok(FileAccess.get_open_error(), "Couldn't open '" + path  + "'. Inside of res:// in exported build? No access? No HD space?")
	file.store_string(var_to_str(name_value_dict))

##Checks whether a value can be serialized, basically checks the is_valid list for valid types, and checks arrays and dicts recursively.
func is_var_allowed(val)->bool:
	if valid_types.values().any(func(comp)->bool:return typeof(val) == comp):
		return true
	if typeof(val) == TYPE_ARRAY:
		var allowed = true
		for v in val:
			allowed = allowed && is_var_allowed(v)
		return allowed
	if typeof(val) == TYPE_DICTIONARY:
		var allowed = true
		for v in val.keys():
			allowed = allowed && is_var_allowed(v)
		for v in val.values():
			allowed = allowed && is_var_allowed(v)
		return allowed
	return false

##Loads the contence of a GSON file into this object.
func load_from_GSON(path:String):
	if !FileAccess.file_exists(path):
		Log.err("Couldn't find file '" + path + "'")
		return
	_gson_string = FileAccess.get_file_as_string(path)
	if _gson_string.is_empty():
		Log.err("File access failed or is empty")
		return
	if !_gson_string.begins_with("{"):
		Log.err("GSON files must start with '{'")
		return
	if !_gson_string.ends_with("}"):
		Log.err("GSON files must end with '}'")
		return
	_skip_whitespace()
	var dict:Dictionary = _parse_value()
	for property in dict.keys():
		##TODO: check whether property exist
		set(property, dict[property])
	var spl = path.split("/", false)
	var filename = spl[spl.size()-1]
	resource_name = filename.split(".")[0]
	resource_path = path

func _skip_whitespace():
	while _current_index < _gson_string.length() && (_gson_string[_current_index] == ' ' || _gson_string[_current_index] == '\n' ||_gson_string[_current_index] == '\t' || _gson_string[_current_index] == '\r'):
		_current_index += 1
	#also remove comments

func _parse_value() -> Variant:
	var char = _gson_string[_current_index]
	var identifier := ""
	
	if char == "[" || char == "{":
		identifier = char
	else:
		var allowed_special_chars = ["\"", "-", "."]
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
			#basically check for first closing parentheses
			
			else:
				Log.err("Invalid identifier: '" + identifier + "'")
				return null

func _parse_object() -> Variant:
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

func _parse_array() -> Variant:
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
