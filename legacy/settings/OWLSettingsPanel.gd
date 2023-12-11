extends VBoxContainer

class_name OWLSettingsPanel

##Object on which following property and methods are located, 
##usually the object which you interact with this class through
var API_object:Object : set = _set_API_object

##Name of a method that is defined on the API object. 
##Called when data has been updated and should be saved. Takes no arguments and returns nothing
var save_method_name:="save_settings"

##Name of the method on the API object where all "add_..._setting()" should be called, 
##called when the panel is building. Takes 1 argument which is the attached SettingsPanel and returns nothing. 
##It is called whenever the API object is set.
var registry_method_name:="register_settings"

##The name of the property that should exist on the API object which is a Dictionary, 
##and contains: [setting_name]:[value] where the names are strings and values corresponds to 
##the setting types defined in the method descirped in registry_method_name 
var settings_dict_property_name:="settings"

##Name of method on API_object to customly control whether a certain setting is 
##visible during current conditions, takes the setting name as single parameter 
##Returns whether the setting should be visible as a bool
##if the value is "", then this functionality is ignored 
var visibility_control_method:=""

@export var open_section_icon: Texture2D = preload("res://legacy/settings/OpenSectionIcon.png")
@export var closed_section_icon: Texture2D = preload("res://legacy/settings/ClosedSectionIcon.png")
@export var reset_icon: Texture2D = preload("res://legacy/settings/ResetSettingIcon.png")

##how tall the settings are in the list (pixels)
@export var setting_height: int = 40

@onready var _setting_container = $SettingsPane/VBoxContainer
@onready var _search_box = $titleBar/SearchBox

var _settings := []
var _group_setting_dict := {}
var _has_visibility_control_method := false

func _ready():
	assert(get_tree().root.connect("size_changed",Callable(self,"_on_root_size_changed"))==OK)


func _notification(what):
	if what == NOTIFICATION_EXIT_TREE:
		for setting in _settings:
			setting.queue_free()
		for group in _group_setting_dict.keys():
			group.queue_free()


func register_setting_inline(setting_scene_path:String, setting_name:String, group:String, default_value, tooltip:="")->BaseSetting:
	var setting:BaseSetting = load(setting_scene_path).instantiate()
	setting.tooltip_text = tooltip
	setting.set_default_value(default_value)
	setting.name = setting_name
	setting.setting_group = group
	register_setting(setting)
	return setting

func register_setting(setting:BaseSetting):
	assert(!_settings.any(func(existing:BaseSetting): return existing.name == setting.name), 
			"Setting ' " + setting.name + "' already exists in this context, please use another name")
	assert(setting.setting_group != "", "group can't be null")
	assert(setting.setting_default_value!=null, "setting_default_value must be set before added to context")
	
	#create group if not already available, then add setting
	var group_button:Button
	for button in _group_setting_dict:
		if button.text == setting.setting_group:
			group_button = button
			break
	if group_button==null:
		group_button = Button.new()
		group_button.icon = open_section_icon
		group_button.expand_icon = true
		group_button.text = setting.setting_group
		group_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		group_button.focus_mode = Control.FOCUS_CLICK
		group_button.flat = true
		group_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		group_button.name = "group_" + setting.setting_group

		group_button.connect("pressed",Callable(self,"_on_group_button_pressed").bind(group_button))
		_group_setting_dict[group_button] = [setting]
	else:
		_group_setting_dict[group_button].append(setting)
	
	_settings.append(setting)
	
	#ensure that the external settings dict has all the specified settings and
	#that they are valid. (User may have updated valid values in code, 
	#but the changes haven't gone through on disk yet) 
	if API_object:
		var name_value_dict:Dictionary
		name_value_dict = API_object.get(settings_dict_property_name)
		if !name_value_dict.has(setting.name):
			name_value_dict[setting.name] = setting.setting_default_value
		elif !setting.value_is_valid(name_value_dict[setting.name]):
			name_value_dict[setting.name] = setting.setting_default_value
			Log.warn("Setting value of setting '" + setting.name + "' is not allowed, resetting to default")
			API_object.call(save_method_name)
			#TODO: reset file value to valid and mark change


##internal setter for the API object, makes sure the API object conforms to the API and registers methods
func _set_API_object(_API_object):
	API_object = _API_object
	assert(API_object.has_method(save_method_name)) #,"Can't find method '" + save_method_name + "' on API_object '" + str(API_object) + "'. Either add property with said name or redefine property 'save_method_name' to match your method pattern.")
	
	assert(API_object.has_method(registry_method_name)) #,"Can't find method '" + registry_method_name + "' on API_object '" + str(API_object) + "'. Either add property with said name or redefine property 'registry_method_name' to match your method pattern.")
	
	assert(API_object.get(settings_dict_property_name)!=null) #covers both case where property doesn't exist and is equal to null#,"Either can't find property '" + settings_dict_property_name + "' on API_object '" + str(API_object) + "' or it's equal to null. Either add property with said name, set it to a value of type Dictionary or redefine property 'settings_dict_property_name' to match your property pattern.")
	assert(API_object.get(settings_dict_property_name) is Dictionary) #,"Property '" + settings_dict_property_name + "' must be of type Dictionary.")
	_has_visibility_control_method = API_object.has_method(visibility_control_method)
	assert(visibility_control_method == "" || _has_visibility_control_method, "visibility control method indicated, but not found.")
	API_object.call(registry_method_name, self)


##connected to the panels signal with the same name
func on_made_visible():
	if is_inside_tree() && API_object!=null:#fire only if made visible and in scene tree
		var name_value_dict = API_object.get(settings_dict_property_name)
		for setting in _settings:
			if name_value_dict.has(setting.name):
				setting.setting_value = name_value_dict[setting.name]
		_paint_rows()


