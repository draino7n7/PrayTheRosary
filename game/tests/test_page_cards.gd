extends "res://tests/test_base.gd"
## Automated unit tests for 2:3 portrait page card components across all 6 page types.

const RosaryDataLoaderScript = preload("res://scripts/data/rosary_data_loader.gd")
const PageCardScene: PackedScene = preload("res://scenes/ui/page_card.tscn")
const CoverPageCardScene: PackedScene = preload("res://scenes/ui/pages/cover_page_card.tscn")
const FrontMatterPageCardScene: PackedScene = preload("res://scenes/ui/pages/front_matter_page_card.tscn")
const PrayerSequencePageCardScene: PackedScene = preload("res://scenes/ui/pages/prayer_sequence_page_card.tscn")
const MysteryPrayerPageCardScene: PackedScene = preload("res://scenes/ui/pages/mystery_prayer_page_card.tscn")
const ArtworkPageCardScene: PackedScene = preload("res://scenes/ui/pages/artwork_page_card.tscn")
const CreditsPageCardScene: PackedScene = preload("res://scenes/ui/pages/credits_page_card.tscn")
const BackCoverPageCardScene: PackedScene = preload("res://scenes/ui/pages/back_cover_page_card.tscn")


func _get_loaded_loader() -> RosaryDataLoader:
	var loader: RosaryDataLoader = RosaryDataLoaderScript.new() as RosaryDataLoader
	loader.load_all()
	return loader


func test_page_card_scenes_and_resources_exist() -> void:
	assert_not_null(PageCardScene, "PageCard master scene must load cleanly")
	assert_not_null(CoverPageCardScene, "CoverPageCard scene must load cleanly")
	assert_not_null(FrontMatterPageCardScene, "FrontMatterPageCard scene must load cleanly")
	assert_not_null(PrayerSequencePageCardScene, "PrayerSequencePageCard scene must load cleanly")
	assert_not_null(MysteryPrayerPageCardScene, "MysteryPrayerPageCard scene must load cleanly")
	assert_not_null(ArtworkPageCardScene, "ArtworkPageCard scene must load cleanly")
	assert_not_null(CreditsPageCardScene, "CreditsPageCard scene must load cleanly")
	assert_not_null(BackCoverPageCardScene, "BackCoverPageCard scene must load cleanly")


func test_page_card_aspect_ratio_and_dimensions() -> void:
	var scenes: Array[PackedScene] = [
		PageCardScene,
		CoverPageCardScene,
		FrontMatterPageCardScene,
		PrayerSequencePageCardScene,
		MysteryPrayerPageCardScene,
		ArtworkPageCardScene,
		CreditsPageCardScene,
		BackCoverPageCardScene
	]

	var expected_ratio: float = 2.0 / 3.0
	for sc: PackedScene in scenes:
		var inst: Node = sc.instantiate()
		test_root_window.add_child(inst)
		var card: BasePageCard = inst as BasePageCard
		assert_not_null(card, "Card instance must extend BasePageCard")
		assert_true(abs(card.ratio - expected_ratio) < 0.001, "Card must enforce 2:3 aspect ratio (%f vs %f)" % [card.ratio, expected_ratio])
		assert_eq(card.custom_minimum_size, Vector2(720, 1080), "Card minimum size must be 720x1080 (2:3 portrait)")
		inst.free()


