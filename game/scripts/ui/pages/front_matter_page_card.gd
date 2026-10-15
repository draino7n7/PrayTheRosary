class_name FrontMatterPageCard
extends BasePageCard
## Pages 2–3 Front-Matter Text Cards: History and Book Structure.

@onready var subheading_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/SubheadingLabel") as Label
@onready var heading_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/HeadingLabel") as Label
@onready var sections_container: VBoxContainer = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/SectionsContainer") as VBoxContainer


func _ready() -> void:
	if not page_data.is_empty():
		_apply_page_data()


func _apply_page_data() -> void:
	if subheading_label == null:
		subheading_label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/SubheadingLabel") as Label
	if heading_label == null:
		heading_label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/HeadingLabel") as Label
	if sections_container == null:
		sections_container = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/SectionsContainer") as VBoxContainer

	var heading_font_size: int = 34
	var subheading_font_size: int = 22
	match text_size_preset:
		PRESET_MOBILE:
			heading_font_size = 38
			subheading_font_size = 25
		PRESET_EXTRA_LARGE:
			heading_font_size = 44
			subheading_font_size = 29
		_:
			heading_font_size = 34
			subheading_font_size = 22

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

	if sections_container != null:
		for child: Node in sections_container.get_children():
			sections_container.remove_child(child)
			child.free()

		var sections: Array = page_data.get("sections", [])
		var font_bold: FontFile = load("res://assets/fonts/EBGaramond-Bold.ttf") as FontFile
		var font_italic: FontFile = load("res://assets/fonts/EBGaramond-Italic.ttf") as FontFile
		var font_reg: FontFile = load("res://assets/fonts/EBGaramond-Regular.ttf") as FontFile

		# Calibrate font size based on page text density (Page 2 vs Page 3)
		var total_chars: int = 0
		for sec_val: Variant in sections:
			if sec_val is Dictionary:
				total_chars += str((sec_val as Dictionary).get("body", "")).length()

		var body_font_size: int = 22 if total_chars <= 1650 else 20
		var title_font_size: int = body_font_size + 3

		match text_size_preset:
			PRESET_MOBILE:
				body_font_size = 30 if total_chars <= 1650 else 28
				title_font_size = body_font_size + 4
			PRESET_EXTRA_LARGE:
				body_font_size = 39 if total_chars <= 1650 else 37
				title_font_size = body_font_size + 5
			_:
				body_font_size = 22 if total_chars <= 1650 else 20
				title_font_size = body_font_size + 3

		var total_h: float = 64.0
		if font_italic != null:
			total_h += font_italic.get_multiline_string_size(sub_text, HORIZONTAL_ALIGNMENT_CENTER, 656.0, subheading_font_size).y + 6.0
		if font_bold != null:
			total_h += font_bold.get_multiline_string_size(head_text, HORIZONTAL_ALIGNMENT_CENTER, 656.0, heading_font_size).y + 6.0
		total_h += 2.0 + 20.0

		for sec_val: Variant in sections:
			if not (sec_val is Dictionary):
				continue
			var sec: Dictionary = sec_val
			var sec_vbox: VBoxContainer = VBoxContainer.new()
			sec_vbox.name = "Step_%s" % str(sec.get("title", "")).validate_node_name()
			sec_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			sec_vbox.add_theme_constant_override("separation", 6)

			var sec_title: String = str(sec.get("title", ""))
			var title_lbl: Label = Label.new()
			title_lbl.name = "SectionTitle"
			title_lbl.text = sec_title
			if font_bold != null:
				title_lbl.add_theme_font_override("font", font_bold)
			title_lbl.add_theme_font_size_override("font_size", title_font_size)
			title_lbl.add_theme_color_override("font_color", COLOR_CRIMSON)
			title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			sec_vbox.add_child(title_lbl)
			if font_bold != null:
				total_h += font_bold.get_multiline_string_size(sec_title, HORIZONTAL_ALIGNMENT_LEFT, 656.0, title_font_size).y + 6.0

			var body_lbl: Label = Label.new()
			body_lbl.name = "SectionBody"
			body_lbl.text = str(sec.get("body", ""))
			if font_reg != null:
				body_lbl.add_theme_font_override("font", font_reg)
			body_lbl.add_theme_font_size_override("font_size", body_font_size)
			body_lbl.add_theme_color_override("font_color", COLOR_CHARCOAL)
			body_lbl.add_theme_constant_override("line_spacing", 3)
			body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			sec_vbox.add_child(body_lbl)
			if font_reg != null:
				total_h += font_reg.get_multiline_string_size(str(sec.get("body", "")), HORIZONTAL_ALIGNMENT_LEFT, 656.0, body_font_size).y

			total_h += 16.0
			sections_container.add_child(sec_vbox)

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


func get_section_count() -> int:
	if sections_container != null:
		return sections_container.get_child_count()
	var arr: Array = page_data.get("sections", [])
	return arr.size()
