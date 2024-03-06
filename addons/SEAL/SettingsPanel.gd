extends VBoxContainer

class_name OWLSettingsPanel


@export var open_section_icon: Texture2D = preload("res://addons/SEAL/OpenSectionIcon.png")
@export var closed_section_icon: Texture2D = preload("res://addons/SEAL/ClosedSectionIcon.png")
@export var reset_icon: Texture2D = preload("res://addons/SEAL/ResetSettingIcon.png")


@onready var _setting_container = $SettingsPane/VBoxContainer
@onready var _search_box = $titleBar/SearchBox

var _has_visibility_control_method := false
var settings_collection:SettingsCollection
var group_settings_dict := {}
var group_button_dict := {}

func _ready():
	assert(get_tree().root.connect("size_changed",Callable(self,"_on_root_size_changed"))==OK)


##connected to the panels signal with the same name
func on_made_visible():
	if is_inside_tree() && settings_collection:#fire only if made visible and in scene tree
		var settings = settings_collection.settings
		for setting in settings.values():
			var group_name:String = setting._group
			if !group_settings_dict.keys().has(group_name):
				_add_group(group_name)
			var settings_painter:SettingsPainter = setting.get_settings_painter_scene().instantiate()
			group_settings_dict[group_name].append(settings_painter)
			_setting_container.add_child(settings_painter)
			settings_painter._on_show(setting)
			
		_update_visuals()


func _add_group(group_name:String):
	group_settings_dict[group_name] = []
	var group_button = Button.new()
	group_button.icon = open_section_icon
	group_button.expand_icon = true
	group_button.text = group_name
	group_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	group_button.focus_mode = Control.FOCUS_CLICK
	group_button.flat = true
	group_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	group_button.name = "group_" + group_name
	group_button.connect("pressed",Callable(self,"_on_group_button_pressed").bind(group_button))
	_setting_container.add_child(group_button)
	group_button_dict[group_name] = group_button


##Internal method for controlling the collapsing of the sections.
func _on_group_button_pressed(button:Button):
	button.icon = closed_section_icon if button.icon == open_section_icon else open_section_icon
	
	for setting in group_settings_dict[button.text]:
		setting.visible = button.icon == open_section_icon##TODO: Add dependable settings... 

##Internal method that visibility of the the list of settings, 
##done when changes are made to for example the search
func _update_visuals():
	_setting_container.size.x = size.x
	var search_term = _search_box.text
	for group_name in group_settings_dict:
		var match_group_name = group_name.count(search_term)>0
		var has_matching_setting = false
		for setting:SettingsPainter in group_settings_dict[group_name]:
			setting.visible = search_term == "" || match_group_name || setting.name.count(search_term)>0
			has_matching_setting = true
		group_button_dict[group_name].visible = match_group_name || search_term == ""


##Internal method connected to when the text in the search box is changed.
func _on_search_changed(_new_text):
	_update_visuals()


##Internal method connected to the of the window. Makes sure that the settings fill the entire scroll panel.
func _on_root_size_changed():
	_setting_container.size.x = size.x