func test_page_1_front_cover_card() -> void:
	var loader: RosaryDataLoader = _get_loaded_loader()
	var p1: Dictionary = loader.get_page(1)
	assert_false(p1.is_empty(), "Page 1 data must exist")

	var card: PageCard = PageCardScene.instantiate() as PageCard
	test_root_window.add_child(card)
	card.bind_page_data(p1, loader)

	assert_eq(card.page_number, 1, "Page number must be 1")
	assert_eq(card.page_type, "front_cover", "Page type must be front_cover")
	assert_true(card.get_sub_card() is CoverPageCard, "Sub card must be CoverPageCard")
	assert_eq(card.get_heading_text(), "PRAY THE ROSARY", "Cover title must match")
	assert_true(card.get_subheading_text().contains("Twenty Mysteries"), "Cover subtitle must describe Twenty Mysteries")

	var tex: Texture2D = card.get_artwork_texture()
	assert_not_null(tex, "Cover artwork texture must load")
	assert_true(tex.get_width() > 0 and tex.get_height() > 0, "Cover texture must have non-zero dimensions")

	var cover_sub: CoverPageCard = card.get_sub_card() as CoverPageCard
	assert_not_null(cover_sub, "Sub card must be CoverPageCard")

	var header_c: Control = cover_sub.get_header_container()
	var artwork_c: Control = cover_sub.get_artwork_container()
	var cover_tex_rect: TextureRect = cover_sub.get_cover_texture()
	var title_lbl: Label = cover_sub.title_label
	var subtitle_lbl: Label = cover_sub.subtitle_label

	assert_not_null(header_c, "Top Header Band container must exist")
	assert_not_null(artwork_c, "Artwork framed container must exist")
	assert_not_null(cover_tex_rect, "CoverTexture must exist")
	assert_not_null(title_lbl, "TitleLabel must exist")
	assert_not_null(subtitle_lbl, "SubtitleLabel must exist")
	assert_true(title_lbl.get_theme_font_size("font_size") >= 34, "Cover title font size must be >= 34pt")
	assert_true(subtitle_lbl.get_theme_font_size("font_size") >= 22, "Cover subtitle font size must be >= 22pt")

	# Verify vertical layout hierarchy separation
	assert_eq(header_c.get_parent(), artwork_c.get_parent(), "Header and Artwork containers must share the same vertical container parent")
	assert_true(header_c.get_parent() is VBoxContainer, "Header and Artwork container parent must be a VBoxContainer")
	assert_true(header_c.get_index() < artwork_c.get_index(), "Header container must precede artwork container in vertical layout order")

	# Force layout update to compute rects
	card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	card.size = Vector2(720, 1080)
	card.propagate_notification(Container.NOTIFICATION_SORT_CHILDREN)

	var header_bottom: float = header_c.position.y + header_c.size.y
	var artwork_top: float = artwork_c.position.y
	assert_true(header_bottom <= artwork_top, "Header bottom (%f) must be <= artwork top (%f)" % [header_bottom, artwork_top])

	var title_rect: Rect2 = title_lbl.get_global_rect()
	var subtitle_rect: Rect2 = subtitle_lbl.get_global_rect()
	var cover_rect: Rect2 = cover_tex_rect.get_global_rect()
	assert_false(title_rect.intersects(cover_rect), "Title label must not overlap cover texture")
	assert_false(subtitle_rect.intersects(cover_rect), "Subtitle label must not overlap cover texture")
	assert_true(title_rect.end.y <= cover_rect.position.y, "Title label bottom must be strictly above cover texture top")
	assert_true(subtitle_rect.end.y <= cover_rect.position.y, "Subtitle label bottom must be strictly above cover texture top")

	_assert_no_visible_page_numbers(card, 1)
	card.free()


func test_cover_page_card_dedicated_header_and_framed_artwork() -> void:
	var loader: RosaryDataLoader = _get_loaded_loader()
	var p1: Dictionary = loader.get_page(1)
	assert_false(p1.is_empty(), "Page 1 data must exist")

	var cover: CoverPageCard = CoverPageCardScene.instantiate() as CoverPageCard
	test_root_window.add_child(cover)
	cover.bind_page_data(p1, loader)

	var header_c: Control = cover.get_header_container()
	var artwork_c: Control = cover.get_artwork_container()
	var tex_rect: TextureRect = cover.get_cover_texture()

	assert_not_null(header_c, "Header container must not be null")
	assert_not_null(artwork_c, "Artwork container must not be null")
	assert_not_null(tex_rect, "CoverTexture must not be null")

	# Verify TextureRect aspect ratio preserving properties
	assert_eq(tex_rect.expand_mode, TextureRect.EXPAND_IGNORE_SIZE, "CoverTexture expand_mode must be EXPAND_IGNORE_SIZE (1)")
	assert_eq(tex_rect.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "CoverTexture stretch_mode must be STRETCH_KEEP_ASPECT_CENTERED (5)")

	# Verify container hierarchy and ordering
	var parent_vbox: VBoxContainer = header_c.get_parent() as VBoxContainer
	assert_not_null(parent_vbox, "Parent container must be a VBoxContainer")
	assert_eq(artwork_c.get_parent(), parent_vbox, "Artwork container must share the same parent VBoxContainer")
	assert_true(header_c.get_index() < artwork_c.get_index(), "Header must appear before artwork container in VBox order")

	# Verify layout rects and separation
	cover.set_anchors_preset(Control.PRESET_TOP_LEFT)
	cover.size = Vector2(720, 1080)
	cover.propagate_notification(Container.NOTIFICATION_SORT_CHILDREN)

	var header_bottom: float = header_c.position.y + header_c.size.y
	var artwork_top: float = artwork_c.position.y
	assert_true(header_bottom <= artwork_top, "Header bottom must be strictly <= artwork top (%f vs %f)" % [header_bottom, artwork_top])

	var title_lbl: Label = cover.title_label
	var subtitle_lbl: Label = cover.subtitle_label
	assert_not_null(title_lbl, "Title label must exist")
	assert_not_null(subtitle_lbl, "Subtitle label must exist")
	assert_true(title_lbl.get_theme_font_size("font_size") >= 34, "Cover title font size must be >= 34pt")
	assert_true(subtitle_lbl.get_theme_font_size("font_size") >= 22, "Cover subtitle font size must be >= 22pt")

	var title_rect: Rect2 = title_lbl.get_global_rect()
	var subtitle_rect: Rect2 = subtitle_lbl.get_global_rect()
	var tex_rect_bounds: Rect2 = tex_rect.get_global_rect()

	assert_false(title_rect.intersects(tex_rect_bounds), "Title must have zero overlap with cover texture")
	assert_false(subtitle_rect.intersects(tex_rect_bounds), "Subtitle must have zero overlap with cover texture")
	assert_true(title_rect.end.y <= tex_rect_bounds.position.y, "Title rect bottom must be strictly above artwork top")
	assert_true(subtitle_rect.end.y <= tex_rect_bounds.position.y, "Subtitle rect bottom must be strictly above artwork top")

	# Test artwork unload and reload lifecycle
	assert_not_null(cover.get_artwork_texture(), "Artwork texture must be loaded")
	cover.unload_artwork()
	assert_null(tex_rect.texture, "Unload artwork must clear texture")
	cover.load_artwork()
	assert_not_null(cover.get_artwork_texture(), "Load artwork must restore texture")

	cover.free()


