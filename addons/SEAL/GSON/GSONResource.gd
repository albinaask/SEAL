extends Resource

##Note: Using non static variables, the type will be determined by the GSON file. This can potentially be exploited and requires you to handle this.
##Note: There is no guard against you storing for example source code as a string that is then read in and you running it as part of your code. 
##Doing that will return all the vunerabilities that this class aim to prevent. 
class_name GSONResource


##Saves the properties in this object to a GSON file, see class description for a definition of GSON.
func save_as_GSON(path:String, name_black_list:=[]):
	var properties = get_property_list()
	name_black_list.append_array(["resource_local_to_scene", "resource_path", "resource_name", "script"])
	properties = properties.filter(
		func(property)->bool: 
			var usage_flag = property["usage"]
			if (usage_flag & PROPERTY_USAGE_EDITOR) && !name_black_list.has(property["name"]):
				var allowed = GSONParser.validate_type(get(property["name"]))
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

##Loads the contence of a GSON file into this object.
func load_from_GSON(path:String):
	var dict = GSONParser.load_from_GSON(path)
	for property_name in dict.keys():
		##TODO: check whether property exist
		if get_property_list().any(func(prop:Dictionary)->bool: return prop["type"] == typeof(dict[property_name])):
			set(property_name, dict[property_name])
	var spl = path.split("/", false)
	var filename = spl[spl.size()-1]
	resource_name = filename.split(".")[0]
	resource_path = path
