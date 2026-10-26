extends "res://tests/test_base.gd"
## Automated unit tests for NavigationDrawer and Main navigation integration.
## Covers:
## - Top-right floating button and overlay drawer visibility toggling
## - Modal scrim clicks and ui_cancel (Escape) dismissing
## - "Resume Last Page" button fallback, reading progress, and page emission
## - Top-level landmark section links (Pages 1, 2, 3, 4, 46, 48, 50)
## - Expandable Mystery Set accordions (dual-action rows):
##   * Disclosure arrow (▸ / ▾) expansion/collapse without closing drawer
##   * Title button jump to 1st mystery and close drawer
##   * All 20 individual mystery buttons and page targets
## - Dynamic Liturgical "Recommended Today" badge assignment
## - FloatingButton dimensions, glyph resolution, and calibrated StyleBox centering
## - Main scene integration: scroll coordination and input pausing

const NavigationDrawerScene: PackedScene = preload("res://scenes/ui/navigation_drawer.tscn")
const MainScene: PackedScene = preload("res://scenes/main/main.tscn")
const RosaryDataLoaderScript = preload("res://scripts/data/rosary_data_loader.gd")
const ReadingProgressManagerScript = preload("res://scripts/core/reading_progress_manager.gd")


func _create_nav_drawer() -> NavigationDrawer:
	var drawer: NavigationDrawer = NavigationDrawerScene.instantiate() as NavigationDrawer
	test_root_window.add_child(drawer)
	drawer._ready()
	return drawer


func test_navigation_drawer_scene_structure() -> void:
	var drawer: NavigationDrawer = _create_nav_drawer()

	assert_true(drawer is CanvasLayer, "NavigationDrawer must extend CanvasLayer")
	assert_true(drawer.layer >= 10, "NavigationDrawer layer must be >= 10 (got %d)" % drawer.layer)

	var float_btn: Button = drawer.get_floating_button()
	assert_not_null(float_btn, "FloatingMenuButton must exist")
	assert_eq(float_btn.text, "☰", "Floating button must display hamburger icon")
	assert_eq(float_btn.custom_minimum_size, Vector2(104, 104), "Floating button custom_minimum_size must be 104x104")

	var scrim: ColorRect = drawer.get_scrim()
	assert_not_null(scrim, "Scrim node must exist")
	assert_eq(scrim.mouse_filter, Control.MOUSE_FILTER_STOP, "Scrim must block mouse inputs")

	var panel: PanelContainer = drawer.get_drawer_panel()
	assert_not_null(panel, "DrawerPanel node must exist")
	assert_eq(panel.mouse_filter, Control.MOUSE_FILTER_STOP, "DrawerPanel must block mouse inputs")

	var close_btn: Button = drawer.get_close_button()
	assert_not_null(close_btn, "Close button must exist")
	assert_eq(close_btn.text, "✕", "Close button must display ✕")

	var resume_btn: Button = drawer.get_resume_button()
	assert_not_null(resume_btn, "Resume button must exist")

	assert_false(drawer.is_open(), "Drawer must be closed initially")
	assert_false(drawer.drawer_overlay.visible, "Drawer overlay must be invisible initially")

	drawer.free()


func test_navigation_drawer_font_fallbacks() -> void:
	var drawer: NavigationDrawer = _create_nav_drawer()
	var symbol_font_path: String = "res://assets/fonts/NotoSansSymbols-Regular.ttf"
	var expected_symbol_font: Font = load(symbol_font_path) as Font
	assert_not_null(expected_symbol_font, "Symbol fallback font must load cleanly")

	assert_not_null(drawer._font_bold, "drawer._font_bold must be loaded")
	assert_not_null(drawer._font_regular, "drawer._font_regular must be loaded")

	var font_checks: Array[Dictionary] = [
		{"name": "_font_bold", "font": drawer._font_bold},
		{"name": "_font_regular", "font": drawer._font_regular}
	]

	for item: Dictionary in font_checks:
		var font_name: String = str(item.get("name", ""))
		var font_obj: Font = item.get("font") as Font
		assert_not_null(font_obj, "%s must not be null" % font_name)
		if font_obj == null:
			continue

		var has_symbols: bool = false
		for fb: Font in font_obj.fallbacks:
			if fb != null and (fb == expected_symbol_font or fb.resource_path == symbol_font_path):
				has_symbols = true
				break
		assert_true(has_symbols, "NavigationDrawer %s must have NotoSansSymbols-Regular.ttf in fallbacks" % font_name)
		assert_true(font_obj.has_char(0x2630), "%s must support ☰ (U+2630)" % font_name)
		assert_true(font_obj.has_char(0x2715), "%s must support ✕ (U+2715)" % font_name)
		assert_true(font_obj.has_char(0x25B8), "%s must support ▸ (U+25B8)" % font_name)
		assert_true(font_obj.has_char(0x25BE), "%s must support ▾ (U+25BE)" % font_name)
		assert_true(font_obj.has_char(0x2605), "%s must support ★ (U+2605)" % font_name)

	var float_btn: Button = drawer.get_floating_button()
	assert_not_null(float_btn, "Floating button must exist")
	var float_font: Font = float_btn.get_theme_font("font")
	assert_not_null(float_font, "Floating button font must exist")
	assert_true(float_font.has_char(0x2630), "Floating button font must resolve ☰ (U+2630)")

	var close_btn: Button = drawer.get_close_button()
	assert_not_null(close_btn, "Close button must exist")
	var close_font: Font = close_btn.get_theme_font("font")
	assert_not_null(close_font, "Close button font must exist")
	assert_true(close_font.has_char(0x2715), "Close button font must resolve ✕ (U+2715)")

	drawer.free()