func test_pages_2_and_3_front_matter_cards() -> void:
	var loader: RosaryDataLoader = _get_loaded_loader()

	# Page 2: The History of the Holy Rosary
	var p2: Dictionary = loader.get_page(2)
	var card2: PageCard = PageCardScene.instantiate() as PageCard
	test_root_window.add_child(card2)
	card2.bind_page_data(p2, loader)

	assert_eq(card2.page_number, 2, "Page number must be 2")
	assert_true(card2.get_sub_card() is FrontMatterPageCard, "Sub card must be FrontMatterPageCard")
	assert_eq(card2.get_heading_text(), "The History of the Holy Rosary", "Page 2 heading must match")
	assert_eq(card2.get_subheading_text(), "Origins of the Gospel Prayer of the Church", "Page 2 subheading must match")
	var fmc2: FrontMatterPageCard = card2.get_sub_card() as FrontMatterPageCard
	assert_eq(fmc2.get_section_count(), 3, "Page 2 must render 3 historical sections")
	assert_true(fmc2.subheading_label.get_theme_font_size("font_size") >= 22, "Page 2 subheading font size must be >= 22pt")
	assert_true(fmc2.heading_label.get_theme_font_size("font_size") >= 34, "Page 2 heading font size must be >= 34pt")
	var sec_title2: Label = fmc2.sections_container.get_child(0).get_node("SectionTitle") as Label
	var sec_body2: Label = fmc2.sections_container.get_child(0).get_node("SectionBody") as Label
	var sec3_body2: Label = fmc2.sections_container.get_child(2).get_node("SectionBody") as Label
	assert_eq(sec_title2.get_theme_font_size("font_size"), 25, "Page 2 section title font size must be 25pt")
	assert_eq(sec_body2.get_theme_font_size("font_size"), 22, "Page 2 section body font size must be 22pt")
	assert_true(sec3_body2.text.contains("instituted the feast of Our Lady of Victory (renamed the Feast of Our Lady of the Rosary in 1573)."), "Page 2 Section 3 must display updated 1571/1573 feast note")
	_assert_no_visible_page_numbers(card2, 2)
	card2.free()

	# Page 3: Structure of the Book & How to Pray
	var p3: Dictionary = loader.get_page(3)
	var card3: PageCard = PageCardScene.instantiate() as PageCard
	test_root_window.add_child(card3)
	card3.bind_page_data(p3, loader)

	assert_eq(card3.page_number, 3, "Page number must be 3")
	assert_true(card3.get_sub_card() is FrontMatterPageCard, "Sub card must be FrontMatterPageCard")
	assert_eq(card3.get_heading_text(), "Structure of the Book & How to Pray", "Page 3 heading must match")
	assert_eq(card3.get_subheading_text(), "Praying with Scripture, Prayer, and Sacred Art", "Page 3 subheading must match")
	var fmc3: FrontMatterPageCard = card3.get_sub_card() as FrontMatterPageCard
	assert_eq(fmc3.get_section_count(), 3, "Page 3 must render 3 instructional sections")
	assert_true(fmc3.subheading_label.get_theme_font_size("font_size") >= 22, "Page 3 subheading font size must be >= 22pt")
	assert_true(fmc3.heading_label.get_theme_font_size("font_size") >= 34, "Page 3 heading font size must be >= 34pt")
	var sec_title3: Label = fmc3.sections_container.get_child(0).get_node("SectionTitle") as Label
	var sec_body3: Label = fmc3.sections_container.get_child(0).get_node("SectionBody") as Label
	assert_true(sec_title3.get_theme_font_size("font_size") >= 23, "Page 3 section title font size must be >= 23pt (was 21pt)")
	assert_true(sec_body3.get_theme_font_size("font_size") >= 20, "Page 3 section body font size must be >= 20pt (was 16pt)")
	assert_true(
		sec_body3.text.contains("(taken from the Douay-Rheims / Confraternity Edition of the Bible)"),
		"Page 3 'How This Book Is Organized' must note the Douay-Rheims / Confraternity Edition of the Bible"
	)
	_assert_no_visible_page_numbers(card3, 3)
	card3.free()


