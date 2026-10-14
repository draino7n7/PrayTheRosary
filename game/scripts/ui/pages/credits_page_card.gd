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

	if subheading_label != null:
		subheading_label.text = str(page_data.get("subheading", ""))
	if heading_label != null:
		heading_label.text = str(page_data.get("heading", ""))

	var artworks: Array = page_data.get("attributions", [])
	if artworks.is_empty():
		var aids: Array = page_data.get("attribution_ids", [])
		for aid: Variant in aids:
			var art_dict: Dictionary = {}
			if data_loader != null:
				art_dict = data_loader.get_artwork(str(aid))
			if not art_dict.is_empty():
				artworks.append(art_dict)

	if credits_container != null:
		for child: Node in credits_container.get_children():
			child.queue_free()

		var font_bold: FontFile = load("res://assets/fonts/EBGaramond-Bold.ttf") as FontFile
		var font_reg: FontFile = load("res://assets/fonts/EBGaramond-Regular.ttf") as FontFile

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
			title_lbl.add_theme_font_size_override("font_size", 16)
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
			details_lbl.add_theme_font_size_override("font_size", 14)
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
				scripture_notice_label.text = str(colophon.get("scripture_notice", ""))
				scripture_notice_label.add_theme_font_size_override("font_size", 13)
				scripture_notice_label.add_theme_constant_override("line_spacing", -1)
			if colophon_notice_label != null:
				colophon_notice_label.text = str(colophon.get("artwork_notice", ""))
				colophon_notice_label.add_theme_font_size_override("font_size", 13)
				colophon_notice_label.add_theme_constant_override("line_spacing", -1)

	configure_pass_through_mouse_filters(self)


func get_attribution_count() -> int:
	if credits_container != null:
		return credits_container.get_child_count()
	var arr: Array = page_data.get("attribution_ids", [])
	return arr.size()