func test_navigation_drawer_open_close_toggle() -> void:
	var drawer: NavigationDrawer = _create_nav_drawer()

	# 1. Open drawer
	drawer.open_drawer(false)
	assert_true(drawer.is_open(), "Drawer must report open")
	assert_true(drawer.drawer_overlay.visible, "Overlay must be visible when open")

	# 2. Close drawer
	drawer.close_drawer(false)
	assert_false(drawer.is_open(), "Drawer must report closed")
	assert_false(drawer.drawer_overlay.visible, "Overlay must be invisible when closed")

	# 3. Toggle drawer
	drawer.toggle_drawer(false)
	assert_true(drawer.is_open(), "Toggle when closed should open")
	drawer.toggle_drawer(false)
	assert_false(drawer.is_open(), "Toggle when open should close")

	# 4. Floating button triggers toggle
	drawer.floating_button.pressed.emit()
	assert_true(drawer.is_open(), "Pressing floating button when closed must open drawer")
	drawer.floating_button.pressed.emit()
	assert_false(drawer.is_open(), "Pressing floating button when open must close drawer")

	# 5. Close button triggers close
	drawer.open_drawer(false)
	drawer.close_button.pressed.emit()
	assert_false(drawer.is_open(), "Pressing close button must close drawer")

	# 6. Scrim mouse click triggers close
	drawer.open_drawer(false)
	var click_event: InputEventMouseButton = InputEventMouseButton.new()
	click_event.pressed = true
	click_event.button_index = MOUSE_BUTTON_LEFT
	drawer._on_scrim_gui_input(click_event)
	assert_false(drawer.is_open(), "Clicking scrim must close drawer")

	# 7. ui_cancel (Escape) triggers close
	drawer.open_drawer(false)
	var cancel_event: InputEventAction = InputEventAction.new()
	cancel_event.action = "ui_cancel"
	cancel_event.pressed = true
	drawer._unhandled_input(cancel_event)
	assert_false(drawer.is_open(), "Pressing ui_cancel (Escape) must close drawer")

	drawer.free()


func test_resume_last_page_persistence_and_fallback() -> void:
	var temp_cfg: String = "user://test_nav_resume_temp.cfg"
	var manager: ReadingProgressManager = ReadingProgressManagerScript.new(temp_cfg) as ReadingProgressManager
	manager.clear_progress()

	var drawer: NavigationDrawer = _create_nav_drawer()
	drawer.set_progress_manager(manager)

	# 1. Fallback to Page 1 when file does not exist
	assert_eq(drawer.get_saved_page(), 1, "Default saved page should be Page 1")
	var resume_btn: Button = drawer.get_resume_button()
	assert_not_null(resume_btn, "Resume button must exist")
	assert_true(resume_btn.text.contains("Front Cover"), "Resume text must show Front Cover when at Page 1")
	assert_true(resume_btn.text.contains("(Page 1)"), "Resume text must show (Page 1)")

	# Verify clicking resume button emits page 1 and closes drawer
	var emitted_page: Array[int] = [-1]
	drawer.page_requested.connect(func(page: int) -> void: emitted_page[0] = page)

	drawer.open_drawer(false)
	resume_btn.pressed.emit()
	assert_eq(emitted_page[0], 1, "Clicking resume must emit page 1")
	assert_false(drawer.is_open(), "Clicking resume must close drawer")

	# 2. Save progress for Page 16 (Luminous 1: The Baptism of the Lord)
	manager.save_progress(16)
	drawer.update_resume_button()
	assert_eq(drawer.get_saved_page(), 16, "Saved page must be 16 after progress saved")
	assert_true(resume_btn.text.contains("Baptism"), "Resume text must show Baptism")
	assert_true(resume_btn.text.contains("(Page 16)"), "Resume text must show (Page 16)")

	emitted_page[0] = -1
	drawer.open_drawer(false)
	resume_btn.pressed.emit()
	assert_eq(emitted_page[0], 16, "Clicking resume must emit saved page 16")
	assert_false(drawer.is_open(), "Clicking resume must close drawer")

	# 3. Clean up
	manager.clear_progress()
	drawer.free()


func test_top_level_landmark_section_buttons() -> void:
	var drawer: NavigationDrawer = _create_nav_drawer()

	var expected_landmarks: Array[Dictionary] = [
		{"id": "front_cover", "expected_page": 1},
		{"id": "history", "expected_page": 2},
		{"id": "structure", "expected_page": 3},
		{"id": "opening_prayers", "expected_page": 4},
		{"id": "closing_prayers", "expected_page": 46},
		{"id": "credits", "expected_page": 48},
		{"id": "back_cover", "expected_page": 50}
	]

	var emitted_page: Array[int] = [-1]
	drawer.page_requested.connect(func(page: int) -> void: emitted_page[0] = page)

	for lm: Dictionary in expected_landmarks:
		var sec_id: String = str(lm["id"])
		var target_page: int = int(lm["expected_page"])

		var btn: Button = drawer.get_section_button(sec_id)
		assert_not_null(btn, "Landmark button for %s must exist" % sec_id)
		assert_true(btn.text.length() > 0, "Landmark button text must not be empty")

		emitted_page[0] = -1
		drawer.open_drawer(false)
		btn.pressed.emit()

		assert_eq(emitted_page[0], target_page, "Clicking %s button must emit Page %d" % [sec_id, target_page])
		assert_false(drawer.is_open(), "Clicking %s button must close drawer" % sec_id)

	drawer.free()


