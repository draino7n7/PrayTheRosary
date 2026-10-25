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

	assert_eq(str(loader.get_prayer("our_father").get("title", "")), "The Our Father", "our_father title must be 'The Our Father'")
	assert_eq(str(loader.get_prayer("glory_be").get("title", "")), "The Glory Be", "glory_be title must be 'The Glory Be'")
	assert_eq(
		str(loader.get_prayer("glory_be").get("text", "")),
		"Glory be to the Father, and to the Son, and to the Holy Spirit,\nas it was in the beginning, is now, and ever shall be, world without end. Amen.",
		"glory_be text must match single-sentence wording with newline separating leader and response"
	)
	assert_eq(
		str(loader.get_prayer("glory_be").get("leader_text", "")),
		"Glory be to the Father, and to the Son, and to the Holy Spirit,",
		"glory_be leader_text must end with a comma"
	)
	assert_eq(
		str(loader.get_prayer("glory_be").get("response_text", "")),
		"as it was in the beginning, is now, and ever shall be, world without end. Amen.",
		"glory_be response_text must begin with lowercase 'as it was in the beginning'"
	)


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
			var scrip_ref: String = str(dec.get("scripture_reference", ""))
			assert_ne(scrip_ref, "", "Mystery must have a non-empty scripture_reference")
			assert_false(scrip_ref.contains("(Douay-Rheims)"), "Mystery scripture_reference must not contain '(Douay-Rheims)' suffix")
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
	assert_eq(
		str(spread_24.get("left_page", {}).get("subheading", "")),
		"Front Cover, Opening Prayers, Joyful Mysteries & Luminous Mysteries",
		"Spread 24 left page subheading must list Front Cover, Opening Prayers, Joyful & Luminous Mysteries"
	)
	assert_eq(
		str(spread_24.get("right_page", {}).get("subheading", "")),
		"Sorrowful Mysteries, Glorious Mysteries, Closing Prayers & Text Sources",
		"Spread 24 right page subheading must list Sorrowful, Glorious, Closing Prayers & Text Sources"
	)

	var left_credits: Array = spread_24.get("left_page", {}).get("attribution_ids", [])
	var right_credits: Array = spread_24.get("right_page", {}).get("attribution_ids", [])
	assert_eq(left_credits.size(), 12, "Page 48 must list 12 artwork attributions")
	assert_eq(right_credits.size(), 11, "Page 49 must list 11 artwork attributions")
	assert_eq(left_credits.size() + right_credits.size(), 23, "Spread 24 credits must list all 23 artworks")
	assert_eq(str(right_credits[right_credits.size() - 1]), "closing_prayers", "Last attribution on Page 49 must be closing_prayers")

	var expected_sequential_ids: Array[String] = [
		"cover",
		"opening_prayers",
		"joyful_1_annunciation",
		"joyful_2_visitation",
		"joyful_3_nativity",
		"joyful_4_presentation",
		"joyful_5_finding_in_temple",
		"luminous_1_baptism",
		"luminous_2_wedding_at_cana",
		"luminous_3_proclamation",
		"luminous_4_transfiguration",
		"luminous_5_eucharist",
		"sorrowful_1_agony",
		"sorrowful_2_scourging",
		"sorrowful_3_crowning_with_thorns",
		"sorrowful_4_carrying_cross",
		"sorrowful_5_crucifixion",
		"glorious_1_resurrection",
		"glorious_2_ascension",
		"glorious_3_pentecost",
		"glorious_4_assumption",
		"glorious_5_coronation",
		"closing_prayers"
	]
	var combined_credits: Array[String] = []
	for aid: Variant in left_credits:
		combined_credits.append(str(aid))
	for aid: Variant in right_credits:
		combined_credits.append(str(aid))
	assert_eq(combined_credits, expected_sequential_ids, "All 23 credits across Pages 48-49 must match exact sequential book appearance order")

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


func test_cpdv_citations_and_verbatim_texts() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	assert_eq(
		str(loader.mysteries_data.get("scripture_translation", "")),
		"Catholic Public Domain Version (CPDV)",
		"mysteries.json scripture_translation must be 'Catholic Public Domain Version (CPDV)'"
	)

	# Joyful 3: Luke 2:6-7, 10-11
	var j3: Dictionary = loader.get_mystery_by_id("joyful_3_nativity")
	assert_eq(str(j3.get("scripture_reference", "")), "Luke 2:6–7, 10–11")
	assert_true(str(j3.get("scripture_text", "")).contains("And the Angel said to [the shepherds]: “Do not be afraid. For, behold,"), "Joyful 3 Luke 2:10 must contain 'And the Angel said to [the shepherds]: “Do not be afraid. For, behold,'")

	# Joyful 4: Luke 2:28 bracketed subject
	var j4: Dictionary = loader.get_mystery_by_id("joyful_4_presentation")
	assert_eq(str(j4.get("scripture_reference", "")), "Luke 2:22, 28–32")
	assert_true(str(j4.get("scripture_text", "")).contains("[Then Simeon] took him up, into his arms"), "Joyful 4 Luke 2:28 must use bracketed subject '[Then Simeon] took him up, into his arms'")

	# Luminous 4: Luke 9:29-30, 35 and verbatim 'Listen to him.'
	var l4: Dictionary = loader.get_mystery_by_id("luminous_4_transfiguration")
	assert_eq(str(l4.get("scripture_reference", "")), "Luke 9:29–30, 35")
	assert_true(str(l4.get("scripture_text", "")).contains("Moses and Elijah, appearing in majesty"), "Luminous 4 Luke 9:30 must contain 'Moses and Elijah, appearing in majesty'")
	assert_true(str(l4.get("scripture_text", "")).ends_with("This is my beloved Son. Listen to him.”"), "Luminous 4 Luke 9:35 must end with verbatim CPDV 'This is my beloved Son. Listen to him.”'")
	assert_false(str(l4.get("scripture_text", "")).contains("hear ye him"), "Luminous 4 must not contain KJV 'hear ye him'")

	# Sorrowful 2: John 19:1; Isaiah 53:5
	var s2: Dictionary = loader.get_mystery_by_id("sorrowful_2_scourging")
	assert_eq(str(s2.get("scripture_reference", "")), "John 19:1; Isaiah 53:5")
	assert_true(str(s2.get("scripture_text", "")).contains("Therefore, Pilate then took Jesus into custody and scourged him..."), "Sorrowful 2 must begin with John 19:1")
	assert_true(str(s2.get("scripture_text", "")).contains("The discipline of our peace was upon him. And by his wounds, we are healed."), "Sorrowful 2 must contain Isaiah 53:5")

	# Sorrowful 4: Citation order matching passage order (John 19:17; Luke 23:26-27)
	var s4: Dictionary = loader.get_mystery_by_id("sorrowful_4_carrying_cross")
	assert_eq(str(s4.get("scripture_reference", "")), "John 19:17; Luke 23:26–27")
	assert_true(str(s4.get("scripture_text", "")).contains("And carrying his own cross, he went forth to the place which is called Calvary..."), "Sorrowful 4 must begin with John 19:17")
	assert_true(str(s4.get("scripture_text", "")).contains("And they imposed the cross on him to carry after Jesus."), "Sorrowful 4 must contain Luke 23:26")

	# Sorrowful 5: Luke 23:33–34, 46
	var s5: Dictionary = loader.get_mystery_by_id("sorrowful_5_crucifixion")
	assert_eq(str(s5.get("scripture_reference", "")), "Luke 23:33–34, 46")
	assert_true(str(s5.get("scripture_text", "")).contains("And Jesus, crying out with a loud voice, said: “Father, into your hands I commend my spirit.”"), "Sorrowful 5 Luke 23:46 must contain 'And Jesus, crying out with a loud voice, said: “Father, into your hands I commend my spirit.”'")
	assert_true(str(s5.get("scripture_text", "")).ends_with("And upon saying this, he expired."), "Sorrowful 5 must end with 'And upon saying this, he expired.'")

	# Glorious 2: Luke 24:50–51; Acts 1:9; Luke 24:52
	var g2: Dictionary = loader.get_mystery_by_id("glorious_2_ascension")
	assert_eq(str(g2.get("scripture_reference", "")), "Luke 24:50–51; Acts 1:9; Luke 24:52")
	assert_eq(
		str(g2.get("scripture_text", "")),
		"Then he led them out as far as Bethania. And lifting up his hands, he blessed them. And it happened that, while he was blessing them, he withdrew from them, and he was carried up into heaven... And while they were watching, he was lifted up, and a cloud took him from their sight... And worshiping, they returned to Jerusalem with great joy."
	)

	# Glorious 4: Psalm 131:8 (132:8); Luke 1:48–49; Judith 15:10
	var g4: Dictionary = loader.get_mystery_by_id("glorious_4_assumption")
	assert_eq(str(g4.get("scripture_reference", "")), "Psalm 131:8 (132:8); Luke 1:48–49; Judith 15:10")
	assert_true(str(g4.get("scripture_text", "")).begins_with("Rise up, O Lord, into your resting place. You and the ark of your sanctification..."), "Glorious 4 must begin with Psalm 131:8 (CPDV)")
	assert_true(str(g4.get("scripture_text", "")).contains("For behold, from this time, all generations shall call me blessed."), "Glorious 4 must contain Luke 1:48 (CPDV)")
	assert_true(str(g4.get("scripture_text", "")).ends_with("You are the glory of Jerusalem, you are the joy of Israel, you are the honor of our people."), "Glorious 4 must end with Judith 15:10 (CPDV)")

	# Glorious 5: Revelation 12:1; Sirach 24:7 (24:4)
	var g5: Dictionary = loader.get_mystery_by_id("glorious_5_coronation")
	assert_eq(str(g5.get("scripture_reference", "")), "Revelation 12:1; Sirach 24:7 (24:4)")
	assert_true(str(g5.get("scripture_text", "")).begins_with("And a great sign appeared in heaven: a woman clothed with the sun,"), "Glorious 5 must begin with Revelation 12:1 (CPDV)")
	assert_true(str(g5.get("scripture_text", "")).ends_with("and my throne is in the pillar of a cloud."), "Glorious 5 must end with Sirach 24:7 (CPDV)")


