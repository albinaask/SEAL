#this class is not to be added to the tree by itself, but instead inherited.
extends PanelContainer

class_name SettingsPainter

const MIN_SETTING_HEIGHT = 40
const MARGIN = 0
const SCROLL_MARGIN = 10

var setting_group : String

var _title_label : Label
var _value_group : Control
var _reset_button : Button

var setting_default_value : set = set_default_value
var setting_value : set = set_value
var _settings_panel:OWLSettingsPanel

func _init():
	get_property_list()

func _ready():
	_title_label = $TitleLabel
	_value_group = $ValueGroup
	_reset_button = $ResetButton

#sub classes must contain following methods:
#	value_is_valid(value)->bool
#	get_value_internal()->any
#	set_value_internal(val)->any
#	serialize_setting_value()->String
#	deserialize_setting_value(String)
#	update_visuals()-void

#sub classes may contain following method:
#	on_show()-void
#	equals(other)->bool

func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		_sort_children()
		

func _on_show(settings_panel:OWLSettingsPanel):
	_title_label = $TitleLabel
	_value_group = $ValueGroup
	_reset_button = $ResetButton
	_title_label.text = name
	_reset_button.visible = setting_value != setting_default_value
	_settings_panel = settings_panel
	var name_value_dict = settings_panel.API_object.get(settings_panel.settings_dict_property_name)
	if !call("value_is_valid", name_value_dict[name]):
			name_value_dict[name] = setting_default_value
			SEAL.logger.warn("Setting value of setting '" + name + "' is not allowed, resetting to default")
	
	if has_method("on_show"):
		call("on_show")
	call("update_visuals")


func _sort_children():
	
	if _title_label && _value_group && _reset_button:
		_title_label.anchor_left = 0
		_title_label.anchor_right = 0.5
		_title_label.anchor_top = 0
		_title_label.anchor_bottom = 1
		
		_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_title_label.size_flags_horizontal = SIZE_EXPAND_FILL
		_title_label.size_flags_vertical = SIZE_EXPAND_FILL
		_title_label.offset_left = 0
		_title_label.offset_right = -MIN_SETTING_HEIGHT
		_title_label.offset_top = 0
		_title_label.offset_bottom = 0
		
		_reset_button.anchor_left = 0.5
		_reset_button.anchor_right = 0.5
		_reset_button.anchor_top = 0.5
		_reset_button.anchor_bottom = 0.5
		
		_reset_button.offset_left = -MIN_SETTING_HEIGHT
		_reset_button.offset_right = 0
		_reset_button.offset_top = -MIN_SETTING_HEIGHT/2.0
		_reset_button.offset_bottom = MIN_SETTING_HEIGHT/2.0
		_reset_button.custom_minimum_size = Vector2(MIN_SETTING_HEIGHT, 0)
		
		_value_group.anchor_left = 0.5
		_value_group.anchor_right = 1
		_value_group.anchor_bottom = 1
		_value_group.anchor_top = 0
		
		_value_group.offset_left = MARGIN
		_value_group.offset_right = -MARGIN-SCROLL_MARGIN
		_value_group.offset_top = MARGIN
		_value_group.offset_bottom = -MARGIN
		
		_value_group.size_flags_horizontal = SIZE_EXPAND_FILL
		_value_group.size_flags_vertical = SIZE_EXPAND_FILL
		
		var min_size = Vector2()
		for child in get_children():
			if child is Control:
				min_size.y = max(child.size.y, min_size.y)
				min_size.x = child.size.x + min_size.x
		
		custom_minimum_size = Vector2(min_size.x+2*MARGIN-SCROLL_MARGIN, 2*MARGIN + max(MIN_SETTING_HEIGHT, min_size.y)/2)


func _on_reset_button_pressed():
	set_value(setting_default_value)
	_reset_button.visible = false


func set_value(value):
	if !call("value_is_valid", value):
		SEAL.logger.err("Value illegal")
	else:
		setting_value = value
		if is_inside_tree():
			_reset_button = $ResetButton
			if has_method("equals"):
				_reset_button.visible = !call("equals", setting_default_value)
			else:
				_reset_button.visible = setting_value != setting_default_value
			call("update_visuals")
		if _settings_panel:
			pass
			#_settings_panel._on_setting_value_updated(self)


func set_default_value(value):
	if setting_default_value != null:
		SEAL.logger.err("Default value is set more than once")
	elif !call("value_is_valid", value):
		SEAL.logger.err("Default value type is illegal")
	else:
		setting_default_value = value
		if setting_value==null:
			set_value(setting_default_value)