func test_page_4_and_46_prayer_sequence_cards() -> void:
	var loader: RosaryDataLoader = _get_loaded_loader()

	# Page 4: The Opening Prayers
	var p4: Dictionary = loader.get_page(4)
	var card4: PageCard = PageCardScene.instantiate() as PageCard
	test_root_window.add_child(card4)
	card4.bind_page_data(p4, loader)

	assert_eq(card4.page_number, 4, "Page number must be 4")
	assert_true(card4.get_sub_card() is PrayerSequencePageCard, "Sub card must be PrayerSequencePageCard")
	assert_eq(card4.get_heading_text(), "The Opening Prayers", "Page 4 heading must match")
	var psc4: PrayerSequencePageCard = card4.get_sub_card() as PrayerSequencePageCard
	assert_eq(psc4.get_step_count(), 5, "Page 4 must render 5 introductory prayer steps")
	assert_true(psc4.subheading_label.get_theme_font_size("font_size") >= 22, "Page 4 subheading font size must be >= 22pt")
	assert_true(psc4.heading_label.get_theme_font_size("font_size") >= 34, "Page 4 heading font size must be >= 34pt")
	var p4_text: Label = psc4.steps_container.get_child(0).get_node("PrayerText") as Label
	assert_true(p4_text.get_theme_font_size("font_size") >= 18, "Page 4 PrayerText font size must be >= 18pt (was 14pt)")
	var p4_our_father_title: Label = psc4.steps_container.get_child(2).get_node("PrayerTitle") as Label
	var p4_glory_be_title: Label = psc4.steps_container.get_child(4).get_node("PrayerTitle") as Label
	assert_eq(p4_our_father_title.text, "The Our Father", "Page 4 Step 3 title must be 'The Our Father'")
	assert_eq(p4_glory_be_title.text, "The Glory Be", "Page 4 Step 5 title must be 'The Glory Be'")
	_assert_no_visible_page_numbers(card4, 4)
	card4.free()

	# Page 46: The Closing Prayers
	var p46: Dictionary = loader.get_page(46)
	var card46: PageCard = PageCardScene.instantiate() as PageCard
	test_root_window.add_child(card46)
	card46.bind_page_data(p46, loader)

	assert_eq(card46.page_number, 46, "Page number must be 46")
	assert_true(card46.get_sub_card() is PrayerSequencePageCard, "Sub card must be PrayerSequencePageCard")
	assert_eq(card46.get_heading_text(), "The Closing Prayers", "Page 46 heading must match")
	var psc46: PrayerSequencePageCard = card46.get_sub_card() as PrayerSequencePageCard
	assert_eq(psc46.get_step_count(), 4, "Page 46 must render 4 concluding prayer steps")
	assert_true(psc46.subheading_label.get_theme_font_size("font_size") >= 22, "Page 46 subheading font size must be >= 22pt")
	assert_true(psc46.heading_label.get_theme_font_size("font_size") >= 34, "Page 46 heading font size must be >= 34pt")
	var p46_text: Label = psc46.steps_container.get_child(0).get_node("PrayerText") as Label
	assert_true(p46_text.get_theme_font_size("font_size") >= 22, "Page 46 PrayerText font size must be >= 22pt (was 14pt)")
	_assert_no_visible_page_numbers(card46, 46)
	card46.free()


