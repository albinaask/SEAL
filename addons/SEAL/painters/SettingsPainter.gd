extends Container

##this class does nothing when added to the tree by itself, but should instead be inherited by scenes that are derivetives from SettingsPainter.tscn, see IntSettingsPainter.tscn for reference.
class_name SettingsPainter

##Minimum height of the setting, used so the settings dont shrink to just covering the text and looking weird.
const MIN_SETTING_HEIGHT = 40
##Add some extra space for the scroll bar 
const SCROLL_MARGIN = 10

#Internals for referencing nodes.
var _title_label : Label
var _value_group : Control
var _reset_button : Button

##The setting that is linked to this painter. The type depends on the type of the painter. A BoolSettingsPainter contains a BoolSetting etc.
var setting:Setting

var settings_panel:SettingsPanel

##Since the setting value is set upon clicking the 'confirm' buton in the dialog, the value that the setting should take at that time is stored as an intermediary value here.
var _proxy_value:
	set(val):
		SEAL.logger.err_cond_false(setting.call("is_value_valid", val), "Proxy values must be valid setting values.")
		_proxy_value = val
		_update_visual_value()


##Optional method that is a callback for when this setting is made visible.
var on_show_func:=func():pass


##Internal method called when the Panel is made visible. Should be connected to the "on_show" signal of the dialog or the like.
func _on_show(setting:Setting):
	_title_label = $TitleLabel
	_value_group = $ValueGroup
	_reset_button = $ResetButton
	self.setting = setting
	#Make sure we update the visual value if the setting value is updated while the dialog is shown.
	if !setting.on_setting_changed.is_connected(_update_visual_value):
		setting.on_setting_changed.connect(_update_visual_value)
	
	_proxy_value = setting._value
	var translated = tr(setting.identifier)
	_title_label.text = translated if setting.identifier != translated else setting.identifier.replace("_", " ")
	_title_label.tooltip_text = setting.tooltip
	_reset_button.tooltip_text = tr("reset")
	_reset_button.visible = _proxy_value != setting.default_value
	
	on_show_func.call()

func _enter_tree() -> void:
	sort_children.connect(_sort_children)

#Clean the signal connection.
func _exit_tree() -> void:
	if setting && setting.on_setting_changed.is_connected(_update_visual_value):
		setting.on_setting_changed.disconnect(_update_visual_value)


func _get_minimum_size() -> Vector2:
	var min_size = Vector2()
	var margin = settings_panel.margin if settings_panel != null else 10
	for child in get_children():
		if child is Control:
			var child_size = child.get_combined_minimum_size()
			min_size.y = max(child_size.y, min_size.y)
			min_size.x += child_size.x + abs(child.offset_left) + abs(child.offset_right)
	return Vector2(min_size.x+2*margin+SCROLL_MARGIN, 2*margin + max(MIN_SETTING_HEIGHT, min_size.y))


#Set correct positions of children.
func _sort_children():
	assert(settings_panel, "Settings panel not set, must be set befoere added to tree.")
	if _title_label && _value_group && _reset_button:
		var margin = settings_panel.margin

		_title_label.anchor_left = 0
		_title_label.anchor_right = 0.5
		_title_label.anchor_top = 0
		_title_label.anchor_bottom = 1
		
		_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_title_label.size_flags_horizontal = SIZE_EXPAND_FILL
		_title_label.size_flags_vertical = SIZE_EXPAND_FILL
		_title_label.offset_left = margin
		_title_label.offset_right = - MIN_SETTING_HEIGHT
		_title_label.offset_top = margin
		_title_label.offset_bottom = -margin
		
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
		
		_value_group.offset_left = 0
		_value_group.offset_right = -margin
		_value_group.offset_top = margin
		_value_group.offset_bottom = -margin

#Connected to the reset button.pressed signal. triggers the setting to reset to its default value and therefore the reset button to be hidden.
func _on_reset_button_pressed():
	_proxy_value = setting.default_value

#Internal method for syncing the state of the reset button to the proxy value.
func _update_visual_value():
	_reset_button.visible = !setting.values_are_equal_method.call(_proxy_value, setting.default_value)
	call("update_visuals")
