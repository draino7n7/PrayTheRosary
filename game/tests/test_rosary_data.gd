extends "res://tests/test_base.gd"

const RosaryDataLoaderScript = preload("res://scripts/data/rosary_data_loader.gd")


func test_data_files_load_cleanly() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	var loaded: bool = loader.load_all()
	assert_true(loaded, "RosaryDataLoader should load prayers.json, mysteries.json, and book_layout.json")
	assert_true(loader.is_loaded(), "Loader should report is_loaded() == true")
	assert_eq(loader.get_total_interior_spreads(), 24, "Book must have exactly 24 interior spreads")
	assert_eq(loader.get_total_views(), 26, "Book must have 26 total views (Front Cover + 24 Spreads + Back Cover)")
	assert_eq(loader.get_total_page_sides(), 50, "Book must have 50 total page sides (Pages 1 to 50)")


func test_all_canonical_prayers_present() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	var expected_prayer_ids: Array[String] = [
		"sign_of_the_cross",
		"apostles_creed",
		"our_father",
		"hail_mary",
		"hail_mary_faith",
		"hail_mary_hope",
		"hail_mary_charity",
		"glory_be",
		"fatima_prayer",
		"hail_holy_queen",
		"versicle_response",
		"rosary_concluding_prayer"
	]

	for pid: String in expected_prayer_ids:
		var prayer: Dictionary = loader.get_prayer(pid)
		assert_false(prayer.is_empty(), "Prayer '%s' must exist in prayers.json" % pid)
		assert_ne(str(prayer.get("title", "")), "", "Prayer '%s' must have a title" % pid)
		assert_ne(str(prayer.get("text", "")), "", "Prayer '%s' must have prayer text" % pid)


func test_four_mystery_sets_and_twenty_mysteries() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	var order: Array[String] = loader.get_mystery_set_order()
	var expected_order: Array[String] = ["joyful", "luminous", "sorrowful", "glorious"]
	assert_eq(order, expected_order, "Mystery sets must be ordered Joyful, Luminous, Sorrowful, Glorious")

	var expected_spread: int = 3
	for set_id: String in expected_order:
		var mset: Dictionary = loader.get_mystery_set(set_id)
		assert_false(mset.is_empty(), "Mystery set '%s' must exist" % set_id)
		var decades: Array = mset.get("decades", [])
		assert_eq(decades.size(), 5, "Mystery set '%s' must have 5 decades" % set_id)

		for i: int in range(decades.size()):
			var dec: Dictionary = decades[i]
			assert_eq(int(dec.get("decade_number", 0)), i + 1, "Decade number must be 1..5")
			assert_eq(int(dec.get("spread_number", 0)), expected_spread, "Mystery spread number must be sequential from 3 to 22")
			assert_ne(str(dec.get("title", "")), "", "Mystery must have a title")
			assert_ne(str(dec.get("fruit", "")), "", "Mystery must have a spiritual fruit")
			assert_true(str(dec.get("scripture_reference", "")).contains("Douay-Rheims"), "Mystery scripture reference must cite Douay-Rheims")
			assert_ne(str(dec.get("scripture_text", "")), "", "Mystery must have scripture text")
			assert_ne(str(dec.get("meditation", "")), "", "Mystery must have a contemplative meditation")
			expected_spread += 1