func test_mystery_set_accordions_dual_action_rows() -> void:
	var drawer: NavigationDrawer = _create_nav_drawer()

	var mystery_sets: Array[Dictionary] = [
		{"id": "joyful", "first_page": 6},
		{"id": "luminous", "first_page": 16},
		{"id": "sorrowful", "first_page": 26},
		{"id": "glorious", "first_page": 36}
	]

	var emitted_page: Array[int] = [-1]
	drawer.page_requested.connect(func(page: int) -> void: emitted_page[0] = page)

	for mset: Dictionary in mystery_sets:
		var set_id: String = str(mset["id"])
		var first_page: int = int(mset["first_page"])

		var arrow_btn: Button = drawer.get_mystery_set_arrow_button(set_id)
		var title_btn: Button = drawer.get_mystery_set_title_button(set_id)
		var container: VBoxContainer = drawer.get_mystery_set_container(set_id)

		assert_not_null(arrow_btn, "Arrow button for %s must exist" % set_id)
		assert_not_null(title_btn, "Title button for %s must exist" % set_id)
		assert_not_null(container, "Sub-decades container for %s must exist" % set_id)

		# Initial state: collapsed
		assert_false(drawer.is_mystery_set_expanded(set_id), "%s must be collapsed initially" % set_id)
		assert_eq(arrow_btn.text, "▸", "Arrow button must display ▸ when collapsed")
		var parent_margin: MarginContainer = container.get_parent() as MarginContainer
		assert_false(parent_margin.visible, "Sub-container must be hidden when collapsed")

		# Action 1: Click disclosure arrow -> Expands sub-list without closing drawer or emitting page_requested
		drawer.open_drawer(false)
		emitted_page[0] = -1
		arrow_btn.pressed.emit()

		assert_true(drawer.is_mystery_set_expanded(set_id), "%s must be expanded after arrow click" % set_id)
		assert_eq(arrow_btn.text, "▾", "Arrow button must display ▾ when expanded")
		assert_true(parent_margin.visible, "Sub-container must be visible when expanded")
		assert_true(drawer.is_open(), "Drawer must remain OPEN after arrow click")
		assert_eq(emitted_page[0], -1, "Arrow click must NOT emit page_requested")

		# Action 2: Click disclosure arrow again -> Collapses sub-list
		arrow_btn.pressed.emit()
		assert_false(drawer.is_mystery_set_expanded(set_id), "%s must be collapsed after second arrow click" % set_id)
		assert_eq(arrow_btn.text, "▸", "Arrow button must revert to ▸ when collapsed")
		assert_false(parent_margin.visible, "Sub-container must be hidden after second arrow click")
		assert_true(drawer.is_open(), "Drawer must remain OPEN after collapsing")
		assert_eq(emitted_page[0], -1, "Arrow click must NOT emit page_requested")

		# Action 3: Click title button -> Emits 1st mystery page and closes drawer
		emitted_page[0] = -1
		drawer.open_drawer(false)
		title_btn.pressed.emit()

		assert_eq(emitted_page[0], first_page, "Clicking %s title button must emit Page %d" % [set_id, first_page])
		assert_false(drawer.is_open(), "Clicking %s title button must close drawer" % set_id)

	drawer.free()