func test_all_twenty_mystery_prayer_cards() -> void:
	var loader: RosaryDataLoader = _get_loaded_loader()
	var mystery_prayer_pages: Array[int] = [
		6, 8, 10, 12, 14,
		16, 18, 20, 22, 24,
		26, 28, 30, 32, 34,
		36, 38, 40, 42, 44
	]
	assert_eq(mystery_prayer_pages.size(), 20, "Must have exactly 20 mystery prayer pages")

	for p_num: int in mystery_prayer_pages:
		var page_data: Dictionary = loader.get_page(p_num)
		assert_false(page_data.is_empty(), "Page %d data must exist" % p_num)

		var card: PageCard = PageCardScene.instantiate() as PageCard
		test_root_window.add_child(card)
		card.bind_page_data(page_data, loader)

		assert_eq(card.page_number, p_num, "Page number must be %d" % p_num)
		assert_eq(card.page_type, "mystery_prayer_page", "Page %d type must be mystery_prayer_page" % p_num)
		assert_true(card.get_sub_card() is MysteryPrayerPageCard, "Sub card must be MysteryPrayerPageCard")

		var heading: String = card.get_heading_text()
		var subheading: String = card.get_subheading_text()
		assert_ne(heading, "", "Page %d must have a mystery title heading" % p_num)
		assert_ne(subheading, "", "Page %d must have an ordinal subheading" % p_num)

		var mpc: MysteryPrayerPageCard = card.get_sub_card() as MysteryPrayerPageCard
		assert_true(mpc.get_fruit_text().begins_with("Fruit of the Mystery: "), "Page %d fruit must have callout prefix" % p_num)
		assert_true(mpc.subheading_label.get_theme_font_size("font_size") >= 22, "Page %d subheading font size must be >= 22pt" % p_num)
		assert_true(mpc.heading_label.get_theme_font_size("font_size") >= 34, "Page %d heading font size must be >= 34pt" % p_num)
		assert_true(mpc.fruit_label.get_theme_font_size("font_size") >= 17, "Page %d FruitLabel font size must be >= 17pt" % p_num)
		assert_true(mpc.scripture_citation_label.get_theme_font_size("font_size") >= 16, "Page %d ScriptureCitationLabel font size must be >= 16pt" % p_num)
		assert_ne(mpc.scripture_citation_label.text, "", "Page %d ScriptureCitationLabel text must not be empty" % p_num)
		assert_false(mpc.scripture_citation_label.text.contains("(Douay-Rheims)"), "Page %d ScriptureCitationLabel must not contain '(Douay-Rheims)'" % p_num)
		assert_true(mpc.scripture_text_label.get_theme_font_size("font_size") >= 20, "Page %d ScriptureTextLabel font size must be >= 20pt (was 14pt)" % p_num)
		assert_true(mpc.meditation_label.get_theme_font_size("font_size") >= 20, "Page %d MeditationLabel font size must be >= 20pt (was 14pt)" % p_num)

		var rubric_texts: Array[String] = []
		for child: Node in mpc.decade_prayers_container.get_children():
			var p_vbox: VBoxContainer = child as VBoxContainer
			var rubric_lbl: Label = p_vbox.get_node("DecadeRubric") as Label
			var prayer_lbl: Label = p_vbox.get_node("PrayerText") as Label
			assert_true(rubric_lbl.get_theme_font_size("font_size") >= 16, "Page %d DecadeRubric font size must be >= 16pt (was 14pt)" % p_num)
			assert_true(prayer_lbl.get_theme_font_size("font_size") >= 20, "Page %d PrayerText font size must be >= 20pt (was 13pt)" % p_num)
			rubric_texts.append(rubric_lbl.text)

		assert_true(rubric_texts.has("1× The Our Father"), "Page %d must render '1× The Our Father' in decade rubrics" % p_num)
		assert_true(rubric_texts.has("1× The Glory Be"), "Page %d must render '1× The Glory Be' in decade rubrics" % p_num)

		_assert_no_visible_page_numbers(card, p_num)
		card.free()


func test_all_twenty_two_artwork_cards() -> void:
	var loader: RosaryDataLoader = _get_loaded_loader()
	var artwork_pages: Array[int] = [
		5, 7, 9, 11, 13, 15,
		17, 19, 21, 23, 25,
		27, 29, 31, 33, 35,
		37, 39, 41, 43, 45,
		47
	]
	assert_eq(artwork_pages.size(), 22, "Must have exactly 22 artwork pages (Opening + 20 Mysteries + Closing)")

	for p_num: int in artwork_pages:
		var page_data: Dictionary = loader.get_page(p_num)
		assert_false(page_data.is_empty(), "Artwork page %d data must exist" % p_num)

		var card: PageCard = PageCardScene.instantiate() as PageCard
		test_root_window.add_child(card)
		card.bind_page_data(page_data, loader)

		assert_eq(card.page_number, p_num, "Page number must be %d" % p_num)
		assert_eq(card.page_type, "artwork_page", "Page %d type must be artwork_page" % p_num)
		assert_true(card.get_sub_card() is ArtworkPageCard, "Sub card must be ArtworkPageCard")

		var heading: String = card.get_heading_text()
		var subheading: String = card.get_subheading_text()
		assert_ne(heading, "", "Artwork page %d must have heading" % p_num)
		assert_ne(subheading, "", "Artwork page %d must have subheading" % p_num)

		var tex: Texture2D = card.get_artwork_texture()
		assert_not_null(tex, "Artwork page %d texture must load" % p_num)
		assert_true(tex.get_width() > 0 and tex.get_height() > 0, "Artwork page %d texture dimensions must be valid" % p_num)

		var apc: ArtworkPageCard = card.get_sub_card() as ArtworkPageCard
		assert_false(apc.has_caption(), "Artwork page %d must have strictly NO caption" % p_num)
		assert_true(apc.subheading_label.get_theme_font_size("font_size") >= 22, "Artwork page %d subheading font size must be >= 22pt" % p_num)
		assert_true(apc.heading_label.get_theme_font_size("font_size") >= 34, "Artwork page %d heading font size must be >= 34pt" % p_num)
		_assert_no_visible_page_numbers(card, p_num)
		card.free()


