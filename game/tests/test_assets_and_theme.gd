extends "res://tests/test_base.gd"

const RosaryDataLoaderScript = preload("res://scripts/data/rosary_data_loader.gd")

const EXPECTED_ARCHIVAL_HASHES: Dictionary = {
	"closing_master_murillo_immaculate_conception.jpg": "bcfb26f5d16adb5067d0fcd8a07d1f3e71bad7bd479d1f829f27638732432a7e",
	"cover_master_murillo.jpg": "a637fd7c31f5bbc97206673130c281eb2035d67798e67a8baccf224336318dfd",
	"glorious_1_resurrection_master_murillo.jpg": "6e773bce4ecc42f0ce32c1eceb9e8f5aa56ab1e30cec1a06c4fba38508a20e46",
	"glorious_2_ascension_master_copley.jpg": "0fb337b5b118edb15db03298cb6505566a99d3b85cb4cf134937f284241843f4",
	"glorious_3_pentecost_master_maino.jpg": "82fa55ea08b3cd2953866a2e9504d2419166d2cb599a499001f5be896702369e",
	"glorious_4_assumption_master_murillo.jpg": "c7a67d789182d4ba449e1c1d39d159370f53efa4c57bd58b9389b953d4afc4eb",
	"glorious_5_coronation_master_velazquez.jpg": "3b5e9f035a49165d8d9126e2d8a7a8338fb4cbc7e031a69b4b18b56992d33230",
	"joyful_1_annunciation_master_murillo.jpg": "f19a4b835d2ebdf0e11f4297ca7081c5bf03d77fcef80f443fc4362c501ae443",
	"joyful_2_visitation_master_champaigne.jpg": "89089ce72b82257f9f6aa1c589bcd2945b140f7a5a6cb8d6b797b4890a0521d8",
	"joyful_3_nativity_master_guido_reni.jpg": "05aec460abd127c0682b92af92f7f5108c5f2ea41c0811f1d8d055bc9cc5ceae",
	"joyful_4_presentation_master_carpaccio.jpg": "4a6107b01ff2424d54e220585d59f7d675a7de05c1758e2055da2b58dbe7cceb",
	"joyful_5_finding_in_temple_master_van_orley.jpg": "536da42385638b1db8b0f6d397254a0ce042a61db19fb67bd2e51ecbd0d3db49",
	"luminous_1_baptism_master_guido_reni.jpg": "122d7b0fe080f620720d150d8a8f0d917a141b1f438717bddba372889079eab5",
	"luminous_2_wedding_at_cana_master_ricci.jpg": "b3635b765636a00780c6ccf519ad9698fef14ee49d1e0b5a4898b9949ee4f184",
	"luminous_3_proclamation_master_carl_bloch.jpg": "6d6a88f9eaaae70e9b529c976d72ff8ad22530d993ec0f984146056253ecc96c",
	"luminous_4_transfiguration_master_gerard_david.jpg": "ba029cf83d67c13fb0105b8c654a2157ef10abfbe8150c67c580ac29ee1a395c",
	"luminous_5_eucharist_master_rubens.jpg": "029146882c185563b29b7969f414e347b9793f5fece4845bd2300cb167df7f7b",
	"opening_master_el_greco_trinity.jpg": "c01e6f07077bba0752f5fd149a64d7f9366786db87fddb4b81919b55110e338d",
	"sorrowful_1_agony_master_caracciolo.jpg": "052fdefc2a48531f318290d4cb1680087bc07e2a98cca09962f3353312bf0332",
	"sorrowful_2_scourging_master_rubens.jpg": "2b902ef87b5331204a304d5a309111f767439aae45e6f43493266ba8ef03f761",
	"sorrowful_3_crowning_with_thorns_master_van_dyck.jpg": "e18deb35649a8a83d6a1dc3ca3f9175ad09e717527858fa516cf5412dafb4d3f",
	"sorrowful_4_carrying_cross_master_raphael.jpg": "d2827eb1e3fb132f24ae859b38e2cd91d37ec8552649b32f6ba72b6ba90d8cc3",
	"sorrowful_5_crucifixion_master_murillo.jpg": "d058f9b8e35f73b6d9f28a19e49e26e5d8ce714f3c25681541e07d36d7d500fe"
}