func test_all_twenty_individual_mystery_buttons() -> void:
	var drawer: NavigationDrawer = _create_nav_drawer()

	var expected_decades: Array[Dictionary] = [
		# Joyful
		{"set": "joyful", "index": 0, "page": 6, "name": "The Annunciation"},
		{"set": "joyful", "index": 1, "page": 8, "name": "The Visitation"},
		{"set": "joyful", "index": 2, "page": 10, "name": "The Nativity"},
		{"set": "joyful", "index": 3, "page": 12, "name": "The Presentation"},
		{"set": "joyful", "index": 4, "page": 14, "name": "Finding"},
		# Luminous
		{"set": "luminous", "index": 0, "page": 16, "name": "Baptism"},
		{"set": "luminous", "index": 1, "page": 18, "name": "Cana"},
		{"set": "luminous", "index": 2, "page": 20, "name": "The Proclamation of the Kingdom"},
		{"set": "luminous", "index": 3, "page": 22, "name": "The Transfiguration"},
		{"set": "luminous", "index": 4, "page": 24, "name": "The Institution of the Eucharist"},
		# Sorrowful
		{"set": "sorrowful", "index": 0, "page": 26, "name": "The Agony in the Garden"},
		{"set": "sorrowful", "index": 1, "page": 28, "name": "The Scourging at the Pillar"},
		{"set": "sorrowful", "index": 2, "page": 30, "name": "The Crowning with Thorns"},
		{"set": "sorrowful", "index": 3, "page": 32, "name": "The Carrying of the Cross"},
		{"set": "sorrowful", "index": 4, "page": 34, "name": "The Crucifixion"},
		# Glorious
		{"set": "glorious", "index": 0, "page": 36, "name": "The Resurrection"},
		{"set": "glorious", "index": 1, "page": 38, "name": "The Ascension"},
		{"set": "glorious", "index": 2, "page": 40, "name": "The Descent of the Holy Spirit"},
		{"set": "glorious", "index": 3, "page": 42, "name": "Assumption"},
		{"set": "glorious", "index": 4, "page": 44, "name": "Coronation"}
	]

	var emitted_page: Array[int] = [-1]
	drawer.page_requested.connect(func(page: int) -> void: emitted_page[0] = page)

	for dec: Dictionary in expected_decades:
		var set_id: String = str(dec["set"])
		var idx: int = int(dec["index"])
		var expected_page: int = int(dec["page"])
		var dec_name: String = str(dec["name"])

		var btn: Button = drawer.get_mystery_button(set_id, idx)
		assert_not_null(btn, "Decade button %s[%d] must exist" % [set_id, idx])
		assert_true(btn.text.contains(dec_name), "Decade button must contain title '%s'" % dec_name)

		# Also test lookup by target page
		var btn_by_page: Button = drawer.get_mystery_button_by_page(expected_page)
		assert_eq(btn, btn_by_page, "get_mystery_button_by_page(%d) must match" % expected_page)

		emitted_page[0] = -1
		drawer.open_drawer(false)
		btn.pressed.emit()

		assert_eq(emitted_page[0], expected_page, "Decade %s[%d] must emit Page %d" % [set_id, idx, expected_page])
		assert_false(drawer.is_open(), "Clicking decade button must close drawer")

	drawer.free()


func test_liturgical_badge_assignment() -> void:
	var loader: RosaryDataLoader = RosaryDataLoaderScript.new() as RosaryDataLoader
	loader.load_all()

	var today_rec: String = loader.get_recommended_mystery_set_for_today()
	assert_true(today_rec in ["joyful", "luminous", "sorrowful", "glorious"], "Recommended set must be valid")

	var drawer: NavigationDrawer = _create_nav_drawer()
	drawer.set_data_loader(loader)

	assert_eq(drawer.get_recommended_mystery_set(), today_rec, "Drawer recommended set must match loader")

	for set_id: String in ["joyful", "luminous", "sorrowful", "glorious"]:
		var is_today: bool = (set_id == today_rec)
		assert_eq(drawer.is_mystery_set_recommended(set_id), is_today, "is_mystery_set_recommended(%s) mismatch" % set_id)

		var badge_lbl: Label = drawer.get_mystery_set_badge_label(set_id)
		assert_not_null(badge_lbl, "Badge label for %s must exist" % set_id)
		assert_eq(badge_lbl.visible, is_today, "Badge visibility for %s must be %s" % [set_id, str(is_today)])
		if is_today:
			assert_true(badge_lbl.text.contains("Today"), "Badge text must contain 'Today'")

	drawer.free()


func test_main_integration_with_navigation_drawer() -> void:
	var progress: ReadingProgressManager = ReadingProgressManagerScript.new() as ReadingProgressManager
	progress.clear_progress()

	var main: Main = MainScene.instantiate() as Main
	test_root_window.add_child(main)
	main._ready()

	var nav_drawer: NavigationDrawer = main.get_navigation_drawer()
	assert_not_null(nav_drawer, "Main must contain NavigationDrawer node")
	if nav_drawer != null:
		nav_drawer._ready()

	# 1. Navigation request from drawer scrolls Main
	assert_eq(main.get_current_page(), 1, "Initial page should be Page 1")
	nav_drawer.page_requested.emit(26) # Sorrowful 1st mystery
	assert_eq(main.get_current_page(), 26, "Main must scroll to Page 26 on drawer page_requested")

	# 2. Reading progress in drawer updates when Main scrolls
	main.scroll_to_page(16, false)
	assert_eq(nav_drawer.get_saved_page(), 16, "Drawer saved page must update when Main scrolls")

	# 3. Opening drawer pauses background scroll touches and reader button
	assert_eq(main.scroll_container.mouse_filter, Control.MOUSE_FILTER_IGNORE, "ScrollContainer should have MOUSE_FILTER_IGNORE when drawer closed")
	assert_eq(main.reader_button.mouse_filter, Control.MOUSE_FILTER_STOP, "ReaderButton should have MOUSE_FILTER_STOP when drawer closed")
	nav_drawer.open_drawer(false)
	assert_eq(main.scroll_container.mouse_filter, Control.MOUSE_FILTER_IGNORE, "ScrollContainer must have MOUSE_FILTER_IGNORE when drawer open")
	assert_eq(main.reader_button.mouse_filter, Control.MOUSE_FILTER_IGNORE, "ReaderButton must have MOUSE_FILTER_IGNORE when drawer open")

	nav_drawer.close_drawer(false)
	assert_eq(main.scroll_container.mouse_filter, Control.MOUSE_FILTER_IGNORE, "ScrollContainer must maintain MOUSE_FILTER_IGNORE when drawer closed")
	assert_eq(main.reader_button.mouse_filter, Control.MOUSE_FILTER_STOP, "ReaderButton must restore MOUSE_FILTER_STOP when drawer closed")

	main.free()
	progress.clear_progress()


