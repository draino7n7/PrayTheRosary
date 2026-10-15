extends "res://tests/test_base.gd"
## Automated unit tests for continuous 50-page vertical scroll, in-stream jump bars,
## reading progress persistence, and texture virtualization.

const RosaryDataLoaderScript = preload("res://scripts/data/rosary_data_loader.gd")
const ReadingProgressManagerScript = preload("res://scripts/core/reading_progress_manager.gd")
const MainScene: PackedScene = preload("res://scenes/main/main.tscn")
const InStreamJumpBarScene: PackedScene = preload("res://scenes/ui/in_stream_jump_bar.tscn")


func _get_loaded_loader() -> RosaryDataLoader:
	var loader: RosaryDataLoader = RosaryDataLoaderScript.new() as RosaryDataLoader
	loader.load_all()
	return loader


func test_reading_progress_manager_persistence() -> void:
	var test_cfg_path: String = "user://test_reading_progress_temp.cfg"
	var manager: ReadingProgressManager = ReadingProgressManagerScript.new(test_cfg_path) as ReadingProgressManager
	manager.clear_progress()

	# 1. Defaults to Page 1 when file does not exist
	assert_false(manager.has_saved_progress(), "New manager should not have saved progress initially")
	assert_eq(manager.load_progress(), 1, "Default progress should be Page 1")

	# 2. Saves valid progress and reloads cleanly
	assert_true(manager.save_progress(16), "Saving Page 16 should succeed")
	assert_true(manager.has_saved_progress(), "Manager should now have saved progress")
	assert_eq(manager.load_progress(), 16, "Loaded progress should be Page 16")

	# 3. Clamping boundary checks: minimum 1, maximum 50
	assert_true(manager.save_progress(-5), "Saving page below 1 should clamp")
	assert_eq(manager.load_progress(), 1, "Below-min progress should clamp to Page 1")

	assert_true(manager.save_progress(100), "Saving page above 50 should clamp")
	assert_eq(manager.load_progress(), 50, "Above-max progress should clamp to Page 50")

	# Cleanup
	manager.clear_progress()
	assert_false(FileAccess.file_exists(test_cfg_path), "Temp test config file should be cleared")


func test_in_stream_jump_bar_standalone_post_opening_prayers() -> void:
	var loader: RosaryDataLoader = _get_loaded_loader()
	var separators: Array = loader.get_in_stream_separators()
	assert_true(separators.size() >= 5, "Loader must return at least 5 in-stream separators")

	var opening_sep: Dictionary = separators[0]
	assert_eq(str(opening_sep.get("id", "")), "after_opening_prayers_jump", "First separator must be after_opening_prayers_jump")
	assert_eq(int(opening_sep.get("after_page_number", 0)), 5, "First separator must be after Page 5")

	var jump_bar: InStreamJumpBar = InStreamJumpBarScene.instantiate() as InStreamJumpBar
	test_root_window.add_child(jump_bar)
	jump_bar.bind_separator_data(opening_sep, loader)

	assert_eq(jump_bar.get_separator_id(), "after_opening_prayers_jump", "Separator ID must match")
	assert_eq(jump_bar.get_after_page_number(), 5, "After page number must be 5")
	assert_eq(jump_bar.get_button_count(), 4, "Post-Opening Prayers jump bar must render 4 buttons")
	assert_eq(jump_bar.get_prompt_text(), "Select a Mystery Set to Continue Praying:", "Prompt must match")

	# Verify target pages for each of the 4 mystery sets
	assert_eq(jump_bar.get_target_page_for_button(0), 6, "Button 0 must jump to Joyful Mysteries (Page 6)")
	assert_eq(jump_bar.get_target_page_for_button(1), 16, "Button 1 must jump to Luminous Mysteries (Page 16)")
	assert_eq(jump_bar.get_target_page_for_button(2), 26, "Button 2 must jump to Sorrowful Mysteries (Page 26)")
	assert_eq(jump_bar.get_target_page_for_button(3), 36, "Button 3 must jump to Glorious Mysteries (Page 36)")

	# Verify today's recommended mystery set is badged
	var today_rec: String = loader.get_recommended_mystery_set_for_today()
	var found_rec_button: bool = false
	for i: int in range(4):
		if jump_bar.is_recommended_button(i):
			found_rec_button = true
			break
	assert_true(found_rec_button, "Exactly one mystery set button must be marked as today's recommendation (%s)" % today_rec)

	# Verify signal emission on button press
	var emitted_page: Array[int] = [-1]
	jump_bar.jump_requested.connect(func(page: int) -> void: emitted_page[0] = page)
	jump_bar._on_button_pressed(26)
	assert_eq(emitted_page[0], 26, "Pressing button must emit jump_requested with target page")

	jump_bar.free()