func test_runtime_webp_textures_exist_and_load() -> void:
	var loader: RefCounted = RosaryDataLoaderScript.new()
	assert_true(loader.load_all(), "RosaryDataLoader must load successfully")

	var runtime_paths: Array[String] = []

	var cover_path: String = str(loader.get_front_cover().get("artwork", {}).get("runtime_texture_path", ""))
	runtime_paths.append(cover_path)

	var opening_path: String = str(loader.get_spread(2).get("right_page", {}).get("artwork", {}).get("runtime_texture_path", ""))
	runtime_paths.append(opening_path)

	var closing_path: String = str(loader.get_spread(23).get("right_page", {}).get("artwork", {}).get("runtime_texture_path", ""))
	runtime_paths.append(closing_path)

	for sp_num: int in range(3, 23):
		var sp: Dictionary = loader.get_hydrated_spread(sp_num)
		var m_path: String = str(sp.get("mystery", {}).get("artwork", {}).get("runtime_texture_path", ""))
		runtime_paths.append(m_path)

	assert_eq(runtime_paths.size(), 23, "Must collect exactly 23 runtime texture paths")

	for path: String in runtime_paths:
		assert_true(path.begins_with("res://assets/images/"), "Runtime texture path '%s' must reside in res://assets/images/" % path)
		assert_true(path.ends_with(".webp"), "Runtime texture '%s' must be .webp format" % path)
		assert_true(FileAccess.file_exists(path), "Runtime texture file must exist: %s" % path)

		var texture: Texture2D = load(path) as Texture2D
		assert_not_null(texture, "Runtime texture must load cleanly as Texture2D: %s" % path)
		if texture != null:
			var width: float = texture.get_width()
			var height: float = texture.get_height()
			assert_true(width > 0.0, "Texture width must be greater than 0: %s" % path)
			assert_true(height > 0.0, "Texture height must be greater than 0: %s" % path)
			assert_true(height <= 1800.0, "Texture height must not exceed 1800px: %s (got %f)" % [path, height])


func test_bundled_serif_fonts_exist_and_load() -> void:
	assert_true(FileAccess.file_exists("res://assets/fonts/OFL.txt"), "Font license OFL.txt must exist in res://assets/fonts/")

	var required_weights: Array[String] = [
		"res://assets/fonts/EBGaramond-Regular.ttf",
		"res://assets/fonts/EBGaramond-Bold.ttf",
		"res://assets/fonts/EBGaramond-Italic.ttf",
		"res://assets/fonts/EBGaramond-BoldItalic.ttf"
	]

	for font_path: String in required_weights:
		assert_true(FileAccess.file_exists(font_path), "Font weight file must exist: %s" % font_path)
		var font: FontFile = load(font_path) as FontFile
		assert_not_null(font, "Font file must load cleanly as FontFile: %s" % font_path)


func test_bundled_symbol_fallback_font_and_glyph_coverage() -> void:
	var font_path: String = "res://assets/fonts/NotoSansSymbols-Regular.ttf"
	assert_true(FileAccess.file_exists(font_path), "Symbol font file must exist on disk: %s" % font_path)
	assert_true(ResourceLoader.exists(font_path), "Symbol font resource must exist: %s" % font_path)

	var font: FontFile = load(font_path) as FontFile
	assert_not_null(font, "NotoSansSymbols-Regular must load cleanly as a valid FontFile")
	if font == null:
		return

	# Assert glyph coverage for all 5 required Unicode symbols:
	assert_true(font.has_char(0x2630), "NotoSansSymbols must support ☰ (U+2630 Trigram for Heaven)")
	assert_true(font.has_char(0x2715), "NotoSansSymbols must support ✕ (U+2715 Multiplication X)")
	assert_true(font.has_char(0x25B8), "NotoSansSymbols must support ▸ (U+25B8 Black Right-Pointing Small Triangle)")
	assert_true(font.has_char(0x25BE), "NotoSansSymbols must support ▾ (U+25BE Black Down-Pointing Small Triangle)")
	assert_true(font.has_char(0x2605), "NotoSansSymbols must support ★ (U+2605 Black Star)")


