extends VBoxContainer

class_name SettingsPanel

##Icon that will be shown when the group is not collapsed.
@export var open_section_icon: Texture2D = preload("res://addons/SEAL/visualizers/OpenSectionIcon.png")

##Icon that will be shown when the group is partially collapsed due to search or open only because it is searched.
@export var halfopen_section_icon: Texture2D = preload("res://addons/SEAL/visualizers/PartiallyOpenSectionIcon.png")

##Icon that will be shown when the group is collapsed.
@export var closed_section_icon: Texture2D = preload("res://addons/SEAL/visualizers/ClosedSectionIcon.png")

##Icon for the reset button.
@export var reset_icon: Texture2D = preload("res://addons/SEAL/visualizers/ResetSettingIcon.png")

##The collection that is being visualized by this panel. Must be set before the panel is made visible.
@export var settings_collection:SettingsCollection

##Margin between the contence of the painters.
@export var margin: int = 10

##Search box will ignore case of the inserted text.
@export var _search_box_ignore_case : bool = true

##Search box will display always groups of the found settings e.g. if searched "Show Hp Bar" is found under "Gameplay", it will also display "Gameplay" group above the setting. 
@export var _search_box_display_groups : bool = false

#shorthand values
@onready var _setting_container = $SettingsPane/VBoxContainer
@onready var _search_box = $SearchBar/SearchBox

var _group_settings_dict := {}
var _group_button_dict := {}


func _ready():
	#Connect to the root size changed so that we can resize the panel if the window size changes.
	assert(get_tree().root.connect("size_changed",Callable(self,"_on_root_size_changed"))==OK)


##Called on made visible.
func _on_panel_visibility_changed():
	assert(settings_collection)
	if is_inside_tree() && is_visible_in_tree():#fire only if made visible and in scene tree
		for child in _setting_container.get_children():
			_setting_container.remove_child(child)
		_group_button_dict.clear()
		_group_settings_dict.clear()
		var settings_dict = settings_collection._settings
		for setting:Setting in settings_dict.values():
			var group_name:String = setting._group
			if !_group_settings_dict.keys().has(group_name):
				_add_group(group_name)
			var settings_painter:SettingsPainter = setting.get_settings_painter_scene().instantiate()
			settings_painter.settings_panel = self
			_group_settings_dict[group_name].append(settings_painter)
			
			_setting_container.add_child(settings_painter)
			settings_painter._on_show(setting)
		#initially sync the visuals.
		_update_visuals()


##Internal method for adding a new group, adds a button that controls the visibility of the settings that are connected to this group.
func _add_group(group_name:String):
	_group_settings_dict[group_name] = []
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
	_group_button_dict[group_name] = group_button


##Internal method for controlling the collapsing of the sections.
func _on_group_button_pressed(button:Button):
	var search_term = _search_box.text
	if _search_box_ignore_case:
		search_term = search_term.to_lower()
	
	var match_not_all_settings = false
	var match_all = true

	for settings_painter:SettingsPainter in _group_settings_dict[button.text]:
		if (settings_painter.setting.identifier.to_lower().count(search_term) > 0) if _search_box_ignore_case else (settings_painter.setting.identifier.count(search_term) > 0):
			match_not_all_settings = true
		else:
			match_all = false
	
	match_not_all_settings = match_not_all_settings && !match_all
		
	match button.icon:
		open_section_icon:
			_change_group_visibility(button, false)
		halfopen_section_icon:
			_change_group_visibility(button, true)
		closed_section_icon:
			if match_not_all_settings:
				_update_group_visuals(button.text)
			else:
				_change_group_visibility(button, true)

func _change_group_visibility(button, vsible):
	if vsible:
		button.icon = open_section_icon
		button.was_last_state_closed = false
		for setting in _group_settings_dict[button.text]:
			setting.visible = true##TODO: Add dependable settings... 
	else:
		button.icon = closed_section_icon
		button.was_last_state_closed = true
		for setting in _group_settings_dict[button.text]:
			setting.visible = false##TODO: Add dependable settings... 

func _update_group_visuals(group_name):	
	var search_term = _search_box.text
	if _search_box_ignore_case:
		search_term = search_term.to_lower()
	
	var match_group_name = (group_name.to_lower().count(search_term) > 0) if _search_box_ignore_case else (group_name.count(search_term) > 0)
	var has_matching_setting = false
	var all_matching = true
	
	var group_button = _group_button_dict[group_name]
	for settings_painter:SettingsPainter in _group_settings_dict[group_name]:
		var match_setting_identifier = (settings_painter.setting.identifier.to_lower().count(search_term) > 0) if _search_box_ignore_case else (settings_painter.setting.identifier.count(search_term) > 0)
		settings_painter.visible = (search_term == "" && !group_button.was_last_state_closed) || match_group_name || match_setting_identifier
		if match_setting_identifier:
			has_matching_setting = true
		else:
			all_matching = false
	
	group_button.visible = match_group_name || search_term == "" || (has_matching_setting if _search_box_display_groups else false)
	if has_matching_setting && (group_button.icon == closed_section_icon || !all_matching):
		group_button.icon = halfopen_section_icon
    elif match_group_name && group_button.icon == closed_section_icon:
		group_button.icon = halfopen_section_icon
	else:
		group_button.icon = closed_section_icon if group_button.was_last_state_closed else open_section_icon

##Internal method that visibility of the the list of settings, 
##done when changes are made to for example the search
func _update_visuals():
	_setting_container.size.x = size.x
	for group_name in _group_settings_dict:
		_update_group_visuals(group_name)
	if is_inside_tree():
		_update_min_size.call_deferred()


func _update_min_size():
	var min_size_x = 0
	for child in get_children():
		if child is Control:
			min_size_x = max(min_size_x, child.get_combined_minimum_size().x)
	$SettingsPane/VBoxContainer.custom_minimum_size.x = min_size_x

##Internal method connected to when the text in the search box is changed.
func _on_search_changed(_new_text):
	_update_visuals()

##Called on dialog cofirm or similar to update the setting values to whatever the proxy values  are.
func _resync_settings():
	for group_contence:Array in _group_settings_dict.values():
		for painter:SettingsPainter in group_contence:
			painter.setting._value = painter._proxy_value
