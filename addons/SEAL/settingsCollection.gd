extends RefCounted

## SettingCollections can either be defined in code, such as in res://tests/settings_testing.tscn or generated from a raw GSON.
## The former is the standard and should always be used when you want to use the settings to control code.
## The latter is used to change settings while this code isn't loaded, like in game launchers, outside mod environments etc.
## This means that the settings are inferred from the GSON code, which may include typos, malware or whatever.
## When using this mode, all the validation has to be done by you, while the former handles all of that for you. 
class_name SettingsCollection

##All the settings that are tied to this collection MUST be in this array, it's not enough to keep them as class members!
@export
var settings := {}:
	set(val):
		SEAL.logger.err("This variable is not meant to be set directly, but rather appended to with new settings.")


##shorthand add to avoid having to type out the name twice
func add_setting_to_dict(setting:Setting):
	settings[setting.identifier] = setting

##Stores all the settings in this collection into a dictionary that can be written to a file, shipped over the internet or whatever.
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
	var settings_collection = SettingsCollection.new()
	for key in dict.keys():
		var raw_setting = dict[key]
		if !raw_setting is Dictionary:
			SEAL.logger.err("Serialized setting was not of type Dictionary. Skipping.")
			continue
		if !Setting._check_types_in_settings_dict(key, raw_setting):
			continue
		
		var identifier:String = raw_setting["identifier"]
		var type:String = raw_setting["setting_type"]
		settings_collection.add_setting_to_dict(Setting.create_from_GSON_methods[type].call(raw_setting))
	return settings_collection

##This method is used to populate a SettingsCollection with data when the settings have already been defined.
func deserialize(path):
	if !FileAccess.file_exists(path):
		SEAL.logger.info("SEAL couldn't find file to serialize from, using default values.")
	else:
		var dict := GSONParser.load_from_GSON(path)
		for setting:Setting in settings.values():
			setting.deserializer_method.call(dict[setting.identifier])