func test_floating_button_centering_and_stylebox_calibration() -> void:
	var drawer: NavigationDrawer = _create_nav_drawer()
	var float_btn: Button = drawer.get_floating_button()
	assert_not_null(float_btn, "FloatingButton must exist")

	# 1. Dimensions and Positioning (104x104 at y=18..122, right margin 18)
	assert_eq(float_btn.custom_minimum_size, Vector2(104, 104), "FloatingButton custom_minimum_size must be 104x104")
	assert_eq(float_btn.get_combined_minimum_size(), Vector2(104, 104), "FloatingButton get_combined_minimum_size must be 104x104")
	assert_eq(float_btn.size, Vector2(104, 104), "FloatingButton size must be 104x104")
	assert_eq(float_btn.position.y, 18.0, "FloatingButton position.y must be 18.0")
	assert_eq(float_btn.position.y + float_btn.size.y, 122.0, "FloatingButton bottom y must be 122.0")
	assert_eq(float_btn.offset_left, -122.0, "FloatingButton offset_left must be -122")
	assert_eq(float_btn.offset_top, 18.0, "FloatingButton offset_top must be 18")
	assert_eq(float_btn.offset_right, -18.0, "FloatingButton offset_right must be -18")
	assert_eq(float_btn.offset_bottom, 122.0, "FloatingButton offset_bottom must be 122")

	# 2. Text and Font Glyph Resolution
	assert_eq(float_btn.text, "☰", "FloatingButton text must be hamburger icon ☰")
	var font: Font = float_btn.get_theme_font("font")
	assert_not_null(font, "FloatingButton font must exist")
	assert_true(font.has_char(0x2630), "FloatingButton font must support ☰ (0x2630)")
	assert_eq(float_btn.get_theme_font_size("font_size"), 56, "FloatingButton font size must be 56pt")
	assert_true(font.get_height(56) + 12.0 <= 104.0, "FloatingButton font height + top margin must not exceed 104px")

	# 3. Calibrated StyleBox Margins for Pixel Centering across all states
	var states: Array[String] = ["normal", "hover", "pressed", "focus"]
	for state: String in states:
		var style: StyleBox = float_btn.get_theme_stylebox(state)
		assert_not_null(style, "FloatingButton %s stylebox must be defined" % state)
		if style != null:
			# Symmetric horizontal margins
			assert_eq(style.content_margin_left, 0.0, "FloatingButton %s content_margin_left must be 0" % state)
			assert_eq(style.content_margin_right, 0.0, "FloatingButton %s content_margin_right must be 0" % state)
			assert_eq(style.content_margin_left, style.content_margin_right, "FloatingButton %s horizontal margins must be symmetric" % state)

			# Calibrated vertical margin to counteract font ascent/descent bias and center ☰
			assert_eq(style.content_margin_top, 12.0, "FloatingButton %s content_margin_top must be 12.0" % state)
			assert_eq(style.content_margin_bottom, 0.0, "FloatingButton %s content_margin_bottom must be 0.0" % state)

	drawer.free()


func test_navigation_drawer_preset_normalization_and_panel_widths() -> void:
	var drawer: NavigationDrawer = _create_nav_drawer()
	var panel: PanelContainer = drawer.get_drawer_panel()
	assert_not_null(panel, "DrawerPanel must exist")

	# 1. Preset Normalization
	drawer.set_text_size_preset(0)
	assert_eq(drawer.get_text_size_preset(), "normal", "0 should normalize to 'normal'")
	drawer.set_text_size_preset(1)
	assert_eq(drawer.get_text_size_preset(), "mobile", "1 should normalize to 'mobile'")
	drawer.set_text_size_preset(2)
	assert_eq(drawer.get_text_size_preset(), "extra_large", "2 should normalize to 'extra_large'")
	drawer.set_text_size_preset("XL")
	assert_eq(drawer.get_text_size_preset(), "extra_large", "'XL' should normalize to 'extra_large'")
	drawer.set_text_size_preset("unknown_value")
	assert_eq(drawer.get_text_size_preset(), "normal", "Unknown should fall back to 'normal'")

	# 2. Panel Widths across Presets
	drawer.set_text_size_preset("normal")
	assert_eq(drawer.get_panel_width(), 400.0, "Normal panel width must be 400.0")
	assert_eq(panel.custom_minimum_size.x, 400.0, "Normal panel custom_minimum_size.x must be 400.0")

	drawer.set_text_size_preset("mobile")
	assert_eq(drawer.get_panel_width(), 560.0, "Mobile panel width must be 560.0")
	assert_eq(panel.custom_minimum_size.x, 560.0, "Mobile panel custom_minimum_size.x must be 560.0")

	drawer.set_text_size_preset("extra_large")
	assert_eq(drawer.get_panel_width(), 680.0, "Extra Large panel width must be 680.0")
	assert_eq(panel.custom_minimum_size.x, 680.0, "Extra Large panel custom_minimum_size.x must be 680.0")

	# 3. Offsets when closed vs open across presets
	drawer.set_text_size_preset("normal")
	drawer.close_drawer(false)
	assert_eq(panel.offset_left, 0.0, "Normal closed offset_left must be 0.0")
	assert_eq(panel.offset_right, 400.0, "Normal closed offset_right must be 400.0")

	drawer.open_drawer(false)
	assert_eq(panel.offset_left, -400.0, "Normal open offset_left must be -400.0")
	assert_eq(panel.offset_right, 0.0, "Normal open offset_right must be 0.0")

	# While open, changing preset dynamically updates open offsets
	drawer.set_text_size_preset("mobile")
	assert_eq(panel.offset_left, -560.0, "Mobile open offset_left must be -560.0")
	assert_eq(panel.offset_right, 0.0, "Mobile open offset_right must be 0.0")

	drawer.set_text_size_preset("extra_large")
	assert_eq(panel.offset_left, -680.0, "Extra Large open offset_left must be -680.0")
	assert_eq(panel.offset_right, 0.0, "Extra Large open offset_right must be 0.0")

	# While closed, changing preset dynamically updates closed offsets
	drawer.close_drawer(false)
	assert_eq(panel.offset_left, 0.0, "Extra Large closed offset_left must be 0.0")
	assert_eq(panel.offset_right, 680.0, "Extra Large closed offset_right must be 680.0")

	drawer.set_text_size_preset("normal")
	assert_eq(panel.offset_left, 0.0, "Normal closed offset_left must be 0.0")
	assert_eq(panel.offset_right, 400.0, "Normal closed offset_right must be 400.0")

	drawer.free()