func test_rosary_theme_font_fallbacks() -> void:
	var theme_paths: Array[String] = [
		"res://resources/rosary_theme.tres",
		"res://assets/themes/rosary_theme.tres"
	]
	var symbol_font_path: String = "res://assets/fonts/NotoSansSymbols-Regular.ttf"
	var expected_symbol_font: Font = load(symbol_font_path) as Font
	assert_not_null(expected_symbol_font, "Symbol fallback font must load cleanly")

	for t_path: String in theme_paths:
		assert_true(FileAccess.file_exists(t_path), "Theme file must exist: %s" % t_path)
		var theme: Theme = load(t_path) as Theme
		assert_not_null(theme, "Theme must load cleanly: %s" % t_path)
		if theme == null:
			continue

		var fonts_to_check: Array[Dictionary] = [
			{"name": "default_font", "font": theme.default_font},
			{"name": "Button.font", "font": theme.get_font("font", "Button")},
			{"name": "Label.font", "font": theme.get_font("font", "Label")},
			{"name": "RichTextLabel.normal_font", "font": theme.get_font("normal_font", "RichTextLabel")},
			{"name": "RichTextLabel.bold_font", "font": theme.get_font("bold_font", "RichTextLabel")},
			{"name": "RichTextLabel.italics_font", "font": theme.get_font("italics_font", "RichTextLabel")},
			{"name": "RichTextLabel.bold_italics_font", "font": theme.get_font("bold_italics_font", "RichTextLabel")}
		]

		for item: Dictionary in fonts_to_check:
			var font_item: Font = item.get("font") as Font
			var font_name: String = str(item.get("name", ""))
			assert_not_null(font_item, "Theme %s must have %s configured" % [t_path, font_name])
			if font_item == null:
				continue

			var fallbacks: Array[Font] = font_item.fallbacks
			assert_true(fallbacks.size() > 0, "Theme %s font %s must have fallbacks defined" % [t_path, font_name])
			var has_symbols_fallback: bool = false
			for fb: Font in fallbacks:
				if fb != null and (fb == expected_symbol_font or fb.resource_path == symbol_font_path):
					has_symbols_fallback = true
					break
			assert_true(has_symbols_fallback, "Theme %s font %s fallbacks must contain NotoSansSymbols-Regular.ttf" % [t_path, font_name])

			# Verify glyph coverage through the fallback
			assert_true(font_item.has_char(0x2630), "%s (%s) must resolve ☰ (U+2630) via fallback" % [font_name, t_path])
			assert_true(font_item.has_char(0x2715), "%s (%s) must resolve ✕ (U+2715) via fallback" % [font_name, t_path])
			assert_true(font_item.has_char(0x25B8), "%s (%s) must resolve ▸ (U+25B8) via fallback" % [font_name, t_path])
			assert_true(font_item.has_char(0x25BE), "%s (%s) must resolve ▾ (U+25BE) via fallback" % [font_name, t_path])
			assert_true(font_item.has_char(0x2605), "%s (%s) must resolve ★ (U+2605) via fallback" % [font_name, t_path])


