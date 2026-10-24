extends "res://tests/test_base.gd"

func test_android_and_web_export_presets() -> void:
	var file := FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	assert_true(file != null, "export_presets.cfg should exist.")
	if file == null:
		return
	
	var content := file.get_as_text()
	
	assert_true("package/unique_name=\"games.audrain.praytherosary\"" in content, "Android package unique name should be games.audrain.praytherosary.")
	assert_true("export_path=\"praytherosary.aab\"" in content, "Android export_path should be praytherosary.aab.")
	assert_true("screen/immersive_mode=true" in content, "Android export preset must enable screen/immersive_mode=true to hide system bars.")
	assert_true("include_filter=" in content and "*.json" in content, "include_filter should contain '*.json'.")
	assert_true("name=\"Web\"" in content, "Web export preset should exist.")
	assert_true("platform=\"Web\"" in content, "Web export preset platform should be Web.")
	assert_true(FileAccess.file_exists("res://assets/icons/icon.png"), "icon.png should exist.")
	assert_true(FileAccess.file_exists("res://assets/icons/icon_foreground.png"), "icon_foreground.png should exist.")
	assert_true(FileAccess.file_exists("res://assets/icons/icon_background.png"), "icon_background.png should exist.")


func test_app_icon_and_adaptive_icons() -> void:
	# icon.png
	assert_true(FileAccess.file_exists("res://assets/icons/icon.png"), "icon.png should exist on disk.")
	var icon_img: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/icons/icon.png"))
	assert_not_null(icon_img, "icon.png should load cleanly as an Image.")
	if icon_img != null:
		assert_eq(icon_img.get_width(), 512, "icon.png width must be exactly 512 pixels.")
		assert_eq(icon_img.get_height(), 512, "icon.png height must be exactly 512 pixels.")
		var icon_aspect: float = float(icon_img.get_width()) / float(icon_img.get_height())
		assert_eq(icon_aspect, 1.0, "icon.png must have a square 1:1 aspect ratio.")

	var icon_tex: Texture2D = load("res://assets/icons/icon.png") as Texture2D
	assert_not_null(icon_tex, "icon.png must load cleanly as Texture2D.")
	if icon_tex != null:
		assert_eq(icon_tex.get_width(), 512, "icon.png Texture2D width must be 512.")
		assert_eq(icon_tex.get_height(), 512, "icon.png Texture2D height must be 512.")

	# Compare aspect ratio with full cover image to ensure distinct square crop
	assert_true(FileAccess.file_exists("res://assets/images/cover.webp"), "cover.webp should exist.")
	var cover_img: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/images/cover.webp"))
	assert_not_null(cover_img, "cover.webp should load cleanly as an Image.")
	if cover_img != null:
		var cover_aspect: float = float(cover_img.get_width()) / float(cover_img.get_height())
		assert_ne(cover_aspect, 1.0, "Full cover artwork aspect ratio should differ from square 1.0 icon crop.")

	# icon_foreground.png
	assert_true(FileAccess.file_exists("res://assets/icons/icon_foreground.png"), "icon_foreground.png should exist.")
	var fg_img: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/icons/icon_foreground.png"))
	assert_not_null(fg_img, "icon_foreground.png should load cleanly as an Image.")
	if fg_img != null:
		assert_eq(fg_img.get_width(), 432, "icon_foreground.png should match adaptive icon width 432.")
		assert_eq(fg_img.get_height(), 432, "icon_foreground.png should match adaptive icon height 432.")

	var fg_tex: Texture2D = load("res://assets/icons/icon_foreground.png") as Texture2D
	assert_not_null(fg_tex, "icon_foreground.png must load cleanly as Texture2D.")

	# icon_background.png
	assert_true(FileAccess.file_exists("res://assets/icons/icon_background.png"), "icon_background.png should exist.")
	var bg_img: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/icons/icon_background.png"))
	assert_not_null(bg_img, "icon_background.png should load cleanly as an Image.")
	if bg_img != null:
		assert_eq(bg_img.get_width(), 432, "icon_background.png should match adaptive icon width 432.")
		assert_eq(bg_img.get_height(), 432, "icon_background.png should match adaptive icon height 432.")
		var center_pixel: Color = bg_img.get_pixel(216, 216)
		assert_eq(center_pixel.to_html(false).to_upper(), "141010", "icon_background.png color must match #141010 ambient espresso.")

	var bg_tex: Texture2D = load("res://assets/icons/icon_background.png") as Texture2D
	assert_not_null(bg_tex, "icon_background.png must load cleanly as Texture2D.")


