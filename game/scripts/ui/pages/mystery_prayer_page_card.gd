class_name MysteryPrayerPageCard
extends BasePageCard
## Even Pages 6..44 Mystery Prayer Cards: Scripture, Meditation, Decade Prayers.

@onready var subheading_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/SubheadingLabel") as Label
@onready var heading_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/HeadingLabel") as Label
@onready var fruit_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/FruitBadge/FruitLabel") as Label
@onready var scripture_citation_label: Label = _resolve_scripture_citation_label()
@onready var scripture_text_label: Label = _resolve_scripture_text_label()
@onready var meditation_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/MeditationLabel") as Label
@onready var decade_prayers_container: VBoxContainer = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/DecadePrayersContainer") as VBoxContainer


func _ready() -> void:
	if not page_data.is_empty():
		_apply_page_data()


func _apply_page_data() -> void:
	if subheading_label == null:
		subheading_label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/SubheadingLabel") as Label
	if heading_label == null:
		heading_label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/HeadingLabel") as Label
	if fruit_label == null:
		fruit_label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/FruitBadge/FruitLabel") as Label
	if scripture_citation_label == null:
		scripture_citation_label = _resolve_scripture_citation_label()
	if scripture_text_label == null:
		scripture_text_label = _resolve_scripture_text_label()
	if meditation_label == null:
		meditation_label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/MeditationLabel") as Label
	if decade_prayers_container == null:
		decade_prayers_container = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/DecadePrayersContainer") as VBoxContainer

	var mys: Dictionary = page_data.get("mystery", {})

	var heading_font_size: int = 34
	var subheading_font_size: int = 22
	var fruit_font_size: int = 18
	var citation_font_size: int = 17

	var scrip_str: String = str(mys.get("scripture_text", ""))
	var med_str: String = str(mys.get("meditation", ""))
	var total_text_len: int = scrip_str.length() + med_str.length()

	# Calibrate font size dynamically based on passage length
	var body_font_size: int = 24
	if total_text_len > 580:
		body_font_size = 22
	elif total_text_len > 480:
		body_font_size = 23
	else:
		body_font_size = 24

	var rubric_font_size: int = 17 if body_font_size <= 22 else 18

	match text_size_preset:
		PRESET_MOBILE:
			heading_font_size = 38
			subheading_font_size = 25
			fruit_font_size = 24
			citation_font_size = 23
			body_font_size = 31 if total_text_len > 580 else (32 if total_text_len > 480 else 33)
			rubric_font_size = 24 if body_font_size <= 31 else 25
		PRESET_EXTRA_LARGE:
			heading_font_size = 44
			subheading_font_size = 29
			fruit_font_size = 30
			citation_font_size = 29
			body_font_size = 40 if total_text_len > 580 else (42 if total_text_len > 480 else 44)
			rubric_font_size = 31 if body_font_size <= 40 else 33
		_:
			heading_font_size = 34
			subheading_font_size = 22
			fruit_font_size = 18
			citation_font_size = 17

	if subheading_label != null:
		subheading_label.text = str(page_data.get("subheading", mys.get("ordinal_label", "")))
		subheading_label.add_theme_font_size_override("font_size", subheading_font_size)
	if heading_label != null:
		heading_label.text = str(page_data.get("heading", mys.get("title", "")))
		heading_label.add_theme_font_size_override("font_size", heading_font_size)

	if fruit_label != null:
		var fruit: String = str(mys.get("fruit", ""))
		fruit_label.text = "Fruit of the Mystery: %s" % fruit
		fruit_label.add_theme_font_size_override("font_size", fruit_font_size)

	if scripture_citation_label != null:
		scripture_citation_label.text = str(mys.get("scripture_reference", ""))
		scripture_citation_label.add_theme_font_size_override("font_size", citation_font_size)
	if scripture_text_label != null:
		scripture_text_label.text = "“%s”" % scrip_str
		scripture_text_label.add_theme_font_size_override("font_size", body_font_size)
		scripture_text_label.add_theme_constant_override("line_spacing", 2)

	if meditation_label != null:
		meditation_label.text = med_str
		meditation_label.add_theme_font_size_override("font_size", body_font_size)
		meditation_label.add_theme_constant_override("line_spacing", 2)

	var font_bold: FontFile = load("res://assets/fonts/EBGaramond-Bold.ttf") as FontFile
	var font_italic: FontFile = load("res://assets/fonts/EBGaramond-Italic.ttf") as FontFile
	var font_reg: FontFile = load("res://assets/fonts/EBGaramond-Regular.ttf") as FontFile

	var decade_prayers: Array = page_data.get("decade_prayers", [])
	if decade_prayers_container != null:
		for child: Node in decade_prayers_container.get_children():
			decade_prayers_container.remove_child(child)
			child.free()

		for p_item_val: Variant in decade_prayers:
			if not (p_item_val is Dictionary):
				continue
			var p_item: Dictionary = p_item_val
			var reps: int = int(p_item.get("repetitions", 1))
			var pid: String = str(p_item.get("prayer_id", ""))
			var prayer_dict: Dictionary = p_item.get("prayer", {})
			if prayer_dict.is_empty() and data_loader != null:
				prayer_dict = data_loader.get_prayer(pid)

			var p_vbox: VBoxContainer = VBoxContainer.new()
			p_vbox.name = "Prayer_%s" % pid
			p_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			p_vbox.add_theme_constant_override("separation", 2)

			var prayer_title: String = str(prayer_dict.get("title", pid.capitalize()))
			var rubric_label: Label = Label.new()
			rubric_label.name = "DecadeRubric"
			rubric_label.text = "%d× %s" % [reps, prayer_title]
			if font_bold != null:
				rubric_label.add_theme_font_override("font", font_bold)
			rubric_label.add_theme_font_size_override("font_size", rubric_font_size)
			rubric_label.add_theme_color_override("font_color", COLOR_CRIMSON)
			p_vbox.add_child(rubric_label)

			var p_text: String = str(prayer_dict.get("text", ""))
			if p_text != "":
				var text_label: Label = Label.new()
				text_label.name = "PrayerText"
				text_label.text = p_text
				if font_reg != null:
					text_label.add_theme_font_override("font", font_reg)
				text_label.add_theme_font_size_override("font_size", body_font_size)
				text_label.add_theme_color_override("font_color", COLOR_CHARCOAL)
				text_label.add_theme_constant_override("line_spacing", 2)
				text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				p_vbox.add_child(text_label)

			decade_prayers_container.add_child(p_vbox)

	var total_h: float = 64.0
	if font_italic != null:
		total_h += font_italic.get_height(subheading_font_size) + 4.0
	if font_bold != null:
		total_h += font_bold.get_height(heading_font_size) + 4.0
	if font_italic != null:
		total_h += font_italic.get_height(fruit_font_size) + 8.0 + 4.0
	total_h += 2.0 + 10.0

	if font_bold != null:
		total_h += font_bold.get_height(citation_font_size) + 2.0
	if font_italic != null:
		total_h += font_italic.get_multiline_string_size("“%s”" % scrip_str, HORIZONTAL_ALIGNMENT_LEFT, 636.0, body_font_size).y + 8.0 + 10.0
	if font_reg != null:
		total_h += font_reg.get_multiline_string_size(med_str, HORIZONTAL_ALIGNMENT_LEFT, 656.0, body_font_size).y + 10.0

	for p_item_val: Variant in decade_prayers:
		if not (p_item_val is Dictionary):
			continue
		var p_item: Dictionary = p_item_val
		var pid: String = str(p_item.get("prayer_id", ""))
		var prayer_dict: Dictionary = p_item.get("prayer", {})
		if prayer_dict.is_empty() and data_loader != null:
			prayer_dict = data_loader.get_prayer(pid)
		if font_bold != null:
			total_h += font_bold.get_height(rubric_font_size) + 2.0
		var p_text: String = str(prayer_dict.get("text", ""))
		if p_text != "" and font_reg != null:
			total_h += font_reg.get_multiline_string_size(p_text, HORIZONTAL_ALIGNMENT_LEFT, 656.0, body_font_size).y
		total_h += 8.0

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


func get_fruit_text() -> String:
	if fruit_label != null:
		return fruit_label.text
	var mys: Dictionary = page_data.get("mystery", {})
	return str(mys.get("fruit", ""))


func _resolve_scripture_citation_label() -> Label:
	var lbl: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ScriptureContainer/ScriptureVBox/ScriptureCitationLabel") as Label
	if lbl == null:
		lbl = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ScriptureContainer/ScriptureCitationLabel") as Label
	return lbl


func _resolve_scripture_text_label() -> Label:
	var lbl: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ScriptureContainer/ScriptureVBox/ScriptureTextLabel") as Label
	if lbl == null:
		lbl = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ScriptureContainer/ScriptureTextLabel") as Label
	return lbl
