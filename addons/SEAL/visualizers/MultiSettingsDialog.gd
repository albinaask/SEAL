extends ConfirmationDialog

var packed_settings_panel:PackedScene = load("res://addons/SEAL/visualizers/SettingsPanel.tscn")

#Stores all the panels.
var _panels:Dictionary = {}

## Adds a collection to the dialog with the given name.
func add_settings_collection(name:String, settings_collection:SettingsCollection):
	var panel:SettingsPanel = packed_settings_panel.instantiate()
	panel.name = tr(name)
	panel.settings_collection = settings_collection
	_panels[settings_collection] = panel
	$TabContainer.add_child(panel)

##Resyncs setting values of all the panels. Connected to the dialog's confirm button.
func _on_confirmed() -> void:
	for panel:SettingsPanel in _panels.values():
		panel._resync_settings()

## Removes a collection from the dialog.
func remove_collection(collection:SettingsCollection) -> void:
	var panel = _panels[collection]
	_panels.erase(collection)
	$TabContainer.remove_child(panel)
	panel.queue_free()

## Removes all the collections from the dialog.
func clear_collections() -> void:
	for collection:SettingsCollection in _panels.keys():
		remove_collection(collection)