func test_museum_catalog_attributions_and_synchronization() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	var expected_inventory: Dictionary = {
		"cover": "DPG281",
		"opening_prayers": "P00824",
		"closing_prayers": "P02809",
		"joyful_1_annunciation": "P00970",
		"joyful_2_visitation": "y1994-17",
		"joyful_3_nativity": "NG6270",
		"joyful_4_presentation": "Cat. 44",
		"joyful_5_finding_in_temple": "1952.5.47.a (NGA 41661)",
		"luminous_1_baptism": "GG 222",
		"luminous_2_wedding_at_cana": "59-2",
		"luminous_3_proclamation": "King's Oratory (Kongens Bedekammer)",
		"luminous_4_transfiguration": "OLV.0003.I",
		"luminous_5_eucharist": "97",
		"sorrowful_1_agony": "GG F 17",
		"sorrowful_2_scourging": "70926",
		"sorrowful_3_crowning_with_thorns": "P01474",
		"sorrowful_4_carrying_cross": "P00298",
		"sorrowful_5_crucifixion": "P00967",
		"glorious_1_resurrection": "0641",
		"glorious_2_ascension": "25.95",
		"glorious_3_pentecost": "P03018",
		"glorious_4_assumption": "ГЭ-387",
		"glorious_5_coronation": "P01168"
	}

	var expected_section_labels: Dictionary = {
		"cover": "Front Cover",
		"opening_prayers": "Opening Prayers",
		"joyful_1_annunciation": "1st Joyful Mystery (The Annunciation)",
		"joyful_2_visitation": "2nd Joyful Mystery (The Visitation)",
		"joyful_3_nativity": "3rd Joyful Mystery (The Nativity of Our Lord)",
		"joyful_4_presentation": "4th Joyful Mystery (The Presentation of Jesus in the Temple)",
		"joyful_5_finding_in_temple": "5th Joyful Mystery (The Finding of Jesus in the Temple)",
		"luminous_1_baptism": "1st Luminous Mystery (The Baptism of Jesus in the Jordan)",
		"luminous_2_wedding_at_cana": "2nd Luminous Mystery (The Wedding Feast at Cana)",
		"luminous_3_proclamation": "3rd Luminous Mystery (The Proclamation of the Kingdom of God)",
		"luminous_4_transfiguration": "4th Luminous Mystery (The Transfiguration)",
		"luminous_5_eucharist": "5th Luminous Mystery (The Institution of the Eucharist)",
		"sorrowful_1_agony": "1st Sorrowful Mystery (The Agony in the Garden)",
		"sorrowful_2_scourging": "2nd Sorrowful Mystery (The Scourging at the Pillar)",
		"sorrowful_3_crowning_with_thorns": "3rd Sorrowful Mystery (The Crowning with Thorns)",
		"sorrowful_4_carrying_cross": "4th Sorrowful Mystery (The Carrying of the Cross)",
		"sorrowful_5_crucifixion": "5th Sorrowful Mystery (The Crucifixion and Death of Our Lord)",
		"glorious_1_resurrection": "1st Glorious Mystery (The Resurrection of Our Lord)",
		"glorious_2_ascension": "2nd Glorious Mystery (The Ascension of Our Lord into Heaven)",
		"glorious_3_pentecost": "3rd Glorious Mystery (The Descent of the Holy Spirit)",
		"glorious_4_assumption": "4th Glorious Mystery (The Assumption of the Blessed Virgin Mary)",
		"glorious_5_coronation": "5th Glorious Mystery (The Coronation of the Blessed Virgin Mary)",
		"closing_prayers": "Closing Prayers"
	}

	for art_id: String in expected_inventory.keys():
		var art: Dictionary = loader.get_artwork(art_id)
		assert_false(art.is_empty(), "Artwork '%s' must exist in RosaryDataLoader" % art_id)
		assert_eq(str(art.get("inventory_number", "")), expected_inventory[art_id], "Artwork '%s' inventory_number must match museum catalog" % art_id)
		assert_eq(str(art.get("section_label", "")), expected_section_labels[art_id], "Artwork '%s' section_label must match non-numbered book placement label" % art_id)

	assert_eq(str(loader.get_artwork("joyful_2_visitation").get("creation_date", "")), "1643–1648")
	assert_eq(str(loader.get_artwork("luminous_2_wedding_at_cana").get("creation_date", "")), "c. 1712–1715")
	assert_eq(str(loader.get_artwork("luminous_5_eucharist").get("creation_date", "")), "1630–1631")
	assert_eq(str(loader.get_artwork("glorious_2_ascension").get("original_dimensions", "")), "81.3 cm × 73.0 cm")
	assert_eq(str(loader.get_artwork("glorious_3_pentecost").get("creation_date", "")), "1612–1614")
	assert_eq(str(loader.get_artwork("glorious_4_assumption").get("current_location", "")), "State Hermitage Museum, St. Petersburg, Russia")
	assert_eq(str(loader.get_artwork("glorious_4_assumption").get("creation_date", "")), "c. 1680")
	assert_eq(str(loader.get_artwork("glorious_4_assumption").get("original_dimensions", "")), "195 cm × 145 cm")
	assert_eq(str(loader.get_artwork("glorious_5_coronation").get("creation_date", "")), "c. 1635–1636")

	# Verify synchronization with assets/2D/gimp/attributions.json
	var repo_root: String = ProjectSettings.globalize_path("res://..").simplify_path()
	var attr_path: String = repo_root.path_join("assets/2D/gimp/attributions.json")
	assert_true(FileAccess.file_exists(attr_path), "attributions.json must exist at %s" % attr_path)

	var file: FileAccess = FileAccess.open(attr_path, FileAccess.READ)
	assert_not_null(file, "Must open attributions.json")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	assert_true(parsed is Dictionary, "attributions.json root must be Dictionary")

	var images: Array = (parsed as Dictionary).get("images", [])
	assert_eq(images.size(), 23, "attributions.json must contain all 23 master artworks")
	assert_eq(str((images[images.size() - 1] as Dictionary).get("id", "")), "closing_prayers", "attributions.json must order closing_prayers last to match book appearance")

	var attr_by_id: Dictionary = {}
	for img_val: Variant in images:
		if img_val is Dictionary:
			var img: Dictionary = img_val
			var id_str: String = str(img.get("id", ""))
			attr_by_id[id_str] = img
			assert_ne(str(img.get("inventory_number", "")), "", "attributions.json '%s' must have non-empty inventory_number" % id_str)
			assert_ne(str(img.get("original_dimensions", "")), "", "attributions.json '%s' must have non-empty original_dimensions" % id_str)
			assert_ne(str(img.get("section_label", "")), "", "attributions.json '%s' must have non-empty section_label" % id_str)

			var runtime_art: Dictionary = loader.get_artwork(id_str)
			assert_eq(str(img.get("inventory_number", "")), str(runtime_art.get("inventory_number", "")), "Inventory number for '%s' must match between attributions.json and runtime data" % id_str)
			assert_eq(str(img.get("creation_date", "")), str(runtime_art.get("creation_date", "")), "Creation date for '%s' must match between attributions.json and runtime data" % id_str)
			assert_eq(str(img.get("current_location", "")), str(runtime_art.get("current_location", "")), "Location for '%s' must match between attributions.json and runtime data" % id_str)
			assert_eq(str(img.get("section_label", "")), str(runtime_art.get("section_label", "")), "Section label for '%s' must match between attributions.json and runtime data" % id_str)
			assert_eq(str(img.get("original_dimensions", "")), str(runtime_art.get("original_dimensions", "")), "Original dimensions for '%s' must match between attributions.json and runtime data" % id_str)

	assert_eq(str(attr_by_id.get("cover", {}).get("original_dimensions", "")), "197.8 cm × 128 cm")
	assert_eq(str(attr_by_id.get("joyful_2_visitation", {}).get("original_dimensions", "")), "114.5 cm × 88.5 cm")
	assert_eq(str(attr_by_id.get("luminous_3_proclamation", {}).get("original_dimensions", "")), "104 cm × 92 cm")
	assert_eq(str(attr_by_id.get("glorious_2_ascension", {}).get("original_dimensions", "")), "81.3 cm × 73.0 cm")
	assert_eq(str(attr_by_id.get("glorious_4_assumption", {}).get("original_dimensions", "")), "195 cm × 145 cm")
	assert_eq(str(attr_by_id.get("glorious_5_coronation", {}).get("original_dimensions", "")), "178.5 cm × 134.5 cm")