##Reads the settings and updates the values in the dictionary which corresponds to [settings_dict_property_name].
##Usually called when you press "done" to "save" the settings and continue your experience
func update_settings_array():
	#compose a dict with setting values
	if API_object && API_object.get(settings_dict_property_name)!=null:
		var perm_name_value_dict:Dictionary = API_object.get(settings_dict_property_name)
		
		perm_name_value_dict.clear()
		for setting in _settings:
			perm_name_value_dict[setting.name] = setting.setting_value
		
		API_object.call(save_method_name)


##Internal method for controlling the collapsing of the sections.
func _on_group_button_pressed(button:Button):
	button.icon = closed_section_icon if button.icon == open_section_icon else open_section_icon
	
	for setting in _group_setting_dict[button]:
		setting.visible = button.icon == open_section_icon && API_object.call(visibility_control_method, setting.name)

##Internal method that repaints the list of settings, 
##done when changes are made to for example the search
func _paint_rows():
	_setting_container.size.x = size.x
	
	for child in _setting_container.get_children():
		_setting_container.remove_child(child)
	
	var search_term = _search_box.text
	var visible_dict:Dictionary
	if search_term == "":
		visible_dict = _group_setting_dict
	else:
		for group in _group_setting_dict:
			for setting in _group_setting_dict[group]:
				if setting.name.count(search_term)>0:
					if !visible_dict.has(group):
						visible_dict[group] = [setting]
					else:
						visible_dict[group].append(setting)
	var groups := visible_dict.keys()
	#groups.sort_custom(Callable(self,"_sort_group_func"))
	
	for i in range(groups.size()):
		var group_button:Button = groups[i]
		_setting_container.add_child(group_button, true)
		for setting in visible_dict[group_button]:
			_setting_container.add_child(setting, true)
			setting._on_show(self)


##Internal method connected to when the text in the search box is changed.
func _on_search_changed(_new_text):
	_paint_rows()


##Internal method connected to the of the window. Makes sure that the settings fill the entire scroll panel.
func _on_root_size_changed():
	_setting_container.size.x = size.x


func _sort_group_func(button1:Button, button2:Button)->bool:
	return button1.name < button2.name


##Internal method called from the when the 
func _on_setting_value_updated(updated:BaseSetting):
	if  _has_visibility_control_method:
		for setting in _settings:
			if setting != updated:
				setting.visible = API_object.call(visibility_control_method, setting.name)
	

func register_bool_setting(setting_name:String, group:String, default_value:=false, tooltip:=""):
# warning-ignore:return_value_discarded
	register_setting_inline("res://legacy/settings/types/BoolSetting.tscn", setting_name, group, default_value, tooltip)

func register_string_setting(setting_name:String, group:String, default_value:="", tooltip:=""):
# warning-ignore:return_value_discarded
	register_setting_inline("res://legacy/settings/types/StringSetting.tscn", setting_name, group, default_value, tooltip)
	
func register_option_setting(setting_name:String, group:String, valid_values:PackedStringArray, default_value:String, tooltip:=""):
	var setting = register_setting_inline("res://legacy/settings/types/OptionSetting.tscn", setting_name, group, default_value, tooltip)
	setting.valid_values = valid_values

func register_color_setting(setting_name:String, group:String, default_value:=Color.BLACK, tooltip:="", use_alpha:=false):
	var setting = register_setting_inline("res://legacy/settings/types/ColorSetting.tscn", setting_name, group, default_value, tooltip)
	setting._use_alpha = use_alpha

func register_int_setting(setting_name:String, group:String, default_value:=0, tooltip:="", unit:="", min_val:=-2147483647, max_val:=2147483647):
	var setting = register_setting_inline("res://legacy/settings/types/IntSetting.tscn", setting_name, group, default_value, tooltip)
	setting.min_val = min_val
	setting.max_val = max_val
	setting.unit=unit
	
func register_float_setting(setting_name:String, group:String, default_value:=0.0, tooltip:="", unit:="", min_val:=-INF, max_val:=INF):
	var setting = register_setting_inline("res://legacy/settings/types/FloatSetting.tscn", setting_name, group, default_value, tooltip)
	setting.min_val = min_val
	setting.max_val = max_val
	setting.unit=unit


func register_vec2_setting(setting_name:String, group:String, default_value:=Vector2(), tooltip:="", unit:="", min_val:=Vector2(-INF, -INF), max_val:=Vector2(INF, INF)):
	var setting = register_setting_inline("res://legacy/settings/types/Vec2Setting.tscn", setting_name, group, default_value, tooltip)
	setting.min_val = min_val
	setting.max_val = max_val
	setting.unit=unit
	
func register_vec3_setting(setting_name:String, group:String, default_value:=Vector3(), tooltip:="", unit:="", min_val:=Vector3(-INF, -INF, -INF), max_val:=Vector3(INF, INF, INF)):
	var setting := register_setting_inline("res://legacy/settings/types/Vec3Setting.tscn", setting_name, group, default_value, tooltip)
	setting.min_val = min_val
	setting.max_val = max_val
	setting.unit=unit


func register_key_setting(setting_name:String, group:String, key_scan_code:Key, tooltip := "", shift_required:=false, control_required:=false, alt_required:=false):
	var val := InputEventKey.new()
	val.keycode = key_scan_code
	val.shift_pressed = shift_required
	val.ctrl_pressed = control_required
	val.alt_pressed = alt_required
# warning-ignore:return_value_discarded
	register_setting_inline("res://legacy/settings/types/KeySetting.tscn", setting_name, group, val, tooltip)

