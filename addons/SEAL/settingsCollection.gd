extends GSONResource


class_name SettingsCollection

@export
var settings := {}


func serialize(path):
	var dict = Dictionary()
	for setting:Setting in settings.values():
		var ret = setting.serializer_method.call()
		if ret is Dictionary:
			dict[ret["identifier"]] = ret
		else:
			SEAL.logger.err("setting.serializer() must return dictionary.")
	GSONParser.save_to_GSON(path, dict)

func deserialize(path):
	
	var dict := GSONParser.load_from_GSON(path)
	