func test_historical_feast_note_and_marian_counsel_quote() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	var p2: Dictionary = loader.get_page(2)
	var sections: Array = p2.get("sections", [])
	assert_eq(sections.size(), 3, "Page 2 must have 3 historical sections")
	var sec3_body: String = str((sections[2] as Dictionary).get("body", ""))
	assert_true(
		sec3_body.contains("In 1571, he instituted the feast of Our Lady of Victory (renamed the Feast of Our Lady of the Rosary in 1573)."),
		"Page 2 Section 3 must document the standalone 1571 Our Lady of Victory feast and 1573 renaming sentence"
	)
	assert_true(
		sec3_body.contains("the Joyful Mysteries (Christ's Incarnation and early life, from the Annunciation to the Finding in the Temple)"),
		"Page 2 Section 3 must summarize the Joyful Mysteries"
	)
	assert_true(
		sec3_body.contains("the Sorrowful Mysteries (His Passion and Death, from the Agony in the Garden to the Crucifixion)"),
		"Page 2 Section 3 must summarize the Sorrowful Mysteries"
	)
	assert_true(
		sec3_body.contains("the Glorious Mysteries (His Resurrection, Ascension, and the crowning glory of the Church and the Blessed Virgin)"),
		"Page 2 Section 3 must summarize the Glorious Mysteries"
	)
	assert_true(
		sec3_body.contains("introducing the five Luminous Mysteries, contemplating the public ministry of Christ from His Baptism in the Jordan to the Institution of the Eucharist."),
		"Page 2 Section 3 must summarize the Luminous Mysteries"
	)
	assert_true(
		sec3_body.contains("\n"),
		"Page 2 Section 3 must contain a newline separator dividing Pope St. Pius V from Pope St. John Paul II"
	)
	assert_false(
		sec3_body.contains("(the Mysteries of Light)"),
		"Page 2 Section 3 must not contain redundant parenthetical '(the Mysteries of Light)'"
	)

	var back: Dictionary = loader.get_back_cover()
	var counsel: Dictionary = back.get("marian_counsel", {})
	assert_eq(
		str(counsel.get("quote", "")),
		"Never will anyone who says his Rosary every day become a formal heretic or be led astray by the devil. This is a statement that I would gladly sign with my blood.",
		"Back cover Marian counsel quote must match St. Louis Marie de Montfort's full verbatim sentence"
	)
	var expected_synopsis: String = "Designed so that you never need to turn a page mid-decade, Pray the Rosary pairs the complete prayers, Sacred Scripture passages, meditations, and spiritual fruits of all twenty Mysteries on the left-hand pages with breathtaking Renaissance and Baroque masterworks on the right-hand pages. Whether used for quiet personal contemplation, family prayer, or learning the Rosary for the first time, this volume invites you to gaze upon the face of Christ with the heart of His Blessed Mother."
	assert_eq(
		str(back.get("synopsis", "")),
		expected_synopsis,
		"Back cover synopsis must match updated wording"
	)
	var test_repo_root: String = ProjectSettings.globalize_path("res://..").simplify_path()
	var test_ref_content: String = FileAccess.get_file_as_string(test_repo_root.path_join("documents/references.md"))
	assert_true(
		test_ref_content.contains(expected_synopsis),
		"documents/references.md Page 50 section must match updated synopsis text"
	)


func test_simplified_prayer_titles_and_front_matter_bible_version_note() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	assert_eq(
		str(loader.get_prayer("our_father").get("title", "")),
		"The Our Father",
		"prayers.our_father.title must be simplified to 'The Our Father'"
	)
	assert_eq(
		str(loader.get_prayer("glory_be").get("title", "")),
		"The Glory Be",
		"prayers.glory_be.title must be simplified to 'The Glory Be'"
	)

	var p3: Dictionary = loader.get_page(3)
	var sections: Array = p3.get("sections", [])
	assert_eq(sections.size(), 3, "Page 3 must have 3 instructional sections")
	var sec0: Dictionary = sections[0] as Dictionary
	assert_eq(str(sec0.get("title", "")), "How This Book Is Organized", "Page 3 Section 1 title must be 'How This Book Is Organized'")
	var sec0_body: String = str(sec0.get("body", ""))
	assert_true(
		sec0_body.contains("Catholic Public Domain Version"),
		"Page 3 'How This Book Is Organized' section body must cite the Catholic Public Domain Version"
	)
	assert_true(
		sec0_body.contains("• Left Page (Word & Prayer): Displays the Mystery title, its spiritual fruit, a passage from Sacred Scripture (taken from the Catholic Public Domain Version of the Bible), a brief meditation, and the complete prayers for that decade."),
		"Page 3 Left Page (Word & Prayer) bullet must include '(taken from the Catholic Public Domain Version of the Bible)'"
	)
	assert_true(
		sec0_body.contains("• Right Page (Visual Contemplation): Displays the Mystery header at the top and a related Renaissance or Baroque masterpiece to rest your eyes and heart upon as you pray."),
		"Page 3 Right Page (Visual Contemplation) bullet must match refined visual contemplation wording"
	)


func test_page_3_step_by_step_guide_daily_vs_complete_rosary() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	var p3: Dictionary = loader.get_page(3)
	var sections: Array = p3.get("sections", [])
	assert_eq(sections.size(), 3, "Page 3 must have 3 instructional sections")

	var sec1: Dictionary = sections[1] as Dictionary
	assert_eq(
		str(sec1.get("title", "")),
		"Step-by-Step Guide to Praying the Rosary",
		"Page 3 Section 2 title must be 'Step-by-Step Guide to Praying the Rosary'"
	)

	var expected_body: String = "1. Opening Prayers (Tab O): Make the Sign of the Cross, pray the Apostles' Creed on the Crucifix, the Our Father on the first large bead, three Hail Marys (for Faith, Hope, and Charity) on the three small beads, and the Glory Be.\n2. The Decades (Tabs J, L, S, G): For each decade, read the Scripture and meditation, and pray one Our Father, ten Hail Marys, one Glory Be, and the Fatima Prayer, using the artwork to help you contemplate the Mystery. Pray either the five decades of the day's Mystery set, or all four Mystery sets (twenty decades) back-to-back in chronological order (Joyful, Luminous, Sorrowful, Glorious) for a complete Rosary.\n3. Closing Prayers (Tab C): Flip Tab C to the left and conclude with the Hail, Holy Queen (Salve Regina), the Concluding Rosary Prayer, and the Sign of the Cross."
	var sec1_body: String = str(sec1.get("body", ""))
	assert_eq(
		sec1_body,
		expected_body,
		"Page 3 'Step-by-Step Guide to Praying the Rosary' body must match exact updated wording"
	)
	assert_true(
		sec1_body.contains(", and pray one Our Father, ten Hail Marys, one Glory Be, and the Fatima Prayer, using the artwork to help you contemplate the Mystery."),
		"Page 3 Step-by-Step Guide decade prayer sequence must include Fatima Prayer and artwork contemplation clause"
	)
	assert_true(
		sec1_body.contains("five decades of the day's Mystery set"),
		"Page 3 Step-by-Step Guide must explain praying the five decades of the day's Mystery set"
	)
	assert_true(
		sec1_body.contains("all four Mystery sets (twenty decades) back-to-back in chronological order (Joyful, Luminous, Sorrowful, Glorious) for a complete Rosary"),
		"Page 3 Step-by-Step Guide must explain praying all four Mystery sets (twenty decades) back-to-back in chronological order"
	)


