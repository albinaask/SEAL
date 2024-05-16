# SEAL
## What is SEAL?

SEAL, or SEttings Abstraction Layer is a Godot plugin that aims to bring an easy, yet maximally flexible solution to handle user settings. Whether it is global performance settings, settings of a cloud based infrastructure or settings that is set per DLC per game world, SEAL aims to provide a streamlined solution.

With the ability to add and remove settings, set and get setting values all with one line of code each from anywhere throughout your application, we hope SEAL should not stand in the way of your other code and act as a solid building block to build your solutions around and upon. 

Saving, loading and displaying settings each requires only a few simple lines of code and can be done whenever needed. All of this is accomplished with minimum boilerplate code and aims to be well documented. While keeping the barriers to entry at an absolute minimum, the code is written in a way that makes it feasible to extend the plugin in several ways through well defined APIs and a fragmented plugin that can easily be picked apart and put toghether again with some original and some new parts. Want to add your own setting types? Sure, go ahead. Want to store the settings as part of a world file. Go right ahead.

Last but not least, SEAL is designed to be easy to learn and work with, providing example code, a thorough yet high level explanation of the design and features through this document and then guiding you through the code with extensive comments that explains what is done and why so it is easy to rewire things according to project specific needs.

SEAL is under the MIT license.

## Installation
SEAL uses the [Log](https://github.com/albinaask/Log) plugin for printing data to the console. This is a requirement for SEAL to work properly, and is shipped with SEAL. No extra install is needed.

Installing SEAL is done either through the asset store or through downloading the Github repo and copying the "addons/logger"(contains Log) and "addons/SEAL"(Contains SEAL) folders to your project/addons folder.

The addons are then enabled through checking the checkboxes under Project->Project Settings->Plugins. 

Make sure Log.gd lies above SEAL.gd in the list under Project->Project Settings->Autoloads. Correct this with the arrows for up and down.

## Using SEAL

SEAL is divided into two distinct APIs and sides, one data management API and one visualisation API. A good analogy is that in a web development context, this would be referred to as the backend and frontend, even though this is done for other reasons in SEAL, the result is similar. The data management part of SEAL uses Object derived from settings and settings Collections, the very much reassembles databases and data base objects. When they are then visualized, they are done so by settings painters inside settings panels. The guide will focus on the data management side first. 

### The setting
The setting class is the heart of the data management side of SEAL. It first and foremost represents a value that can be used in your code. It is implemented through derived classes of the Setting.gd, such as the BoolSetting, IntSetting or MultiChoiceSetting. In SEAL these are referred to as Types, one may thus create two BoolSettings, one called setting_1 and one called bool_setting_2, but they are both of the Type BoolSetting, since they both are holding Bool values.

SEAL supports the following types by default:
- BoolSetting
- IntSetting
- FloatSetting
- StringSetting
- Float and Int VectorSettings
- MultichoiceSetting
- ColorSetting
- KeySetting

Settings are created using the relevant object constructor. All settings that come natively with SEAL all need arguments that are passed to the constructor. Some passed arguments are passed to all setting types, and some arguments are unique to one or some setting types. Some of the values passed are to do with the visualization of the setting. It may seem odd at first to bundle data that has to do with the visualization of a setting with the data, but due to some limitation caused by very specific use cases SEAL must fulfil(See *visualizing settings without protocol backing* for details) this is unfortunately necessary.

All settings require the following arguments:
- identifier - This is the String that will (changing underscores for spaces (Just like Godot does in the case of exported variables) and respecting translation tables, see *translation* for details) be shown in the settings dialog as well as being the identifier for the setting when serialized onto disk
- group - The String name of the group under which the setting is visually grouped in a dialog. For all volume controls that controls gui, music and ambient souds, this would perhaps be "sounds", or a an option for V-sync would be under "display". Names can be chosen freely.
- tooltip - A string that represents the tooltip that is shown in the settings dialog when hovering over the label with the setting's name.

Most settings takes or can take more arguments, but this entirely dependent on the type, and the specs can be found as doc comments above the individual constructor:
- default_value - For built-in settings you may pass a setting default value, that the setting is reverted to and that the setting will have until the user changes it or will get if SEAL fails to load the data from disk. All settings have this as an optional parameter except for MultiChoiceSetting, which requires it. For the BoolSetting it is false and for FloatSetting it is 0.0 for example. See the values in the constructors for details on what the default value is for the current setting Types.
- min_value & max_value - Range parameters min_value & max_value. FloatSetting, IntSetting & vector setting types, e.g Vector2Setting, Vector4iSetting etc. all has optional min and max values that you may pass in to make the setting value always stay within those two values. These are set to infinity and minus infinity by default.
- \_locked - a mostly internal parameter that controls whether a setting is considered 'locked', (See *visualizing settings without protocol backing* for more details). This will almost always be left untouched.

Let's create some settings:
```
var bool_setting = BoolSetting.new("my bool setting", "test group", "this is a bool setting")

#A default value may be passed
var use_v_sync = BoolSetting.new("V-Sync", "Graphics", "Controls whether the game uses V-Sync...", true)

#A float setting that can take values between 0 and 1, with a default of 0.8.
var master_volume = FloatSetting.new("Master volume", "Sounds", "volume control", 0.8, 0, 1.0)
```

The methods `get_value()` and `set_value(val)` is used to manipulate the values of the settings. Settings always has 'valid' values, this means that `get_value()` of a BoolSetting always will return either true or false, while a float value in the specified range will be returned from a FloatSetting. There is no need to check this. 

Some examples are shown below:
```
#val will return false since no other default value was passed above, and the default of the default value is false.
var val = bool_setting.get_value()

#This returns true since the default value is set to true and it has not yet been changed.
var use_v_sync = use_v_sync.get_value()

bool_setting.set_value(true)

#val2 will return true since we set it accordingly.
var val2 = bool_setting.get_value()
```
### Settings Containers
In most cases, SEAL expects your settings to be linked to a settings container. Think of this as a data base, where the individual setting is acting as an individual entry in that data base. 

There are several pros to store them this way:
1. The entire collection may be stored inside a single file, all with one line of code.
2. The entire collection may be sent of to be visualized with a single line of code.
3. A common use case is to have a main batch of application settings in an autoload singleton for easy access in your code, since SettingsCollection extends node, this can easily be done.
4. They keep your many different settings neat and in order.

Settings collections may be used in two ways, either as a simple object:
```
var my_collection = SettingsCollection.new()
func _init():
	var bool_setting = BoolSetting.new("my bool setting", "test group", "this is a bool setting")
	var use_v_sync = BoolSetting.new("V-Sync", "Graphics", "Controls whether the game uses V-Sync...", true)
	
	my_collection.add_setting(bool_setting)
	my_collection.add_setting(use_v_sync)
	my_collection.add_setting(FloatSetting.new("Master volume", "Sounds", "volume control", 0.8, 0, 1.0))
```

Now, these can be accessed at any point as long as the "my_collection" variable is reachable from your code (aka it hasn't been collected by the garbage collector) through the following:
```
var use_v_sync = my_collection.get_setting("V-Sync")
print(use_v_sync.get_value())
```

Please note that identifier Strings are case sensitive:
```
##Global settings init
func init():
	add_setting(BoolSetting.new("V-Sync", "Graphics", "Controls whether the game uses V-Sync..."))

func somewhere_else():
	#valid
	var setting_value = GlobalSettings.get_setting("V-sync")
	
	#invalid
	var setting_value = GlobalSettings.get_setting("v_sync")
	
	#invalid
	var setting_value = GlobalSettings.get_setting("v-sync")
	
	#invalid
	var setting_value = GlobalSettings.get_setting("Vsync")
	
```


Having to fetch the setting every time it is needed get's old quick though. The other way of creating a settings collection is therefore create a class that  extends the SettingsCollection class:
```
extends SettingsCollection

#Can of course be called whatever.
class_name GlobalSettings

var v_sync_setting = BoolSetting.new("V-Sync", "Graphics", "Controls whether the game uses V-Sync...")

func _init():
	add_setting(v_sync_setting)
```

The advantage of using this approach is that we may add this class as an autoload singleton, under Project->Project settings->AutoLoads.
This means that there is easy access to these settings from anywhere with the following snippet:
```
func some_function_in_some_script():
	print("doing something")
	var use_v_sync = GlobalSettings.v_sync_setting.get_value()
```

Any number of settings collections may be created in a project, they may be used in any scope and passed around like any other variable. They are, after all just a bin to toss settings in to make them more managable.

### Serializing settings
Serialization is the process of storing objects to disk and recovering them at a later time, for example when the program is restarted or run at a later point, in layman's terms you may say that objects are loaded and saved to and from disk.

In SEAL, this is generally done on the SettingsCollection level, even though each setting has a serialize and deserialize method that can be used, they are generally less convinient since they needs to be looped over, added to dicts and then manually printed to a file, at which point the collection may just be used.

The API looks like this:
```
#Save my_collection to disk
my_collection.save_to_GSON("res://some path.GSON")

#Load the data into GlobalSettings
GlobalSettings.load_from_GSON("res://settings.GSON")
```

>[!Info]
> This is usually not how the API is used, instead the load generally used in the constructor and save after changes or upon quit.

In the context of global settings in an autoload, the following may be done:
```
extends SettingsCollection

class_name GlobalSettings

var v_sync_setting = BoolSetting.new("V-Sync", "Graphics", "Controls whether the game uses V-Sync...")

const _PATH = "user://settings/global_settings.GSON"

func _init():
	add_setting(v_sync_setting)
	#And all your other settings of course.
	
	#If no file is found, the settings all have their default values.
	if FileAccess.file_exists(_PATH):
		load_from_GSON(_PATH)

func _exit_tree():
	save_to_GSON(_PATH)
```

>[!IMPORTANT]
>Settings added to the Collection after the `load_from_GSON()` will **NOT** have their values altered.


As long as the relevant settings are in the collection, SEAL doesn't care how, when or why you serialize. It can be done at any point during the execution of the project.

The reason serialization is not automatically done by SEAL is that you as a developer should be free to store the setting data however suits you. If you want to store them as part of a JSON world file (like in [this](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html) Godot tutorial), that shouldn't be a problem for . What you may do then is use the version of GlobalSettings from the last chapter, and then just insert this code into your saving routine:

```

func save_game():
	var save_game = FileAccess.open("user://savegame.save", FileAccess.WRITE)
		#All the other code from the Godot example...

		#This is literraly it.
save_game.store_line(JSON.stringify(GlobalSettings.serialize()))
```
Loading is the reverse, but with the caveat that JSON has no support for advanced types, so storing a vector or color setting will cause it to convert to an array with N numbers, where N is the number of elements in the original vector. You would during load need to convert these back into Godot types, which is why SEAL by default uses GSON. This is a version of JSON that supports most Godot Basic types. (For more info, see section GSON).

If the settings are stored online, the SEAL API supports export and import through dictionaries. These may either be hooked directly to a data base or converted to a string to be stored. 

### GSON

GSON is a JSON lookalike file format that in addition to what JSON provides, also accept Godot Basic types as values. For example it can handle Transforms, Vectors and Colors in contrast to JSONs, by design it excludes Callables, Rids and some other obvious security vulnerabilities. It can therefore be opened in any text editor.

So Why in the world is there a custom file format when there are literally thousands of them out there, seemingly capable of doing the exact same thing? Why don't we use The built-in Resource class format or just plain JSON for example?

Scripts can be attached to resources, which technically causes a security vulnerability if you load a Resource file created by some unknown part. Even though I've never heard of this being exploited, it's an unnecessary risk to take when it is easily alleviated.

JSON on the other hand (and most general formats) can't handle Godot specific Objects, They can't store a Vector4I for example, you'd have to wrap it in a string or the like. This forces SEAL to make a conversion that takes more or less the exact same code that a custom parser would use... So then it makes sense to put in a few extra lines of code to skip wrapping and change the file ending. 

### Visualizing settings
The main reason why we care about settings in the first place is that we want our users to alter a program's behaviour in some way, for example setting whether V-Sync should be enabled or not.

SEAL enables the end user to do this through a popup called the SettingsDialog. It can be done at any point during the life cycle of the program, as long as there is a SettingsCollection to be shown.

This is done like the following:
```
func _input(event):
	if event is InputEventKey && event.keycode == KEY_ESCAPE:
		show_settings()

#Note that SEAL doesn't care how or when this is called, pressing the escape button is just an example.
func show_settings():
	#We may preload it, load it on demand or make derived classes in code, SEAL doesn't care.
	var settings_dialog_scene = load("res://addons/SEAL/visualizers/SettingsDialog.tscn")
	var settings_dialog = settings_dialog_scene.instantiate()
	#We can keep it in the tree whenever whereever, it's completely inert until we call popup.
	add_child(settings_dialog)
	#We specify the collection we want it to show before we call popup
	settings_dialog.get_node("SettingsPanel").settings_collection = GlobalSettings
	#Since this is a normal Confirmation dialog we can call any popup like command.
	settings_dialog.popup_centered()
```

>[!Note]
>Setting values are only updated once the accept button is pressed by the user.


#### Visualizing multiple SettingsCollections

In the case settings are broken up into multiple sections, you may use the MultiSettingsDialog instead of the SettingsDialog. This basically has more than one settings panel that each individually display their collections in separate tabs. This is handled exactly the same as the SettingsDialog shown above, but instead of setting the Settings_collection, you instead call the `add_settings_collection` method and pass a name as well as the collection. 

#### Visualizing settings outside of a dialog.

In SEAL, a Scene called the SettingsPanel contains the node collection that visualizes the settings, this means that you may visualize the settings anywhere, not just inside the usual dialog, just like with the Godot ColorPicker Node.

### Internationalization.
SEAL fully supports internationalization in all parts of the Visualization. It is done through inserting the setting identifiers, group names and other misc strings(like "search" for the search box etc) as keys into the csv or po file(s). See [godot documentation on serialization](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_translations.html) for more details. SEAL generally uses plain English as keys, so there is no need to create translation support in that case.
Here's an example of how to add Swedish translation for SEAL to a CSV:
```
keys,sv
use_V_sync, använd V-Sync
Controls whether the game uses V-Sync..., kontrollerar om V-sync ska användas...
group 1,Grupp 1
```

Note that either a snake case naming convention (to make them 'feel' like variables) or any other convention, including plain text may be used for the setting identifier. `use_v_sync` is just as valid as `use v-sync` as identifier of a setting, as long as the exact same identifier string is used across the code base, including case sensitivity. Snake case setting identifiers will automatically be visualized with underscores exchanged for spaces, just like Godot does when you use the @export keyword for a property. The underscores will however still be used in the code base. 


## Putting it all together in a Demo.
SEAL comes with all the above code as a demo. This can be used to either explore or to start adding global settings directly to a project. It's located under `res://addons/SEAL/demo`. It contains one class called GlobalSettings.gd, this must be added as a global singleton with the name "GlobalSettings" for the demo to work. This is done like with any other global singleton (shown [here](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html#autoload)). 

It should look like this:
![[Pasted image 20240513154717.png]]

This class contain some settings by default. There is also one main scene which has only one node, this has a script attached. This script shows a dialog when the escape button is pressed. Testing the demo is done through running the scene.


## Advanced topics
The above documentation should more than cover most users' needs. However, for some use cases more features or better customization is needed, for which SEAL offers more complex integration capabilities. Please note that this part of SEAL is made to maximize extendibility and customizability at the expense of simplicity. This may make the solutions or even the use cases hard to grasp. If there is any questions, please visit the Discussions tab on the github page for the project and I'll do my best to answer and offer support.

### Visualizing settings without protocol backing

SettingsCollections with neatly defined setting properties are great, however they have their limitations. Consider the use case where you are making a launcher for your game. You can manage all versions of your game from there, and don't want to load all the code of all the versions of the game every time the user runs the launcher, so you put the game code and the launcher in separate pck files like [this Godot tutorial shows](https://docs.godotengine.org/en/stable/tutorials/export/exporting_pcks.html). You still want to access global settings from the launcher however.

There are a few ways to achieve this through somehow loading in the relevant code. However all of the ones I've come up with are either not supported by Godot or will inadvertently end in a giant mess of hacky, buggy and worse, undebuggable code.  So to solve this?

SEAL has a built-in solution for just the case where it is inconvenient to access the SettingsCollection code. The idea is that a generic SettingsCollection is built from an already existing GSON file, it can then be visualized and values changed like normal with a SettingsPanel. 

It's done like following:
```
func on_show_settings_from_launcher():
	var settings_dialog_scene = load("res://addons/SEAL/visualizers/SettingsDialog.tscn")
	var settings_collection = SettingsCollection.create_locked_collection_from_GSON(path)
	
	var settings_dialog = settings_dialog_scene.instantiate()
	add_child(settings_dialog)
	
	settings_dialog.get_node("SettingsPanel").settings_collection = settings_collection
	settings_dialog.popup_centered()
```

There are a few quirks that needs to be handled by the developer as a consecuence to this apporach however.

The first of them is that this sensitive to users who manually changes the GSON file or corrupt data is written to the GSON file. If the collection is loaded the normal way, that setting is just skipped by SEAL, the default value is used and no harm is done to the program integrity

But where there is no collection to compare to, this can't be done. This means that a user may accidentally cause bugs that alter the execution pattern of the project in an unintended way. If the end user has changed the type and value for a setting, and this is handled in code without checking the type, there may either be a type error that is caught by Godot, or the result is some undefined behaviour that causes strange bugs. SEAL handles this through locking SettingsCollections that are created this way for this reason. This means in the Launcher code, setting values may neither be set nor get without an error. This may be circumvented, but doing this may cause strange and or inexplicable bugs that shows up on some users' machines and not others'. This also means default values, setting types and other parameters of the settings should not be trusted and checked for correct type and the like manually in code.

The second quirk is that if the settings are created this way before they are saved for the first time in a new location, (e.g a fresh install of the end user software or whatever). There will be no GSON file if this is not passed along with the executable. This is relatively easily fixed through bundling a default settings GSON as part of the launcher export. It is not ideal for the developer to have to remember this, another option is to store default settings somewhere within res://, this file can then be extracted and used as base for dict using the Godot builtin class ZIPReader, which should be able to read both zips and pcks.

It would be done something along the lines of the following:
```
var settings_collection
if GSON_present:
	settings_collection = SettingsCollection.create_locked_collection_from_GSON("user://settings/global_settings.GSON")
else:
	var reader = ZipReader.new()
	reader.open("user://game.pck")
	var contence = reader.read_file("res://settings/default_settings.GSON").get_string_from_utf8()
	settings_collection = SettingsCollection.create_locked_collection_from_dict(GSONParser.load_from_string(contence))
```

Thirdly settings may vary between versions of your software. This means that they may have to be added or subtracted from the settings file so that the right settings are shown for the right versions of the game. SEAL does not currently support this feature natively, but it may be added in the future depending on need.

### Making custom setting types

SEAL has quite a few setting types built in, and more will probably be added as need arises. Although, a core component of SEAL is that one should be able to extend the functionality to fit the needs of the project. We will here show how settings are implemented in SEAL, since there are quite a few binding points to get right for the implementation to work correctly. We'll show the main idea here, but the API can be used to accomplish a lot of different things, have a look around the different project files for reference. Some files and scenes that are especially suitable to have a look at:
- BoolSetting.gd&BoolSettingsPainter.tscn - For a simple setup that hasn't got too much going on. 
- Int- or FloatSetting.gd - For forcing certain values of a setting, storing extra values to the GSON and manipulating the user input of a setting field.
- KeySetting for storing Custom Objects as settings, making complex interaction behaviour.
- Setting.gd for exact implementation details on how to make settings work in realtion to their parent.
- SettingsPainter.tscn & SettingsPainter.gd for showing how the visualization works behind the scenes and when each method is called.

#### The setting
First of all Setting Object is needed to store the setting value as well as handling serialization among other things. This is done by making a script that extends the type Setting: 

```
extends Setting

class_name ColorSetting

const _TYPE = "ColorSetting"

var use_alpha:bool

```

The ColorSetting is here used as an example. The constant  \_TYPE is defined (more about this constant can be read under *setting registration*) and an option to use alpha in the setting is defined. This gives the developer the option to choose between whether the user sees a Color picker set up for RGB or RGBA. This cannot be handled by the 'Color' Godot Type by itself, so it is added as a property of the setting. The int setting has corresponding properties for min and max values in case the developer chooses to limit the range of numbers that can be used for that setting and MultiOptionSetting has the available options the user can choose from as an array property.

Next up is the constructor:
```
func _init(identifier:String, group:String, tooltip:String, default_value:=Color.BLACK, use_alpha:=false, _locked:=false) -> void:
	self.use_alpha = use_alpha
	super(identifier, group, tooltip, default_value, _TYPE, _locked)
```

The parent class Setting has a constructor that takes several arguments, these are supplied under the `super` call. The parameters are:
- identifier - The "name" of the setting, but since SEAL supports translation we want to have one identifier across the project, no matter which language the application is run by, therefore we call it the identifier.
- group - As mentioned before, we store visual related information directly on the setting object to be able to deserialize it without protocol backing.
- tooltip
- default value - This must be a **valid** setting value, checked by the is_value_valid method.
- \_TYPE - We pass the unique setting type. 
- \_locked - We must take this parameter since we need it in the static constructor (see below).
Some of these parameters are passed on for the developer to set, while \_TYPE are set to the static value that is defined above. SEAL does not care about which argument is passed onto the developer and which is set statically.

The option of RGB or RGBA mode is also passed in as an argument since this is needed to be set at constructor time.

All settings also needs a static constructor. This is a piece of code that runs when the Class first enter scope, aka just before the \_init function is run of the first object of this type. 

```
static func _static_init() -> void:
	create_locked_collection_from_GSON_methods[_TYPE] = func(raw_setting:Dictionary)->ColorSetting:
		return ColorSetting.new(raw_setting["identifier"], raw_setting["group"], raw_setting["tooltip"], raw_setting["default_value"], raw_setting["use_alpha"], true)#lock the setting
```

The part that starts with the "func(raw_setting:Dictionary)" expression is called a lambda, it is more or less used to make SEAL a way of creating this setting automatically, which is needed to visualize the setting without protocol backing. The raw_setting is an identical dictionary to the one handed of to SEAL as part of the serialization process, and will be explained there. It is important that the dictionary keys match those set there, so that it returns a setting of the correct type (an object of the current class) and that the signature matches with the constructor.

The setting is also locked as part of this call here since it is locked when the setting object is constructed with an automatic signature. 

On the topic of serialization those methods are needed:

```
func serialize()->Dictionary:
    var dict = {}
    dict["use_alpha"] = use_alpha
    return serialize_base(dict)
```

The serialize method expects a dictionary of all the members that should either be saved as part of the setting or used by the settings painter. The rule of thumb i that any extra properties added are pushed to the dict. What text is put as key is irrelevant to SEAL, but must match the deserialize method as well as the static constructor and it may only contain the letters a-z, A-Z and the special characters: underscore(\_), hyphen(-), period(.) and space( ). 

The core setting stuff, such as the value, default_value and identifier is set through the short hand method serialize_base() to which the dict is passed and returned.

Note: that if the GSON format is used, the dictionary may **ONLY** contain the following types:
- TYPE_INT
- TYPE_FLOAT
- TYPE_BOOL 
- TYPE_STRING
- TYPE_VECTOR2
- TYPE_VECTOR2I
- TYPE_RECT2
- TYPE_RECT2I
- TYPE_VECTOR3
- TYPE_VECTOR3I
- TYPE_TRANSFORM2D
- TYPE_VECTOR4
- TYPE_VECTOR4I
- TYPE_PLANE
- TYPE_QUATERNION
- TYPE_AABB
- TYPE_BASIS
- TYPE_TRANSFORM3D
- TYPE_PROJECTION
- TYPE_COLOR

Aka basic Godot types except RID, Callable and the like for security reasons. If the project doesn't intend to use GSON, any type is fine, including the non-basic types. However, then there are no security measures at hand. An example of how SEAL handles a non-basic setting value type is shown in KeySetting: 

```
func serialize()->Dictionary:
    var dict = serialize_base({}, false)
    dict["key_code"]=_value.keycode
    dict["requires_shift"]=_value.shift_pressed
    dict["requires_ctrl"]=_value.control_pressed
    dict["requires_alt"]=_value.alt_pressed
	
	dict["default_value_key_code"]= _value.keycode
    dict["default_value_requires_shift"]= _value.shift_pressed
    dict["default_value_requires_ctrl"]= _value.ctrl_pressed
    dict["default_value_requires_alt"]= _value.alt_pressed
    
    return dict
```

 Passing the non-default false flag into the serialize_base will cause the method to skip the setting value, leaving this to the developer.

Deserializing is the exact opposite procedure (KeySetting below):
```
func deserialize(dict:Dictionary)->void:
    var event = InputEventKey.new()
    event.keycode = dict["key_code"]
    event.shift_pressed = dict["requires_shift"]
    event.control_pressed = dict["requires_ctrl"]
    event.alt_pressed = dict["requires_alt"]

    deserialize_base(dict, false)
```

The following function is also needed:
```
func get_settings_painter_scene():
	return load("res://addons/SEAL/painters/ColorSettingsPainter.tscn")
```

What this should do is returning a PackedScene Resource Object that contains the settings painter scene (*more details about this below*) that this Setting should be painted with. Note that these are unique for each Setting type. Matching a new, custom type with a built-in SettingsPainter may or may not work, SEAL does not guarantee this.

There is last but not least an optional method that SEAL uses for determining whether two settings have the same value, this has a default implementation that uses the '\==' operator. This is overridden through setting the Callable 'values_are_equal_method' to a new lambda which takes two values and returns whether they equal each other or not as a bool. this is usually done in the constructor like so:
```
func _init(identifier:String, group:String, tooltip:String, default_value:=Color.BLACK, use_alpha:=false, _locked:=false) -> void:
	self.use_alpha = use_alpha
	values_are_equal_method = func(val1:Color, val2:Color):return val1.is_equal_approx(val2)
	super(identifier, group, tooltip, default_value, _TYPE, _locked)
	
```

 Another example is in KeySetting where the default implementation would compare the memory adress and not the content of the objects' compared.
#### The settingsPainter scene
To show settings in the SettingsPanel, all setting types have their own corresponding SettingsPainter Scene. This is set up as a derivative of the SettingsPainter.tscn according to the specific needs of the settings at hand. The specific content is added under /\[TheSettingsPainter]/ValueGroup by the builtin settings, but any part of this scene may be changed at will. Some Painters are very simple, like the BoolSetting or ColorSetting that only contains a CheckBox or ColorPickerButton respectively and only has a couple of lines of code attached while some requires more nodes and or more code, like the KeySetting which has more bells and whistles.

To go along with these some code is usually added, (ColorSettingsPainter code is shown below):

```
extends AbstractSettingsPainter

var _picker

func update_visuals():
	_picker = $ValueGroup/Picker
	_picker.color = _proxy_value
	_picker.edit_alpha = setting.use_alpha

func _on_value_changed(color:Color):
	_proxy_value = color

```
From top to bottom the class extends the SettingsPainter Class that goes with the scene template. Then some internal reference variables are usually stored so they don't need to be querried using a $ expression for each operation.

During the update_visuals method the visuals are made to match the setting value, so if the setting is changed from code, this is reflected in what the user sees in the panel. This is also called when the settingsPanel that the painter is part of is made visible.

the method \_on_value_change is not a method that is in any way related to SEAL, but SEAL needs to know the value of the setting when the user confirms the setting (usually through pressing the "OK" button in the SettingsDialog). 

The \_proxy_value (the intermediate setting value that the painter holds not to update the setting value before the new value is confirmed) must therefore be in sync when the time comes. Therefore it is set when suitable, but is for example bound to "button_pressed" in the BoolSettingsPainter,  "color_changed" in ColorSettingsPainter etc. More fancy varieties of this behaviour may be seen in the intSettingsPainter, vectorSettingsPainters and the KeySettingsPainter.

#### Setting registration
Finally a settings type must be registered to SEAL in order to be able to be used. This must be done before the setting type is used, generally early in  startup. SEAL does this in the autoload singleton called SEAL, but it may be done where ever. If you want to separate your code (which is generally adviced) this may be done from whereever, if you on the other hand want to submit your setting type to be part of SEAL so other people can use it, it is tacked into SEAL.gd. If the feature of visualizing without protocol backing is used, the setting class, the painter scene, the painter code, all resources and the registration code MUST be present as part of the 'base' piece of code, aka where the rest of the SEAL code lives.

The registration is simply done through calling `SEAL.valid_setting_types.append(\[SettingClassName].\_TYPE)` or the like.

In SEAL.gd, the registration of the built-in types are found:
```
func _init():
	valid_setting_types.append(BoolSetting._TYPE)
	valid_setting_types.append(FloatSetting._TYPE)
	...
```

During the init all setting types in SEAL are simply appended to the valid_settings_types array, which lives in the same class.

>[!IMPORTANT]
> Please note that you must bring the Setting class into static scope with this piece of code. This means you have to somehow reference the Class here, preferably through just using the convention of storing the type name in a constant called \_TYPE, just like SEAL does it. AKA, `valid_setting_types.append("BoolSetting")` is **NOT** enough!

## Contributing
You are more than welcome to contribute to any part of SEAL through opening an issue with a bug or suggestion, making a PR that contributes with code or documentation.

However, note that if you want to contribute with code, make sure to test your code with the /test/Settings testing.tscn before making a PR. If you need help with this or any thing else, as for help in the discussions tab on the Github page or open a PR where you state what you want to add and what you haven't goten to work and we'll figure it out.