func test_rosary_theme_resource() -> void:
	var theme_paths: Array[String] = [
		"res://resources/rosary_theme.tres",
		"res://assets/themes/rosary_theme.tres"
	]

	for t_path: String in theme_paths:
		assert_true(FileAccess.file_exists(t_path), "Theme file must exist: %s" % t_path)
		var theme: Theme = load(t_path) as Theme
		assert_not_null(theme, "Theme resource must load cleanly: %s" % t_path)
		if theme == null:
			continue

		# Default Font & Size
		assert_not_null(theme.default_font, "Theme default_font must be set")
		assert_eq(theme.default_font_size, 20, "Theme default_font_size should be 20")

		# Palette verification on RosaryPalette
		var parchment: Color = theme.get_color("parchment", "RosaryPalette")
		assert_eq(parchment.to_html(false).to_upper(), "FAF6EE", "Parchment color must match #FAF6EE")

		var charcoal: Color = theme.get_color("charcoal", "RosaryPalette")
		assert_eq(charcoal.to_html(false).to_upper(), "1E1815", "Charcoal color must match #1E1815")

		var crimson: Color = theme.get_color("crimson", "RosaryPalette")
		assert_eq(crimson.to_html(false).to_upper(), "6B1D21", "Crimson color must match #6B1D21")

		var umber: Color = theme.get_color("umber", "RosaryPalette")
		assert_eq(umber.to_html(false).to_upper(), "5C4338", "Umber color must match #5C4338")

		var gold: Color = theme.get_color("gold", "RosaryPalette")
		assert_eq(gold.to_html(false).to_upper(), "B89130", "Gold border color must match #B89130")

		var ambient: Color = theme.get_color("ambient_espresso", "RosaryPalette")
		assert_eq(ambient.to_html(false).to_upper(), "141010", "Ambient espresso color must match #141010")

		var cover_crimson: Color = theme.get_color("cover_crimson", "RosaryPalette")
		assert_eq(cover_crimson.to_html(false).to_upper(), "4A1215", "Cover crimson color must match #4A1215")

		var warm_gold: Color = theme.get_color("warm_gold", "RosaryPalette")
		assert_eq(warm_gold.to_html(false).to_upper(), "D4AF37", "Warm gold accent must match #D4AF37")

		var ivory: Color = theme.get_color("ivory_text", "RosaryPalette")
		assert_eq(ivory.to_html(false).to_upper(), "F7F2E7", "Ivory text color must match #F7F2E7")

		# Label Overrides
		assert_true(theme.has_color("font_color", "Label"), "Label font_color must be defined")
		assert_true(theme.has_color("heading_color", "Label"), "Label heading_color must be defined")
		assert_true(theme.has_color("subheading_color", "Label"), "Label subheading_color must be defined")

		# RichTextLabel Overrides
		assert_true(theme.has_font("normal_font", "RichTextLabel"), "RichTextLabel normal_font must be set")
		assert_true(theme.has_font("bold_font", "RichTextLabel"), "RichTextLabel bold_font must be set")
		assert_true(theme.has_font("italics_font", "RichTextLabel"), "RichTextLabel italics_font must be set")

		# Button Visual States
		var btn_states: Array[String] = ["normal", "hover", "pressed", "focus", "disabled"]
		for state: String in btn_states:
			assert_true(theme.has_stylebox(state, "Button"), "Button must define stylebox for state '%s'" % state)
			var sb: StyleBox = theme.get_stylebox(state, "Button")
			assert_true(sb is StyleBoxFlat, "Button '%s' stylebox must be a StyleBoxFlat" % state)

		# PanelContainer Stylebox
		assert_true(theme.has_stylebox("panel", "PanelContainer"), "PanelContainer panel stylebox must be defined")
		var p_sb: StyleBox = theme.get_stylebox("panel", "PanelContainer")
		assert_true(p_sb is StyleBoxFlat, "PanelContainer panel stylebox must be StyleBoxFlat")

		# ScrollContainer Stylebox
		assert_true(theme.has_stylebox("panel", "ScrollContainer"), "ScrollContainer panel stylebox must be defined")
		var s_sb: StyleBox = theme.get_stylebox("panel", "ScrollContainer")
		assert_true(s_sb is StyleBoxEmpty, "ScrollContainer panel stylebox must be StyleBoxEmpty")


func test_archival_master_files_remain_untouched() -> void:
	var repo_root: String = ProjectSettings.globalize_path("res://..").simplify_path()
	var original_dir: String = repo_root.path_join("assets/2D/gimp/original_downloads")

	assert_true(DirAccess.dir_exists_absolute(original_dir), "Archival downloads directory must exist: %s" % original_dir)

	for file_name: String in EXPECTED_ARCHIVAL_HASHES.keys():
		var full_path: String = original_dir.path_join(file_name)
		assert_true(FileAccess.file_exists(full_path), "Master artwork file must exist: %s" % file_name)

		var fa: FileAccess = FileAccess.open(full_path, FileAccess.READ)
		assert_not_null(fa, "Master file must be readable: %s" % file_name)
		if fa != null:
			var buffer: PackedByteArray = fa.get_buffer(fa.get_length())
			fa.close()
			var ctx: HashingContext = HashingContext.new()
			ctx.start(HashingContext.HASH_SHA256)
			ctx.update(buffer)
			var computed_hash: String = ctx.finish().hex_encode().to_lower()
			var expected_hash: String = str(EXPECTED_ARCHIVAL_HASHES[file_name]).to_lower()
			assert_eq(computed_hash, expected_hash, "Archival file %s SHA-256 hash must remain byte-for-byte identical" % file_name)
