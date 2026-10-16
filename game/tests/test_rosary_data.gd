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


func test_douay_rheims_citations_and_verbatim_texts() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	# Joyful 4: Luke 2:28 bracketed subject
	var j4: Dictionary = loader.get_mystery_by_id("joyful_4_presentation")
	assert_eq(str(j4.get("scripture_reference", "")), "Luke 2:22, 28–32")
	assert_true(str(j4.get("scripture_text", "")).contains("[Then Simeon] took him into his arms"), "Joyful 4 Luke 2:28 must use bracketed subject '[Then Simeon] took him into his arms'")

	# Luminous 4: Luke 9:29-31, 35 and verbatim 'hear him.'
	var l4: Dictionary = loader.get_mystery_by_id("luminous_4_transfiguration")
	assert_eq(str(l4.get("scripture_reference", "")), "Luke 9:29–31, 35")
	assert_true(str(l4.get("scripture_text", "")).ends_with("This is my beloved Son; hear him."), "Luminous 4 Luke 9:35 must end with verbatim DRBO 'hear him.'")
	assert_false(str(l4.get("scripture_text", "")).contains("hear ye him"), "Luminous 4 must not contain KJV 'hear ye him'")

	# Sorrowful 2: Isaias (Isaiah) 53:5
	var s2: Dictionary = loader.get_mystery_by_id("sorrowful_2_scourging")
	assert_eq(str(s2.get("scripture_reference", "")), "John 19:1; Isaias (Isaiah) 53:5")

	# Sorrowful 4: Citation order matching passage order (John 19:17; Luke 23:26-27)
	var s4: Dictionary = loader.get_mystery_by_id("sorrowful_4_carrying_cross")
	assert_eq(str(s4.get("scripture_reference", "")), "John 19:17; Luke 23:26–27")

	# Sorrowful 5: Luke 23:46 'crying out with a loud voice'
	var s5: Dictionary = loader.get_mystery_by_id("sorrowful_5_crucifixion")
	assert_true(str(s5.get("scripture_text", "")).contains("And Jesus crying out with a loud voice, said:"), "Sorrowful 5 Luke 23:46 must include 'out' in 'crying out with a loud voice'")

	# Glorious 2: Separated Luke 24:50-52 and Acts 1:9 in canonical order with ellipses
	var g2: Dictionary = loader.get_mystery_by_id("glorious_2_ascension")
	assert_eq(str(g2.get("scripture_reference", "")), "Luke 24:50–52; Acts 1:9")
	assert_eq(
		str(g2.get("scripture_text", "")),
		"And he led them out as far as Bethania: and lifting up his hands, he blessed them. And it came to pass, whilst he blessed them, he departed from them, and was carried up to heaven. And they adoring went back into Jerusalem with great joy... And when he had said these things, while they looked on, he was raised up: and a cloud received him out of their sight."
	)

	# Glorious 4: Citation order matching passage order (Judith 15:10; Psalm 44:14, 16)
	var g4: Dictionary = loader.get_mystery_by_id("glorious_4_assumption")
	assert_eq(str(g4.get("scripture_reference", "")), "Judith 15:10; Psalm 44:14, 16")

	# Glorious 5: Ecclesiasticus (Sirach) 24:7
	var g5: Dictionary = loader.get_mystery_by_id("glorious_5_coronation")
	assert_eq(str(g5.get("scripture_reference", "")), "Apocalypse (Revelation) 12:1; Ecclesiasticus (Sirach) 24:7")


func test_museum_catalog_attributions_and_synchronization() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	var expected_inventory: Dictionary = {
		"cover": "P00975",
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
		"sorrowful_1_agony": "GG F17",
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

	assert_eq(str(loader.get_artwork("luminous_2_wedding_at_cana").get("creation_date", "")), "c. 1712–1715")
	assert_eq(str(loader.get_artwork("luminous_5_eucharist").get("creation_date", "")), "1631–1632")
	assert_eq(str(loader.get_artwork("glorious_3_pentecost").get("creation_date", "")), "1612–1614")
	assert_eq(str(loader.get_artwork("glorious_4_assumption").get("current_location", "")), "State Hermitage Museum, St. Petersburg, Russia")
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

	assert_eq(str(attr_by_id.get("joyful_2_visitation", {}).get("original_dimensions", "")), "114.5 cm × 88.5 cm")
	assert_eq(str(attr_by_id.get("luminous_3_proclamation", {}).get("original_dimensions", "")), "104 cm × 92 cm")
	assert_eq(str(attr_by_id.get("glorious_5_coronation", {}).get("original_dimensions", "")), "178.5 cm × 134.5 cm")


func test_historical_feast_note_and_marian_counsel_quote() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	loader.load_all()

	var p2: Dictionary = loader.get_page(2)
	var sections: Array = p2.get("sections", [])
	assert_eq(sections.size(), 3, "Page 2 must have 3 historical sections")
	var sec3_body: String = str((sections[2] as Dictionary).get("body", ""))
	assert_true(
		sec3_body.contains("and in 1571 instituted the feast of Our Lady of Victory (renamed the Feast of Our Lady of the Rosary in 1573)."),
		"Page 2 Section 3 must document the 1571 Our Lady of Victory feast and 1573 renaming"
	)

	var back: Dictionary = loader.get_back_cover()
	var counsel: Dictionary = back.get("marian_counsel", {})
	assert_eq(
		str(counsel.get("quote", "")),
		"Never will anyone who says his Rosary every day become a formal heretic or be led astray by the devil. This is a statement that I would gladly sign with my blood.",
		"Back cover Marian counsel quote must match St. Louis Marie de Montfort's full verbatim sentence"
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
		sec0_body.contains("Douay-Rheims"),
		"Page 3 'How This Book Is Organized' section body must cite the Douay-Rheims Bible translation"
	)
	assert_true(
		sec0_body.contains("• Left Page (Word & Prayer): Displays the Mystery title, its spiritual fruit, a passage from Sacred Scripture (taken from the Douay-Rheims / Confraternity Edition of the Bible), a brief meditation, and the complete prayers for that decade."),
		"Page 3 Left Page (Word & Prayer) bullet must include '(taken from the Douay-Rheims / Confraternity Edition of the Bible)'"
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

	var expected_body: String = "1. Opening Prayers (Tab O): Make the Sign of the Cross, pray the Apostles' Creed on the Crucifix, the Our Father on the first large bead, three Hail Marys (for Faith, Hope, and Charity) on the three small beads, and the Glory Be.\n2. The Decades (Tabs J, L, S, G): For each decade, read the Scripture and meditation, pray one Our Father, ten Hail Marys while contemplating the artwork, one Glory Be, and the Fatima Prayer. Pray either the five decades of the day's Mystery set, or all four Mystery sets (twenty decades) back-to-back in chronological order (Joyful, Luminous, Sorrowful, Glorious) for a complete Rosary.\n3. Closing Prayers (Tab C): Flip Tab C to the left and conclude with the Hail, Holy Queen (Salve Regina), the Concluding Rosary Prayer, and the Sign of the Cross."
	var sec1_body: String = str(sec1.get("body", ""))
	assert_eq(
		sec1_body,
		expected_body,
		"Page 3 'Step-by-Step Guide to Praying the Rosary' body must match exact updated wording"
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