func test_book_spread_sequence_and_page_numbering() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	var front: Dictionary = loader.get_front_cover()
	assert_eq(int(front.get("page_number", 0)), 1, "Front cover must be page 1")
	assert_eq(str(front.get("title", "")), "Pray the Rosary", "Front cover title must be 'Pray the Rosary'")

	# Spread 1: History (Left, Page 2) & How to Use (Right, Page 3)
	var spread_1: Dictionary = loader.get_hydrated_spread(1)
	assert_eq(str(spread_1.get("id", "")), "history_and_how_to_use", "Spread 1 must be history_and_how_to_use")
	assert_eq(int(spread_1.get("left_page", {}).get("page_number", 0)), 2, "Spread 1 left page must be page 2")
	assert_eq(int(spread_1.get("right_page", {}).get("page_number", 0)), 3, "Spread 1 right page must be page 3")

	# Spread 2: Opening Prayers (Left, Page 4) & Holy Trinity Art (Right, Page 5)
	var spread_2: Dictionary = loader.get_hydrated_spread(2)
	assert_eq(str(spread_2.get("id", "")), "opening_prayers", "Spread 2 must be opening_prayers")
	assert_eq(int(spread_2.get("left_page", {}).get("page_number", 0)), 4, "Spread 2 left page must be page 4")
	assert_eq(int(spread_2.get("right_page", {}).get("page_number", 0)), 5, "Spread 2 right page must be page 5")

	# Spreads 3..22: All 20 Mysteries (Pages 6..45)
	for sp_num: int in range(3, 23):
		var sp: Dictionary = loader.get_hydrated_spread(sp_num)
		assert_eq(str(sp.get("type", "")), "mystery_spread", "Spread %d must be mystery_spread" % sp_num)
		assert_eq(int(sp.get("left_page_number", 0)), sp_num * 2, "Spread %d left page must be %d" % [sp_num, sp_num * 2])
		assert_eq(int(sp.get("right_page_number", 0)), sp_num * 2 + 1, "Spread %d right page must be %d" % [sp_num, sp_num * 2 + 1])
		var hydrated_mystery: Dictionary = sp.get("mystery", {})
		assert_false(hydrated_mystery.is_empty(), "Spread %d must hydrate its mystery dictionary" % sp_num)
		var decade_prayers: Array = sp.get("decade_prayers", [])
		assert_eq(decade_prayers.size(), 4, "Spread %d must hydrate 4 decade prayer steps (Our Father, Hail Mary, Glory Be, Fatima)" % sp_num)

	# Spread 23: Closing Prayers (Left, Page 46) & Immaculate Conception Art (Right, Page 47)
	var spread_23: Dictionary = loader.get_hydrated_spread(23)
	assert_eq(str(spread_23.get("id", "")), "closing_prayers", "Spread 23 must be closing_prayers")
	assert_eq(int(spread_23.get("left_page", {}).get("page_number", 0)), 46, "Spread 23 left page must be page 46")
	assert_eq(int(spread_23.get("right_page", {}).get("page_number", 0)), 47, "Spread 23 right page must be page 47")

	# Spread 24: Credits & Attributions (Left Page 48, Right Page 49)
	var spread_24: Dictionary = loader.get_hydrated_spread(24)
	assert_eq(str(spread_24.get("id", "")), "credits_and_attributions", "Spread 24 must be credits_and_attributions")
	assert_eq(int(spread_24.get("left_page", {}).get("page_number", 0)), 48, "Spread 24 left page must be page 48")
	assert_eq(int(spread_24.get("right_page", {}).get("page_number", 0)), 49, "Spread 24 right page must be page 49")

	var left_credits: Array = spread_24.get("left_page", {}).get("attribution_ids", [])
	var right_credits: Array = spread_24.get("right_page", {}).get("attribution_ids", [])
	assert_eq(left_credits.size() + right_credits.size(), 23, "Spread 24 credits must list all 23 artworks")

	# Back Cover: Page 50
	var back: Dictionary = loader.get_back_cover()
	assert_eq(int(back.get("page_number", 0)), 50, "Back cover must be page 50")


func test_index_tabs_and_continuous_scroll_pages() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	var tabs: Array = loader.get_index_tabs()
	assert_eq(tabs.size(), 6, "Must have 6 index tabs: O, J, L, S, G, C")
	var expected_letters: Array[String] = ["O", "J", "L", "S", "G", "C"]
	var expected_left_pages: Array[int] = [4, 6, 16, 26, 36, 46]
	for i: int in range(tabs.size()):
		var tab: Dictionary = tabs[i]
		assert_eq(str(tab.get("letter", "")), expected_letters[i], "Tab %d letter must match" % (i + 1))
		assert_eq(int(tab.get("target_left_page", 0)), expected_left_pages[i], "Tab %s must open to left page %d" % [expected_letters[i], expected_left_pages[i]])

	var separators: Array = loader.get_in_stream_separators()
	assert_eq(separators.size(), 5, "Must have 5 in-stream separators after pages 5, 15, 25, 35, and 45")

	var all_pages: Array[Dictionary] = loader.get_all_pages()
	assert_eq(all_pages.size(), 50, "Continuous scroll must have 50 sequential pages")
	for p_idx: int in range(all_pages.size()):
		var page: Dictionary = all_pages[p_idx]
		assert_eq(int(page.get("page_number", 0)), p_idx + 1, "Page number must match 1..50 sequence")
		if str(page.get("page_type", "")) == "artwork_page":
			assert_ne(str(page.get("heading", "")), "", "Artwork page %d must have a top header title" % (p_idx + 1))
			assert_ne(str(page.get("subheading", "")), "", "Artwork page %d must have a top header subtitle" % (p_idx + 1))