func test_pages_48_and_49_credits_cards() -> void:
	var loader: RosaryDataLoader = _get_loaded_loader()

	# Page 48: Part I (13 items)
	var p48: Dictionary = loader.get_page(48)
	var card48: PageCard = PageCardScene.instantiate() as PageCard
	test_root_window.add_child(card48)
	card48.bind_page_data(p48, loader)

	assert_eq(card48.page_number, 48, "Page number must be 48")
	assert_true(card48.get_sub_card() is CreditsPageCard, "Sub card must be CreditsPageCard")
	assert_eq(card48.get_heading_text(), "Sacred Artwork Credits (Part I)", "Page 48 heading must match")
	var cpc48: CreditsPageCard = card48.get_sub_card() as CreditsPageCard
	assert_eq(cpc48.get_attribution_count(), 13, "Page 48 must list 13 artwork attributions")
	assert_true(cpc48.subheading_label.get_theme_font_size("font_size") >= 22, "Page 48 subheading font size must be >= 22pt")
	assert_true(cpc48.heading_label.get_theme_font_size("font_size") >= 34, "Page 48 heading font size must be >= 34pt")
	var title48: Label = cpc48.credits_container.get_child(0).get_node("Title") as Label
	var details48: Label = cpc48.credits_container.get_child(0).get_node("Details") as Label
	assert_true(title48.get_theme_font_size("font_size") >= 16, "Credits Title font size must be >= 16pt (was 13pt)")
	assert_true(details48.get_theme_font_size("font_size") >= 14, "Credits Details font size must be >= 14pt (was 11pt)")
	_assert_no_visible_page_numbers(card48, 48)
	card48.free()

	# Page 49: Part II & Colophon (10 items)
	var p49: Dictionary = loader.get_page(49)
	var card49: PageCard = PageCardScene.instantiate() as PageCard
	test_root_window.add_child(card49)
	card49.bind_page_data(p49, loader)

	assert_eq(card49.page_number, 49, "Page number must be 49")
	assert_true(card49.get_sub_card() is CreditsPageCard, "Sub card must be CreditsPageCard")
	assert_eq(card49.get_heading_text(), "Sacred Artwork Credits (Part II) & Colophon", "Page 49 heading must match")
	var cpc49: CreditsPageCard = card49.get_sub_card() as CreditsPageCard
	assert_eq(cpc49.get_attribution_count(), 10, "Page 49 must list 10 artwork attributions")
	assert_true(cpc49.subheading_label.get_theme_font_size("font_size") >= 22, "Page 49 subheading font size must be >= 22pt")
	assert_true(cpc49.heading_label.get_theme_font_size("font_size") >= 34, "Page 49 heading font size must be >= 34pt")
	var title49: Label = cpc49.credits_container.get_child(0).get_node("Title") as Label
	var details49: Label = cpc49.credits_container.get_child(0).get_node("Details") as Label
	assert_true(title49.get_theme_font_size("font_size") >= 16, "Credits Title font size must be >= 16pt (was 13pt)")
	assert_true(details49.get_theme_font_size("font_size") >= 14, "Credits Details font size must be >= 14pt (was 11pt)")
	assert_true(cpc49.scripture_notice_label.get_theme_font_size("font_size") >= 13, "Colophon scripture notice must be >= 13pt (was 12pt)")
	assert_true(cpc49.colophon_notice_label.get_theme_font_size("font_size") >= 13, "Colophon artwork notice must be >= 13pt (was 11pt)")
	_assert_no_visible_page_numbers(card49, 49)
	card49.free()


func test_page_50_back_cover_card() -> void:
	var loader: RosaryDataLoader = _get_loaded_loader()
	var p50: Dictionary = loader.get_page(50)
	assert_false(p50.is_empty(), "Page 50 data must exist")

	var card: PageCard = PageCardScene.instantiate() as PageCard
	test_root_window.add_child(card)
	card.bind_page_data(p50, loader)

	assert_eq(card.page_number, 50, "Page number must be 50")
	assert_eq(card.page_type, "back_cover", "Page type must be back_cover")
	assert_true(card.get_sub_card() is BackCoverPageCard, "Sub card must be BackCoverPageCard")
	assert_eq(card.get_heading_text(), "PRAY THE ROSARY", "Back cover title must match")
	assert_true(card.get_subheading_text().contains("Twenty Mysteries"), "Back cover subtitle must match")

	var bcc: BackCoverPageCard = card.get_sub_card() as BackCoverPageCard
	assert_true(bcc.title_label.get_theme_font_size("font_size") >= 34, "Back cover title font size must be >= 34pt")
	assert_true(bcc.subtitle_label.get_theme_font_size("font_size") >= 22, "Back cover subtitle font size must be >= 22pt")
	assert_true(bcc.epigraph_quote_label.get_theme_font_size("font_size") >= 20, "Back cover epigraph quote font size must be >= 20pt (was 16pt)")
	assert_true(bcc.synopsis_label.get_theme_font_size("font_size") >= 18, "Back cover synopsis font size must be >= 18pt (was 15pt)")
	assert_true(bcc.counsel_quote_label.get_theme_font_size("font_size") >= 20, "Back cover counsel quote font size must be >= 20pt (was 16pt)")
	assert_true(bcc.counsel_quote_label.text.contains("become a formal heretic or be led astray by the devil."), "Back cover counsel quote must include full verbatim Montfort text")

	_assert_no_visible_page_numbers(card, 50)
	card.free()