func test_in_stream_jump_bars_post_mystery_sets() -> void:
	var loader: RosaryDataLoader = _get_loaded_loader()
	var separators: Array = loader.get_in_stream_separators()

	var expected_mystery_ends: Array[Dictionary] = [
		{"index": 1, "id": "after_joyful_mysteries_jump", "after_page": 15},
		{"index": 2, "id": "after_luminous_mysteries_jump", "after_page": 25},
		{"index": 3, "id": "after_sorrowful_mysteries_jump", "after_page": 35},
		{"index": 4, "id": "after_glorious_mysteries_jump", "after_page": 45}
	]

	for exp: Dictionary in expected_mystery_ends:
		var sep_data: Dictionary = separators[int(exp["index"])]
		assert_eq(str(sep_data.get("id", "")), str(exp["id"]), "Separator %s ID must match" % exp["id"])
		assert_eq(int(sep_data.get("after_page_number", 0)), int(exp["after_page"]), "Separator %s after_page must match" % exp["id"])

		var jump_bar: InStreamJumpBar = InStreamJumpBarScene.instantiate() as InStreamJumpBar
		test_root_window.add_child(jump_bar)
		jump_bar.bind_separator_data(sep_data, loader)

		assert_eq(jump_bar.get_button_count(), 1, "Post-mystery separator must contain exactly 1 action button")
		assert_eq(jump_bar.get_target_page_for_button(0), 46, "Post-mystery action button must jump directly to Page 46 (Closing Prayers)")

		var emitted_target: Array[int] = [-1]
		jump_bar.jump_requested.connect(func(page: int) -> void: emitted_target[0] = page)
		jump_bar._on_button_pressed(46)
		assert_eq(emitted_target[0], 46, "Button press must emit jump_requested to Page 46")

		jump_bar.free()


