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
	GSONParser.save_to_GSON(path, name_value_dict)

##Checks whether a value can be serialized, basically checks the is_valid list for valid types, and checks arrays and dicts recursively.
func is_var_allowed(val)->bool:
	if GSONParser.valid_types.values().any(func(comp)->bool:return typeof(val) == comp):
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
	var dict = GSONParser.load_from_GSON(path)
	for property in dict.keys():
		##TODO: check whether property exist
		set(property, dict[property])
	var spl = path.split("/", false)
	var filename = spl[spl.size()-1]
	resource_name = filename.split(".")[0]
	resource_path = path
