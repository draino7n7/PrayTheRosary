class_name CreditsPageCard
extends BasePageCard
## Pages 48–49 Sacred Artwork Credits & Colophon.

@onready var subheading_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/SubheadingLabel") as Label
@onready var heading_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/HeadingLabel") as Label
@onready var credits_container: VBoxContainer = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/CreditsContainer") as VBoxContainer
@onready var colophon_container: VBoxContainer = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ColophonContainer") as VBoxContainer
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
	var font_italic: FontFile = load("res://assets/fonts/EBGaramond-Italic.ttf") as FontFile
	var font_reg: FontFile = load("res://assets/fonts/EBGaramond-Regular.ttf") as FontFile

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
			art_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			art_vbox.add_theme_constant_override("separation", 0)

			var title_lbl: Label = Label.new()
			title_lbl.name = "Title"
			var section_label: String = str(art.get("section_label", "")).strip_edges()
			var art_title: String = str(art.get("title", "")).strip_edges()
			if section_label != "" and art_title != "":
				title_lbl.text = "%s — %s" % [section_label, art_title]
			elif section_label != "":
				title_lbl.text = section_label
			else:
				title_lbl.text = art_title
			if font_bold != null:
				title_lbl.add_theme_font_override("font", font_bold)
			title_lbl.add_theme_font_size_override("font_size", title_font_size)
			title_lbl.add_theme_color_override("font_color", COLOR_CRIMSON)
			title_lbl.add_theme_constant_override("line_spacing", -1)
			title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			art_vbox.add_child(title_lbl)

			var details: String = "%s (%s), %s • %s • %s" % [
				str(art.get("artist", "")),
				str(art.get("artist_dates", "")),
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

			credits_container.add_child(art_vbox)

	var colophon: Dictionary = page_data.get("colophon", {})
	if colophon_container != null:
		if colophon.is_empty():
			colophon_container.visible = false
		else:
			colophon_container.visible = true
			if scripture_notice_label != null:
				scripture_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				scripture_notice_label.text = str(colophon.get("scripture_notice", ""))
				scripture_notice_label.add_theme_font_size_override("font_size", notice_font_size)
				scripture_notice_label.add_theme_constant_override("line_spacing", -1)
			if colophon_notice_label != null:
				colophon_notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				colophon_notice_label.text = str(colophon.get("artwork_notice", ""))
				colophon_notice_label.add_theme_font_size_override("font_size", notice_font_size)
				colophon_notice_label.add_theme_constant_override("line_spacing", -1)

	var total_h: float = 44.0
	if font_italic != null:
		total_h += font_italic.get_multiline_string_size(sub_text, HORIZONTAL_ALIGNMENT_CENTER, 656.0, subheading_font_size).y + 2.0
	if font_bold != null:
		total_h += font_bold.get_multiline_string_size(head_text, HORIZONTAL_ALIGNMENT_CENTER, 656.0, heading_font_size).y + 2.0
	total_h += 2.0 + 6.0

	for art_val: Variant in artworks:
		if not (art_val is Dictionary):
			continue
		var art: Dictionary = art_val
		var sec_label: String = str(art.get("section_label", "")).strip_edges()
		var art_title: String = str(art.get("title", "")).strip_edges()
		var combined_title: String = "%s — %s" % [sec_label, art_title] if (sec_label != "" and art_title != "") else art_title
		if font_bold != null:
			total_h += font_bold.get_multiline_string_size(combined_title, HORIZONTAL_ALIGNMENT_LEFT, 656.0, title_font_size).y
		var details: String = "%s (%s), %s • %s • %s" % [
			str(art.get("artist", "")),
			str(art.get("artist_dates", "")),
			str(art.get("creation_date", "")),
			str(art.get("medium", "")),
			str(art.get("current_location", ""))
		]
		if font_reg != null:
			total_h += font_reg.get_multiline_string_size(details, HORIZONTAL_ALIGNMENT_LEFT, 656.0, details_font_size).y + 3.0

	if not colophon.is_empty():
		total_h += 6.0 + 1.0 + 3.0
		if font_italic != null:
			total_h += font_italic.get_multiline_string_size(str(colophon.get("scripture_notice", "")), HORIZONTAL_ALIGNMENT_LEFT, 656.0, notice_font_size).y + 3.0
		if font_reg != null:
			total_h += font_reg.get_multiline_string_size(str(colophon.get("artwork_notice", "")), HORIZONTAL_ALIGNMENT_LEFT, 656.0, notice_font_size).y

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