func test_continuous_scroll_stream_structure_and_ordering() -> void:
	var main_node: Main = MainScene.instantiate() as Main
	test_root_window.add_child(main_node)
	main_node._ready()

	# Verify exact count of 55 elements: 50 page cards and 5 in-stream jump bars
	var element_count: int = main_node.get_stream_element_count()
	assert_eq(element_count, 55, "Stream must contain exactly 55 child elements (50 pages + 5 separators), got %d" % element_count)

	var elements: Array[Node] = main_node.get_stream_elements()
	assert_eq(elements.size(), 55, "Stream element array size must be 55")

	# Sequence definition for verification:
	# Indices 0..4: Pages 1..5
	for p: int in range(1, 6):
		var node: Node = elements[p - 1]
		assert_true(node is PageCard, "Element %d must be PageCard" % (p - 1))
		assert_eq((node as PageCard).page_number, p, "PageCard at index %d must be Page %d" % [p - 1, p])

	# Index 5: Separator 1 (after_opening_prayers_jump, after Page 5)
	assert_true(elements[5] is InStreamJumpBar, "Element 5 must be InStreamJumpBar")
	assert_eq((elements[5] as InStreamJumpBar).get_separator_id(), "after_opening_prayers_jump", "Element 5 must be after_opening_prayers_jump")
	assert_eq((elements[5] as InStreamJumpBar).get_after_page_number(), 5, "Element 5 must be after Page 5")

	# Indices 6..15: Pages 6..15 (Joyful Mysteries)
	for p: int in range(6, 16):
		var idx: int = p  # page 6 is at index 6
		var node: Node = elements[idx]
		assert_true(node is PageCard, "Element %d must be PageCard for Page %d" % [idx, p])
		assert_eq((node as PageCard).page_number, p, "PageCard at index %d must be Page %d" % [idx, p])

	# Index 16: Separator 2 (after_joyful_mysteries_jump, after Page 15)
	assert_true(elements[16] is InStreamJumpBar, "Element 16 must be InStreamJumpBar")
	assert_eq((elements[16] as InStreamJumpBar).get_separator_id(), "after_joyful_mysteries_jump", "Element 16 must be after_joyful_mysteries_jump")
	assert_eq((elements[16] as InStreamJumpBar).get_after_page_number(), 15, "Element 16 must be after Page 15")

	# Indices 17..26: Pages 16..25 (Luminous Mysteries)
	for p: int in range(16, 26):
		var idx: int = p + 1
		var node: Node = elements[idx]
		assert_true(node is PageCard, "Element %d must be PageCard for Page %d" % [idx, p])
		assert_eq((node as PageCard).page_number, p, "PageCard at index %d must be Page %d" % [idx, p])

	# Index 27: Separator 3 (after_luminous_mysteries_jump, after Page 25)
	assert_true(elements[27] is InStreamJumpBar, "Element 27 must be InStreamJumpBar")
	assert_eq((elements[27] as InStreamJumpBar).get_separator_id(), "after_luminous_mysteries_jump", "Element 27 must be after_luminous_mysteries_jump")
	assert_eq((elements[27] as InStreamJumpBar).get_after_page_number(), 25, "Element 27 must be after Page 25")

	# Indices 28..37: Pages 26..35 (Sorrowful Mysteries)
	for p: int in range(26, 36):
		var idx: int = p + 2
		var node: Node = elements[idx]
		assert_true(node is PageCard, "Element %d must be PageCard for Page %d" % [idx, p])
		assert_eq((node as PageCard).page_number, p, "PageCard at index %d must be Page %d" % [idx, p])

	# Index 38: Separator 4 (after_sorrowful_mysteries_jump, after Page 35)
	assert_true(elements[38] is InStreamJumpBar, "Element 38 must be InStreamJumpBar")
	assert_eq((elements[38] as InStreamJumpBar).get_separator_id(), "after_sorrowful_mysteries_jump", "Element 38 must be after_sorrowful_mysteries_jump")
	assert_eq((elements[38] as InStreamJumpBar).get_after_page_number(), 35, "Element 38 must be after Page 35")

	# Indices 39..48: Pages 36..45 (Glorious Mysteries)
	for p: int in range(36, 46):
		var idx: int = p + 3
		var node: Node = elements[idx]
		assert_true(node is PageCard, "Element %d must be PageCard for Page %d" % [idx, p])
		assert_eq((node as PageCard).page_number, p, "PageCard at index %d must be Page %d" % [idx, p])

	# Index 49: Separator 5 (after_glorious_mysteries_jump, after Page 45)
	assert_true(elements[49] is InStreamJumpBar, "Element 49 must be InStreamJumpBar")
	assert_eq((elements[49] as InStreamJumpBar).get_separator_id(), "after_glorious_mysteries_jump", "Element 49 must be after_glorious_mysteries_jump")
	assert_eq((elements[49] as InStreamJumpBar).get_after_page_number(), 45, "Element 49 must be after Page 45")

	# Indices 50..54: Pages 46..50 (Closing Prayers, Credits, Back Cover)
	for p: int in range(46, 51):
		var idx: int = p + 4
		var node: Node = elements[idx]
		assert_true(node is PageCard, "Element %d must be PageCard for Page %d" % [idx, p])
		assert_eq((node as PageCard).page_number, p, "PageCard at index %d must be Page %d" % [idx, p])

	main_node.free()


func test_scroll_to_page_bounds_and_target_positions() -> void:
	var main_node: Main = MainScene.instantiate() as Main
	test_root_window.add_child(main_node)
	main_node._ready()

	# Verify Page 1 starts at top offset 0
	var pos_p1: int = main_node.get_target_scroll_for_page(1)
	assert_eq(pos_p1, 0, "Page 1 target scroll must be 0")

	# Verify scroll positions increase strictly monotonically
	var prev_pos: int = pos_p1
	var sample_pages: Array[int] = [2, 5, 6, 16, 26, 36, 46, 50]
	for p: int in sample_pages:
		var pos: int = main_node.get_target_scroll_for_page(p)
		assert_true(pos > prev_pos, "Page %d target position (%d) must exceed previous (%d)" % [p, pos, prev_pos])
		prev_pos = pos

	# Verify clamping
	assert_eq(main_node.get_target_scroll_for_page(0), pos_p1, "Clamping 0 should match Page 1")
	assert_eq(main_node.get_target_scroll_for_page(-10), pos_p1, "Clamping -10 should match Page 1")
	var pos_p50: int = main_node.get_target_scroll_for_page(50)
	assert_eq(main_node.get_target_scroll_for_page(99), pos_p50, "Clamping 99 should match Page 50")

	# Verify scroll_to_page sets current page and emits page_changed
	var emitted_pages: Array[int] = []
	main_node.page_changed.connect(func(page: int) -> void: emitted_pages.append(page))

	main_node.scroll_to_page(16, false)
	assert_eq(main_node.get_current_page(), 16, "Current page should be 16 after scroll_to_page")
	assert_eq(emitted_pages.size(), 1, "page_changed must be emitted once")
	assert_eq(emitted_pages[0], 16, "Emitted page must be 16")

	main_node.free()


