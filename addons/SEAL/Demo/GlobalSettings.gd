extends SettingsCollection

const _PATH = "res://addons/SEAL/Demo/global_settings.GSON"

#Even though Godot can be set to more values than true or false for V-Sync, this demo only handles true and false.
var v_sync_setting = BoolSetting.new("V-Sync", "Graphics", "Controls whether the game uses V-Sync.")
var window_mode_setting = MultiChoiceSetting.new("Window mode", "Window", "Controls the window mode.", "Windowed", ["Fullscreen", "Windowed", "Borderless window"])
var render_engine_setting = MultiChoiceSetting.new("Render method", "Graphics", "Which render engine to use, Forward+ is a modern, Vulkan based engine capable of better graphics, has more features and is more optimized for mdoern graphics cards. Compatability is an engine that is meant for older devices without vulkan support. Mobile is a Vulkan based render engine that is meant for mobile devices.", "Forward+", ["Forward+", "Compatability", "Mobile"])
var debanding_setting = BoolSetting.new("Debanding", "Graphics", "Debanding can be turned on to alleviate color bands, but may cause artefacts so is only recommended if accually needed.")

var dialog_key:KeySetting


func _init():
	add_setting(v_sync_setting)
	add_setting(window_mode_setting)
	add_setting(render_engine_setting)
	add_setting(debanding_setting)
	var def_key = InputEventKey.new()
	def_key.keycode = KEY_ESCAPE
	dialog_key = KeySetting.new("dialog_key", "Input", "The key used to open the dialog.", def_key)
	add_setting(dialog_key)

	v_sync_setting.on_setting_changed.connect(on_v_sync_updated)
	window_mode_setting.on_setting_changed.connect(on_window_mode_updated)
	render_engine_setting.on_setting_changed.connect(on_render_backend_updated)
	debanding_setting.on_setting_changed.connect(on_debanding_updated)

	#If no file is found, the settings all have their default values.
	if FileAccess.file_exists(_PATH):
		load_from_GSON(_PATH)

func on_v_sync_updated():
	if v_sync_setting.get_value() == true:
		ProjectSettings["display/window/vsync/vsync_mode"] = DisplayServer.VSYNC_ENABLED
	else:
		ProjectSettings["display/window/vsync/vsync_mode"] = DisplayServer.VSYNC_DISABLED


func on_render_backend_updated():
	var value = render_engine_setting.get_value()
	#We need to set the driver for each platform. :(
	ProjectSettings["rendering/rendering_device/driver.windows"] = value
	ProjectSettings["rendering/rendering_device/driver.linuxbsd"] = value
	ProjectSettings["rendering/rendering_device/driver.macos"] = value
	ProjectSettings["rendering/rendering_device/driver.ios"] = value
	ProjectSettings["rendering/rendering_device/driver.android"] = value
	

func on_debanding_updated():
	ProjectSettings["rendering/anti_aliasing/quality/use_debanding"] = debanding_setting.get_value()

func on_window_mode_updated():
	var mode:String = window_mode_setting.get_value()
	var window := get_window()
	if mode == "Fullscreen":
		window.borderless = true
		window.mode = Window.MODE_FULLSCREEN
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED
		window.always_on_top = true
	elif mode == "Windowed":
		window.borderless = false
		window.mode = Window.MODE_WINDOWED #Exclusive has no effect.
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		window.always_on_top = false
	elif mode == "Borderless window":
		window.borderless = true
		window.mode = Window.MODE_FULLSCREEN
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		window.always_on_top = false



func _exit_tree():
	save_to_GSON(_PATH)