func test_all_fifty_pages_hydrate_cleanly() -> void:
	var loader: RosaryDataLoader = _get_loaded_loader()
	var all_pages: Array[Dictionary] = loader.get_all_pages()
	assert_eq(all_pages.size(), 50, "Loader must return exactly 50 sequential pages")

	for i: int in range(all_pages.size()):
		var p_data: Dictionary = all_pages[i]
		var expected_page_num: int = i + 1
		assert_eq(int(p_data.get("page_number", 0)), expected_page_num, "Page %d must match index" % expected_page_num)

		var card: PageCard = PageCardScene.instantiate() as PageCard
		test_root_window.add_child(card)
		card.bind_page_data(p_data, loader)

		assert_eq(card.page_number, expected_page_num, "Card %d page_number must match" % expected_page_num)
		assert_not_null(card.get_sub_card(), "Card %d must instantiate a sub card" % expected_page_num)
		assert_true(abs(card.ratio - (2.0 / 3.0)) < 0.001, "Card %d must have 2:3 ratio" % expected_page_num)

		var req_h: float = _calculate_page_content_required_height(card.get_sub_card(), p_data, loader)
		assert_true(req_h <= 1080.0, "Page %d content required height (%.1fpx) must not exceed 1080px (zero overflow)" % [expected_page_num, req_h])

		_assert_no_visible_page_numbers(card, expected_page_num)

		card.free()