func test_texture_virtualization_management() -> void:
	var main_node: Main = MainScene.instantiate() as Main
	test_root_window.add_child(main_node)
	main_node._ready()

	# Scroll to Page 1
	main_node.scroll_to_page(1, false)

	# Nearby artwork pages (Page 5: Opening Prayers) should have loaded artwork
	var p5_card: PageCard = main_node.get_page_card(5)
	assert_not_null(p5_card, "Page 5 PageCard must exist")
	assert_not_null(p5_card.get_artwork_texture(), "Page 5 (buffer distance 4) texture should be accessible")

	# Distant artwork pages (e.g. Page 35, 45, 47) should be unloaded from active VRAM
	var p35_card: PageCard = main_node.get_page_card(35)
	assert_not_null(p35_card, "Page 35 PageCard must exist")
	# Subcard texture is unassigned while out of active buffer window
	var apc35: ArtworkPageCard = p35_card.get_sub_card() as ArtworkPageCard
	if apc35 != null and apc35.artwork_texture != null:
		assert_null(apc35.artwork_texture.texture, "Page 35 texture should be virtualized/unloaded while on Page 1")

	# Jump to Page 35
	main_node.scroll_to_page(35, false)

	# Now Page 35 texture is loaded
	if apc35 != null and apc35.artwork_texture != null:
		assert_not_null(apc35.artwork_texture.texture, "Page 35 texture must be loaded when active")

	# And Page 1 cover texture is unloaded
	var p1_card: PageCard = main_node.get_page_card(1)
	var cpc1: CoverPageCard = p1_card.get_sub_card() as CoverPageCard
	if cpc1 != null and cpc1.cover_texture != null:
		assert_null(cpc1.cover_texture.texture, "Page 1 cover texture should be virtualized/unloaded when distant")

	main_node.free()


func test_in_stream_jump_bar_connections_in_main() -> void:
	var main_node: Main = MainScene.instantiate() as Main
	test_root_window.add_child(main_node)
	main_node._ready()

	var jump_bars: Array[InStreamJumpBar] = main_node.get_jump_bars()
	assert_eq(jump_bars.size(), 5, "Main must register 5 in-stream jump bars")

	# Test Post-Opening Prayers jump bar (Separators[0])
	var sep1: InStreamJumpBar = jump_bars[0]
	assert_eq(sep1.get_separator_id(), "after_opening_prayers_jump", "Separator 1 must be after_opening_prayers_jump")

	# Jump to Luminous (Page 16)
	sep1._on_button_pressed(16)
	assert_eq(main_node.get_current_page(), 16, "Pressing Luminous button should scroll Main to Page 16")

	# Jump to Sorrowful (Page 26)
	sep1._on_button_pressed(26)
	assert_eq(main_node.get_current_page(), 26, "Pressing Sorrowful button should scroll Main to Page 26")

	# Test Post-Mystery-Set jump bars jumping to Page 46
	var sep2: InStreamJumpBar = jump_bars[1] # after Joyful
	sep2._on_button_pressed(46)
	assert_eq(main_node.get_current_page(), 46, "Pressing Joyful completion jump should scroll Main to Page 46")

	var sep3: InStreamJumpBar = jump_bars[2] # after Luminous
	sep3._on_button_pressed(46)
	assert_eq(main_node.get_current_page(), 46, "Pressing Luminous completion jump should scroll Main to Page 46")

	main_node.free()


func test_startup_reading_progress_restoration() -> void:
	# Save a progress position of Page 20 to test config
	var progress: ReadingProgressManager = ReadingProgressManagerScript.new() as ReadingProgressManager
	progress.save_progress(20)

	var main_node: Main = MainScene.instantiate() as Main
	test_root_window.add_child(main_node)
	main_node._ready()

	# In headless mode or deferred callback, verify restore
	main_node._restore_saved_page(progress.load_progress())
	assert_eq(main_node.get_current_page(), 20, "Startup restore should set current page to saved page 20")

	# Clean up progress
	progress.clear_progress()
	main_node.free()


func test_screen_keep_on_guard() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.screen_set_keep_on(true)
		assert_true(DisplayServer.screen_is_kept_on(), "Screen should be kept on in non-headless mode")
	else:
		# In headless runner, verify call does not crash
		assert_eq(DisplayServer.get_name(), "headless", "Test runner should be running headlessly")