func test_archival_master_files_exist_on_disk() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	var repo_root: String = ProjectSettings.globalize_path("res://..").simplify_path()
	var master_files: Array[String] = []

	master_files.append(str(loader.get_front_cover().get("artwork", {}).get("master_file", "")))
	master_files.append(str(loader.get_spread(2).get("right_page", {}).get("artwork", {}).get("master_file", "")))
	master_files.append(str(loader.get_spread(23).get("right_page", {}).get("artwork", {}).get("master_file", "")))

	for sp_num: int in range(3, 23):
		var sp: Dictionary = loader.get_hydrated_spread(sp_num)
		var m_file: String = str(sp.get("mystery", {}).get("artwork", {}).get("master_file", ""))
		master_files.append(m_file)

	assert_eq(master_files.size(), 23, "Must collect all 23 master file paths")
	for rel_path: String in master_files:
		assert_true(rel_path.begins_with("assets/2D/gimp/original_downloads/"), "Master file '%s' must reside in protected original_downloads folder" % rel_path)
		var abs_path: String = repo_root.path_join(rel_path)
		assert_true(FileAccess.file_exists(abs_path), "Master artwork file must exist on disk: %s" % abs_path)


func test_weekday_mystery_recommendations() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	assert_eq(loader.get_recommended_mystery_set_for_weekday(Time.WEEKDAY_MONDAY), "joyful")
	assert_eq(loader.get_recommended_mystery_set_for_weekday(Time.WEEKDAY_SATURDAY), "joyful")
	assert_eq(loader.get_recommended_mystery_set_for_weekday(Time.WEEKDAY_THURSDAY), "luminous")
	assert_eq(loader.get_recommended_mystery_set_for_weekday(Time.WEEKDAY_TUESDAY), "sorrowful")
	assert_eq(loader.get_recommended_mystery_set_for_weekday(Time.WEEKDAY_FRIDAY), "sorrowful")
	assert_eq(loader.get_recommended_mystery_set_for_weekday(Time.WEEKDAY_WEDNESDAY), "glorious")
	assert_eq(loader.get_recommended_mystery_set_for_weekday(Time.WEEKDAY_SUNDAY), "glorious")

	assert_eq(loader.get_starting_spread_for_mystery_set("joyful"), 3)
	assert_eq(loader.get_starting_spread_for_mystery_set("luminous"), 8)
	assert_eq(loader.get_starting_spread_for_mystery_set("sorrowful"), 13)
	assert_eq(loader.get_starting_spread_for_mystery_set("glorious"), 18)

	# 2026 Easter Sunday is April 5, 2026
	var easter_2026: Dictionary = loader.compute_easter_sunday(2026)
	assert_eq(int(easter_2026["month"]), 4)
	assert_eq(int(easter_2026["day"]), 5)

	# Lenten Sundays in 2026: Feb 22 (1st Sunday of Lent) through March 29 (Palm Sunday) -> Sorrowful
	assert_eq(loader.get_recommended_mystery_set_for_date(2026, 2, 22), "sorrowful", "1st Sunday of Lent 2026 must be sorrowful")
	assert_eq(loader.get_recommended_mystery_set_for_date(2026, 3, 29), "sorrowful", "Palm Sunday 2026 must be sorrowful")

	# Easter Sunday (April 5, 2026) & Ordinary Time Sunday (July 12, 2026) -> Glorious
	assert_eq(loader.get_recommended_mystery_set_for_date(2026, 4, 5), "glorious", "Easter Sunday 2026 must be glorious")
	assert_eq(loader.get_recommended_mystery_set_for_date(2026, 7, 12), "glorious", "Ordinary Time Sunday must be glorious")

	# Advent Sunday (Nov 29, 2026) & Christmas Season Sunday (Jan 11, 2026) -> Joyful
	assert_eq(loader.get_recommended_mystery_set_for_date(2026, 11, 29), "joyful", "1st Sunday of Advent 2026 must be joyful")
	assert_eq(loader.get_recommended_mystery_set_for_date(2026, 12, 27), "joyful", "Holy Family Sunday 2026 must be joyful")
	assert_eq(loader.get_recommended_mystery_set_for_date(2026, 1, 11), "joyful", "Baptism of the Lord Sunday 2026 must be joyful")