func test_glory_be_single_sentence_formatting_and_page_hydration() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	var expected_text: String = "Glory be to the Father, and to the Son, and to the Holy Spirit,\nas it was in the beginning, is now, and ever shall be, world without end. Amen."
	var expected_leader: String = "Glory be to the Father, and to the Son, and to the Holy Spirit,"
	var expected_response: String = "as it was in the beginning, is now, and ever shall be, world without end. Amen."

	var glory_be: Dictionary = loader.get_prayer("glory_be")
	assert_false(glory_be.is_empty(), "glory_be prayer must exist in prayers.json")
	assert_eq(
		str(glory_be.get("text", "")),
		expected_text,
		"glory_be.text must format as a single sentence with comma punctuation"
	)
	assert_eq(
		str(glory_be.get("leader_text", "")),
		expected_leader,
		"glory_be.leader_text must end with a trailing comma"
	)
	assert_eq(
		str(glory_be.get("response_text", "")),
		expected_response,
		"glory_be.response_text must begin with lowercase 'as it was in the beginning' completing the single sentence"
	)

	# Verify Page 4 Opening Prayers hydration (Spread 2 left page)
	var spread_2: Dictionary = loader.get_hydrated_spread(2)
	var s2_steps: Array = spread_2.get("left_page", {}).get("prayer_steps", [])
	var found_s2_glory_be: bool = false
	for step_val: Variant in s2_steps:
		if step_val is Dictionary:
			var step: Dictionary = step_val
			if str(step.get("prayer_id", "")) == "glory_be":
				found_s2_glory_be = true
				var p_dict: Dictionary = step.get("prayer", {})
				assert_false(p_dict.is_empty(), "Spread 2 must hydrate glory_be prayer dictionary")
				assert_eq(str(p_dict.get("text", "")), expected_text, "Spread 2 hydrated glory_be text must match single-sentence wording")
				assert_eq(str(p_dict.get("leader_text", "")), expected_leader, "Spread 2 hydrated glory_be leader_text must match")
				assert_eq(str(p_dict.get("response_text", "")), expected_response, "Spread 2 hydrated glory_be response_text must match")
	assert_true(found_s2_glory_be, "Page 4 (Spread 2) prayer steps must contain glory_be")

	# Verify Page 4 via loader.get_page(4)
	var p4: Dictionary = loader.get_page(4)
	var p4_steps: Array = p4.get("prayer_steps", [])
	var found_p4_glory_be: bool = false
	for step_val: Variant in p4_steps:
		if step_val is Dictionary:
			var step: Dictionary = step_val
			if str(step.get("prayer_id", "")) == "glory_be":
				found_p4_glory_be = true
				var p_dict: Dictionary = step.get("prayer", {})
				assert_eq(str(p_dict.get("text", "")), expected_text, "Page 4 hydrated glory_be text must match single-sentence wording")
				assert_eq(str(p_dict.get("leader_text", "")), expected_leader, "Page 4 hydrated glory_be leader_text must match")
				assert_eq(str(p_dict.get("response_text", "")), expected_response, "Page 4 hydrated glory_be response_text must match")
	assert_true(found_p4_glory_be, "Page 4 direct lookup must contain glory_be")

	# Verify all 20 Mystery spreads (Spreads 3..22, corresponding to Left Pages 6, 8, ..., 44)
	for sp_num: int in range(3, 23):
		var sp: Dictionary = loader.get_hydrated_spread(sp_num)
		var decade_prayers: Array = sp.get("decade_prayers", [])
		var found_mystery_glory_be: bool = false
		for step_val: Variant in decade_prayers:
			if step_val is Dictionary:
				var step: Dictionary = step_val
				if str(step.get("prayer_id", "")) == "glory_be":
					found_mystery_glory_be = true
					var p_dict: Dictionary = step.get("prayer", {})
					assert_false(p_dict.is_empty(), "Spread %d must hydrate glory_be prayer dictionary" % sp_num)
					assert_eq(
						str(p_dict.get("text", "")),
						expected_text,
						"Spread %d decade prayer glory_be text must match single-sentence wording" % sp_num
					)
					assert_eq(
						str(p_dict.get("leader_text", "")),
						expected_leader,
						"Spread %d decade prayer glory_be leader_text must match" % sp_num
					)
					assert_eq(
						str(p_dict.get("response_text", "")),
						expected_response,
						"Spread %d decade prayer glory_be response_text must match" % sp_num
					)
		assert_true(found_mystery_glory_be, "Spread %d must contain glory_be in decade_prayers" % sp_num)

		# Also check page by number (left page is sp_num * 2)
		var left_page_num: int = sp_num * 2
		var page_dict: Dictionary = loader.get_page(left_page_num)
		var page_decade_prayers: Array = page_dict.get("decade_prayers", [])
		var found_page_glory_be: bool = false
		for step_val: Variant in page_decade_prayers:
			if step_val is Dictionary:
				var step: Dictionary = step_val
				if str(step.get("prayer_id", "")) == "glory_be":
					found_page_glory_be = true
					var p_dict: Dictionary = step.get("prayer", {})
					assert_eq(
						str(p_dict.get("text", "")),
						expected_text,
						"Page %d decade prayer glory_be text must match single-sentence wording" % left_page_num
					)
		assert_true(found_page_glory_be, "Page %d must contain glory_be in decade_prayers" % left_page_num)