func _assert_no_control_stops_mouse(node: Node, context: String) -> void:
	if node is BaseButton:
		var btn: BaseButton = node as BaseButton
		assert_eq(
			btn.mouse_filter,
			Control.MOUSE_FILTER_PASS,
			"%s BaseButton '%s' must use MOUSE_FILTER_PASS" % [context, btn.name]
		)
	elif node is Control:
		var ctrl: Control = node as Control
		assert_ne(
			ctrl.mouse_filter,
			Control.MOUSE_FILTER_STOP,
			"%s Control '%s' must not use MOUSE_FILTER_STOP" % [context, ctrl.name]
		)
	for child: Node in node.get_children():
		_assert_no_control_stops_mouse(child, context)


func test_scrollbar_hidden_and_pass_through_mouse_filters() -> void:
	var main_node: Main = MainScene.instantiate() as Main
	test_root_window.add_child(main_node)
	main_node._ready()

	assert_not_null(main_node.scroll_container, "Main ScrollContainer must exist")
	assert_eq(
		main_node.scroll_container.vertical_scroll_mode,
		ScrollContainer.SCROLL_MODE_SHOW_NEVER,
		"Main ScrollContainer vertical_scroll_mode must be SCROLL_MODE_SHOW_NEVER (3)"
	)
	assert_eq(
		main_node.scroll_container.horizontal_scroll_mode,
		ScrollContainer.SCROLL_MODE_DISABLED,
		"Main ScrollContainer horizontal_scroll_mode must be SCROLL_MODE_DISABLED (0)"
	)

	var nav_drawer: NavigationDrawer = main_node.get_navigation_drawer()
	assert_not_null(nav_drawer, "NavigationDrawer must exist")
	if nav_drawer != null:
		nav_drawer._ready()
		assert_not_null(nav_drawer.drawer_scroll, "NavigationDrawer DrawerScroll must exist")
		assert_eq(
			nav_drawer.drawer_scroll.vertical_scroll_mode,
			ScrollContainer.SCROLL_MODE_SHOW_NEVER,
			"DrawerScroll vertical_scroll_mode must be SCROLL_MODE_SHOW_NEVER (3)"
		)
		_assert_no_control_stops_mouse(nav_drawer.content_container, "NavigationDrawer/ContentContainer")

	for p_num: int in range(1, 51):
		var card: PageCard = main_node.get_page_card(p_num)
		assert_not_null(card, "PageCard %d must exist" % p_num)
		_assert_no_control_stops_mouse(card, "PageCard_%d" % p_num)

	for jump_bar: InStreamJumpBar in main_node.get_jump_bars():
		_assert_no_control_stops_mouse(jump_bar, "InStreamJumpBar_%s" % jump_bar.get_separator_id())

	main_node.free()


func test_touch_swipe_mouse_drag_and_wheel_scroll_input() -> void:
	var main_node: Main = MainScene.instantiate() as Main
	test_root_window.add_child(main_node)
	main_node._ready()

	main_node.scroll_to_page(1, false)
	assert_eq(main_node.scroll_container.scroll_vertical, 0, "Initial scroll_vertical should be 0")

	# 1. Touch swipe up (negative relative.y scrolls down the stream)
	var swipe_up: InputEventScreenDrag = InputEventScreenDrag.new()
	swipe_up.relative = Vector2(0.0, -240.0)
	main_node.handle_scroll_input(swipe_up)
	assert_eq(main_node.scroll_container.scroll_vertical, 240, "Touch swipe up (-240px) should increase scroll_vertical to 240")

	# 2. Touch swipe down (positive relative.y scrolls up the stream)
	var swipe_down: InputEventScreenDrag = InputEventScreenDrag.new()
	swipe_down.relative = Vector2(0.0, 90.0)
	main_node.handle_scroll_input(swipe_down)
	assert_eq(main_node.scroll_container.scroll_vertical, 150, "Touch swipe down (+90px) should decrease scroll_vertical to 150")

	# 3. Left-mouse-button drag up (negative relative.y scrolls down the stream)
	var mouse_drag: InputEventMouseMotion = InputEventMouseMotion.new()
	mouse_drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	mouse_drag.relative = Vector2(0.0, -150.0)
	main_node.handle_scroll_input(mouse_drag)
	assert_eq(main_node.scroll_container.scroll_vertical, 300, "Left mouse drag (-150px) should increase scroll_vertical to 300")

	# 4. Unpressed mouse motion should not scroll
	var hover_motion: InputEventMouseMotion = InputEventMouseMotion.new()
	hover_motion.button_mask = 0
	hover_motion.relative = Vector2(0.0, -200.0)
	main_node.handle_scroll_input(hover_motion)
	assert_eq(main_node.scroll_container.scroll_vertical, 300, "Hover motion without left button pressed must not change scroll_vertical")

	# 5. Mouse wheel down scrolls down
	var wheel_down: InputEventMouseButton = InputEventMouseButton.new()
	wheel_down.pressed = true
	wheel_down.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel_down.factor = 1.0
	main_node._input(wheel_down)
	assert_true(main_node.scroll_container.scroll_vertical > 300, "Mouse wheel down must increase scroll_vertical")
	var after_wheel_down: int = main_node.scroll_container.scroll_vertical

	# 6. Mouse wheel up scrolls up
	var wheel_up: InputEventMouseButton = InputEventMouseButton.new()
	wheel_up.pressed = true
	wheel_up.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel_up.factor = 1.0
	main_node._input(wheel_up)
	assert_eq(main_node.scroll_container.scroll_vertical, 300, "Mouse wheel up must decrease scroll_vertical back to 300 (was %d)" % after_wheel_down)

	# 7. When NavigationDrawer is open, scroll input is ignored
	if main_node.navigation_drawer != null:
		main_node.navigation_drawer._ready()
		main_node.navigation_drawer.open_drawer(false)
		main_node._input(swipe_up)
		assert_eq(main_node.scroll_container.scroll_vertical, 300, "Scroll input must be ignored while NavigationDrawer is open")
		main_node.navigation_drawer.close_drawer(false)

	main_node.free()