func test_project_settings() -> void:
	var file := FileAccess.open("res://project.godot", FileAccess.READ)
	assert_true(file != null, "project.godot should exist.")
	if file == null:
		return
	
	var content := file.get_as_text()
	assert_true("window/handheld/orientation=1" in content, "Portrait orientation should be set.")
	assert_true("window/stretch/mode=\"canvas_items\"" in content, "Stretch mode should be canvas_items.")
	assert_true("window/stretch/aspect=\"expand\"" in content, "Stretch aspect should be expand.")
	assert_true("pointing/emulate_touch_from_mouse=true" in content, "pointing/emulate_touch_from_mouse=true should be enabled under [input_devices].")
	assert_true(bool(ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false)), "input_devices/pointing/emulate_touch_from_mouse ProjectSetting must be true.")
	assert_true("renderer/rendering_method=\"gl_compatibility\"" in content, "Renderer should be set to gl_compatibility.")
	assert_true("renderer/rendering_method.mobile=\"gl_compatibility\"" in content, "Mobile renderer should be set to gl_compatibility.")
	assert_true("McpInteractionServer=\"*res://autoloads/mcp_interaction_server.gd\"" in content, "McpInteractionServer should point to res://autoloads/mcp_interaction_server.gd.")
	assert_true(FileAccess.file_exists("res://autoloads/mcp_interaction_server.gd"), "mcp_interaction_server.gd should exist in res://autoloads/.")

	# Icon & Boot splash assertions
	assert_true("config/icon=\"res://assets/icons/icon.png\"" in content, "config/icon should point to res://assets/icons/icon.png.")
	assert_true("boot_splash/image=\"res://assets/icons/boot_splash.png\"" in content or "boot_splash/image=\"res://assets/images/cover.webp\"" in content, "boot_splash/image should point to full cover artwork.")
	assert_true("boot_splash/bg_color=Color(0.0784314, 0.0627451, 0.0627451, 1)" in content, "boot_splash/bg_color should match Color(0.0784314, 0.0627451, 0.0627451, 1).")
	assert_true(FileAccess.file_exists("res://assets/icons/boot_splash.png"), "res://assets/icons/boot_splash.png must exist.")
	assert_true(FileAccess.file_exists("res://assets/images/cover.webp"), "Cover art image referenced by boot splash must exist.")

	var splash_path: String = ProjectSettings.get_setting("application/boot_splash/image", "")
	assert_true(splash_path == "res://assets/icons/boot_splash.png" or splash_path == "res://assets/images/cover.webp", "boot_splash/image must be full cover art.")
	assert_true(FileAccess.file_exists(splash_path), "Configured boot splash file must exist on disk: %s" % splash_path)

	var splash_bg: Color = ProjectSettings.get_setting("application/boot_splash/bg_color", Color.BLACK)
	assert_eq(splash_bg.to_html(false).to_upper(), "141010", "boot_splash/bg_color must match #141010 ambient espresso.")


func test_application_version_synchronization() -> void:
	var app_version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	assert_ne(app_version, "", "application/config/version in ProjectSettings must be non-empty.")

	var proj_file := FileAccess.open("res://project.godot", FileAccess.READ)
	assert_true(proj_file != null, "project.godot should exist.")
	if proj_file != null:
		var proj_content := proj_file.get_as_text()
		var target_proj_needle: String = "config/version=\"%s\"" % app_version
		assert_true(proj_content.contains(target_proj_needle), "project.godot must define %s." % target_proj_needle)

	var preset_file := FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	assert_true(preset_file != null, "export_presets.cfg should exist.")
	if preset_file != null:
		var preset_content := preset_file.get_as_text()
		var target_preset_needle: String = "version/name=\"%s\"" % app_version
		assert_true(preset_content.contains(target_preset_needle), "export_presets.cfg version/name must match application/config/version exactly (%s)." % app_version)


func test_android_runtime_fullscreen_guard() -> void:
	assert_true(Main.should_use_android_fullscreen("Android", "Android"), "Android on active display driver should enable fullscreen.")
	assert_true(Main.should_use_android_fullscreen("Android", "dummy_driver"), "Android on custom display driver should enable fullscreen.")
	assert_false(Main.should_use_android_fullscreen("Android", "headless"), "Android on headless driver should avoid fullscreen.")
	assert_false(Main.should_use_android_fullscreen("Windows", "windows"), "Windows platform should not trigger Android fullscreen.")
	assert_false(Main.should_use_android_fullscreen("Web", "web"), "Web platform should not trigger Android fullscreen.")
	assert_false(Main.should_use_android_fullscreen("macOS", "macos"), "macOS platform should not trigger Android fullscreen.")
	assert_false(Main.should_use_android_fullscreen("iOS", "ios"), "iOS platform should not trigger Android fullscreen.")

