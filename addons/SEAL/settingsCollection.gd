extends Node

## SettingCollections can either be defined in code, such as in "res://tests/Settings testing.tscn" or generated from a raw GSON file.
## The former is the standard and should always be used when you want to use the settings to control code.
## The latter is used to change settings while this code isn't loaded, like in game launchers, outside mod environments etc.
## This means that the settings are inferred from the GSON code, which may include typos, malware or whatever.
## When using this mode, all the validation has to be done by you, while the former handles all of that for you. 

#TODO: Make the user can conviniently access global settingsCollections as singletons... for now the simplest solution is to just add them as a property to a singleton, or to the SEAL autoload...
class_name SettingsCollection

##All the settings that are tied to this collection MUST be in this dictionary, it's NOT enough to just have them as class members!
##They also MUST have their identifier as the key in the dictionary.
@export
var _settings := {}:
	set(val):
		SEAL.logger.err("This variable is not meant to be set, and is mostly internal to SEAL.")

##Shorthand for adding a setting to the collection,so the user doesn't have to type out the identifier twice.
func add_setting(setting:Setting):
	_settings[setting.identifier] = setting

func get_setting(identifier:String)->Setting:
	SEAL.logger.err_cond_false(_settings.has(identifier), "No setting found in this collection with identifier ", false, identifier)
	return _settings[identifier]

##Stores all the settings in this collection into a dictionary that can be written to a file, shipped over the internet or whatever you like.
func serialize()->Dictionary:
	var dict = Dictionary()
	for setting:Setting in _settings.values():
		var ret = setting.serialize()
		if ret is Dictionary:
			dict[ret["identifier"]] = ret
		else:
			SEAL.logger.err("Method bound to Setting.serializer_method must return dictionary.")
	return dict
	

##This method is used to populate a SettingsCollection with data when the settings have already been defined.
func deserialize(dict:Dictionary):
	for setting:Setting in _settings.values():
		if dict.has(setting.identifier):
			setting.deserialize(dict[setting.identifier])
		else:
			SEAL.logger.dbg("deserialization source dict didn't have the key '" + setting.identifier + "', skipping this setting.")

static func create_locked_collection_from_dict(dict:Dictionary)->SettingsCollection:
	var settings_collection = SettingsCollection.new()
	for key in dict.keys():
		var raw_setting = dict[key]
		if !raw_setting is Dictionary:
			SEAL.logger.err("Serialized setting was not of type Dictionary. Skipping.")
			continue
		if !Setting.check_types_in_settings_dict(raw_setting):
			continue
		
		var type:String = raw_setting["setting_type"]
		var setting = Setting.create_locked_collection_from_GSON_methods[type].call(raw_setting)
		#We allow null return if setting is invalid.
		if setting != null && setting is Setting:
			settings_collection.add_setting(setting)
	
	#We load the settings' values.
	settings_collection.deserialize(dict)
	
	return settings_collection


#----GSON----#

##Saves the settings collection to a GSON file.
func save_to_GSON(path):
	GSONParser.save_to_GSON(path, serialize())

##Loads the settings collection from a GSON file.
func load_from_GSON(path):
	if !FileAccess.file_exists(path):
		SEAL.logger.err("SEAL couldn't find file to serialize from, aborting.")
	else:
		deserialize(GSONParser.load_from_GSON(path))

##Used for deserializing settings when there is no validation layer present. Prevents unsafe setting values from being used in the code.
static func create_locked_collection_from_GSON(path)->SettingsCollection:
	return create_locked_collection_from_dict(GSONParser.load_from_GSON(path))
