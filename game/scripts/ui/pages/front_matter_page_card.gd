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

	if subheading_label != null:
		subheading_label.text = str(page_data.get("subheading", ""))
	if heading_label != null:
		heading_label.text = str(page_data.get("heading", ""))

	if sections_container != null:
		for child: Node in sections_container.get_children():
			child.queue_free()

		var sections: Array = page_data.get("sections", [])
		var font_bold: FontFile = load("res://assets/fonts/EBGaramond-Bold.ttf") as FontFile
		var font_reg: FontFile = load("res://assets/fonts/EBGaramond-Regular.ttf") as FontFile

		# Calibrate font size based on page text density (Page 2 vs Page 3)
		var total_chars: int = 0
		for sec_val: Variant in sections:
			if sec_val is Dictionary:
				total_chars += str((sec_val as Dictionary).get("body", "")).length()

		var body_font_size: int = 22 if total_chars <= 1650 else 20
		var title_font_size: int = body_font_size + 3

		for sec_val: Variant in sections:
			if not (sec_val is Dictionary):
				continue
			var sec: Dictionary = sec_val
			var sec_vbox: VBoxContainer = VBoxContainer.new()
			sec_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			sec_vbox.add_theme_constant_override("separation", 6)

			var title_lbl: Label = Label.new()
			title_lbl.name = "SectionTitle"
			title_lbl.text = str(sec.get("title", ""))
			if font_bold != null:
				title_lbl.add_theme_font_override("font", font_bold)
			title_lbl.add_theme_font_size_override("font_size", title_font_size)
			title_lbl.add_theme_color_override("font_color", COLOR_CRIMSON)
			title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			sec_vbox.add_child(title_lbl)

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

			sections_container.add_child(sec_vbox)


func get_section_count() -> int:
	if sections_container != null:
		return sections_container.get_child_count()
	var arr: Array = page_data.get("sections", [])
	return arr.size()