func test_navigation_drawer_typography_and_control_heights_scaling() -> void:
	var drawer: NavigationDrawer = _create_nav_drawer()

	var title_lbl: Label = drawer.get_title_label()
	var close_btn: Button = drawer.get_close_button()
	var resume_btn: Button = drawer.get_resume_button()
	var mystery_hdr: Label = drawer.get_mystery_header()

	assert_not_null(title_lbl, "TitleLabel must exist")
	assert_not_null(close_btn, "CloseButton must exist")
	assert_not_null(resume_btn, "ResumeButton must exist")
	assert_not_null(mystery_hdr, "MysteryHeader label must exist")

	var preset_specs: Array[Dictionary] = [
		{
			"preset": "normal",
			"panel_width": 400.0,
			"title_font_size": 24,
			"close_font_size": 22,
			"close_btn_size": Vector2(40, 40),
			"resume_font_size": 17,
			"resume_min_h": 46.0,
			"landmark_font_size": 17,
			"landmark_min_h": 40.0,
			"header_font_size": 15,
			"set_font_size": 18,
			"set_min_h": 42.0,
			"arrow_btn_size": Vector2(38, 42),
			"badge_font_size": 13,
			"decade_font_size": 16,
			"decade_min_h": 36.0
		},
		{
			"preset": "mobile",
			"panel_width": 560.0,
			"title_font_size": 32,
			"close_font_size": 28,
			"close_btn_size": Vector2(48, 48),
			"resume_font_size": 24,
			"resume_min_h": 58.0,
			"landmark_font_size": 24,
			"landmark_min_h": 52.0,
			"header_font_size": 20,
			"set_font_size": 25,
			"set_min_h": 54.0,
			"arrow_btn_size": Vector2(48, 54),
			"badge_font_size": 18,
			"decade_font_size": 22,
			"decade_min_h": 48.0
		},
		{
			"preset": "extra_large",
			"panel_width": 680.0,
			"title_font_size": 38,
			"close_font_size": 34,
			"close_btn_size": Vector2(56, 56),
			"resume_font_size": 30,
			"resume_min_h": 72.0,
			"landmark_font_size": 30,
			"landmark_min_h": 64.0,
			"header_font_size": 25,
			"set_font_size": 31,
			"set_min_h": 66.0,
			"arrow_btn_size": Vector2(56, 66),
			"badge_font_size": 22,
			"decade_font_size": 28,
			"decade_min_h": 58.0
		}
	]

	for spec: Dictionary in preset_specs:
		var preset: String = str(spec["preset"])
		drawer.set_text_size_preset(preset)

		# TitleLabel
		assert_eq(title_lbl.get_theme_font_size("font_size"), int(spec["title_font_size"]),
			"TitleLabel font_size must be %d for preset %s" % [int(spec["title_font_size"]), preset])

		# CloseButton
		assert_eq(close_btn.get_theme_font_size("font_size"), int(spec["close_font_size"]),
			"CloseButton font_size must be %d for preset %s" % [int(spec["close_font_size"]), preset])
		assert_eq(close_btn.custom_minimum_size, spec["close_btn_size"],
			"CloseButton size must be %s for preset %s" % [str(spec["close_btn_size"]), preset])

		# ResumeButton
		assert_eq(resume_btn.get_theme_font_size("font_size"), int(spec["resume_font_size"]),
			"ResumeButton font_size must be %d for preset %s" % [int(spec["resume_font_size"]), preset])
		assert_eq(resume_btn.custom_minimum_size.y, float(spec["resume_min_h"]),
			"ResumeButton min height must be %f for preset %s" % [float(spec["resume_min_h"]), preset])
		assert_eq(resume_btn.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART,
			"ResumeButton autowrap_mode must be AUTOWRAP_WORD_SMART")

		# Landmark Buttons
		for sec_id: String in drawer._section_buttons.keys():
			var btn: Button = drawer.get_section_button(sec_id)
			assert_not_null(btn, "Landmark button %s must exist" % sec_id)
			assert_eq(btn.get_theme_font_size("font_size"), int(spec["landmark_font_size"]),
				"Landmark %s font_size must be %d for preset %s" % [sec_id, int(spec["landmark_font_size"]), preset])
			assert_eq(btn.custom_minimum_size.y, float(spec["landmark_min_h"]),
				"Landmark %s min height must be %f for preset %s" % [sec_id, float(spec["landmark_min_h"]), preset])
			assert_eq(btn.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART,
				"Landmark %s autowrap_mode must be AUTOWRAP_WORD_SMART" % sec_id)

		# Mystery Header
		assert_eq(mystery_hdr.get_theme_font_size("font_size"), int(spec["header_font_size"]),
			"MysteryHeader font_size must be %d for preset %s" % [int(spec["header_font_size"]), preset])

		# Mystery Set Title & Arrow Buttons
		for set_id: String in NavigationDrawer.MYSTERY_SET_ORDER:
			var t_btn: Button = drawer.get_mystery_set_title_button(set_id)
			assert_not_null(t_btn, "TitleButton %s must exist" % set_id)
			assert_eq(t_btn.get_theme_font_size("font_size"), int(spec["set_font_size"]),
				"TitleButton %s font_size must be %d for preset %s" % [set_id, int(spec["set_font_size"]), preset])
			assert_eq(t_btn.custom_minimum_size.y, float(spec["set_min_h"]),
				"TitleButton %s min height must be %f for preset %s" % [set_id, float(spec["set_min_h"]), preset])
			assert_eq(t_btn.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART,
				"TitleButton %s autowrap_mode must be AUTOWRAP_WORD_SMART" % set_id)

			var a_btn: Button = drawer.get_mystery_set_arrow_button(set_id)
			assert_not_null(a_btn, "ArrowButton %s must exist" % set_id)
			assert_eq(a_btn.get_theme_font_size("font_size"), int(spec["set_font_size"]),
				"ArrowButton %s font_size must be %d for preset %s" % [set_id, int(spec["set_font_size"]), preset])
			assert_eq(a_btn.custom_minimum_size, spec["arrow_btn_size"],
				"ArrowButton %s size must be %s for preset %s" % [set_id, str(spec["arrow_btn_size"]), preset])

			var badge_lbl: Label = drawer.get_mystery_set_badge_label(set_id)
			assert_not_null(badge_lbl, "BadgeLabel %s must exist" % set_id)
			assert_eq(badge_lbl.get_theme_font_size("font_size"), int(spec["badge_font_size"]),
				"BadgeLabel %s font_size must be %d for preset %s" % [set_id, int(spec["badge_font_size"]), preset])

			for dec_idx: int in range(5):
				var dec_btn: Button = drawer.get_mystery_button(set_id, dec_idx)
				assert_not_null(dec_btn, "Decade %s[%d] must exist" % [set_id, dec_idx])
				assert_eq(dec_btn.get_theme_font_size("font_size"), int(spec["decade_font_size"]),
					"Decade %s[%d] font_size must be %d for preset %s" % [set_id, dec_idx, int(spec["decade_font_size"]), preset])
				assert_eq(dec_btn.custom_minimum_size.y, float(spec["decade_min_h"]),
					"Decade %s[%d] min height must be %f for preset %s" % [set_id, dec_idx, float(spec["decade_min_h"]), preset])
				assert_eq(dec_btn.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART,
					"Decade %s[%d] autowrap_mode must be AUTOWRAP_WORD_SMART" % [set_id, dec_idx])

	drawer.free()


