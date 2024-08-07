extends Node

## Class that implements some tests and acts as an example of how to use the addon.

##For testing purposes we use a file inside of res://, using the addon in production code, you probably want a file under user://, but it does not matter for the plugin.
var path = "res://tests/test_setting_collection.GSON"
##settings available and valid from anywhere!
var initial_collection := TestSettingCollection.new()
##A reference to the SettingsDialog object.
@onready
var settings_panel:SettingsPanel = $SettingsDialog/SettingsPanel

func _init():
	#We only find this file if test has crashed, mainly included for illustrative purposes to show how it may be done.
	if FileAccess.file_exists(path):
		#Must be done befre acessing the settings, but can theoretically be done anywhere. Just remember that the settings has default values before this and that you override any values by calling this method.
		initial_collection.load_from_GSON(path)

func _ready():
	#These two go hand in hand, poping up the dialog without settings will show no settings, setting the collecion will not make the dialog show up. You just link them together.	
	settings_panel.settings_collection = initial_collection
	#We can construct the Settings dialog whenever we want to view the settings, does not need to be in ready.
	#We show the dialog whenever, but now done to test. We can also hide and repopup however. SEAL does not care.
	$SettingsDialog.popup_centered()

##Method that is connected to the accept signal of the dialog. Not part of the addon API and you may omit this entirely. 
func _on_settings_dialog_confirmed() -> void:
	#Since the method is connected to both the initial and the rerun, we only want the code to run on the first run.
	if settings_panel.settings_collection == initial_collection:
		#Save all the settings to disk.
		initial_collection.save_to_GSON(path)
		#Access any setting value from any part of the code as long as it is not initialized as locked.
		#Note: The setting values are updated when the accept button is pressed, not when they are updated in the dialog.
		print(initial_collection.test_setting_1.get_value())
		
		#Since this is a node that is not part of the scene tree, we have to free it.
		initial_collection.queue_free()
		#Makes a new settingsCollection from the same data, but this time settings should be locked since we have not done any type checks against a valid collection template.
		#This can be used when we haven't loaded the settings collection, as part of a launcher or to access DLC settings without loading the any of the DLC source code.
		var new_collection = SettingsCollection.create_locked_collection_from_GSON(path)
		#To visualize a new collection, we just set the property and calls popup.
		settings_panel.settings_collection = new_collection
		$SettingsDialog.popup_centered()
	else:
		#When we press accept second time in the test, instead land here.
		#Remove the test file.
		DirAccess.remove_absolute(path)
		#We can't use this like the other because this collection is just made from the GSON and we don not know if someone has put in incorrect values.
		#AKA, an error here equals sucess!
		print(settings_panel.settings_collection.get_setting("setting_3").get_value())
		#again, we have to free it.
		settings_panel.settings_collection.queue_free()
		



##Our settings collection. This must not be an inherited class, just making an instance of SettingsCollection is perfectly allowed, but then you can't add any short hand properties and has to access the settings through your_collection.get_setting() or whatever.
class TestSettingCollection extends SettingsCollection:
	
	##Setting here is just a short hand, settings are internally all linked to the SettingsCollection through the 
	##settings dict and must be added to that for it to work properly, but this makes it more convinient to access from outside, since you can refer to it as test_setting_1, instead of having to access it through the dict all the time.
	##Note: The shorthand setting is added to the settings dict of the collection in the constructor.
	##Note: This object can live anywhere and is in sync with the collection as long as the collection is valid and a reference to it is in the dictionary.
	var test_setting_1 = BoolSetting.new("test_setting_1", "group 1", "setting 1")
	
	func _init() -> void:
		#We add our shorthand setting to the settings dict of the collection.
		add_setting(test_setting_1)
		
		#We add some more settings that we want to test with.
		add_setting(Vector2Setting.new("setting_3", "group 2", "A Vec2 setting", Vector2(1,2), Vector2(0,0), Vector2(10,10), "kg"))
		
		#We add an int setting that has an initial value of 1, a min value of 0, a max value of 10, and a unit of "pcs"(short for pieces), but any string goes as unit.
		#Note: min value must be less than max value and default_value must lay in between.
		add_setting(IntSetting.new("setting_2", "group 2", "my special int setting", 1, 0, 10, "pcs"))
		#floats can have the same range behaviour, but we don't have to add that info. Neither do we on int.
		add_setting(FloatSetting.new("setting_4", "float group", "my special float setting"))
		add_setting(Vector2Setting.new("setting_5", "vector group", "my special vector2 setting"))
		
		#Vector settings ar the same, but we pass Vectors in as min and max values, which are the per diameter min and max.
		add_setting(Vector3Setting.new("vector3_setting", "vector group", "a Vector3 setting", Vector3(1,2,3), Vector3(-10, -10, -10), Vector3(10, 10, 10), "m"))
		add_setting(Vector4Setting.new("vector4_setting", "vector group", "a Vector4 setting", Vector4(1,2,3,4), Vector4(-10, -10, -10,-10), Vector4(10, 10, 10, 10), "m"))

		add_setting(Vector2iSetting.new("Vector2i_setting", "vector2i group", "my special Vector2i setting"))
		add_setting(Vector3iSetting.new("Vector3i_setting", "vector3i group", "my special Vector3i setting"))
		add_setting(Vector4iSetting.new("Vector4i_setting", "vector4i group", "my special Vector4i setting"))
		
		add_setting(StringSetting.new("My string setting", "String group", "some tooltip"))
		add_setting(ColorSetting.new("Color", "group 2", ""))
		var def_key = InputEventKey.new()
		def_key.keycode = KEY_G
		def_key.shift_pressed = true
		add_setting(KeySetting.new("crouch", "gorup 2", "this key is used to crouch.", def_key))
		add_setting(MultiChoiceSetting.new("Multi choice", "group 2", "this is a multi choice setting", "one", ["one", "two", "three"]))