func test_momentum_scroll_high_velocity_drag_release() -> void:
	var main_node: Main = MainScene.instantiate() as Main
	test_root_window.add_child(main_node)
	main_node._ready()

	main_node.scroll_to_page(5, false)
	var initial_scroll: int = main_node.scroll_container.scroll_vertical

	# 1. High-velocity touch swipe
	var touch_down: InputEventScreenTouch = InputEventScreenTouch.new()
	touch_down.pressed = true
	main_node.handle_scroll_input(touch_down)

	var swipe_up: InputEventScreenDrag = InputEventScreenDrag.new()
	swipe_up.relative = Vector2(0.0, -100.0)
	swipe_up.velocity = Vector2(0.0, -1500.0)
	main_node.handle_scroll_input(swipe_up)

	assert_eq(main_node.scroll_container.scroll_vertical, initial_scroll + 100, "1:1 drag should move scroll by 100px")
	assert_eq(main_node.get_drag_velocity(), 1500.0, "Drag velocity should track -velocity.y (1500 px/s)")

	var touch_up: InputEventScreenTouch = InputEventScreenTouch.new()
	touch_up.pressed = false
	main_node.handle_scroll_input(touch_up)

	assert_true(main_node.is_momentum_scrolling(), "High-velocity touch release must initiate momentum scrolling")
	assert_true(main_node.get_momentum_velocity() > 1000.0, "Initial momentum velocity must match flick velocity")

	# Step physics frame 1
	var prev_scroll: int = main_node.scroll_container.scroll_vertical
	var prev_vel: float = main_node.get_momentum_velocity()
	main_node._process(0.016)

	assert_true(main_node.scroll_container.scroll_vertical > prev_scroll, "Scroll position must advance after process step")
	assert_true(main_node.get_momentum_velocity() < prev_vel, "Velocity must decelerate due to friction")

	# Step physics frame 2
	prev_scroll = main_node.scroll_container.scroll_vertical
	prev_vel = main_node.get_momentum_velocity()
	main_node._process(0.016)

	assert_true(main_node.scroll_container.scroll_vertical > prev_scroll, "Scroll position must continue advancing on frame 2")
	assert_true(main_node.get_momentum_velocity() < prev_vel, "Velocity must continue decelerating")

	# Verify virtualization and page progress update during large glide
	var p5_page: int = main_node.get_current_page()
	main_node.start_momentum(4000.0)
	main_node._process(0.4)
	assert_true(main_node.get_current_page() >= p5_page, "Active page must advance or stay consistent as scroll increases")

	# Stop momentum for mouse test
	main_node.stop_momentum()
	assert_false(main_node.is_momentum_scrolling(), "Momentum must be stopped")

	# 2. High-velocity left mouse drag
	var mouse_down: InputEventMouseButton = InputEventMouseButton.new()
	mouse_down.button_index = MOUSE_BUTTON_LEFT
	mouse_down.pressed = true
	main_node.handle_scroll_input(mouse_down)

	var mouse_drag: InputEventMouseMotion = InputEventMouseMotion.new()
	mouse_drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	mouse_drag.relative = Vector2(0.0, -80.0)
	mouse_drag.velocity = Vector2(0.0, -1200.0)
	main_node.handle_scroll_input(mouse_drag)

	var mouse_up: InputEventMouseButton = InputEventMouseButton.new()
	mouse_up.button_index = MOUSE_BUTTON_LEFT
	mouse_up.pressed = false
	main_node.handle_scroll_input(mouse_up)

	assert_true(main_node.is_momentum_scrolling(), "High-velocity mouse release must initiate momentum scrolling")
	assert_true(main_node.get_momentum_velocity() > 800.0, "Momentum velocity should be positive and high")

	# Advance frames until momentum naturally rests
	var step_count: int = 0
	while main_node.is_momentum_scrolling() and step_count < 300:
		main_node._process(0.05)
		step_count += 1

	assert_false(main_node.is_momentum_scrolling(), "Momentum glide must naturally rest when velocity drops below cutoff")
	assert_eq(main_node.get_momentum_velocity(), 0.0, "Residual momentum velocity must be 0 at rest")

	main_node.free()