func test_main_preset_switching_updates_navigation_drawer() -> void:
	var progress: ReadingProgressManager = ReadingProgressManagerScript.new() as ReadingProgressManager
	progress.clear_progress()

	var main: Main = MainScene.instantiate() as Main
	test_root_window.add_child(main)
	main._ready()

	var nav_drawer: NavigationDrawer = main.get_navigation_drawer()
	assert_not_null(nav_drawer, "Main must contain NavigationDrawer")
	if nav_drawer != null:
		nav_drawer._ready()

	# 1. Initial State: Normal
	assert_eq(main.get_text_size_preset(), "normal", "Main preset should be normal initially")
	assert_eq(nav_drawer.get_text_size_preset(), "normal", "Drawer preset should match Main initially")
	assert_eq(nav_drawer.get_panel_width(), 400.0, "Drawer panel width should be 400.0 initially")
	assert_eq(nav_drawer.get_drawer_panel().custom_minimum_size.x, 400.0, "Panel min size.x must be 400.0")

	# 2. Cycle Preset: Normal -> Mobile
	var next_p: String = main.cycle_text_size_preset()
	assert_eq(next_p, "mobile", "1st cycle should switch to mobile")
	assert_eq(main.get_text_size_preset(), "mobile", "Main preset should be mobile")
	assert_eq(nav_drawer.get_text_size_preset(), "mobile", "Drawer preset should be mobile")
	assert_eq(nav_drawer.get_panel_width(), 560.0, "Drawer panel width should be 560.0")
	assert_eq(nav_drawer.get_drawer_panel().custom_minimum_size.x, 560.0, "Panel min size.x must be 560.0")

	# 3. Cycle Preset: Mobile -> Extra Large
	next_p = main.cycle_text_size_preset()
	assert_eq(next_p, "extra_large", "2nd cycle should switch to extra_large")
	assert_eq(main.get_text_size_preset(), "extra_large", "Main preset should be extra_large")
	assert_eq(nav_drawer.get_text_size_preset(), "extra_large", "Drawer preset should be extra_large")
	assert_eq(nav_drawer.get_panel_width(), 680.0, "Drawer panel width should be 680.0")
	assert_eq(nav_drawer.get_drawer_panel().custom_minimum_size.x, 680.0, "Panel min size.x must be 680.0")

	# 4. Cycle Preset: Extra Large -> Normal
	next_p = main.cycle_text_size_preset()
	assert_eq(next_p, "normal", "3rd cycle should return to normal")
	assert_eq(main.get_text_size_preset(), "normal", "Main preset should be normal")
	assert_eq(nav_drawer.get_text_size_preset(), "normal", "Drawer preset should be normal")
	assert_eq(nav_drawer.get_panel_width(), 400.0, "Drawer panel width should be 400.0")
	assert_eq(nav_drawer.get_drawer_panel().custom_minimum_size.x, 400.0, "Panel min size.x must be 400.0")

	# 5. Open Drawer and Change Presets Directly
	nav_drawer.open_drawer(false)
	assert_true(nav_drawer.is_open(), "Drawer should be open")
	assert_eq(nav_drawer.get_drawer_panel().offset_left, -400.0, "Normal open offset_left must be -400.0")
	assert_eq(nav_drawer.get_drawer_panel().offset_right, 0.0, "Normal open offset_right must be 0.0")

	main.set_text_size_preset("mobile")
	assert_eq(nav_drawer.get_text_size_preset(), "mobile", "Drawer preset must be mobile")
	assert_eq(nav_drawer.get_drawer_panel().offset_left, -560.0, "Mobile open offset_left must be -560.0")
	assert_eq(nav_drawer.get_drawer_panel().offset_right, 0.0, "Mobile open offset_right must be 0.0")

	main.set_text_size_preset("extra_large")
	assert_eq(nav_drawer.get_text_size_preset(), "extra_large", "Drawer preset must be extra_large")
	assert_eq(nav_drawer.get_drawer_panel().offset_left, -680.0, "Extra Large open offset_left must be -680.0")
	assert_eq(nav_drawer.get_drawer_panel().offset_right, 0.0, "Extra Large open offset_right must be 0.0")

	nav_drawer.close_drawer(false)
	assert_false(nav_drawer.is_open(), "Drawer should be closed")
	assert_eq(nav_drawer.get_drawer_panel().offset_left, 0.0, "Extra Large closed offset_left must be 0.0")
	assert_eq(nav_drawer.get_drawer_panel().offset_right, 680.0, "Extra Large closed offset_right must be 680.0")

	main.free()
	progress.clear_progress()