func _calculate_page_content_required_height(sub: BasePageCard, p_data: Dictionary, loader: RosaryDataLoader) -> float:
	var font_bold: Font = load("res://assets/fonts/EBGaramond-Bold.ttf") as Font
	var font_italic: Font = load("res://assets/fonts/EBGaramond-Italic.ttf") as Font
	var font_reg: Font = load("res://assets/fonts/EBGaramond-Regular.ttf") as Font
	var width: float = 656.0 # 720 - 64 margins
	var total_h: float = 64.0 # 32 top + 32 bottom margins

	if sub is FrontMatterPageCard:
		total_h += font_italic.get_height(22) + 6.0
		total_h += font_bold.get_height(34) + 6.0
		total_h += 2.0 + 20.0
		var sections: Array = p_data.get("sections", [])
		var total_chars: int = 0
		for s_val: Variant in sections:
			if s_val is Dictionary:
				total_chars += str((s_val as Dictionary).get("body", "")).length()
		var body_sz: int = 22 if total_chars <= 1650 else 20
		var title_sz: int = body_sz + 3
		for s_val: Variant in sections:
			if s_val is Dictionary:
				var s: Dictionary = s_val as Dictionary
				total_h += font_bold.get_height(title_sz) + 6.0
				total_h += font_reg.get_multiline_string_size(str(s.get("body", "")), HORIZONTAL_ALIGNMENT_LEFT, width, body_sz).y
				total_h += 16.0
	elif sub is PrayerSequencePageCard:
		total_h += font_italic.get_height(22) + 4.0
		total_h += font_bold.get_height(34) + 4.0
		total_h += 2.0 + 14.0
		var steps: Array = p_data.get("prayer_steps", [])
		var is_5: bool = steps.size() >= 5
		var body_sz: int = 19 if is_5 else 23
		var rubric_sz: int = 16 if is_5 else 18
		var title_sz: int = 20 if is_5 else 24
		for s_val: Variant in steps:
			if not (s_val is Dictionary):
				continue
			var s: Dictionary = s_val as Dictionary
			var bead: String = str(s.get("bead_label", ""))
			var rubric: String = str(s.get("rubric", ""))
			var rtext: String = "[%s] %s" % [bead, rubric] if bead != "" else rubric
			if rtext != "":
				total_h += font_italic.get_multiline_string_size(rtext, HORIZONTAL_ALIGNMENT_LEFT, width, rubric_sz).y + 3.0
			var p: Dictionary = s.get("prayer", {})
			if p.is_empty():
				p = loader.get_prayer(str(s.get("prayer_id", "")))
			if str(p.get("title", "")) != "":
				total_h += font_bold.get_height(title_sz) + 3.0
			if str(p.get("text", "")) != "":
				total_h += font_reg.get_multiline_string_size(str(p.get("text", "")), HORIZONTAL_ALIGNMENT_LEFT, width, body_sz).y
			total_h += 10.0
	elif sub is MysteryPrayerPageCard:
		total_h += font_italic.get_height(22) + 4.0
		total_h += font_bold.get_height(34) + 4.0
		total_h += font_italic.get_height(18) + 8.0 + 4.0
		total_h += 2.0 + 10.0
		var mys: Dictionary = p_data.get("mystery", {})
		var scrip_str: String = str(mys.get("scripture_text", ""))
		var med_str: String = str(mys.get("meditation", ""))
		var t_len: int = scrip_str.length() + med_str.length()
		var body_sz: int = 24
		if t_len > 580:
			body_sz = 22
		elif t_len > 480:
			body_sz = 23
		var rubric_sz: int = 17 if body_sz <= 22 else 18
		total_h += font_bold.get_height(17) + 2.0
		total_h += font_italic.get_multiline_string_size("“%s”" % scrip_str, HORIZONTAL_ALIGNMENT_LEFT, width - 20.0, body_sz).y + 8.0 + 10.0
		total_h += font_reg.get_multiline_string_size(med_str, HORIZONTAL_ALIGNMENT_LEFT, width, body_sz).y + 10.0
		var dec: Array = p_data.get("decade_prayers", [])
		for p_item_val: Variant in dec:
			if not (p_item_val is Dictionary):
				continue
			var p_item: Dictionary = p_item_val as Dictionary
			total_h += font_bold.get_height(rubric_sz) + 2.0
			var p_dict: Dictionary = p_item.get("prayer", {})
			if p_dict.is_empty():
				p_dict = loader.get_prayer(str(p_item.get("prayer_id", "")))
			total_h += font_reg.get_multiline_string_size(str(p_dict.get("text", "")), HORIZONTAL_ALIGNMENT_LEFT, width, body_sz).y
			total_h += 8.0
	elif sub is CreditsPageCard:
		total_h += font_italic.get_height(22) + 4.0
		total_h += font_bold.get_height(34) + 4.0
		total_h += 2.0 + 10.0
		var artworks: Array = p_data.get("attributions", [])
		if artworks.is_empty():
			for aid: Variant in p_data.get("attribution_ids", []):
				artworks.append(loader.get_artwork(str(aid)))
		for art_val: Variant in artworks:
			if not (art_val is Dictionary):
				continue
			var art: Dictionary = art_val as Dictionary
			total_h += font_bold.get_height(17) + 1.0
			var details: String = "%s (%s), %s • %s • %s" % [
				str(art.get("artist", "")),
				str(art.get("artist_dates", "")),
				str(art.get("creation_date", "")),
				str(art.get("medium", "")),
				str(art.get("current_location", ""))
			]
			total_h += font_reg.get_multiline_string_size(details, HORIZONTAL_ALIGNMENT_LEFT, width, 15).y + 6.0
		var colophon: Dictionary = p_data.get("colophon", {})
		if not colophon.is_empty():
			total_h += 10.0 + 1.0 + 6.0
			total_h += font_italic.get_multiline_string_size(str(colophon.get("scripture_notice", "")), HORIZONTAL_ALIGNMENT_LEFT, width, 14).y + 6.0
			total_h += font_reg.get_multiline_string_size(str(colophon.get("artwork_notice", "")), HORIZONTAL_ALIGNMENT_LEFT, width, 14).y
	elif sub is BackCoverPageCard:
		var inner_w: float = 720.0 - (12.0 + 22.0) * 2.0
		total_h = (12.0 + 26.0) * 2.0
		total_h += font_bold.get_height(38) + 8.0
		total_h += font_italic.get_multiline_string_size("A Contemplative Visual Guide to the Twenty Mysteries", HORIZONTAL_ALIGNMENT_CENTER, inner_w, 22).y + 8.0
		total_h += 2.0 + 24.0
		var epi: Dictionary = p_data.get("epigraph", {})
		total_h += font_italic.get_multiline_string_size("“%s”" % str(epi.get("quote", "")), HORIZONTAL_ALIGNMENT_LEFT, inner_w, 22).y + 6.0
		total_h += font_reg.get_height(17) + 24.0
		total_h += font_reg.get_multiline_string_size(str(p_data.get("synopsis", "")), HORIZONTAL_ALIGNMENT_LEFT, inner_w, 20).y + 24.0
		var coun: Dictionary = p_data.get("marian_counsel", {})
		total_h += font_italic.get_multiline_string_size("“%s”" % str(coun.get("quote", "")), HORIZONTAL_ALIGNMENT_LEFT, inner_w, 22).y + 6.0
		total_h += font_reg.get_height(17)
	else:
		total_h = 1080.0

	return total_h


func _assert_no_visible_page_numbers(node: Node, page_num: int) -> void:
	if node is Label:
		var lbl: Label = node as Label
		var text: String = lbl.text.strip_edges()
		if text == str(page_num) and lbl.visible:
			assert_true(false, "Found visible page number label displaying '%s'" % text)
	for child: Node in node.get_children():
		_assert_no_visible_page_numbers(child, page_num)
