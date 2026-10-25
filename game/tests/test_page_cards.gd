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
	assert_eq(card2.get_subheading_text(), "Origins and Tradition of the Most Holy Rosary", "Page 2 subheading must match")
	var fmc2: FrontMatterPageCard = card2.get_sub_card() as FrontMatterPageCard
	assert_eq(fmc2.get_section_count(), 3, "Page 2 must render 3 historical sections")
	assert_true(fmc2.subheading_label.get_theme_font_size("font_size") >= 22, "Page 2 subheading font size must be >= 22pt")
	assert_true(fmc2.heading_label.get_theme_font_size("font_size") >= 34, "Page 2 heading font size must be >= 34pt")
	var sec_title2: Label = fmc2.sections_container.get_child(0).get_node("SectionTitle") as Label
	var sec_body2: Label = fmc2.sections_container.get_child(0).get_node("SectionBody") as Label
	var sec3_body2: Label = fmc2.sections_container.get_child(2).get_node("SectionBody") as Label
	assert_eq(sec_title2.get_theme_font_size("font_size"), 23, "Page 2 section title font size must be 23pt (calibrated for > 1,650 chars)")
	assert_eq(sec_body2.get_theme_font_size("font_size"), 20, "Page 2 section body font size must be 20pt (calibrated for > 1,650 chars)")
	assert_true(sec3_body2.text.contains("instituted the feast of Our Lady of Victory (renamed the Feast of Our Lady of the Rosary in 1573)."), "Page 2 Section 3 must display updated 1571/1573 feast note")
	assert_true(sec3_body2.text.contains("\n\n"), "Page 2 Section 3 body text must have paragraph breaks")
	var req_h2: float = _calculate_page_content_required_height(fmc2, p2, loader)
	assert_true(req_h2 <= 1080.0, "Page 2 content required height (%.1fpx) must stay strictly within 1080.0px" % req_h2)
	_assert_no_visible_page_numbers(card2, 2)
	card2.free()

	# Page 3: Structure of This Book & How to Pray
	var p3: Dictionary = loader.get_page(3)
	var card3: PageCard = PageCardScene.instantiate() as PageCard
	test_root_window.add_child(card3)
	card3.bind_page_data(p3, loader)

	assert_eq(card3.page_number, 3, "Page number must be 3")
	assert_true(card3.get_sub_card() is FrontMatterPageCard, "Sub card must be FrontMatterPageCard")
	assert_eq(card3.get_heading_text(), "Structure of This Book & How to Pray", "Page 3 heading must match")
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
		sec_body3.text.contains("(taken from the Catholic Public Domain Version of the Bible)"),
		"Page 3 'How This Book Is Organized' must note the Catholic Public Domain Version of the Bible"
	)
	var sec1_title3: Label = fmc3.sections_container.get_child(1).get_node("SectionTitle") as Label
	var sec1_body3: Label = fmc3.sections_container.get_child(1).get_node("SectionBody") as Label
	assert_eq(sec1_title3.text, "Step-by-Step Guide to Praying the Rosary", "Page 3 Section 2 title must be 'Step-by-Step Guide to Praying the Rosary'")
	assert_true(
		sec1_body3.text.contains("2. The Decades (Tabs J, L, S, G):"),
		"Page 3 Step-by-Step Guide must display updated '2. The Decades (Tabs J, L, S, G):' step heading"
	)
	assert_true(
		sec1_body3.text.contains("five decades of the day's Mystery set"),
		"Page 3 Step-by-Step Guide must explain praying the five decades of the day's Mystery set"
	)
	assert_true(
		sec1_body3.text.contains("all four Mystery sets (twenty decades) back-to-back in chronological order (Joyful, Luminous, Sorrowful, Glorious) for a complete Rosary."),
		"Page 3 Step-by-Step Guide must explain praying all four Mystery sets (twenty decades) back-to-back in chronological order"
	)
	var req_h3: float = _calculate_page_content_required_height(fmc3, p3, loader)
	assert_true(req_h3 <= 1080.0, "Page 3 content required height (%.1fpx) must stay strictly within 1080.0px" % req_h3)
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

	var font_bold: Font = load("res://assets/fonts/EBGaramond-Bold.ttf") as Font
	var font_reg: Font = load("res://assets/fonts/EBGaramond-Regular.ttf") as Font

	# Step 1: Sign of the Cross (Unison)
	var step1: VBoxContainer = psc4.steps_container.get_child(0) as VBoxContainer
	var s1_prayer: Label = step1.get_node("PrayerText") as Label
	var s1_resp: Label = step1.get_node("ResponseText") as Label
	assert_false(s1_prayer.visible, "Page 4 Step 1 (Sign of Cross) PrayerText must be hidden (unison prayer)")
	assert_true(s1_resp.visible, "Page 4 Step 1 (Sign of Cross) ResponseText must be visible")
	assert_eq(s1_resp.text, "In the name of the Father, and of the Son, and of the Holy Spirit. Amen.")
	assert_eq(s1_resp.get_theme_font("font"), font_bold, "Page 4 Step 1 ResponseText must use bold font")

	# Step 2: Apostles' Creed (Split)
	var step2: VBoxContainer = psc4.steps_container.get_child(1) as VBoxContainer
	var s2_prayer: Label = step2.get_node("PrayerText") as Label
	var s2_resp: Label = step2.get_node("ResponseText") as Label
	assert_true(s2_prayer.visible, "Page 4 Step 2 (Apostles' Creed) PrayerText must be visible")
	assert_true(s2_prayer.text.begins_with("I believe in God, the Father Almighty"), "Page 4 Step 2 PrayerText must contain leader text")
	assert_eq(s2_prayer.get_theme_font("font"), font_reg, "Page 4 Step 2 PrayerText must use regular font")
	assert_true(s2_resp.visible, "Page 4 Step 2 (Apostles' Creed) ResponseText must be visible")
	assert_true(s2_resp.text.begins_with("I believe in the Holy Spirit"), "Page 4 Step 2 ResponseText must contain response text")
	assert_eq(s2_resp.get_theme_font("font"), font_bold, "Page 4 Step 2 ResponseText must use bold font")

	# Step 3: Our Father (Split)
	var step3: VBoxContainer = psc4.steps_container.get_child(2) as VBoxContainer
	var s3_prayer: Label = step3.get_node("PrayerText") as Label
	var s3_resp: Label = step3.get_node("ResponseText") as Label
	assert_true(s3_prayer.visible, "Page 4 Step 3 (Our Father) PrayerText must be visible")
	assert_eq(s3_prayer.get_theme_font("font"), font_reg, "Page 4 Step 3 PrayerText must use regular font")
	assert_true(s3_resp.visible, "Page 4 Step 3 (Our Father) ResponseText must be visible")
	assert_eq(s3_resp.get_theme_font("font"), font_bold, "Page 4 Step 3 ResponseText must use bold font")

	# Step 4: Three Hail Marys (Split)
	var step4: VBoxContainer = psc4.steps_container.get_child(3) as VBoxContainer
	var s4_title: Label = step4.get_node("PrayerTitle") as Label
	assert_not_null(s4_title, "Page 4 Step 4 PrayerTitle must exist")
	assert_eq(s4_title.text, "3× The Hail Mary", "Page 4 Step 4 title must be '3× The Hail Mary'")
	var s4_prayer: Label = step4.get_node("PrayerText") as Label
	var s4_resp: Label = step4.get_node("ResponseText") as Label
	assert_true(s4_prayer.visible, "Page 4 Step 4 (Hail Mary) PrayerText must be visible")
	assert_eq(s4_prayer.get_theme_font("font"), font_reg, "Page 4 Step 4 PrayerText must use regular font")
	assert_true(s4_resp.visible, "Page 4 Step 4 (Hail Mary) ResponseText must be visible")
	assert_eq(s4_resp.get_theme_font("font"), font_bold, "Page 4 Step 4 ResponseText must use bold font")

	# Step 5: Glory Be (Split)
	var step5: VBoxContainer = psc4.steps_container.get_child(4) as VBoxContainer
	var s5_prayer: Label = step5.get_node("PrayerText") as Label
	var s5_resp: Label = step5.get_node("ResponseText") as Label
	assert_true(s5_prayer.visible, "Page 4 Step 5 (Glory Be) PrayerText must be visible")
	assert_eq(s5_prayer.get_theme_font("font"), font_reg, "Page 4 Step 5 PrayerText must use regular font")
	assert_true(s5_resp.visible, "Page 4 Step 5 (Glory Be) ResponseText must be visible")
	assert_eq(s5_resp.get_theme_font("font"), font_bold, "Page 4 Step 5 ResponseText must use bold font")

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
	assert_eq(psc46.get_step_count(), 3, "Page 46 must render 3 concluding prayer steps")
	assert_true(psc46.subheading_label.get_theme_font_size("font_size") >= 22, "Page 46 subheading font size must be >= 22pt")
	assert_true(psc46.heading_label.get_theme_font_size("font_size") >= 34, "Page 46 heading font size must be >= 34pt")
	var p46_text: Label = psc46.steps_container.get_child(0).get_node("PrayerText") as Label
	assert_true(p46_text.get_theme_font_size("font_size") >= 22, "Page 46 PrayerText font size must be >= 22pt (was 14pt)")

	# Step 1: Hail, Holy Queen (Unison) with Appended Versicle & Response
	var p46_s1: VBoxContainer = psc46.steps_container.get_child(0) as VBoxContainer
	var p46_s1_title: Label = p46_s1.get_node("PrayerTitle") as Label
	var p46_s1_prayer: Label = p46_s1.get_node("PrayerText") as Label
	var p46_s1_resp: Label = p46_s1.get_node("ResponseText") as Label
	var p46_s1_vlead: Label = p46_s1.get_node("VersicleLeaderText") as Label
	var p46_s1_vresp: Label = p46_s1.get_node("VersicleResponseText") as Label
	assert_not_null(p46_s1_title, "Page 46 Step 1 PrayerTitle must exist")
	assert_eq(p46_s1_title.text, "The Hail, Holy Queen", "Page 46 Step 1 PrayerTitle must be 'The Hail, Holy Queen'")
	assert_false(p46_s1_prayer.visible, "Page 46 Step 1 (Hail Holy Queen) PrayerText must be hidden (unison prayer)")
	assert_true(p46_s1_resp.visible, "Page 46 Step 1 (Hail Holy Queen) ResponseText must be visible")
	assert_eq(p46_s1_resp.get_theme_font("font"), font_bold, "Page 46 Step 1 ResponseText must use bold font")
	assert_not_null(p46_s1_vlead, "Page 46 Step 1 VersicleLeaderText must exist")
	assert_true(p46_s1_vlead.visible, "Page 46 Step 1 VersicleLeaderText must be visible")
	assert_eq(p46_s1_vlead.text, "Pray for us, O holy Mother of God.", "Page 46 Step 1 VersicleLeaderText must match")
	assert_eq(p46_s1_vlead.get_theme_font("font"), font_reg, "Page 46 Step 1 VersicleLeaderText must use regular font")
	assert_not_null(p46_s1_vresp, "Page 46 Step 1 VersicleResponseText must exist")
	assert_true(p46_s1_vresp.visible, "Page 46 Step 1 VersicleResponseText must be visible")
	assert_eq(p46_s1_vresp.text, "That we may be made worthy of the promises of Christ.", "Page 46 Step 1 VersicleResponseText must match")
	assert_eq(p46_s1_vresp.get_theme_font("font"), font_bold, "Page 46 Step 1 VersicleResponseText must use bold font")

	# Step 2: Concluding Rosary Prayer (Split)
	var p46_s2: VBoxContainer = psc46.steps_container.get_child(1) as VBoxContainer
	var p46_s2_title: Label = p46_s2.get_node("PrayerTitle") as Label
	var p46_s2_prayer: Label = p46_s2.get_node("PrayerText") as Label
	var p46_s2_resp: Label = p46_s2.get_node("ResponseText") as Label
	assert_not_null(p46_s2_title, "Page 46 Step 2 PrayerTitle must exist")
	assert_eq(p46_s2_title.text, "The Concluding Rosary Prayer", "Page 46 Step 2 title must be 'The Concluding Rosary Prayer'")
	assert_true(p46_s2_prayer.visible, "Page 46 Step 2 (Concluding Rosary Prayer) PrayerText must be visible")
	assert_eq(p46_s2_prayer.text, "Let us pray.")
	assert_eq(p46_s2_prayer.get_theme_font("font"), font_reg, "Page 46 Step 2 PrayerText must use regular font")
	assert_true(p46_s2_resp.visible, "Page 46 Step 2 ResponseText must be visible")
	assert_true(p46_s2_resp.text.begins_with("O God, whose only begotten Son"))
	assert_eq(p46_s2_resp.get_theme_font("font"), font_bold, "Page 46 Step 2 ResponseText must use bold font")

	# Step 3: Final Blessing (Unison)
	var p46_s3: VBoxContainer = psc46.steps_container.get_child(2) as VBoxContainer
	var p46_s3_title: Label = p46_s3.get_node("PrayerTitle") as Label
	var p46_s3_prayer: Label = p46_s3.get_node("PrayerText") as Label
	var p46_s3_resp: Label = p46_s3.get_node("ResponseText") as Label
	assert_not_null(p46_s3_title, "Page 46 Step 3 PrayerTitle must exist")
	assert_eq(p46_s3_title.text, "The Sign of the Cross", "Page 46 Step 3 title must be 'The Sign of the Cross'")
	assert_false(p46_s3_prayer.visible, "Page 46 Step 3 (Sign of Cross) PrayerText must be hidden (unison prayer)")
	assert_true(p46_s3_resp.visible, "Page 46 Step 3 ResponseText must be visible")
	assert_eq(p46_s3_resp.text, "In the name of the Father, and of the Son, and of the Holy Spirit. Amen.")
	assert_eq(p46_s3_resp.get_theme_font("font"), font_bold, "Page 46 Step 3 ResponseText must use bold font")
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
		assert_true(mpc.fruit_label.get_theme_color("font_color").is_equal_approx(BasePageCard.COLOR_CRIMSON), "Page %d FruitLabel font color must be COLOR_CRIMSON" % p_num)
		var scripture_c: PanelContainer = mpc.get_node("CardPanel/MarginContainer/VBoxContainer/ScriptureContainer") as PanelContainer
		assert_not_null(scripture_c, "Page %d ScriptureContainer must exist" % p_num)
		var sc_style: StyleBoxFlat = scripture_c.get_theme_stylebox("panel") as StyleBoxFlat
		assert_not_null(sc_style, "Page %d ScriptureContainer must have a StyleBoxFlat panel" % p_num)
		assert_eq(sc_style.border_width_left, 1, "Page %d ScriptureContainer border_width_left must be 1" % p_num)
		assert_eq(sc_style.border_width_top, 1, "Page %d ScriptureContainer border_width_top must be 1" % p_num)
		assert_eq(sc_style.border_width_right, 1, "Page %d ScriptureContainer border_width_right must be 1" % p_num)
		assert_eq(sc_style.border_width_bottom, 1, "Page %d ScriptureContainer border_width_bottom must be 1" % p_num)
		assert_true(sc_style.border_color.is_equal_approx(BasePageCard.COLOR_ANTIQUE_GOLD), "Page %d ScriptureContainer border_color must be COLOR_ANTIQUE_GOLD" % p_num)
		assert_eq(sc_style.corner_radius_top_left, 3, "Page %d ScriptureContainer corner_radius must be 3" % p_num)
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

		var font_bold: Font = load("res://assets/fonts/EBGaramond-Bold.ttf") as Font
		var font_reg: Font = load("res://assets/fonts/EBGaramond-Regular.ttf") as Font

		var decade_children: Array[Node] = mpc.decade_prayers_container.get_children()
		assert_eq(decade_children.size(), 4, "Page %d must have 4 decade prayers" % p_num)

		# 0: Our Father (Split)
		var of_vbox: VBoxContainer = decade_children[0] as VBoxContainer
		var of_prayer: Label = of_vbox.get_node("PrayerText") as Label
		var of_resp: Label = of_vbox.get_node("ResponseText") as Label
		assert_true(of_prayer.visible, "Page %d Our Father PrayerText must be visible" % p_num)
		assert_eq(of_prayer.get_theme_font("font"), font_reg, "Page %d Our Father PrayerText must use regular font" % p_num)
		assert_true(of_resp.visible, "Page %d Our Father ResponseText must be visible" % p_num)
		assert_eq(of_resp.get_theme_font("font"), font_bold, "Page %d Our Father ResponseText must use bold font" % p_num)

		# 1: Hail Mary (Split)
		var hm_vbox: VBoxContainer = decade_children[1] as VBoxContainer
		var hm_prayer: Label = hm_vbox.get_node("PrayerText") as Label
		var hm_resp: Label = hm_vbox.get_node("ResponseText") as Label
		assert_true(hm_prayer.visible, "Page %d Hail Mary PrayerText must be visible" % p_num)
		assert_eq(hm_prayer.get_theme_font("font"), font_reg, "Page %d Hail Mary PrayerText must use regular font" % p_num)
		assert_true(hm_resp.visible, "Page %d Hail Mary ResponseText must be visible" % p_num)
		assert_eq(hm_resp.get_theme_font("font"), font_bold, "Page %d Hail Mary ResponseText must use bold font" % p_num)

		# 2: Glory Be (Split)
		var gb_vbox: VBoxContainer = decade_children[2] as VBoxContainer
		var gb_prayer: Label = gb_vbox.get_node("PrayerText") as Label
		var gb_resp: Label = gb_vbox.get_node("ResponseText") as Label
		assert_true(gb_prayer.visible, "Page %d Glory Be PrayerText must be visible" % p_num)
		assert_eq(gb_prayer.get_theme_font("font"), font_reg, "Page %d Glory Be PrayerText must use regular font" % p_num)
		assert_true(gb_resp.visible, "Page %d Glory Be ResponseText must be visible" % p_num)
		assert_eq(gb_resp.get_theme_font("font"), font_bold, "Page %d Glory Be ResponseText must use bold font" % p_num)

		# 3: Fatima Prayer (Unison)
		var fp_vbox: VBoxContainer = decade_children[3] as VBoxContainer
		var fp_prayer: Label = fp_vbox.get_node("PrayerText") as Label
		var fp_resp: Label = fp_vbox.get_node("ResponseText") as Label
		assert_false(fp_prayer.visible, "Page %d Fatima Prayer PrayerText must be hidden (unison)" % p_num)
		assert_true(fp_resp.visible, "Page %d Fatima Prayer ResponseText must be visible" % p_num)
		assert_eq(fp_resp.get_theme_font("font"), font_bold, "Page %d Fatima Prayer ResponseText must use bold font" % p_num)

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

	var expected_page_48_ids: Array[String] = [
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
		"luminous_5_eucharist"
	]
	var expected_page_49_ids: Array[String] = [
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

	# Page 48: Part I (12 items)
	var p48: Dictionary = loader.get_page(48)
	var card48: PageCard = PageCardScene.instantiate() as PageCard
	test_root_window.add_child(card48)
	card48.bind_page_data(p48, loader)

	assert_eq(card48.page_number, 48, "Page number must be 48")
	assert_true(card48.get_sub_card() is CreditsPageCard, "Sub card must be CreditsPageCard")
	assert_eq(card48.get_heading_text(), "Sacred Artwork Credits (Part I)", "Page 48 heading must match")
	assert_eq(card48.get_subheading_text(), "Front Cover, Opening Prayers, Joyful Mysteries & Luminous Mysteries", "Page 48 subheading must match")
	var cpc48: CreditsPageCard = card48.get_sub_card() as CreditsPageCard
	assert_eq(cpc48.get_attribution_count(), 12, "Page 48 must list 12 artwork attributions in sequential book order")
	assert_true(cpc48.subheading_label.get_theme_font_size("font_size") >= 22, "Page 48 subheading font size must be >= 22pt")
	assert_true(cpc48.heading_label.get_theme_font_size("font_size") >= 34, "Page 48 heading font size must be >= 34pt")

	for i: int in range(expected_page_48_ids.size()):
		var aid: String = expected_page_48_ids[i]
		var art: Dictionary = loader.get_artwork(aid)
		var sec_label: String = str(art.get("section_label", ""))
		var art_title: String = str(art.get("title", ""))
		assert_ne(sec_label, "", "Artwork '%s' must have a non-empty section_label" % aid)
		var item_node: Node = cpc48.credits_container.get_child(i)
		assert_eq(String(item_node.name), "Attribution_%s" % aid, "Page 48 item %d must be Attribution_%s" % [i, aid])
		var title_lbl: Label = item_node.get_node("Title") as Label
		var details_lbl: Label = item_node.get_node("Details") as Label
		var display_sec: String = sec_label
		var paren_idx: int = display_sec.find(" (")
		if paren_idx != -1 and display_sec.ends_with(")"):
			display_sec = display_sec.substr(0, paren_idx).strip_edges()
		assert_eq(title_lbl.text, "%s — %s" % [display_sec, art_title], "Page 48 item %d Title must include clean section_label and painting title" % i)
		assert_false(details_lbl.text.contains(")...("), "Page 48 item %d Details must not contain duplicate parentheticals ')...('" % i)
		assert_eq(title_lbl.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "Page 48 Title label must use AUTOWRAP_WORD_SMART")
		assert_true(title_lbl.get_theme_font_size("font_size") >= 16, "Credits Title font size must be >= 16pt (was 13pt)")
		assert_true(details_lbl.get_theme_font_size("font_size") >= 14, "Credits Details font size must be >= 14pt (was 11pt)")

	var el_greco_item: Node = cpc48.credits_container.get_node("Attribution_opening_prayers")
	var el_greco_details: Label = el_greco_item.get_node("Details") as Label
	assert_true(el_greco_details.text.contains("El Greco (Doménikos Theotokópoulos, 1541–1614)"), "El Greco credit details must merge sobriquet into single parenthetical")

	# Colophon assertions on Page 48
	assert_true(cpc48.colophon_container != null and cpc48.colophon_container.visible, "Page 48 ColophonContainer must be visible")
	assert_not_null(cpc48.creator_notice_label, "Page 48 creator_notice_label must exist")
	assert_true(cpc48.creator_notice_label.visible, "Page 48 creator_notice_label must be visible")
	assert_eq(cpc48.creator_notice_label.text, "This edition of “Pray the Rosary” was created and is maintained by Kevin Audrain.", "Page 48 creator notice text must match")
	assert_not_null(cpc48.version_label, "Page 48 version_label must exist")
	assert_true(cpc48.version_label.visible, "Page 48 version_label must be visible")
	var expected_version_str: String = "Version %s" % str(ProjectSettings.get_setting("application/config/version", ""))
	assert_eq(cpc48.version_label.text, expected_version_str, "Page 48 version label must match '%s'" % expected_version_str)
	assert_false(cpc48.scripture_notice_label.visible, "Page 48 scripture_notice_label must not be visible")
	assert_false(cpc48.colophon_notice_label.visible, "Page 48 colophon_notice_label must not be visible")
	assert_true(cpc48.creator_notice_label.get_theme_font_size("font_size") >= 13, "Page 48 creator notice font size must be >= 13pt")
	assert_true(cpc48.version_label.get_theme_font_size("font_size") >= 13, "Page 48 version font size must be >= 13pt")

	_assert_no_visible_page_numbers(card48, 48)
	card48.free()

	# Page 49: Part II & Colophon (11 items, ending with closing_prayers)
	var p49: Dictionary = loader.get_page(49)
	var card49: PageCard = PageCardScene.instantiate() as PageCard
	test_root_window.add_child(card49)
	card49.bind_page_data(p49, loader)

	assert_eq(card49.page_number, 49, "Page number must be 49")
	assert_true(card49.get_sub_card() is CreditsPageCard, "Sub card must be CreditsPageCard")
	assert_eq(card49.get_heading_text(), "Sacred Artwork Credits (Part II) & Colophon", "Page 49 heading must match")
	assert_eq(card49.get_subheading_text(), "Sorrowful Mysteries, Glorious Mysteries, Closing Prayers & Text Sources", "Page 49 subheading must match")
	var cpc49: CreditsPageCard = card49.get_sub_card() as CreditsPageCard
	assert_eq(cpc49.get_attribution_count(), 11, "Page 49 must list 11 artwork attributions in sequential book order")
	assert_true(cpc49.subheading_label.get_theme_font_size("font_size") >= 22, "Page 49 subheading font size must be >= 22pt")
	assert_true(cpc49.heading_label.get_theme_font_size("font_size") >= 34, "Page 49 heading font size must be >= 34pt")

	for i: int in range(expected_page_49_ids.size()):
		var aid: String = expected_page_49_ids[i]
		var art: Dictionary = loader.get_artwork(aid)
		var sec_label: String = str(art.get("section_label", ""))
		var art_title: String = str(art.get("title", ""))
		assert_ne(sec_label, "", "Artwork '%s' must have a non-empty section_label" % aid)
		var item_node: Node = cpc49.credits_container.get_child(i)
		assert_eq(String(item_node.name), "Attribution_%s" % aid, "Page 49 item %d must be Attribution_%s" % [i, aid])
		var title_lbl: Label = item_node.get_node("Title") as Label
		var details_lbl: Label = item_node.get_node("Details") as Label
		var display_sec: String = sec_label
		var paren_idx: int = display_sec.find(" (")
		if paren_idx != -1 and display_sec.ends_with(")"):
			display_sec = display_sec.substr(0, paren_idx).strip_edges()
		assert_eq(title_lbl.text, "%s — %s" % [display_sec, art_title], "Page 49 item %d Title must include clean section_label and painting title" % i)
		assert_false(details_lbl.text.contains(")...("), "Page 49 item %d Details must not contain duplicate parentheticals ')...('" % i)
		assert_eq(title_lbl.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "Page 49 Title label must use AUTOWRAP_WORD_SMART")
		assert_true(title_lbl.get_theme_font_size("font_size") >= 16, "Credits Title font size must be >= 16pt (was 13pt)")
		assert_true(details_lbl.get_theme_font_size("font_size") >= 14, "Credits Details font size must be >= 14pt (was 11pt)")

	var caracciolo_item: Node = cpc49.credits_container.get_node("Attribution_sorrowful_1_agony")
	var caracciolo_details: Label = caracciolo_item.get_node("Details") as Label
	assert_true(caracciolo_details.text.contains("Giovanni Battista Caracciolo (Battistello, 1578–1635)"), "Caracciolo credit details must merge sobriquet into single parenthetical")

	var raphael_item: Node = cpc49.credits_container.get_node("Attribution_sorrowful_4_carrying_cross")
	var raphael_details: Label = raphael_item.get_node("Details") as Label
	assert_true(raphael_details.text.contains("Raphael (Raffaello Sanzio, 1483–1520)"), "Raphael credit details must merge sobriquet into single parenthetical")

	var last_item49: Node = cpc49.credits_container.get_child(cpc49.get_attribution_count() - 1)
	assert_eq(String(last_item49.name), "Attribution_closing_prayers", "Final credit entry on Page 49 must be Attribution_closing_prayers")

	# Colophon assertions on Page 49
	assert_true(cpc49.colophon_container != null and cpc49.colophon_container.visible, "Page 49 ColophonContainer must be visible")
	assert_not_null(cpc49.creator_notice_label, "Page 49 creator_notice_label must exist")
	assert_false(cpc49.creator_notice_label.visible, "Page 49 creator_notice_label must not be visible")
	assert_not_null(cpc49.version_label, "Page 49 version_label must exist")
	assert_false(cpc49.version_label.visible, "Page 49 version_label must not be visible")
	assert_true(cpc49.scripture_notice_label.visible, "Page 49 scripture_notice_label must be visible")
	assert_true(cpc49.colophon_notice_label.visible, "Page 49 colophon_notice_label must be visible")
	assert_true(cpc49.scripture_notice_label.get_theme_font_size("font_size") >= 13, "Colophon scripture notice must be >= 13pt (was 12pt)")
	assert_true(
		cpc49.scripture_notice_label.text.contains("Catholic Public Domain Version (CPDV)"),
		"Colophon scripture notice must cite Catholic Public Domain Version (CPDV)"
	)
	assert_true(cpc49.colophon_notice_label.get_theme_font_size("font_size") >= 13, "Colophon artwork notice must be >= 13pt (was 11pt)")
	assert_eq(cpc49.colophon_notice_label.get_theme_color("font_color"), BasePageCard.COLOR_UMBER, "Colophon artwork notice font color must be COLOR_UMBER")
	_assert_no_visible_page_numbers(card49, 49)
	card49.free()


func test_page_48_colophon_and_presets() -> void:
	var loader: RosaryDataLoader = _get_loaded_loader()
	var p48: Dictionary = loader.get_page(48)
	var card: PageCard = PageCardScene.instantiate() as PageCard
	test_root_window.add_child(card)
	card.bind_page_data(p48, loader)

	var cpc: CreditsPageCard = card.get_sub_card() as CreditsPageCard
	assert_not_null(cpc, "Page 48 sub-card must be CreditsPageCard")

	# 1. Normal preset
	card.set_text_size_preset("normal")
	assert_eq(card.custom_minimum_size, Vector2(720.0, 1080.0), "Page 48 normal preset dimensions must be 720x1080")
	assert_eq(cpc.custom_minimum_size, Vector2(720.0, 1080.0), "Page 48 sub-card normal preset dimensions must be 720x1080")
	assert_true(cpc.colophon_container.visible, "ColophonContainer must be visible on Page 48")
	assert_true(cpc.creator_notice_label.visible, "CreatorNoticeLabel must be visible on Page 48")
	assert_eq(cpc.creator_notice_label.text, "This edition of “Pray the Rosary” was created and is maintained by Kevin Audrain.")
	assert_true(cpc.version_label.visible, "VersionNoticeLabel must be visible on Page 48")
	var expected_ver_str: String = "Version %s" % str(ProjectSettings.get_setting("application/config/version", ""))
	assert_eq(cpc.version_label.text, expected_ver_str)
	assert_false(cpc.scripture_notice_label.visible, "ScriptureNoticeLabel must be hidden on Page 48")
	assert_false(cpc.colophon_notice_label.visible, "ColophonNoticeLabel must be hidden on Page 48")

	# 2. Mobile preset
	card.set_text_size_preset("mobile")
	var mobile_h: float = card.custom_minimum_size.y
	assert_true(mobile_h > 1080.0, "Page 48 mobile height (%.1fpx) must elongate > 1080.0px" % mobile_h)
	assert_true(cpc.creator_notice_label.visible, "CreatorNoticeLabel must remain visible under mobile preset")
	assert_true(cpc.version_label.visible, "VersionNoticeLabel must remain visible under mobile preset")
	assert_eq(cpc.creator_notice_label.get_theme_font_size("font_size"), 18, "Mobile notice font size must be 18pt")

	# 3. Extra Large preset
	card.set_text_size_preset("extra_large")
	var xl_h: float = card.custom_minimum_size.y
	assert_true(xl_h > 1080.0, "Page 48 extra large height (%.1fpx) must elongate > 1080.0px" % xl_h)
	assert_true(xl_h > mobile_h, "Page 48 extra large height (%.1fpx) must exceed mobile height (%.1fpx)" % [xl_h, mobile_h])
	assert_true(cpc.creator_notice_label.visible, "CreatorNoticeLabel must remain visible under extra large preset")
	assert_true(cpc.version_label.visible, "VersionNoticeLabel must remain visible under extra large preset")
	assert_eq(cpc.creator_notice_label.get_theme_font_size("font_size"), 23, "Extra large notice font size must be 23pt")

	card.free()


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
	assert_true(bcc.epigraph_container is PanelContainer, "Epigraph container must be a PanelContainer callout box")
	assert_true(bcc.counsel_container is PanelContainer, "Counsel container must be a PanelContainer callout box")
	var epi_sb: StyleBoxFlat = bcc.epigraph_container.get_theme_stylebox("panel") as StyleBoxFlat
	assert_not_null(epi_sb, "Epigraph container must have StyleBoxFlat")
	assert_eq(epi_sb.bg_color, Color(0.164706, 0.035294, 0.043137, 1), "Epigraph callout box must use dark crimson bg_color #2A090B")
	var coun_sb: StyleBoxFlat = bcc.counsel_container.get_theme_stylebox("panel") as StyleBoxFlat
	assert_not_null(coun_sb, "Counsel container must have StyleBoxFlat")
	assert_eq(coun_sb.bg_color, Color(0.164706, 0.035294, 0.043137, 1), "Counsel callout box must use dark crimson bg_color #2A090B")

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
	var font_reg: Font = load("res://assets/fonts/EBGaramond-Regular.ttf") as Font
	var width: float = 656.0 # 720 - 64 margins
	var total_h: float = 64.0 # 32 top + 32 bottom margins

	if sub is FrontMatterPageCard:
		total_h += font_reg.get_height(22) + 6.0
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
		total_h += font_reg.get_height(22) + 4.0
		total_h += font_bold.get_height(34) + 4.0
		total_h += 2.0 + 14.0
		var steps: Array = p_data.get("prayer_steps", [])
		var is_5: bool = steps.size() >= 5
		var body_sz: int = 18 if is_5 else 22
		var rubric_sz: int = 15 if is_5 else 18
		var title_sz: int = 19 if is_5 else 23
		for s_val: Variant in steps:
			if not (s_val is Dictionary):
				continue
			var s: Dictionary = s_val as Dictionary
			var bead: String = str(s.get("bead_label", ""))
			var rubric: String = str(s.get("rubric", ""))
			var rtext: String = "[%s] %s" % [bead, rubric] if bead != "" else rubric
			if rtext != "":
				total_h += font_reg.get_multiline_string_size(rtext, HORIZONTAL_ALIGNMENT_LEFT, width, rubric_sz).y + 3.0
			var p: Dictionary = s.get("prayer", {})
			if p.is_empty():
				p = loader.get_prayer(str(s.get("prayer_id", "")))
			if str(p.get("title", "")) != "":
				total_h += font_bold.get_height(title_sz) + 3.0
			var leader_str: String = str(p.get("leader_text", ""))
			var response_str: String = str(p.get("response_text", ""))
			if leader_str == "" and response_str == "":
				response_str = str(p.get("text", ""))

			if leader_str != "":
				total_h += font_reg.get_multiline_string_size(leader_str, HORIZONTAL_ALIGNMENT_LEFT, width, body_sz).y
			if response_str != "":
				total_h += font_bold.get_multiline_string_size(response_str, HORIZONTAL_ALIGNMENT_LEFT, width, body_sz).y
			if leader_str != "" and response_str != "":
				total_h += 3.0

			var v_leader_str: String = str(s.get("versicle_leader_text", ""))
			var v_resp_str: String = str(s.get("versicle_response_text", ""))
			var append_pid: String = str(s.get("append_prayer_id", ""))
			if (v_leader_str == "" and v_resp_str == "") and append_pid != "":
				var app_p: Dictionary = loader.get_prayer(append_pid)
				v_leader_str = str(app_p.get("leader_text", ""))
				v_resp_str = str(app_p.get("response_text", ""))

			if v_leader_str != "":
				total_h += font_reg.get_multiline_string_size(v_leader_str, HORIZONTAL_ALIGNMENT_LEFT, width, body_sz).y + 3.0
			if v_resp_str != "":
				total_h += font_bold.get_multiline_string_size(v_resp_str, HORIZONTAL_ALIGNMENT_LEFT, width, body_sz).y + 3.0

			total_h += 8.0
	elif sub is MysteryPrayerPageCard:
		total_h += font_reg.get_height(22) + 4.0
		total_h += font_bold.get_height(34) + 4.0
		total_h += font_reg.get_height(18) + 8.0 + 4.0
		total_h += 2.0 + 10.0
		var mys: Dictionary = p_data.get("mystery", {})
		var scrip_str: String = str(mys.get("scripture_text", ""))
		var med_str: String = str(mys.get("meditation", ""))
		var t_len: int = scrip_str.length() + med_str.length()
		var body_sz: int = 24
		if t_len > 580:
			body_sz = 20
		elif t_len > 480:
			body_sz = 21
		elif t_len > 380:
			body_sz = 22
		else:
			body_sz = 23
		var rubric_sz: int = 17 if body_sz <= 21 else 18
		total_h += font_bold.get_height(17) + 2.0
		total_h += font_reg.get_multiline_string_size(scrip_str, HORIZONTAL_ALIGNMENT_LEFT, width - 20.0, body_sz).y + 8.0 + 10.0
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
			var leader_str: String = str(p_dict.get("leader_text", ""))
			var response_str: String = str(p_dict.get("response_text", ""))
			if leader_str == "" and response_str == "":
				response_str = str(p_dict.get("text", ""))

			if leader_str != "":
				total_h += font_reg.get_multiline_string_size(leader_str, HORIZONTAL_ALIGNMENT_LEFT, width, body_sz).y
			if response_str != "":
				total_h += font_bold.get_multiline_string_size(response_str, HORIZONTAL_ALIGNMENT_LEFT, width, body_sz).y
			if leader_str != "" and response_str != "":
				total_h += 2.0
			total_h += 8.0
	elif sub is CreditsPageCard:
		total_h = 44.0 # 22 top + 22 bottom margins
		total_h += font_reg.get_height(22) + 2.0
		total_h += font_bold.get_height(34) + 2.0
		total_h += 2.0 + 6.0
		var artworks: Array = p_data.get("attributions", [])
		if artworks.is_empty():
			for aid: Variant in p_data.get("attribution_ids", []):
				artworks.append(loader.get_artwork(str(aid)))
		for art_val: Variant in artworks:
			if not (art_val is Dictionary):
				continue
			var art: Dictionary = art_val as Dictionary
			var sec_label: String = str(art.get("section_label", "")).strip_edges()
			var art_title: String = str(art.get("title", "")).strip_edges()
			var combined_title: String = "%s — %s" % [sec_label, art_title] if (sec_label != "" and art_title != "") else art_title
			total_h += font_bold.get_multiline_string_size(combined_title, HORIZONTAL_ALIGNMENT_LEFT, width, 16).y
			var details: String = "%s (%s), %s • %s • %s" % [
				str(art.get("artist", "")),
				str(art.get("artist_dates", "")),
				str(art.get("creation_date", "")),
				str(art.get("medium", "")),
				str(art.get("current_location", ""))
			]
			total_h += font_reg.get_multiline_string_size(details, HORIZONTAL_ALIGNMENT_LEFT, width, 14).y + 3.0
		var colophon: Dictionary = p_data.get("colophon", {})
		if not colophon.is_empty():
			total_h += 6.0 + 1.0 + 3.0
			total_h += font_reg.get_multiline_string_size(str(colophon.get("scripture_notice", "")), HORIZONTAL_ALIGNMENT_LEFT, width, 13).y + 3.0
			total_h += font_reg.get_multiline_string_size(str(colophon.get("artwork_notice", "")), HORIZONTAL_ALIGNMENT_LEFT, width, 13).y
	elif sub is BackCoverPageCard:
		var inner_w: float = 720.0 - (12.0 + 22.0) * 2.0
		total_h = (12.0 + 20.0) * 2.0
		total_h += font_bold.get_height(38) + 8.0
		total_h += font_reg.get_multiline_string_size("A Contemplative Visual Guide to the Twenty Mysteries", HORIZONTAL_ALIGNMENT_CENTER, inner_w, 22).y + 8.0
		total_h += 2.0 + 24.0
		var epi: Dictionary = p_data.get("epigraph", {})
		total_h += 24.0 # Callout box padding
		total_h += font_reg.get_multiline_string_size("“%s”" % str(epi.get("quote", "")), HORIZONTAL_ALIGNMENT_LEFT, inner_w - 28.0, 22).y + 6.0
		total_h += font_reg.get_height(17) + 24.0
		total_h += font_reg.get_multiline_string_size(str(p_data.get("synopsis", "")), HORIZONTAL_ALIGNMENT_LEFT, inner_w, 20).y + 24.0
		var coun: Dictionary = p_data.get("marian_counsel", {})
		total_h += 24.0 # Callout box padding
		total_h += font_reg.get_multiline_string_size("“%s”" % str(coun.get("quote", "")), HORIZONTAL_ALIGNMENT_LEFT, inner_w - 28.0, 22).y + 6.0
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


func _assert_no_italic_fonts_in_labels(node: Node, page_num: int) -> void:
	if node is Label:
		var lbl: Label = node as Label
		var font: Font = null
		if lbl.has_theme_font_override("font"):
			font = lbl.get_theme_font("font")
		elif lbl.get_theme_font("font") != null:
			font = lbl.get_theme_font("font")

		if font != null:
			var path: String = font.resource_path
			assert_false(path.ends_with("EBGaramond-Italic.ttf"), "Page %d Label '%s' must not use EBGaramond-Italic.ttf (found %s)" % [page_num, lbl.name, path])
			assert_false(path.ends_with("EBGaramond-BoldItalic.ttf"), "Page %d Label '%s' must not use EBGaramond-BoldItalic.ttf (found %s)" % [page_num, lbl.name, path])
			if font is FontVariation:
				var fv: FontVariation = font as FontVariation
				if fv.base_font != null:
					var bpath: String = fv.base_font.resource_path
					assert_false(bpath.ends_with("EBGaramond-Italic.ttf"), "Page %d Label '%s' FontVariation must not use EBGaramond-Italic.ttf" % [page_num, lbl.name])
					assert_false(bpath.ends_with("EBGaramond-BoldItalic.ttf"), "Page %d Label '%s' FontVariation must not use EBGaramond-BoldItalic.ttf" % [page_num, lbl.name])
	for child: Node in node.get_children():
		_assert_no_italic_fonts_in_labels(child, page_num)


func test_no_italic_fonts_across_all_fifty_pages() -> void:
	var loader: RosaryDataLoader = _get_loaded_loader()
	var all_pages: Array[Dictionary] = loader.get_all_pages()
	assert_eq(all_pages.size(), 50, "Loader must return exactly 50 sequential pages")

	for i: int in range(all_pages.size()):
		var p_data: Dictionary = all_pages[i]
		var page_num: int = i + 1
		var card: PageCard = PageCardScene.instantiate() as PageCard
		test_root_window.add_child(card)
		card.bind_page_data(p_data, loader)

		_assert_no_italic_fonts_in_labels(card, page_num)

		card.free()


func test_dynamic_text_size_presets_font_scaling() -> void:
	var loader: RosaryDataLoader = _get_loaded_loader()

	# 1. PrayerSequencePageCard (Page 4)
	var p4_card: PageCard = PageCardScene.instantiate() as PageCard
	test_root_window.add_child(p4_card)
	p4_card.bind_page_data(loader.get_page(4), loader)
	var psc: PrayerSequencePageCard = p4_card.get_sub_card() as PrayerSequencePageCard
	assert_not_null(psc, "Page 4 subcard must be PrayerSequencePageCard")

	p4_card.set_text_size_preset("normal")
	var p4_body_normal: int = (psc.steps_container.get_child(0).get_node("PrayerText") as Label).get_theme_font_size("font_size")
	var p4_title_normal: int = (psc.steps_container.get_child(0).get_node("PrayerTitle") as Label).get_theme_font_size("font_size")
	var p4_head_normal: int = psc.heading_label.get_theme_font_size("font_size")

	p4_card.set_text_size_preset("mobile")
	var p4_body_mobile: int = (psc.steps_container.get_child(0).get_node("PrayerText") as Label).get_theme_font_size("font_size")
	var p4_title_mobile: int = (psc.steps_container.get_child(0).get_node("PrayerTitle") as Label).get_theme_font_size("font_size")
	var p4_head_mobile: int = psc.heading_label.get_theme_font_size("font_size")

	p4_card.set_text_size_preset("extra_large")
	var p4_body_xl: int = (psc.steps_container.get_child(0).get_node("PrayerText") as Label).get_theme_font_size("font_size")
	var p4_title_xl: int = (psc.steps_container.get_child(0).get_node("PrayerTitle") as Label).get_theme_font_size("font_size")
	var p4_head_xl: int = psc.heading_label.get_theme_font_size("font_size")

	assert_true(p4_body_normal < p4_body_mobile and p4_body_mobile < p4_body_xl, "Page 4 body font size must strictly increase: %d < %d < %d" % [p4_body_normal, p4_body_mobile, p4_body_xl])
	assert_true(p4_title_normal < p4_title_mobile and p4_title_mobile < p4_title_xl, "Page 4 title font size must strictly increase: %d < %d < %d" % [p4_title_normal, p4_title_mobile, p4_title_xl])
	assert_true(p4_head_normal < p4_head_mobile and p4_head_mobile < p4_head_xl, "Page 4 heading font size must strictly increase: %d < %d < %d" % [p4_head_normal, p4_head_mobile, p4_head_xl])
	p4_card.free()

	# 2. MysteryPrayerPageCard (Page 6)
	var p6_card: PageCard = PageCardScene.instantiate() as PageCard
	test_root_window.add_child(p6_card)
	p6_card.bind_page_data(loader.get_page(6), loader)
	var mpc: MysteryPrayerPageCard = p6_card.get_sub_card() as MysteryPrayerPageCard
	assert_not_null(mpc, "Page 6 subcard must be MysteryPrayerPageCard")

	p6_card.set_text_size_preset("normal")
	var p6_scrip_normal: int = mpc.scripture_text_label.get_theme_font_size("font_size")
	var p6_cite_normal: int = mpc.scripture_citation_label.get_theme_font_size("font_size")
	var p6_fruit_normal: int = mpc.fruit_label.get_theme_font_size("font_size")

	p6_card.set_text_size_preset("mobile")
	var p6_scrip_mobile: int = mpc.scripture_text_label.get_theme_font_size("font_size")
	var p6_cite_mobile: int = mpc.scripture_citation_label.get_theme_font_size("font_size")
	var p6_fruit_mobile: int = mpc.fruit_label.get_theme_font_size("font_size")

	p6_card.set_text_size_preset("extra_large")
	var p6_scrip_xl: int = mpc.scripture_text_label.get_theme_font_size("font_size")
	var p6_cite_xl: int = mpc.scripture_citation_label.get_theme_font_size("font_size")
	var p6_fruit_xl: int = mpc.fruit_label.get_theme_font_size("font_size")

	assert_true(p6_scrip_normal < p6_scrip_mobile and p6_scrip_mobile < p6_scrip_xl, "Page 6 scripture font size must strictly increase: %d < %d < %d" % [p6_scrip_normal, p6_scrip_mobile, p6_scrip_xl])
	assert_true(p6_cite_normal < p6_cite_mobile and p6_cite_mobile < p6_cite_xl, "Page 6 citation font size must strictly increase: %d < %d < %d" % [p6_cite_normal, p6_cite_mobile, p6_cite_xl])
	assert_true(p6_fruit_normal < p6_fruit_mobile and p6_fruit_mobile < p6_fruit_xl, "Page 6 fruit badge font size must strictly increase: %d < %d < %d" % [p6_fruit_normal, p6_fruit_mobile, p6_fruit_xl])
	p6_card.free()

	# 3. FrontMatterPageCard (Page 2)
	var p2_card: PageCard = PageCardScene.instantiate() as PageCard
	test_root_window.add_child(p2_card)
	p2_card.bind_page_data(loader.get_page(2), loader)
	var fmc: FrontMatterPageCard = p2_card.get_sub_card() as FrontMatterPageCard
	assert_not_null(fmc, "Page 2 subcard must be FrontMatterPageCard")

	p2_card.set_text_size_preset("normal")
	var p2_body_normal: int = (fmc.sections_container.get_child(0).get_node("SectionBody") as Label).get_theme_font_size("font_size")
	var p2_title_normal: int = (fmc.sections_container.get_child(0).get_node("SectionTitle") as Label).get_theme_font_size("font_size")

	p2_card.set_text_size_preset("mobile")
	var p2_body_mobile: int = (fmc.sections_container.get_child(0).get_node("SectionBody") as Label).get_theme_font_size("font_size")
	var p2_title_mobile: int = (fmc.sections_container.get_child(0).get_node("SectionTitle") as Label).get_theme_font_size("font_size")

	p2_card.set_text_size_preset("extra_large")
	var p2_body_xl: int = (fmc.sections_container.get_child(0).get_node("SectionBody") as Label).get_theme_font_size("font_size")
	var p2_title_xl: int = (fmc.sections_container.get_child(0).get_node("SectionTitle") as Label).get_theme_font_size("font_size")

	assert_true(p2_body_normal < p2_body_mobile and p2_body_mobile < p2_body_xl, "Page 2 body font size must strictly increase: %d < %d < %d" % [p2_body_normal, p2_body_mobile, p2_body_xl])
	assert_true(p2_title_normal < p2_title_mobile and p2_title_mobile < p2_title_xl, "Page 2 title font size must strictly increase: %d < %d < %d" % [p2_title_normal, p2_title_mobile, p2_title_xl])
	p2_card.free()

	# 4. CreditsPageCard (Page 48)
	var p48_card: PageCard = PageCardScene.instantiate() as PageCard
	test_root_window.add_child(p48_card)
	p48_card.bind_page_data(loader.get_page(48), loader)
	var cpc: CreditsPageCard = p48_card.get_sub_card() as CreditsPageCard
	assert_not_null(cpc, "Page 48 subcard must be CreditsPageCard")

	p48_card.set_text_size_preset("normal")
	var p48_title_normal: int = (cpc.credits_container.get_child(0).get_node("Title") as Label).get_theme_font_size("font_size")
	var p48_details_normal: int = (cpc.credits_container.get_child(0).get_node("Details") as Label).get_theme_font_size("font_size")

	p48_card.set_text_size_preset("mobile")
	var p48_title_mobile: int = (cpc.credits_container.get_child(0).get_node("Title") as Label).get_theme_font_size("font_size")
	var p48_details_mobile: int = (cpc.credits_container.get_child(0).get_node("Details") as Label).get_theme_font_size("font_size")

	p48_card.set_text_size_preset("extra_large")
	var p48_title_xl: int = (cpc.credits_container.get_child(0).get_node("Title") as Label).get_theme_font_size("font_size")
	var p48_details_xl: int = (cpc.credits_container.get_child(0).get_node("Details") as Label).get_theme_font_size("font_size")

	assert_true(p48_title_normal < p48_title_mobile and p48_title_mobile < p48_title_xl, "Page 48 title font size must strictly increase: %d < %d < %d" % [p48_title_normal, p48_title_mobile, p48_title_xl])
	assert_true(p48_details_normal < p48_details_mobile and p48_details_mobile < p48_details_xl, "Page 48 details font size must strictly increase: %d < %d < %d" % [p48_details_normal, p48_details_mobile, p48_details_xl])
	p48_card.free()


func test_text_cards_dynamic_vertical_elongation() -> void:
	var loader: RosaryDataLoader = _get_loaded_loader()
	var test_pages: Array[int] = [2, 4, 6, 48]

	for p_num: int in test_pages:
		var card: PageCard = PageCardScene.instantiate() as PageCard
		test_root_window.add_child(card)
		card.bind_page_data(loader.get_page(p_num), loader)

		# 1. Normal preset: baseline dimensions (<= 1080px)
		card.set_text_size_preset("normal")
		assert_true(card.custom_minimum_size.y <= 1080.0, "Page %d normal height must be <= 1080.0, got %f" % [p_num, card.custom_minimum_size.y])
		assert_true(card.get_sub_card().custom_minimum_size.y <= 1080.0, "Page %d subcard normal height must be <= 1080.0" % p_num)

		# 2. Mobile preset: expands vertically > 1080px
		card.set_text_size_preset("mobile")
		var mobile_h: float = card.custom_minimum_size.y
		assert_true(mobile_h > 1080.0, "Page %d mobile height (%f) must exceed 1080px" % [p_num, mobile_h])
		assert_true(card.get_required_card_height() > 1080.0, "Page %d required height must exceed 1080px" % p_num)
		assert_true(card.get_sub_card().custom_minimum_size.y > 1080.0, "Page %d subcard mobile height must exceed 1080px" % p_num)
		assert_true(card.get_sub_card().get_required_card_height() > 1080.0, "Page %d subcard required height must exceed 1080px" % p_num)

		# 3. Extra Large preset: expands further beyond mobile height
		card.set_text_size_preset("extra_large")
		var xl_h: float = card.custom_minimum_size.y
		assert_true(xl_h > 1080.0, "Page %d extra_large height (%f) must exceed 1080px" % [p_num, xl_h])
		assert_true(xl_h > mobile_h, "Page %d extra_large height (%f) must exceed mobile height (%f)" % [p_num, xl_h, mobile_h])
		assert_true(card.get_required_card_height() > mobile_h, "Page %d extra_large required height must exceed mobile height" % p_num)
		assert_true(card.get_sub_card().custom_minimum_size.y > mobile_h, "Page %d subcard extra_large height must exceed mobile height" % p_num)
		assert_true(card.get_sub_card().get_required_card_height() > mobile_h, "Page %d subcard extra_large required height must exceed mobile height" % p_num)

		card.free()


func test_artwork_and_cover_cards_aspect_ratio_lock() -> void:
	var loader: RosaryDataLoader = _get_loaded_loader()
	var test_pages: Array[int] = [1, 5, 23, 50]
	var presets: Array[String] = ["normal", "mobile", "extra_large"]

	for p_num: int in test_pages:
		var card: PageCard = PageCardScene.instantiate() as PageCard
		test_root_window.add_child(card)
		card.bind_page_data(loader.get_page(p_num), loader)

		for preset: String in presets:
			card.set_text_size_preset(preset)
			assert_eq(card.custom_minimum_size, Vector2(720.0, 1080.0), "Page %d under preset '%s' must strictly preserve 720x1080 min size" % [p_num, preset])
			assert_true(abs(card.ratio - (2.0 / 3.0)) < 0.001, "Page %d under preset '%s' must strictly preserve 2:3 ratio lock" % [p_num, preset])
			assert_eq(card.get_sub_card().custom_minimum_size, Vector2(720.0, 1080.0), "Page %d subcard under preset '%s' must strictly preserve 720x1080 min size" % [p_num, preset])
			assert_true(abs(card.get_sub_card().ratio - (2.0 / 3.0)) < 0.001, "Page %d subcard under preset '%s' must strictly preserve 2:3 ratio lock" % [p_num, preset])

		card.free()


func test_all_fifty_pages_width_constraint_across_presets() -> void:
	var loader: RosaryDataLoader = _get_loaded_loader()
	var presets: Array[String] = ["normal", "mobile", "extra_large"]

	for p_num: int in range(1, 51):
		var p_data: Dictionary = loader.get_page(p_num)
		assert_false(p_data.is_empty(), "Page %d data must exist" % p_num)

		for preset: String in presets:
			var card: PageCard = PageCardScene.instantiate() as PageCard
			test_root_window.add_child(card)
			card.bind_page_data(p_data, loader)
			card.set_text_size_preset(preset)

			var card_min_w: float = card.get_combined_minimum_size().x
			assert_true(card_min_w <= 720.0, "Page %d under '%s' card combined_minimum_size.x (%f) must be <= 720.0" % [p_num, preset, card_min_w])
			assert_true(card.custom_minimum_size.x <= 720.0, "Page %d under '%s' card custom_minimum_size.x (%f) must be <= 720.0" % [p_num, preset, card.custom_minimum_size.x])

			var sub_card: BasePageCard = card.get_sub_card()
			if sub_card != null:
				var sub_min_w: float = sub_card.get_combined_minimum_size().x
				assert_true(sub_min_w <= 720.0, "Page %d under '%s' subcard combined_minimum_size.x (%f) must be <= 720.0" % [p_num, preset, sub_min_w])
				assert_true(sub_card.custom_minimum_size.x <= 720.0, "Page %d under '%s' subcard custom_minimum_size.x (%f) must be <= 720.0" % [p_num, preset, sub_card.custom_minimum_size.x])

				var card_panel: PanelContainer = sub_card.get_node_or_null("CardPanel") as PanelContainer
				if card_panel != null:
					var panel_min_w: float = card_panel.get_combined_minimum_size().x
					assert_true(panel_min_w <= 720.0, "Page %d under '%s' CardPanel combined_minimum_size.x (%f) must be <= 720.0" % [p_num, preset, panel_min_w])

				_assert_no_label_exceeds_content_width(sub_card, p_num, preset)

			card.free()


func _assert_no_label_exceeds_content_width(node: Node, page_num: int, preset: String) -> void:
	if node is Label:
		var lbl: Label = node as Label
		var is_in_scripture: bool = _is_inside_scripture_container(lbl)
		var max_allowed_w: float = 636.0 if is_in_scripture else 656.0
		var min_w: float = lbl.get_combined_minimum_size().x
		assert_true(min_w <= max_allowed_w, "Page %d '%s' label '%s' min_size.x (%f) must not exceed %f" % [page_num, preset, lbl.name, min_w, max_allowed_w])
	for child: Node in node.get_children():
		_assert_no_label_exceeds_content_width(child, page_num, preset)


static func _is_inside_scripture_container(node: Node) -> bool:
	var curr: Node = node.get_parent()
	while curr != null:
		if curr.name == "ScriptureContainer":
			return true
		curr = curr.get_parent()
	return false


func test_uniform_vertical_spacing_across_all_text_and_prayer_pages() -> void:
	var loader: RosaryDataLoader = _get_loaded_loader()
	var test_pages: Array[int] = [
		2, 3, # Front Matter (sections_container)
		4, # Opening Prayers sequence (steps_container)
		6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44, # 20 Mystery Prayer pages (decade_prayers_container)
		46, # Closing Prayers sequence (steps_container)
		48, 49, # Credits Part I & II (credits_container)
		50 # Back Cover (main_vbox)
	]
	assert_eq(test_pages.size(), 27, "Must test exactly 27 multi-item text and prayer pages")

	for p_num: int in test_pages:
		var page_data: Dictionary = loader.get_page(p_num)
		assert_false(page_data.is_empty(), "Page %d data must exist" % p_num)

		# 1. Test Normal Preset: Uniform spacing, no SIZE_EXPAND, height <= 1080.0
		var card: PageCard = PageCardScene.instantiate() as PageCard
		test_root_window.add_child(card)
		card.bind_page_data(page_data, loader)
		card.set_text_size_preset("normal")

		assert_true(card.custom_minimum_size.y <= 1080.0, "Page %d normal card height (%.1fpx) must be <= 1080.0" % [p_num, card.custom_minimum_size.y])
		assert_true(card.get_sub_card().custom_minimum_size.y <= 1080.0, "Page %d normal subcard height (%.1fpx) must be <= 1080.0" % [p_num, card.get_sub_card().custom_minimum_size.y])

		var sub_card: BasePageCard = card.get_sub_card()
		var multi_container: VBoxContainer = null
		var items: Array[Node] = []

		if sub_card is FrontMatterPageCard:
			var fmc: FrontMatterPageCard = sub_card as FrontMatterPageCard
			multi_container = fmc.sections_container
			items = multi_container.get_children()
		elif sub_card is PrayerSequencePageCard:
			var psc: PrayerSequencePageCard = sub_card as PrayerSequencePageCard
			multi_container = psc.steps_container
			items = multi_container.get_children()
		elif sub_card is MysteryPrayerPageCard:
			var mpc: MysteryPrayerPageCard = sub_card as MysteryPrayerPageCard
			multi_container = mpc.decade_prayers_container
			items = multi_container.get_children()
		elif sub_card is CreditsPageCard:
			var cpc: CreditsPageCard = sub_card as CreditsPageCard
			multi_container = cpc.credits_container
			items = multi_container.get_children()
		elif sub_card is BackCoverPageCard:
			var bcc: BackCoverPageCard = sub_card as BackCoverPageCard
			multi_container = bcc.main_vbox
			items = multi_container.get_children()

		assert_not_null(multi_container, "Page %d multi-item container must exist" % p_num)
		assert_true(items.size() >= 2, "Page %d must contain at least 2 child items, found %d" % [p_num, items.size()])

		# Verify SIZE_EXPAND is strictly stripped from all child item containers (Issue #43)
		for item: Node in items:
			var ctrl: Control = item as Control
			assert_not_null(ctrl, "Page %d child item '%s' must be a Control" % [p_num, item.name])
			assert_eq(ctrl.size_flags_vertical & Control.SIZE_EXPAND, 0, "Page %d child '%s' must not have vertical SIZE_EXPAND" % [p_num, item.name])
			assert_true(ctrl.get_combined_minimum_size().y > 0.0, "Page %d child '%s' natural height must be > 0" % [p_num, item.name])

		# Verify uniform separation theme constant on the container
		var sep: int = multi_container.get_theme_constant("separation")
		assert_true(sep >= 2, "Page %d container '%s' separation (%d) must be >= 2px" % [p_num, multi_container.name, sep])

		# In Godot BoxContainer, when children have no vertical expand flags, adjacent visual gap is identically the container separation
		var gaps: Array[float] = []
		for i: int in range(items.size() - 1):
			gaps.append(float(sep))

		var min_gap: float = gaps[0]
		var max_gap: float = gaps[0]
		for g: float in gaps:
			min_gap = minf(min_gap, g)
			max_gap = maxf(max_gap, g)
		assert_true(max_gap - min_gap <= 2.0, "Page %d visual gaps must be uniform (max_gap %.1f - min_gap %.1f <= 2.0px)" % [p_num, max_gap, min_gap])

		# 2. Test Scaled Presets: Mobile and Extra Large Elongation
		if p_num != 50:
			# Mobile preset
			card.set_text_size_preset("mobile")
			var mobile_h: float = card.custom_minimum_size.y
			assert_true(mobile_h > 1080.0, "Page %d mobile height (%.1fpx) must elongate > 1080.0px" % [p_num, mobile_h])
			assert_true(card.get_required_card_height() > 1080.0, "Page %d mobile required height must exceed 1080.0px" % p_num)

			# Extra large preset
			card.set_text_size_preset("extra_large")
			var xl_h: float = card.custom_minimum_size.y
			assert_true(xl_h > 1080.0, "Page %d extra_large height (%.1fpx) must elongate > 1080.0px" % [p_num, xl_h])
			assert_true(xl_h > mobile_h, "Page %d extra_large height (%.1fpx) must exceed mobile height (%.1fpx)" % [p_num, xl_h, mobile_h])
		else:
			# Page 50 Back Cover is aspect ratio locked to 720x1080
			card.set_text_size_preset("mobile")
			assert_eq(card.custom_minimum_size, Vector2(720.0, 1080.0), "Page 50 must preserve 720x1080 under mobile preset")
			card.set_text_size_preset("extra_large")
			assert_eq(card.custom_minimum_size, Vector2(720.0, 1080.0), "Page 50 must preserve 720x1080 under extra_large preset")

		card.free()