func test_navigation_drawer_fallbacks_and_mystery_set_defaults() -> void:
	var drawer: NavigationDrawer = _create_nav_drawer()
	assert_eq(drawer.get_page_title(3), "Structure of This Book & How to Pray", "Page 3 title must match canonical 'Structure of This Book & How to Pray'")

	var loader: RosaryDataLoader = RosaryDataLoaderScript.new() as RosaryDataLoader
	loader.load_all()
	var canonical_sets: Array = loader.mysteries_data.get("mystery_sets", [])
	assert_true(canonical_sets.size() == 4, "Must have 4 canonical mystery sets")

	var defaults: Dictionary = NavigationDrawer.MYSTERY_SET_DEFAULTS
	for set_dict: Variant in canonical_sets:
		var c_set: Dictionary = set_dict as Dictionary
		var set_id: String = str(c_set.get("id", ""))
		var expected_title: String = str(c_set.get("title", ""))
		assert_true(defaults.has(set_id), "MYSTERY_SET_DEFAULTS must contain set '%s'" % set_id)
		var def_set: Dictionary = defaults.get(set_id, {}) as Dictionary
		assert_eq(str(def_set.get("title", "")), expected_title, "Mystery set title for '%s' must match canonical" % set_id)

		var canonical_decades: Array = c_set.get("decades", []) as Array
		var def_decades: Array = def_set.get("decades", []) as Array
		assert_eq(def_decades.size(), canonical_decades.size(), "Decade count for set '%s' must match" % set_id)

		for i: int in range(canonical_decades.size()):
			var c_dec: Dictionary = canonical_decades[i] as Dictionary
			var d_dec: Dictionary = def_decades[i] as Dictionary
			var exp_dec_title: String = str(c_dec.get("title", ""))
			var actual_dec_title: String = str(d_dec.get("title", ""))
			assert_eq(actual_dec_title, exp_dec_title, "Decade %d in '%s' must match canonical '%s'" % [i + 1, set_id, exp_dec_title])

	drawer.free()


func cleanup() -> void:
	var progress: ReadingProgressManager = ReadingProgressManagerScript.new() as ReadingProgressManager
	progress.clear_progress()
