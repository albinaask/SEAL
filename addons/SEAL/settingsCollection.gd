extends GSONResource


class_name SettingsCollection

@export
var settings := []

var link_func:Callable

func _init():
	SLAM.logger.err_cond_null(link_func, "Link func can't be null, please specify function to link settings.")
	link_func.call()

func link_int_project_setting(identifier:String, group:String, prj_settings_path:String):
	pass

func link_int_setting(indetifier:String, group:String, getter:Callable, setter:Callable):
	pass