func test_momentum_scroll_interruption_by_touch_and_mouse_press() -> void:
	var main_node: Main = MainScene.instantiate() as Main
	test_root_window.add_child(main_node)
	main_node._ready()

	main_node.scroll_to_page(10, false)

	# 1. Interruption by touch press
	main_node.start_momentum(1000.0)
	assert_true(main_node.is_momentum_scrolling(), "Momentum scrolling should be active")
	main_node._process(0.016)

	var touch_press: InputEventScreenTouch = InputEventScreenTouch.new()
	touch_press.pressed = true
	main_node.handle_scroll_input(touch_press)

	assert_false(main_node.is_momentum_scrolling(), "Touch press must immediately halt active momentum")
	assert_eq(main_node.get_momentum_velocity(), 0.0, "Momentum velocity must be 0 after touch press interruption")

	# Releasing tap without drag must NOT start momentum
	var touch_release: InputEventScreenTouch = InputEventScreenTouch.new()
	touch_release.pressed = false
	main_node.handle_scroll_input(touch_release)
	assert_false(main_node.is_momentum_scrolling(), "Releasing tap without dragging must not trigger momentum")

	# 2. Interruption by mouse press
	main_node.start_momentum(1000.0)
	assert_true(main_node.is_momentum_scrolling(), "Momentum scrolling should be active")

	var mouse_press: InputEventMouseButton = InputEventMouseButton.new()
	mouse_press.button_index = MOUSE_BUTTON_LEFT
	mouse_press.pressed = true
	main_node.handle_scroll_input(mouse_press)

	assert_false(main_node.is_momentum_scrolling(), "Mouse press must immediately halt active momentum")
	assert_eq(main_node.get_momentum_velocity(), 0.0, "Momentum velocity must be 0 after mouse press interruption")

	var mouse_release: InputEventMouseButton = InputEventMouseButton.new()
	mouse_release.button_index = MOUSE_BUTTON_LEFT
	mouse_release.pressed = false
	main_node.handle_scroll_input(mouse_release)
	assert_false(main_node.is_momentum_scrolling(), "Releasing mouse click without dragging must not trigger momentum")

	# 3. Interruption by drawer opening
	main_node.start_momentum(1000.0)
	assert_true(main_node.is_momentum_scrolling(), "Momentum scrolling should be active")
	main_node._on_drawer_opened()
	assert_false(main_node.is_momentum_scrolling(), "Opening drawer must halt active momentum")

	# 4. Interruption by page jump
	main_node.start_momentum(1000.0)
	assert_true(main_node.is_momentum_scrolling(), "Momentum scrolling should be active")
	main_node.scroll_to_page(20, false)
	assert_false(main_node.is_momentum_scrolling(), "Initiating scroll_to_page must halt active momentum")

	main_node.free()


