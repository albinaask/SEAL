extends Button

##Forces a minimal size to fit the text, icon and separation between those
@export var set_minimum_size : bool = true 

##Calculates minimal size to fit the text, icon and separation between those
func calc_min_size() -> void:
	if !self.set_minimum_size:
		return
	
	var font = self.get_theme_font("font")
	var font_size = self.get_theme_font_size("font_size")
	var text_width = 0.0
	var h_separation = 4.0
	var icon_width = self.icon.get_width() * self.size.y/self.icon.get_height()
	
	if !font:
		font = self.get_theme_default_font()
		font_size = self.get_theme_default_font_size()
	
	if font:
		text_width = font.get_string_size(self.text, 0, -1, font_size).x
	
	if self.get("theme_constants/h_separation") != null:
		h_separation = self.get("theme_constants/h_separation")
	if self.get("theme_override_constants/h_separation") != null:
		h_separation = self.get("theme_override_constants/h_separation")
		
	self.custom_minimum_size.x = text_width + h_separation + icon_width

#Just so the user doesn't need to look into the code and learn they need to manually set the size's x to 0
##Helper function to disable minimum size calculation
func disable_calc_min_size():
	self.set_minimum_size = false
	self.custom_minimum_size.x = 0

##Make sure if a theme override occurs, the min size is recalculated 
func _ontheme_changed() -> void:
	#Could use some checks to not add additional work if not needed, but these aren't usually critical
	self.calc_min_size()

##Make sure if an override occurs, the min size is recalculated 
func _onproperty_list_changed() -> void:
	#Could use some checks to not add additional work if not needed, but these aren't usually critical
	self.calc_min_size()
