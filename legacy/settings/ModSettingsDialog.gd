extends OWLUIDialog

var packed_settings_panel:PackedScene = load("res://core/settings/OWLSettingsPanel.tscn")
var _mod_settings_panels := []


func _init():
	OWLWorldLoader.on_mod_settings_init.connect(_preload_settings_panel)

##This is done deferred since if the loading is done async, this signal may come
##before this is inside the scene tree and therefore crash.
func _preload_settings_panel():
	var c = func():
		for mod in OWLWorldLoader.mod_loaders:
			var settings_panel = packed_settings_panel.instantiate()
			if mod.has_method(settings_panel.registry_method_name):
				settings_panel.name = mod.mod_info.name
				$TabContainer.add_child(settings_panel)
				settings_panel.settings_dict_property_name = "mod_settings"
				settings_panel.API_object = mod
				_mod_settings_panels.append(settings_panel)
	c.call_deferred()

func _on_visibility_changed():
	if visible:
		$"TabContainer/Global Settings".on_made_visible()
		for mod_settings_panel in _mod_settings_panels:
			mod_settings_panel.on_made_visible()


func _on_accept_button_pressed():
	visible = false
	#loop through all children but the first (global_settings)
	for settings_tab in $TabContainer.get_children():
		settings_tab.update_settings_array()
		settings_tab.API_object.call(settings_tab.save_method_name)
