extends VectorSettingsPainter


class_name VectorFSettingsPainter

#Same as in the FloatSettingsPainter, but we take the inde of the vector.
func _on_value_changed(new_text:String, index:int):
	var trimmed = new_text.trim_suffix(setting.unit)
	var box = _boxes[index]
	var c_pos = box.caret_column
	if trimmed.is_valid_float(): 
		_proxy_value[index] = clampf(float(trimmed), setting.min_value[index], setting.max_value[index])
		#in case of clamped
		box.text = str(_proxy_value[index]) + setting.unit
	elif !new_text.ends_with(setting.unit):
		#reset visuals to valid value
		box.text = str(_proxy_value[index]) + setting.unit
	box.caret_column = min(box.text.length(), c_pos)


#Same as in the FloatSettingsPainter, but we take the inde of the vector.
func _on_value_box_focus_exited(index):
	var box := _boxes[index]
	if !box.text.trim_suffix(setting.unit).is_valid_float():
		box.text = str(_proxy_value[index]) + setting.unit