func test_all_twelve_prayers_leader_and_response_formatting_and_hydration() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	var all_12_ids: Array[String] = [
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

	for pid: String in all_12_ids:
		var p: Dictionary = loader.get_prayer(pid)
		assert_false(p.is_empty(), "Prayer '%s' must exist" % pid)
		assert_true(p.has("leader_text"), "Prayer '%s' must define leader_text" % pid)
		assert_true(p.has("response_text"), "Prayer '%s' must define response_text" % pid)
		assert_ne(str(p.get("response_text", "")), "", "Prayer '%s' response_text must not be empty" % pid)

	# 1. Unison Prayers: leader_text == "", response_text == text
	var unison_ids: Array[String] = ["sign_of_the_cross", "fatima_prayer", "hail_holy_queen"]
	for pid: String in unison_ids:
		var p: Dictionary = loader.get_prayer(pid)
		assert_eq(str(p.get("leader_text", "")), "", "Unison prayer '%s' leader_text must be empty" % pid)
		assert_eq(str(p.get("text", "")), str(p.get("response_text", "")), "Unison prayer '%s' text must equal response_text" % pid)

	# 2. Split Prayers: non-empty leader_text and response_text, text == leader_text + "\n" + response_text
	var split_ids: Array[String] = [
		"apostles_creed",
		"our_father",
		"hail_mary",
		"hail_mary_faith",
		"hail_mary_hope",
		"hail_mary_charity",
		"glory_be",
		"versicle_response",
		"rosary_concluding_prayer"
	]
	for pid: String in split_ids:
		var p: Dictionary = loader.get_prayer(pid)
		var leader: String = str(p.get("leader_text", ""))
		var response: String = str(p.get("response_text", ""))
		var expected: String = "%s\n%s" % [leader, response]
		assert_ne(leader, "", "Split prayer '%s' leader_text must not be empty" % pid)
		assert_ne(response, "", "Split prayer '%s' response_text must not be empty" % pid)
		assert_eq(str(p.get("text", "")), expected, "Split prayer '%s' text must be leader + '\\n' + response" % pid)

	# 3. versicle_response: V. and R. prefixes stripped
	var vr: Dictionary = loader.get_prayer("versicle_response")
	assert_eq(str(vr.get("leader_text", "")), "Pray for us, O holy Mother of God.", "versicle_response leader_text must not contain 'V. '")
	assert_eq(str(vr.get("response_text", "")), "That we may be made worthy of the promises of Christ.", "versicle_response response_text must not contain 'R. '")
	assert_false(str(vr.get("text", "")).contains("V. "), "versicle_response text must not contain 'V. '")
	assert_false(str(vr.get("text", "")).contains("R. "), "versicle_response text must not contain 'R. '")

	# 4. rosary_concluding_prayer: leader is 'Let us pray.'
	var rcp: Dictionary = loader.get_prayer("rosary_concluding_prayer")
	assert_eq(str(rcp.get("leader_text", "")), "Let us pray.", "rosary_concluding_prayer leader_text must be 'Let us pray.'")

	# 5. hydrate_prayer_item helper method validation
	var sample_item: Dictionary = {"prayer_id": "our_father", "step_number": 3}
	var hydrated_sample: Dictionary = loader.hydrate_prayer_item(sample_item)
	assert_true(hydrated_sample.has("leader_text"), "hydrate_prayer_item must include leader_text")
	assert_true(hydrated_sample.has("response_text"), "hydrate_prayer_item must include response_text")
	assert_true(hydrated_sample.has("text"), "hydrate_prayer_item must include text")
	assert_true(hydrated_sample.has("prayer"), "hydrate_prayer_item must include prayer dict")
	assert_eq(str(hydrated_sample.get("leader_text", "")), str(loader.get_prayer("our_father").get("leader_text", "")))
	assert_eq(str(hydrated_sample.get("response_text", "")), str(loader.get_prayer("our_father").get("response_text", "")))

	# 6. Page 3 book_layout note validation
	var p3: Dictionary = loader.get_page(3)
	var sections: Array = p3.get("sections", [])
	assert_true(sections.size() >= 1, "Page 3 must have sections")
	var sec0_body: String = str((sections[0] as Dictionary).get("body", ""))
	assert_true(
		sec0_body.contains("spoken by the leader and lines in bold are spoken by everyone together"),
		"Page 3 How This Book Is Organized must explain leader (regular) and bold group response"
	)


func test_references_document_and_agent_rules_exist_and_complete() -> void:
	var repo_root: String = ProjectSettings.globalize_path("res://..").simplify_path()
	var references_path: String = repo_root.path_join("documents/references.md")
	var rules_path: String = repo_root.path_join(".agents/rules/references_verification.md")

	# 1. Existence and non-empty checks
	assert_true(FileAccess.file_exists(references_path), "documents/references.md must exist on disk: %s" % references_path)
	assert_true(FileAccess.file_exists(rules_path), ".agents/rules/references_verification.md must exist on disk: %s" % rules_path)

	var ref_content: String = FileAccess.get_file_as_string(references_path)
	var rules_content: String = FileAccess.get_file_as_string(rules_path)

	assert_true(ref_content.length() > 500, "documents/references.md must contain comprehensive documentation")
	assert_true(rules_content.length() > 100, ".agents/rules/references_verification.md must be non-empty")

	# 2. Dedicated AI Agent Verification Section
	assert_true(
		ref_content.contains("AI Agent Verification & Fact-Checking Rules"),
		"documents/references.md must have dedicated 'AI Agent Verification & Fact-Checking Rules' section at the top"
	)
	assert_true(
		rules_content.contains("documents/references.md"),
		".agents/rules/references_verification.md must mandate consulting documents/references.md"
	)

	# 3. Strict 50-Page Book Order Sequence
	var prev_idx: int = -1
	for page_num: int in range(1, 51):
		var page_marker: String = "### Page %d" % page_num
		var idx: int = ref_content.find(page_marker)
		assert_ne(idx, -1, "documents/references.md must contain section heading '%s'" % page_marker)
		if prev_idx != -1:
			assert_true(
				idx > prev_idx,
				"Page %d (char %d) must appear strictly after Page %d (char %d) in book order" % [page_num, idx, page_num - 1, prev_idx]
			)
		prev_idx = idx

	# 4. All 12 Prayers from prayers.json
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
		var pdict: Dictionary = loader.get_prayer(pid)
		assert_false(pdict.is_empty(), "Prayer '%s' must exist" % pid)
		var title: String = str(pdict.get("title", ""))
		assert_true(
			ref_content.contains(pid),
			"documents/references.md must document prayer key '%s'" % pid
		)
		assert_true(
			ref_content.contains(title),
			"documents/references.md must document prayer title '%s'" % title
		)

	# 5. All 20 Mysteries from mysteries.json
	var sets: Array[String] = ["joyful", "luminous", "sorrowful", "glorious"]
	for s_id: String in sets:
		var mset: Dictionary = loader.get_mystery_set(s_id)
		var decades: Array = mset.get("decades", [])
		for dec_obj in decades:
			var dec: Dictionary = dec_obj as Dictionary
			var dec_id: String = str(dec.get("id", ""))
			var dec_title: String = str(dec.get("title", ""))
			var dec_fruit: String = str(dec.get("fruit", ""))
			assert_true(
				ref_content.contains(dec_id),
				"documents/references.md must document mystery ID '%s'" % dec_id
			)
			assert_true(
				ref_content.contains(dec_title),
				"documents/references.md must document mystery title '%s'" % dec_title
			)
			var expected_fruit_line: String = "- **Spiritual Fruit:** %s" % dec_fruit
			assert_true(
				ref_content.contains(expected_fruit_line),
				"documents/references.md must document spiritual fruit line '%s'" % expected_fruit_line
			)

	# 6. All 23 Master Artworks from attributions.json and layout
	var attributions_path: String = repo_root.path_join("assets/2D/gimp/attributions.json")
	assert_true(FileAccess.file_exists(attributions_path), "attributions.json must exist")
	var attr_raw: String = FileAccess.get_file_as_string(attributions_path)
	var attr_json: Variant = JSON.parse_string(attr_raw)
	assert_true(attr_json is Dictionary, "attributions.json must parse as Dictionary")
	var images: Array = (attr_json as Dictionary).get("images", [])
	assert_eq(images.size(), 23, "attributions.json must contain 23 images")

	for img_obj in images:
		var img: Dictionary = img_obj as Dictionary
		var img_id: String = str(img.get("id", ""))
		var master_file: String = str(img.get("master_file", ""))
		var master_url: String = str(img.get("master_source_url", ""))
		var inv: String = str(img.get("inventory_number", ""))
		assert_true(
			ref_content.contains(img_id),
			"documents/references.md must document artwork ID '%s'" % img_id
		)
		assert_true(
			ref_content.contains(master_file),
			"documents/references.md must document master file '%s'" % master_file
		)
		assert_true(
			ref_content.contains(master_url),
			"documents/references.md must document master_source_url '%s'" % master_url
		)
		assert_true(
			ref_content.contains(inv),
			"documents/references.md must document inventory number '%s'" % inv
		)

	# 7. High-Quality Primary Source URLs
	var primary_domains: Array[String] = [
		"https://www.vatican.va",
		"https://www.usccb.org",
		"https://www.sacredbible.org",
		"https://github.com/draino7n7/cpdv",
		"https://www.drbo.org",
		"https://www.museodelprado.es",
		"https://www.nationalgallery.org.uk",
		"https://www.khm.at",
		"https://www.newadvent.org"
	]
	for domain: String in primary_domains:
		assert_true(
			ref_content.contains(domain),
			"documents/references.md must contain authoritative reference links from domain '%s'" % domain
		)

	assert_true(
		ref_content.contains("[Reference 1]"),
		"documents/references.md must use numbered '[Reference 1]' citations"
	)
	assert_true(
		ref_content.contains("[Reference 2]"),
		"documents/references.md must use numbered '[Reference 2]' citations"
	)


func test_references_document_completeness_and_book_order() -> void:
	test_references_document_and_agent_rules_exist_and_complete()

	var repo_root: String = ProjectSettings.globalize_path("res://..").simplify_path()
	var references_path: String = repo_root.path_join("documents/references.md")
	assert_true(FileAccess.file_exists(references_path), "documents/references.md must exist on disk")
	var ref_content: String = FileAccess.get_file_as_string(references_path)

	# 1. Zero unescaped parentheses in Markdown link URLs
	var regex_link: RegEx = RegEx.new()
	var regex_err: Error = regex_link.compile("\\]\\((https?://[^\\s\\)]+)\\)")
	assert_eq(regex_err, OK, "Markdown link RegEx should compile successfully")
	var matches: Array[RegExMatch] = regex_link.search_all(ref_content)
	assert_true(matches.size() > 50, "references.md must contain markdown links")
	for m: RegExMatch in matches:
		var url: String = m.get_string(1)
		assert_false(
			url.contains("(") or url.contains(")"),
			"Markdown link URL must not contain unescaped parentheses: %s" % url
		)

	var regex_raw_paren: RegEx = RegEx.new()
	var paren_err: Error = regex_raw_paren.compile("\\]\\(https?://[^\\s\\)]*\\([^\\)]*\\)")
	assert_eq(paren_err, OK, "Raw parenthesis RegEx should compile successfully")
	var raw_paren_matches: Array[RegExMatch] = regex_raw_paren.search_all(ref_content)
	assert_eq(raw_paren_matches.size(), 0, "No markdown links should contain raw unescaped parentheses")

	# 2. Zero insecure http:// links (all links must be https://)
	var regex_http: RegEx = RegEx.new()
	var http_err: Error = regex_http.compile("http://[^\\s\\)]+")
	assert_eq(http_err, OK, "HTTP RegEx should compile successfully")
	var http_matches: Array[RegExMatch] = regex_http.search_all(ref_content)
	assert_eq(http_matches.size(), 0, "documents/references.md must not contain any insecure http:// links")

	# 3. None of the 20 obsolete, broken, or mismatched URL substrings
	var broken_substrings: Array[String] = [
		"12015.htm",
		"objects/10207",
		"objects/30672",
		"objects/32338",
		"objektdb/detail/403",
		"objektdb/detail/1531",
		"secret-of-the-rosary-5671",
		"catholictradition.org",
		"collezione_online/last-supper",
		"feast-of-our-lady-of-the-rosary.html",
		"66248332-88b6",
		"81643c13-a745",
		"31bc7855-879e",
		"1bb2d634-118b",
		"82eb0216-0421",
		"04259b3f-1002",
		"d8e137f8-be58",
		"41262d22-192a",
		"1da51776-8801",
		"32415"
	]
	for broken: String in broken_substrings:
		assert_false(
			ref_content.contains(broken),
			"documents/references.md must not contain broken/mismatched URL substring: %s" % broken
		)

	# 4. All verified replacement URL substrings must be present
	var replacement_substrings: Array[String] = [
		"18015.htm",
		"jth015.htm",
		"13189a.htm",
		"memorial-of-our-lady-of-the-rosary.html",
		"objects/29292",
		"objects/34052",
		"objects/32172",
		"the-baptism-of-christ-1522",
		"christ-on-the-mount-of-olives-187",
		"collezione-on-line/last-supper",
		"olv-kerk-museum",
		"balat.kikirpa.be/object/89054",
		"balat.kikirpa.be/object/70926",
		"montfortian.info",
		"eb5f85ec-f95d",
		"8b502bfc-bc6d",
		"971fbc95-3a0d",
		"8115e55f-004f",
		"870c8293-1691",
		"4cc5628b-c77f",
		"dd47d10a-81f7",
		"5f39f2cc-0197",
		"76179d81-beaf"
	]
	for rep: String in replacement_substrings:
		assert_true(
			ref_content.contains(rep),
			"documents/references.md must contain verified replacement URL substring: %s" % rep
		)


func test_issue_47_editorial_scriptural_meditation_and_liturgical_refinements() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	# 1. Page 2 Subheading and Marian Psalter body text
	var p2: Dictionary = loader.get_page(2)
	assert_eq(str(p2.get("subheading", "")), "Origins and Tradition of the Most Holy Rosary", "Page 2 subheading must match")
	var p2_sections: Array = p2.get("sections", [])
	assert_eq(p2_sections.size(), 3, "Page 2 must contain 3 sections")
	var p2_sec1: Dictionary = p2_sections[1] as Dictionary
	assert_true(
		str(p2_sec1.get("body", "")).contains("organized the Marian Psalter (the 150 Hail Marys) into fifteen decades"),
		"Page 2 Section 2 body must contain '(the 150 Hail Marys)'"
	)

	# 2. Page 3 Heading
	var p3: Dictionary = loader.get_page(3)
	assert_eq(str(p3.get("heading", "")), "Structure of This Book & How to Pray", "Page 3 heading must match")

	# 3. Meditations across mysteries
	var j2: Dictionary = loader.get_mystery_by_id("joyful_2_visitation")
	assert_eq(
		str(j2.get("meditation", "")),
		"Bearing Christ within her, Mary hastens in charity to visit and care for her aged cousin Elizabeth, bringing sanctifying joy to the unborn John the Baptist.",
		"Joyful 2 meditation must match"
	)

	var l3: Dictionary = loader.get_mystery_by_id("luminous_3_proclamation")
	assert_eq(
		str(l3.get("meditation", "")),
		"Upon the Galilean hillside, Christ proclaims the Beatitudes, calling every soul to conversion of heart, merciful forgiveness, and childlike trust in the Father.",
		"Luminous 3 meditation must match"
	)

	var s4: Dictionary = loader.get_mystery_by_id("sorrowful_4_carrying_cross")
	assert_eq(
		str(s4.get("meditation", "")),
		"Falling beneath the heavy wood along the way to Calvary, Christ exchanges a look of piercing love with His grieving Mother, inviting us to take up our daily cross after Him.",
		"Sorrowful 4 meditation must match"
	)

	var g1: Dictionary = loader.get_mystery_by_id("glorious_1_resurrection")
	assert_eq(
		str(g1.get("meditation", "")),
		"At dawn on the third day, Christ bursts the bonds of death and rises in radiant majesty, opening the gates of eternal life to all who believe in Him.",
		"Glorious 1 meditation must match"
	)

	# 4. Fatima Prayer in prayers.json
	var fatima: Dictionary = loader.get_prayer("fatima_prayer")
	var expected_fatima: String = "O my Jesus, forgive us our sins, save us from the fires of hell, lead all souls to Heaven, especially those in most need of Thy mercy. Amen."
	assert_eq(str(fatima.get("response_text", "")), expected_fatima, "fatima_prayer response_text must use 'in most need'")
	assert_eq(str(fatima.get("text", "")), expected_fatima, "fatima_prayer text must use 'in most need'")

	# 5. Page 46 Closing Prayers structure and hydration
	var spread_23: Dictionary = loader.get_hydrated_spread(23)
	var p46_steps: Array = spread_23.get("left_page", {}).get("prayer_steps", [])
	assert_eq(p46_steps.size(), 3, "Page 46 must have exactly 3 prayer steps")

	var step1: Dictionary = p46_steps[0] as Dictionary
	assert_eq(str(step1.get("prayer_id", "")), "hail_holy_queen", "Step 1 must be hail_holy_queen")
	assert_eq(str(step1.get("append_prayer_id", "")), "versicle_response", "Step 1 must have append_prayer_id == 'versicle_response'")
	assert_eq(str(step1.get("rubric", "")), "After completing the decades, pray the Hail, Holy Queen (Salve Regina):", "Step 1 rubric must match")
	assert_eq(str(step1.get("versicle_leader_text", "")), "Pray for us, O holy Mother of God.", "Step 1 must hydrate versicle_leader_text")
	assert_eq(str(step1.get("versicle_response_text", "")), "That we may be made worthy of the promises of Christ.", "Step 1 must hydrate versicle_response_text")
	assert_false(step1.get("appended_prayer", {}).is_empty(), "Step 1 must hydrate appended_prayer")

	var step2: Dictionary = p46_steps[1] as Dictionary
	assert_eq(int(step2.get("step_number", 0)), 2, "Step 2 step_number must be 2")
	assert_eq(str(step2.get("prayer_id", "")), "rosary_concluding_prayer", "Step 2 must be rosary_concluding_prayer")

	var step3: Dictionary = p46_steps[2] as Dictionary
	assert_eq(int(step3.get("step_number", 0)), 3, "Step 3 step_number must be 3")
	assert_eq(str(step3.get("prayer_id", "")), "sign_of_the_cross", "Step 3 must be sign_of_the_cross")

	# Direct page 46 lookup
	var p46: Dictionary = loader.get_page(46)
	var direct_p46_steps: Array = p46.get("prayer_steps", [])
	assert_eq(direct_p46_steps.size(), 3, "Direct lookup Page 46 must have 3 steps")
	var dir_s1: Dictionary = direct_p46_steps[0] as Dictionary
	assert_eq(str(dir_s1.get("versicle_leader_text", "")), "Pray for us, O holy Mother of God.")
	assert_eq(str(dir_s1.get("versicle_response_text", "")), "That we may be made worthy of the promises of Christ.")

	# 6. references.md verification
	var repo_root: String = ProjectSettings.globalize_path("res://..").simplify_path()
	var ref_content: String = FileAccess.get_file_as_string(repo_root.path_join("documents/references.md"))
	assert_true(ref_content.contains("Origins and Tradition of the Most Holy Rosary"))
	assert_true(ref_content.contains("organized the Marian Psalter (the 150 Hail Marys) into fifteen decades"))
	assert_true(ref_content.contains("Structure of This Book & How to Pray"))
	assert_true(ref_content.contains("especially those in most need of Thy mercy"))
	assert_true(ref_content.contains("https://www.drbo.org/chapter/21131.htm"))
	assert_true(ref_content.contains("https://www.drbo.org/chapter/49001.htm"))
	assert_true(ref_content.contains("https://www.drbo.org/chapter/18015.htm"))
	assert_true(ref_content.contains("https://www.newadvent.org/bible/jth015.htm"))


func test_apostles_creed_modern_resurrection_and_ascension_phrasing() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	var creed: Dictionary = loader.get_prayer("apostles_creed")
	assert_false(creed.is_empty(), "apostles_creed prayer must exist in prayers.json")

	var leader_text: String = str(creed.get("leader_text", ""))
	var response_text: String = str(creed.get("response_text", ""))
	var full_text: String = str(creed.get("text", ""))

	# 1. Verify modern Resurrection and Ascension phrasing
	var expected_resurrection: String = "He descended into hell; on the third day He rose again from the dead."
	var expected_ascension: String = "He ascended into heaven, and is seated at the right hand of God the Father Almighty; from there He will come to judge the living and the dead."

	assert_true(
		leader_text.contains(expected_resurrection),
		"apostles_creed leader_text must contain modern Resurrection phrasing: '%s'" % expected_resurrection
	)
	assert_true(
		leader_text.contains(expected_ascension),
		"apostles_creed leader_text must contain modern Ascension phrasing: '%s'" % expected_ascension
	)
	assert_true(
		full_text.contains(expected_resurrection),
		"apostles_creed full text must contain modern Resurrection phrasing: '%s'" % expected_resurrection
	)
	assert_true(
		full_text.contains(expected_ascension),
		"apostles_creed full text must contain modern Ascension phrasing: '%s'" % expected_ascension
	)

	# 2. Verify archaic phrasing does NOT regress
	assert_false(leader_text.contains("arose again"), "apostles_creed leader_text must not contain archaic 'arose again'")
	assert_false(leader_text.contains("from thence"), "apostles_creed leader_text must not contain archaic 'from thence'")
	assert_false(full_text.contains("arose again"), "apostles_creed text must not contain archaic 'arose again'")
	assert_false(full_text.contains("from thence"), "apostles_creed text must not contain archaic 'from thence'")

	# 3. Verify leader + response concatenation and response preservation
	var expected_full: String = "%s\n%s" % [leader_text, response_text]
	assert_eq(full_text, expected_full, "apostles_creed.text must match leader_text + '\\n' + response_text")

	var expected_response: String = "I believe in the Holy Spirit, the holy Catholic Church, the communion of saints, the forgiveness of sins, the resurrection of the body, and life everlasting. Amen."
	assert_eq(response_text, expected_response, "apostles_creed response_text must be preserved exactly")

	# 4. Verify exact target leader_text
	var expected_leader: String = "I believe in God, the Father Almighty, Creator of heaven and earth; and in Jesus Christ, His only Son, our Lord, who was conceived by the Holy Spirit, born of the Virgin Mary, suffered under Pontius Pilate, was crucified, died, and was buried. He descended into hell; on the third day He rose again from the dead. He ascended into heaven, and is seated at the right hand of God the Father Almighty; from there He will come to judge the living and the dead."
	assert_eq(leader_text, expected_leader, "apostles_creed leader_text must match expected text exactly")


func test_standardized_usccb_spiritual_fruits() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	var expected_fruits: Dictionary = {
		"joyful_1_annunciation": "Humility",
		"joyful_2_visitation": "Love of Neighbor",
		"joyful_3_nativity": "Poverty",
		"joyful_4_presentation": "Purity of Heart and Body",
		"joyful_5_finding_in_temple": "Devotion to Jesus",
		"luminous_1_baptism": "Openness to the Holy Spirit",
		"luminous_2_wedding_at_cana": "To Jesus through Mary",
		"luminous_3_proclamation": "Conversion",
		"luminous_4_transfiguration": "Desire for Holiness",
		"luminous_5_eucharist": "Adoration",
		"sorrowful_1_agony": "Obedience to God's Will",
		"sorrowful_2_scourging": "Mortification",
		"sorrowful_3_crowning_with_thorns": "Courage",
		"sorrowful_4_carrying_cross": "Patience",
		"sorrowful_5_crucifixion": "Sorrow for Our Sins",
		"glorious_1_resurrection": "Faith",
		"glorious_2_ascension": "Hope",
		"glorious_3_pentecost": "Wisdom",
		"glorious_4_assumption": "Devotion to Mary",
		"glorious_5_coronation": "Grace of a Happy Death"
	}

	assert_eq(expected_fruits.size(), 20, "Must define all 20 standardized spiritual fruits")

	for mystery_id: String in expected_fruits.keys():
		var mystery: Dictionary = loader.get_mystery_by_id(mystery_id)
		assert_false(mystery.is_empty(), "Mystery '%s' must exist" % mystery_id)
		assert_eq(
			str(mystery.get("fruit", "")),
			expected_fruits[mystery_id],
			"Mystery '%s' fruit must match standardized USCCB virtue '%s'" % [mystery_id, expected_fruits[mystery_id]]
		)


func test_issue_55_refined_mystery_reflections_and_canonical_ledger() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	var expected_reflections: Dictionary = {
		"joyful_1_annunciation": "With humble surrender, the Blessed Virgin welcomes the Archangel Gabriel's message and conceives the Eternal Word by the power of the Holy Spirit.",
		"luminous_1_baptism": "Descending into the River Jordan to sanctify the waters of Baptism, Christ is anointed by the Holy Spirit and proclaimed the Beloved Son of the Eternal Father.",
		"luminous_4_transfiguration": "Upon the holy mountain, the divine glory shines forth from the face of Christ, strengthening His Apostles for the coming Passion and revealing our call to transfiguring grace.",
		"luminous_5_eucharist": "Having loved His own unto the end, Christ offers His Body, Blood, Soul, and Divinity, under the appearances of bread and wine, to remain truly, really, and substantially present with His Church forever.",
		"sorrowful_2_scourging": "Bound to the pillar in silence, the innocent Lamb of God endures cruel blows in reparation for our sins, healing our wounded human nature.",
		"sorrowful_4_carrying_cross": "Falling beneath the heavy wood along the way to Calvary, Christ exchanges a look of piercing love with His grieving Mother, inviting us to take up our daily cross after Him."
	}

	# 1. Assert all 6 updated meditations in mysteries.json
	for mystery_id: String in expected_reflections.keys():
		var mystery: Dictionary = loader.get_mystery_by_id(mystery_id)
		assert_false(mystery.is_empty(), "Mystery '%s' must exist" % mystery_id)
		assert_eq(
			str(mystery.get("meditation", "")),
			expected_reflections[mystery_id],
			"Mystery '%s' meditation must match refined reflection" % mystery_id
		)

	# 2. Assert all 6 updated - **Meditation:** entries in documents/references.md
	var repo_root: String = ProjectSettings.globalize_path("res://..").simplify_path()
	var references_path: String = repo_root.path_join("documents/references.md")
	assert_true(FileAccess.file_exists(references_path), "documents/references.md must exist on disk")
	var ref_content: String = FileAccess.get_file_as_string(references_path)

	for mystery_id: String in expected_reflections.keys():
		var expected_line: String = "- **Meditation:** %s" % expected_reflections[mystery_id]
		assert_true(
			ref_content.contains(expected_line),
			"documents/references.md must contain exact meditation line '%s' for '%s'" % [expected_line, mystery_id]
		)


func test_page_48_colophon_data_structure_and_creator_attribution() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	var p48: Dictionary = loader.get_page(48)
	assert_false(p48.is_empty(), "Page 48 data must exist")
	assert_true(p48.has("colophon"), "Page 48 must contain a 'colophon' dictionary")

	var colophon: Dictionary = p48.get("colophon", {})
	assert_true(colophon.has("creator_notice"), "Page 48 colophon must define 'creator_notice'")
	assert_eq(
		str(colophon.get("creator_notice", "")),
		"This edition of “Pray the Rosary” was created and is maintained by Kevin Audrain.",
		"Page 48 creator_notice must be 'This edition of “Pray the Rosary” was created and is maintained by Kevin Audrain.'"
	)
	assert_true(colophon.has("show_version"), "Page 48 colophon must define 'show_version'")
	assert_true(
		bool(colophon.get("show_version", false)),
		"Page 48 show_version must be true"
	)

	# Verify Spread 24 left_page in book_layout.json contains the identical colophon
	var spread_24: Dictionary = loader.get_spread(24)
	assert_false(spread_24.is_empty(), "Spread 24 must exist")
	var left_p: Dictionary = spread_24.get("left_page", {})
	assert_true(left_p.has("colophon"), "Spread 24 left_page must contain colophon")
	var spread_colophon: Dictionary = left_p.get("colophon", {})
	assert_eq(str(spread_colophon.get("creator_notice", "")), "This edition of “Pray the Rosary” was created and is maintained by Kevin Audrain.")
	assert_true(bool(spread_colophon.get("show_version", false)))

	# Verify documents/references.md documents Page 48 creator notice
	var repo_root: String = ProjectSettings.globalize_path("res://..").simplify_path()
	var references_path: String = repo_root.path_join("documents/references.md")
	assert_true(FileAccess.file_exists(references_path), "documents/references.md must exist")
	var ref_text: String = FileAccess.get_file_as_string(references_path)
	assert_true(ref_text.contains("This edition of “Pray the Rosary” was created and is maintained by Kevin Audrain."), "documents/references.md must document Page 48 creator notice")


func test_issue_85_prayer_titles_rubrics_and_prose_refinements() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	# 1. Prayer titles: "The Hail, Holy Queen" and "The Concluding Rosary Prayer"
	var hail_holy_queen: Dictionary = loader.get_prayer("hail_holy_queen")
	assert_false(hail_holy_queen.is_empty(), "hail_holy_queen prayer must exist")
	assert_eq(str(hail_holy_queen.get("title", "")), "The Hail, Holy Queen", "hail_holy_queen title must be 'The Hail, Holy Queen'")

	var concluding_prayer: Dictionary = loader.get_prayer("rosary_concluding_prayer")
	assert_false(concluding_prayer.is_empty(), "rosary_concluding_prayer must exist")
	assert_eq(str(concluding_prayer.get("title", "")), "The Concluding Rosary Prayer", "rosary_concluding_prayer title must be 'The Concluding Rosary Prayer'")

	# 2. Concluding Rosary Prayer title case: "Most Holy Rosary"
	var resp_text: String = str(concluding_prayer.get("response_text", ""))
	var full_text: String = str(concluding_prayer.get("text", ""))
	assert_true(resp_text.contains("Most Holy Rosary"), "Concluding prayer response_text must contain 'Most Holy Rosary'")
	assert_true(full_text.contains("Most Holy Rosary"), "Concluding prayer full text must contain 'Most Holy Rosary'")
	assert_false(resp_text.contains("most holy Rosary"), "Concluding prayer response_text must not contain lowercase 'most holy Rosary'")

	# 3. Sorrowful 1 Agony meditation title case: "His Sacred Heart"
	var agony: Dictionary = loader.get_mystery_by_id("sorrowful_1_agony")
	assert_false(agony.is_empty(), "sorrowful_1_agony must exist")
	var agony_meditation: String = str(agony.get("meditation", ""))
	assert_true(agony_meditation.contains("His Sacred Heart"), "Agony meditation must capitalize 'His Sacred Heart'")
	assert_false(agony_meditation.contains("His sacred Heart"), "Agony meditation must not contain 'His sacred Heart'")

	# 4. Page 2 Section 1 prose refinement: "allowed all believers to unite their daily work and prayer"
	var p2: Dictionary = loader.get_page(2)
	assert_false(p2.is_empty(), "Page 2 must exist")
	var p2_sections: Array = p2.get("sections", [])
	assert_true(p2_sections.size() > 0, "Page 2 must have sections")
	var s1_body: String = str(p2_sections[0].get("body", ""))
	assert_true(s1_body.contains("allowed all believers to unite their daily work and prayer"), "Page 2 Section 1 must contain refined phrase 'allowed all believers to unite their daily work and prayer'")

	# 5. Page 4 step rubrics
	var p4: Dictionary = loader.get_page(4)
	assert_false(p4.is_empty(), "Page 4 must exist")
	var p4_steps: Array = p4.get("prayer_steps", [])
	assert_true(p4_steps.size() >= 3, "Page 4 must have at least 3 steps")
	assert_eq(str(p4_steps[1].get("rubric", "")), "Profess the Apostles' Creed:", "Page 4 Step 2 rubric must be 'Profess the Apostles' Creed:'")
	assert_eq(str(p4_steps[2].get("rubric", "")), "Pray the Our Father for the intentions of the Holy Father and the Church:", "Page 4 Step 3 rubric must be 'Pray the Our Father for the intentions of the Holy Father and the Church:'")

	# 6. Page 46 Step 2 rubric
	var p46: Dictionary = loader.get_page(46)
	assert_false(p46.is_empty(), "Page 46 must exist")
	var p46_steps: Array = p46.get("prayer_steps", [])
	assert_true(p46_steps.size() >= 2, "Page 46 must have at least 2 steps")
	assert_eq(str(p46_steps[1].get("rubric", "")), "Conclude with the Concluding Rosary Prayer:", "Page 46 Step 2 rubric must be 'Conclude with the Concluding Rosary Prayer:'")


func test_all_twenty_mysteries_scripture_text_synchronized_with_references_document() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	var repo_root: String = ProjectSettings.globalize_path("res://..").simplify_path()
	var references_path: String = repo_root.path_join("documents/references.md")
	assert_true(FileAccess.file_exists(references_path), "documents/references.md must exist on disk")
	var ref_content: String = FileAccess.get_file_as_string(references_path)

	var mystery_sets: Array[String] = ["joyful", "luminous", "sorrowful", "glorious"]
	var mystery_count: int = 0

	for set_id: String in mystery_sets:
		var mset: Dictionary = loader.get_mystery_set(set_id)
		assert_false(mset.is_empty(), "Mystery set '%s' must exist" % set_id)
		var decades: Array = mset.get("decades", [])
		for dec_var: Variant in decades:
			var dec: Dictionary = dec_var as Dictionary
			mystery_count += 1
			var mystery_id: String = str(dec.get("id", ""))
			var scrip_text: String = str(dec.get("scripture_text", ""))
			assert_false(scrip_text.is_empty(), "Mystery '%s' must have non-empty scripture_text" % mystery_id)

			# Verify no straight quotes exist in scripture_text (typographic quotes only)
			assert_false(scrip_text.contains("\""), "Mystery '%s' scripture_text must not contain straight double quotes" % mystery_id)

			# Verify verbatim match in documents/references.md
			var expected_line: String = "- **Scripture Text:** *\"%s\"*" % scrip_text
			assert_true(
				ref_content.contains(expected_line),
				"documents/references.md must contain exact line for mystery '%s': %s" % [mystery_id, expected_line]
			)

	assert_eq(mystery_count, 20, "Must have exactly 20 mysteries")




