extends RefCounted


class_name SettingsCollection

@export
var settings := {}:
	set(val):
		SEAL.logger.err("This variable is not meant to be set directly, but rather appended to with new settings.")


func serialize(path):
	var dict = Dictionary()
	for setting:Setting in settings.values():
		var ret = setting.serializer_method.call()
		if ret is Dictionary:
			dict[ret["identifier"]] = ret
		else:
			SEAL.logger.err("Method bound to Setting.serializer_method must return dictionary.")
	GSONParser.save_to_GSON(path, dict)

##Used for deserializing settings when there is no validation layer present. Prevents unsafe setting values from being used in the code.
static func create_from_GSON(path)->SettingsCollection:
	var dict := GSONParser.load_from_GSON(path)
	var settings = {}
	for key in dict.keys():
		var raw_setting = dict[key]
		if !raw_setting is Dictionary:
			SEAL.logger.err("Serialized setting was not of type Dictionary. Skipping.")
			continue
		elif !raw_setting.has("identifier"):
			SEAL.logger.err("Serialized setting didn't have key 'identifier', skipping.")
			continue
		
		var identifier:String = raw_setting["identifier"]
		if !raw_setting.has("setting_type"):
			SEAL.logger.err("Serialized setting with name '" + identifier + "' didn't have key 'setting_type', '")
			continue
		
		var type:String = raw_setting["setting_type"]
		if !SEAL.valid_setting_types.has(type):
			SEAL.logger.err("Serialized setting with name '" + identifier + "' didn't match any valid setting types.")
			continue
		
		settings[identifier] = Setting.create_from_GSON_methods[type].call(raw_setting)
	var settings_collection = SettingsCollection.new()
	settings_collection.settings = settings
	return settings_collection

##This method is used when the settings have been validated
func deserialize(path):
	if !FileAccess.file_exists(path):
		SEAL.logger.info("SEAL couldn't find file to serialize from, using default values.")
	else:
		var dict := GSONParser.load_from_GSON(path)
		for setting:Setting in settings.values():
			#Do shit...
			var ret = setting.deserializer_method.call()
			if ret is Dictionary:
				dict[ret["identifier"]] = ret
			else:
				SEAL.logger.err("Method bound to Setting.serializer_method must return dictionary.")
