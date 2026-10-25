class_name CreditsPageCard
extends BasePageCard
## Pages 48–49 Sacred Artwork Credits & Colophon.

@onready var subheading_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/SubheadingLabel") as Label
@onready var heading_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/HeadingLabel") as Label
@onready var credits_container: VBoxContainer = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/CreditsContainer") as VBoxContainer
@onready var colophon_container: VBoxContainer = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ColophonContainer") as VBoxContainer
@onready var creator_notice_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ColophonContainer/CreatorNoticeLabel") as Label
@onready var version_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ColophonContainer/VersionNoticeLabel") as Label
@onready var version_notice_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ColophonContainer/VersionNoticeLabel") as Label
@onready var scripture_notice_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ColophonContainer/ScriptureNoticeLabel") as Label
@onready var colophon_notice_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ColophonContainer/ColophonNoticeLabel") as Label


func _ready() -> void:
	if not page_data.is_empty():
		_apply_page_data()


func _apply_page_data() -> void:
	if subheading_label == null:
		subheading_label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/SubheadingLabel") as Label
	if heading_label == null:
		heading_label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/HeadingLabel") as Label
	if credits_container == null:
		credits_container = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/CreditsContainer") as VBoxContainer
	if colophon_container == null:
		colophon_container = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ColophonContainer") as VBoxContainer
	if creator_notice_label == null:
		creator_notice_label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ColophonContainer/CreatorNoticeLabel") as Label
	if version_label == null:
		version_label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ColophonContainer/VersionNoticeLabel") as Label
	if version_notice_label == null:
		version_notice_label = version_label
	if scripture_notice_label == null:
		scripture_notice_label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ColophonContainer/ScriptureNoticeLabel") as Label
	if colophon_notice_label == null:
		colophon_notice_label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ColophonContainer/ColophonNoticeLabel") as Label

	var heading_font_size: int = 34
	var subheading_font_size: int = 22
	var title_font_size: int = 16
	var details_font_size: int = 14
	var notice_font_size: int = 13

	match text_size_preset:
		PRESET_MOBILE:
			heading_font_size = 38
			subheading_font_size = 25
			title_font_size = 22
			details_font_size = 19
			notice_font_size = 18
		PRESET_EXTRA_LARGE:
			heading_font_size = 44
			subheading_font_size = 29
			title_font_size = 28
			details_font_size = 25
			notice_font_size = 23
		_:
			heading_font_size = 34
			subheading_font_size = 22
			title_font_size = 16
			details_font_size = 14
			notice_font_size = 13

	var sub_text: String = str(page_data.get("subheading", ""))
	if subheading_label != null:
		subheading_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		subheading_label.text = sub_text
		subheading_label.add_theme_font_size_override("font_size", subheading_font_size)
	var head_text: String = str(page_data.get("heading", ""))
	if heading_label != null:
		heading_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		heading_label.text = head_text
		heading_label.add_theme_font_size_override("font_size", heading_font_size)

	var artworks: Array = []
	var raw_arts: Variant = page_data.get("attributions", [])
	if raw_arts is Array and not (raw_arts as Array).is_empty():
		artworks = (raw_arts as Array).duplicate()
	else:
		var aids: Array = page_data.get("attribution_ids", [])
		for aid: Variant in aids:
			var art_dict: Dictionary = {}
			if data_loader != null:
				art_dict = data_loader.get_artwork(str(aid))
			if not art_dict.is_empty():
				artworks.append(art_dict)

	var font_bold: FontFile = load("res://assets/fonts/EBGaramond-Bold.ttf") as FontFile
	var font_reg: FontFile = load("res://assets/fonts/EBGaramond-Regular.ttf") as FontFile

	var sum_art_heights: float = 0.0
	if credits_container != null:
		for child: Node in credits_container.get_children():
			credits_container.remove_child(child)
			child.free()

		for art_val: Variant in artworks:
			if not (art_val is Dictionary):
				continue
			var art: Dictionary = art_val
			var art_vbox: VBoxContainer = VBoxContainer.new()
			art_vbox.name = "Attribution_%s" % str(art.get("id", ""))
			art_vbox.size_flags_vertical = Control.SIZE_FILL
			art_vbox.add_theme_constant_override("separation", 0)

			var title_lbl: Label = Label.new()
			title_lbl.name = "Title"
			var section_label: String = str(art.get("section_label", "")).strip_edges()
			var art_title: String = str(art.get("title", "")).strip_edges()
			var display_section: String = section_label
			if display_section.contains(" Mystery ("):
				var paren_start: int = display_section.find(" (")
				if paren_start != -1:
					display_section = display_section.substr(0, paren_start)
			if display_section != "" and art_title != "":
				title_lbl.text = "%s — %s" % [display_section, art_title]
			elif display_section != "":
				title_lbl.text = display_section
			else:
				title_lbl.text = art_title
			if font_bold != null:
				title_lbl.add_theme_font_override("font", font_bold)
			title_lbl.add_theme_font_size_override("font_size", title_font_size)
			title_lbl.add_theme_color_override("font_color", COLOR_CRIMSON)
			title_lbl.add_theme_constant_override("line_spacing", -1)
			title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			art_vbox.add_child(title_lbl)
			var title_h: float = 0.0
			if font_bold != null:
				var t_lines: int = int(ceilf(font_bold.get_multiline_string_size(title_lbl.text, HORIZONTAL_ALIGNMENT_LEFT, 656.0, title_font_size).y / float(font_bold.get_height(title_font_size))))
				title_h = font_bold.get_multiline_string_size(title_lbl.text, HORIZONTAL_ALIGNMENT_LEFT, 656.0, title_font_size).y - float(maxi(0, t_lines - 1))

			var raw_artist: String = str(art.get("artist", "")).strip_edges()
			var artist_dates: String = str(art.get("artist_dates", "")).strip_edges()
			var artist_str: String = raw_artist
			if artist_dates != "":
				if raw_artist.ends_with(")"):
					artist_str = raw_artist.substr(0, raw_artist.length() - 1) + ", " + artist_dates + ")"
				else:
					artist_str = "%s (%s)" % [raw_artist, artist_dates]
			var details: String = "%s, %s • %s • %s" % [
				artist_str,
				str(art.get("creation_date", "")),
				str(art.get("medium", "")),
				str(art.get("current_location", ""))
			]
			var details_lbl: Label = Label.new()
			details_lbl.name = "Details"
			details_lbl.text = details
			if font_reg != null:
				details_lbl.add_theme_font_override("font", font_reg)
			details_lbl.add_theme_font_size_override("font_size", details_font_size)
			details_lbl.add_theme_color_override("font_color", COLOR_CHARCOAL)
			details_lbl.add_theme_constant_override("line_spacing", -1)
			details_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			art_vbox.add_child(details_lbl)
			var details_h: float = 0.0
			if font_reg != null:
				var d_lines: int = int(ceilf(font_reg.get_multiline_string_size(details, HORIZONTAL_ALIGNMENT_LEFT, 656.0, details_font_size).y / float(font_reg.get_height(details_font_size))))
				details_h = font_reg.get_multiline_string_size(details, HORIZONTAL_ALIGNMENT_LEFT, 656.0, details_font_size).y - float(maxi(0, d_lines - 1))

			sum_art_heights += title_h + details_h
			credits_container.add_child(art_vbox)

	var colophon: Dictionary = page_data.get("colophon", {})
	var creator_text: String = str(colophon.get("creator_notice", "")).strip_edges()
	var show_version: bool = bool(colophon.get("show_version", false))
	var version_text: String = ""
	if show_version:
		var app_version: String = str(ProjectSettings.get_setting("application/config/version", "1.0.0"))
		version_text = "Version %s" % app_version
	var sn_text: String = str(colophon.get("scripture_notice", "")).strip_edges()
	var cn_text: String = str(colophon.get("artwork_notice", "")).strip_edges()

	var has_colophon_content: bool = not colophon.is_empty() and (creator_text != "" or version_text != "" or sn_text != "" or cn_text != "")
	var colophon_h: float = 0.0

	if colophon_container != null:
		if not has_colophon_content:
			colophon_container.visible = false
			if creator_notice_label != null:
				creator_notice_label.visible = false
				creator_notice_label.text = ""
			if version_label != null:
				version_label.visible = false
				version_label.text = ""
			if scripture_notice_label != null:
				scripture_notice_label.visible = false
				scripture_notice_label.text = ""
			if colophon_notice_label != null:
				colophon_notice_label.visible = false
				colophon_notice_label.text = ""
		else:
			colophon_container.visible = true
			colophon_h += 1.0 # Divider height

			var notice_items: Array[Dictionary] = [
				{"label": creator_notice_label, "text": creator_text},
				{"label": version_label, "text": version_text},
				{"label": scripture_notice_label, "text": sn_text},
				{"label": colophon_notice_label, "text": cn_text}
			]

			for item: Dictionary in notice_items:
				var lbl: Label = item["label"] as Label
				var txt: String = item["text"] as String
				if lbl == null:
					continue
				if txt.is_empty():
					lbl.visible = false
					lbl.text = ""
				else:
					lbl.visible = true
					lbl.text = txt
					lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					if font_reg != null:
						lbl.add_theme_font_override("font", font_reg)
					lbl.add_theme_font_size_override("font_size", notice_font_size)
					lbl.add_theme_color_override("font_color", COLOR_UMBER)
					lbl.add_theme_constant_override("line_spacing", -1)

					colophon_h += 3.0 # Separation before notice
					if font_reg != null:
						var n_lines: int = int(ceilf(font_reg.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, 656.0, notice_font_size).y / float(font_reg.get_height(notice_font_size))))
						colophon_h += font_reg.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, 656.0, notice_font_size).y - float(maxi(0, n_lines - 1))

	var header_h: float = 0.0
	if font_reg != null:
		header_h += font_reg.get_multiline_string_size(sub_text, HORIZONTAL_ALIGNMENT_CENTER, 656.0, subheading_font_size).y + 2.0
	if font_bold != null:
		header_h += font_bold.get_multiline_string_size(head_text, HORIZONTAL_ALIGNMENT_CENTER, 656.0, heading_font_size).y + 2.0
	header_h += 2.0 # Divider
	header_h += 4.0 # HeaderVBox separations

	var num_art: int = artworks.size()
	var num_art_gaps: int = maxi(1, num_art - 1)
	var applied_cred_sep: int = 3
	if text_size_preset == PRESET_NORMAL:
		var avail_cred: float = 1036.0 - header_h - 6.0
		if has_colophon_content:
			avail_cred -= (colophon_h + 6.0)
		var leftover_cred: float = avail_cred - sum_art_heights
		applied_cred_sep = int(floor(leftover_cred / float(num_art_gaps)))
		applied_cred_sep = maxi(applied_cred_sep, 2)
	else:
		applied_cred_sep = 8 if text_size_preset == PRESET_MOBILE else 10

	if credits_container != null:
		credits_container.add_theme_constant_override("separation", applied_cred_sep)

	var total_h: float = 44.0 + header_h + 6.0 + sum_art_heights + float(num_art_gaps * applied_cred_sep)
	if has_colophon_content:
		total_h += 6.0 + colophon_h

	var final_height: float = DESIGN_HEIGHT
	if text_size_preset != PRESET_NORMAL:
		final_height = maxf(1081.0, ceilf(total_h + 30.0))

	custom_minimum_size = Vector2(DESIGN_WIDTH, final_height)
	ratio = DESIGN_WIDTH / final_height
	var card_panel: PanelContainer = get_node_or_null("CardPanel") as PanelContainer
	if card_panel != null:
		card_panel.custom_minimum_size = Vector2(DESIGN_WIDTH, final_height)

	var p: Node = get_parent()
	if p != null and p is PageCard:
		(p as PageCard)._sync_with_sub_card()

	configure_pass_through_mouse_filters(self)


func _apply_text_size_preset() -> void:
	if not page_data.is_empty():
		_apply_page_data()


func get_attribution_count() -> int:
	if credits_container != null:
		return credits_container.get_child_count()
	var arr: Array = page_data.get("attribution_ids", [])
	return arr.size()
