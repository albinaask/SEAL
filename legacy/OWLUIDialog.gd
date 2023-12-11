@tool
extends PanelContainer

class_name OWLUIDialog

@export var visible_when_added_to_scene_tree: bool = false
@export var padding: int = 10 : set = set_padding
@export_range(0,1, 0.00001) var screen_size:float = 0.75 : set = set_pane_size # (float, 0, 1)
@export var contence_group_path: NodePath : set = set_contence_group_path
@export var parent_panel: NodePath

signal on_return_from_sub_menu


func _ready():
# warning-ignore:return_value_discarded
	get_tree().root.connect("size_changed",Callable(self,"resize_components"))
	visible = visible_when_added_to_scene_tree


func _notification(what):
	if what == NOTIFICATION_POST_ENTER_TREE || (is_inside_tree() && what == NOTIFICATION_SORT_CHILDREN):
		resize_components()


func set_padding(arg:int):
	padding = arg
	if is_inside_tree():
		resize_components()

func set_pane_size(arg:float):
	screen_size = arg
	if is_inside_tree():
		resize_components()

func set_contence_group_path(path:NodePath):
	contence_group_path = path
	if is_inside_tree():
		resize_components()

func resize_components():
	if visible:
		
		anchor_left = 0.5-screen_size/2
		anchor_right = 0.5+screen_size/2
		anchor_top = 0.5-screen_size/2
		anchor_bottom = 0.5+screen_size/2
		
		offset_left = 0
		offset_right = 0
		offset_top = 0
		offset_bottom = 0
		
		$TitleLabel.anchor_top = 0
		$TitleLabel.anchor_left = 0.5
		
		$TitleLabel.offset_top = padding
		$TitleLabel.offset_left = -$TitleLabel.size.x/2
		$TitleLabel.offset_right = 0
		$TitleLabel.offset_bottom = 0
		
		$ControlGroup.anchor_top = 1
		$ControlGroup.anchor_right = 1
		
		$ControlGroup.offset_top = -$ControlGroup.size.y-padding
		$ControlGroup.offset_bottom = -padding
		$ControlGroup.offset_right = 0
		
		
		if contence_group_path:
			var contence_group:Control = get_node(contence_group_path)
			#contence_group.size_flags_horizontal = 0
			#contence_group.size_flags_vertical = 0
			contence_group.set_anchors_preset(Control.PRESET_CENTER)
			contence_group.anchor_top = 0
			contence_group.anchor_bottom = 1
			contence_group.anchor_left = 0
			contence_group.anchor_right = 1
			
			contence_group.offset_left = padding
			contence_group.offset_right = -padding
			contence_group.offset_top = 2*padding + $TitleLabel.size.y
			contence_group.offset_bottom = -2*padding - $ControlGroup.size.y
			
			#custom_minimum_size = contence_group.size + Vector2(padding*2, 4*padding + $TitleLabel.size.y + $ControlGroup.size.y)
		

func _on_canceled():
	visible = false
	if parent_panel:
		var node = get_node(parent_panel)
		node.visible = true
	emit_signal("on_return_from_sub_menu")
