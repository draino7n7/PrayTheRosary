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

	# 3. Opening drawer pauses background scroll touches
	assert_eq(main.scroll_container.mouse_filter, Control.MOUSE_FILTER_STOP, "ScrollContainer should have MOUSE_FILTER_STOP when drawer closed")
	nav_drawer.open_drawer(false)
	assert_eq(main.scroll_container.mouse_filter, Control.MOUSE_FILTER_IGNORE, "ScrollContainer must have MOUSE_FILTER_IGNORE when drawer open")

	nav_drawer.close_drawer(false)
	assert_eq(main.scroll_container.mouse_filter, Control.MOUSE_FILTER_STOP, "ScrollContainer must restore MOUSE_FILTER_STOP when drawer closed")

	main.free()