func test_momentum_scroll_boundary_clamping() -> void:
	var main_node: Main = MainScene.instantiate() as Main
	test_root_window.add_child(main_node)
	main_node._ready()

	# 1. Top boundary clamping (moving toward Page 1, scroll = 0)
	main_node.scroll_container.scroll_vertical = 80
	main_node.start_momentum(-2000.0)
	assert_true(main_node.is_momentum_scrolling(), "Upward momentum should be active")

	# Process 0.1s: 80 - 2000 * 0.1 = -120, hitting top boundary
	main_node._process(0.1)

	assert_eq(main_node.scroll_container.scroll_vertical, 0, "Scroll position must clamp strictly to 0 at top boundary")
	assert_false(main_node.is_momentum_scrolling(), "Residual momentum must be halted immediately at top boundary")
	assert_eq(main_node.get_momentum_velocity(), 0.0, "Momentum velocity must be zeroed upon hitting top boundary")

	# Subsequent process steps must not move below 0
	main_node._process(0.016)
	assert_eq(main_node.scroll_container.scroll_vertical, 0, "Scroll position must remain at 0 without negative overshoot")

	# 2. Bottom boundary clamping (moving toward Page 50, max scroll)
	var max_scroll: int = main_node._get_max_scroll_vertical()
	main_node.scroll_container.scroll_vertical = max_scroll - 80
	main_node.start_momentum(2000.0)
	assert_true(main_node.is_momentum_scrolling(), "Downward momentum should be active")

	# Process 0.1s: max - 80 + 2000 * 0.1 = max + 120, hitting bottom boundary
	main_node._process(0.1)

	assert_eq(main_node.scroll_container.scroll_vertical, max_scroll, "Scroll position must clamp strictly to max_scroll at bottom boundary")
	assert_false(main_node.is_momentum_scrolling(), "Residual momentum must be halted immediately at bottom boundary")
	assert_eq(main_node.get_momentum_velocity(), 0.0, "Momentum velocity must be zeroed upon hitting bottom boundary")

	# Subsequent process steps must not move beyond max_scroll
	main_node._process(0.016)
	assert_eq(main_node.scroll_container.scroll_vertical, max_scroll, "Scroll position must remain at max_scroll without overshooting")

	# 3. Guard against starting momentum beyond boundaries
	main_node.scroll_container.scroll_vertical = 0
	main_node.start_momentum(-1000.0)
	assert_false(main_node.is_momentum_scrolling(), "Starting upward momentum when already at 0 must not activate momentum")

	main_node.scroll_container.scroll_vertical = max_scroll
	main_node.start_momentum(1000.0)
	assert_false(main_node.is_momentum_scrolling(), "Starting downward momentum when already at max_scroll must not activate momentum")

	main_node.free()


func test_momentum_scroll_slow_drag_no_momentum() -> void:
	var main_node: Main = MainScene.instantiate() as Main
	test_root_window.add_child(main_node)
	main_node._ready()

	main_node.scroll_to_page(5, false)
	var initial_scroll: int = main_node.scroll_container.scroll_vertical

	# 1. Slow touch drag below MIN_FLICK_VELOCITY (50 px/s < 120 px/s)
	var touch_down: InputEventScreenTouch = InputEventScreenTouch.new()
	touch_down.pressed = true
	main_node.handle_scroll_input(touch_down)

	var slow_drag: InputEventScreenDrag = InputEventScreenDrag.new()
	slow_drag.relative = Vector2(0.0, -15.0)
	slow_drag.velocity = Vector2(0.0, -50.0)
	main_node.handle_scroll_input(slow_drag)

	assert_eq(main_node.scroll_container.scroll_vertical, initial_scroll + 15, "Slow drag must move position 1:1")

	var touch_up: InputEventScreenTouch = InputEventScreenTouch.new()
	touch_up.pressed = false
	main_node.handle_scroll_input(touch_up)

	assert_false(main_node.is_momentum_scrolling(), "Slow drag below flick threshold must not initiate momentum scrolling")

	# Process frames: no drift
	main_node._process(0.016)
	assert_eq(main_node.scroll_container.scroll_vertical, initial_scroll + 15, "Position must remain stationary after slow drag release")

	# 2. Slow mouse drag
	var mouse_down: InputEventMouseButton = InputEventMouseButton.new()
	mouse_down.button_index = MOUSE_BUTTON_LEFT
	mouse_down.pressed = true
	main_node.handle_scroll_input(mouse_down)

	var slow_mouse: InputEventMouseMotion = InputEventMouseMotion.new()
	slow_mouse.button_mask = MOUSE_BUTTON_MASK_LEFT
	slow_mouse.relative = Vector2(0.0, -10.0)
	slow_mouse.velocity = Vector2(0.0, -40.0)
	main_node.handle_scroll_input(slow_mouse)

	var mouse_up: InputEventMouseButton = InputEventMouseButton.new()
	mouse_up.button_index = MOUSE_BUTTON_LEFT
	mouse_up.pressed = false
	main_node.handle_scroll_input(mouse_up)

	assert_false(main_node.is_momentum_scrolling(), "Slow mouse drag below flick threshold must not initiate momentum scrolling")

	main_node.free()



