extends PanelContainer

class_name AbstractSettingsPainter
##this class is not to be added to the tree by itself, but instead inherited.

const MIN_SETTING_HEIGHT = 40
const MARGIN = 0
const SCROLL_MARGIN = 10

var _title_label : Label
var _value_group : Control
var _reset_button : Button

var setting:Setting

var _proxy_value

##Optional method for updating the setting's visuals 
var update_visuals_method:=func():pass

##Optional method that is a callback for when this setting is made visible.
var on_show_func:=func():pass


func _notification(what):
	if what == NOTIFICATION_SORT_CHILDREN:
		_sort_children()

func _on_show(setting:Setting):
	_title_label = $TitleLabel
	_value_group = $ValueGroup
	_reset_button = $ResetButton
	self.setting = setting
	if !setting.on_setting_changed.is_connected(_update_visual_value):
		setting.on_setting_changed.connect(_update_visual_value)
	
	_proxy_value = setting.value
	var translated = tr(setting.identifier)
	_title_label.text = translated if setting.identifier != translated else setting.identifier.replace("_", " ")
	_title_label.tooltip_text = setting.tooltip
	_reset_button.tooltip_text = tr("reset")
	_reset_button.visible = _proxy_value != setting.default_value
	
	on_show_func.call()
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
	_proxy_value = setting.default_value


func _update_visual_value():
	_reset_button.visible = !setting.values_are_equal_method.call(_proxy_value, setting.default_value)
	update_visuals_method.call()
