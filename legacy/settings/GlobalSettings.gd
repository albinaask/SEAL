extends OWLSettingsPanel

var _global_settings:Dictionary

const vsync_value_dict = {
	"Enabled":DisplayServer.VSYNC_ENABLED,
	"Disabled":DisplayServer.VSYNC_DISABLED,
	"Adaptive":DisplayServer.VSYNC_ADAPTIVE,
	"Mailbox":DisplayServer.VSYNC_MAILBOX
}

const _compat_blacklist = ["MSAA", "SSAA", "TAA"]
const _auto_save_blacklist = ["Auto save interval", "Auto save pool size"]

var _is_ready := false

func _ready():
	visibility_control_method = "_is_setting_visible"
	settings_dict_property_name = "_global_settings"
	save_method_name = "_save_settings"
	registry_method_name ="_register_settings"
	_global_settings = OWLUtils.read_dict_from_cfg_file(OWLConfig.global_settings_path)
	OWLConfig.global_settings = _global_settings
	_set_API_object(self)#self since this is the API
	
	_update_settings()
	_is_ready = true


func _register_settings(_dialog):
	register_option_setting("Screen mode", "Graphics", PackedStringArray(["Window", "Borderless", "Fullscreen"]), "Window", "Difference between borerless and fullscreen is that the mouse is confined in the window")
	register_bool_setting("Always on top", "Graphics", false, "Forces the game window to always be visible.")
	
	register_option_setting("Render method", "Graphics", PackedStringArray(["Forward+", "Compatability"]), "Forward+", "Which render engine to use, Forward+ is a modern, Vulkan based engine capable of better graphics, has more features and is more optimized for mdoern graphics cards. Compatability is an engine that is meant for older devices without vulkan support")
	
	register_option_setting("V-sync", "Graphics", PackedStringArray(vsync_value_dict.keys()), vsync_value_dict.keys()[0], "Which mode of vertical syncronization to use \n Enabled: V-Sync on \n Disabled: V-Sync off \n Adaptive: off when below screen refresh rate, on when above. \n Mailbox: used to reduce input lag, use when you have too much FPS only." )
	#No anisotropic filtering in Godot 4??
	#register_option_setting("Anisotropic filtering", "Graphics", PackedStringArray(["2", "4", "8", "16"]), "4", "Higher values is more performance expensive, but generally produces better results.")
	
	register_option_setting("MSAA", "Anti ailiasing", PackedStringArray(["off", "2", "4", "8", "16"]), "off", "Use multisampled anti ailiasing, usually performance heavy on the GPU side.")
	register_bool_setting("SSAA", "Anti ailiasing", false, "Screen space anti ailiasing, blurs edges of polygons, may however blur textures.")
	register_bool_setting("TAA", "Anti ailiasing", false, "Temporal anti ailiasing, blurs edges of polygons, may result in unwanted blur")
	register_float_setting("Mipmap bias", "Anti ailiasing", 0, "Hint the renderer to use bigger or smaller mipmaps. If you experience jitter, you may try raise this setting. If you experience excess blur, you may want to lower this", "", -1, 1)
	register_bool_setting("Debanding", "Graphics", false, "Debanding can be turned on to alleviate color bands, but may cause artefacts so is only recommended if accually needed")
	
	register_float_setting("Notification time", "Console", 4.0, "time in seconds until an ingame notification banner starts to fade out", "s", 0, 60)
	register_float_setting("Notification fadeout time", "Console", 0.5, "time in seconds that the notification banner fadeout animation should last for", "s", 0, 10)
	
	if OWLConfig.use_auto_saves:
		register_bool_setting("Auto save", "auto saves", true, "Whether to periodically make autosaves.")
		register_int_setting("Auto save interval", "auto saves", 5, "The interval in minutes between the autosaves", "m", 1)
		register_int_setting("Auto save pool size", "auto saves", 5, "Auto saves will accumulate to this number and progressivly delete the oldest in order not to flood the disk with old saves. This is a global pool and not per world", "", 1, 120)


func _save_settings():
	#can call when all settings aren't initialized, so we check whether we can update them
	if _is_ready:
		_update_settings()
	OWLUtils.write_dict_to_cfg_file(_global_settings, OWLConfig.global_settings_path)
	OWLConfig.on_global_settings_changed.emit()


func _update_settings():
	var window:Window = get_window()
	if _global_settings["Screen mode"] == "Window":
		window.borderless = false
		window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (false) else Window.MODE_WINDOWED
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif _global_settings["Screen mode"] == "Borderless":
		window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (true) else Window.MODE_WINDOWED
		window.borderless = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		window.borderless = true
		window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (true) else Window.MODE_WINDOWED
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED

	if window.always_on_top != _global_settings["Always on top"]:
		window.always_on_top = _global_settings["Always on top"]
	
	_sync_project_setting("rendering/renderer/rendering_method", _global_settings["Render method"])
	
	var use_vulkan = _global_settings["Render method"] == "Forward+"
	var v_sync_text = _global_settings["V-sync"]
	var v_sync_val = vsync_value_dict[v_sync_text]
	
	if use_vulkan:
		_sync_project_setting("display/window/vsync/vsync_mode", v_sync_val)
		var msaa = 0 if _global_settings["MSAA"] == "off" else _global_settings["MSAA"]
		_sync_project_setting("rendering/anti_aliasing/quality/msaa_3d", msaa)
		_sync_project_setting("rendering/anti_aliasing/quality/screen_space_aa", int(_global_settings["SSAA"]))
		_sync_project_setting("rendering/anti_aliasing/quality/use_taa", _global_settings["TAA"])
	else:
		_sync_project_setting("display/window/vsync/vsync_mode", DisplayServer.VSYNC_DISABLED if v_sync_val == DisplayServer.VSYNC_DISABLED else DisplayServer.VSYNC_ENABLED)
		
		#Features not supported with Compatability
		_sync_project_setting("rendering/anti_aliasing/quality/msaa_3d", 0)
		_sync_project_setting("rendering/anti_aliasing/quality/screen_space_aa", 0)
		_sync_project_setting("rendering/anti_aliasing/quality/use_taa", false)
	
	_sync_project_setting("rendering/textures/default_filters/texture_mipmap_bias", _global_settings["Mipmap bias"])
	if is_inside_tree():
		var root:Viewport = get_tree().root
		if root.use_debanding != _global_settings["Debanding"]:
			root.use_debanding = _global_settings["Debanding"]


func _is_setting_visible(setting_name:String)->bool:
	if _compat_blacklist.has(setting_name) && _global_settings["Render method"] != "Forward+":
		return false
	elif _auto_save_blacklist.has(setting_name) && _global_settings["Auto save"] == false:
		return false
	else:
		return true


func _sync_project_setting(project_setting_name:String, value):
	if ProjectSettings[project_setting_name] != value:
		ProjectSettings[project_setting_name] = value
