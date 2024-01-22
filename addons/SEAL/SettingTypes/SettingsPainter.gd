extends PanelContainer

class_name SettingsPainter
##this class is not to be added to the tree by itself, but instead inherited.

const MIN_SETTING_HEIGHT = 40
const MARGIN = 0
const SCROLL_MARGIN = 10

var _title_label : Label
var _value_group : Control
var _reset_button : Button

var setting:Setting
var _settings_panel:OWLSettingsPanel

func _init():
	get_property_list()

func _ready():
	_title_label = $TitleLabel
	_value_group = $ValueGroup
	_reset_button = $ResetButton

##Optional method for updating the setting's visuals 
var update_visuals_method:Callable

##Optional method that is a callback for when this setting is made visible.
var on_show:=func():pass

func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		_sort_children()

func _on_show(setting:Setting, settings_panel:OWLSettingsPanel):
	_title_label = $TitleLabel
	_value_group = $ValueGroup
	_reset_button = $ResetButton
	self.setting = setting
	_title_label.text = tr(setting.identifier) if can_translate_messages() else setting.identifier.replace("_", " ")
	_reset_button.visible = setting.value != setting.default_value
	_settings_panel = settings_panel
	
	on_show.call()
	update_visuals_method.call()


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
	set_setting_value(setting.default_value)
	_reset_button.visible = false


func set_setting_value(value):
	#since we use the unsafe method we check that the setting is valid.
	if setting.value_is_valid_method.call(value):
		SEAL.logger.err("Value illegal")
		return
	
	setting._force_set(value)#in case we are in a locked context
	_reset_button.visible = !setting.equals_method.call(setting.default_value)
	update_visuals_method.call()
