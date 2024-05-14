extends SettingsPainter


class_name VectorSettingsPainter

var _boxes : Array[LineEdit]




func _connect_boxes():
	for i in range(_boxes.size()):
		var box := _boxes[i]
		box.text_changed.connect(Callable(self, "_on_value_changed").bind(i))
		box.focus_exited.connect(Callable(self, "_on_value_box_focus_exited").bind(i))


func update_visuals():
	for i in range(_boxes.size()):
		var box = _boxes[i]
		if box == get_viewport().gui_get_focus_owner():
			var c_pos = box.caret_column
			box.text = str(_proxy_value[i]) + setting.unit
			box.caret_column = min(box.text.length(), c_pos)
		else:
			box.text = str(_proxy_value[i]) + setting.unit


