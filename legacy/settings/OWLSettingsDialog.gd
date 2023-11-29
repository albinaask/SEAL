extends OWLUIDialog

class_name OWLSettingsDialog

func _on_accept_button_pressed():
	visible = false
	$OWLSettingsPanel.update_settings_array()


func _on_visibility_changed():
	if visible:
		$OWLSettingsPanel.on_made_visible()
