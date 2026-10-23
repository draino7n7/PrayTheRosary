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
		body_font_size = 20
	elif total_text_len > 480:
		body_font_size = 21
	elif total_text_len > 380:
		body_font_size = 22
	else:
		body_font_size = 23

	var rubric_font_size: int = 17 if body_font_size <= 21 else 18

	match text_size_preset:
		PRESET_MOBILE:
			heading_font_size = 38
			subheading_font_size = 25
			fruit_font_size = 24
			citation_font_size = 23
			body_font_size = 29 if total_text_len > 580 else (30 if total_text_len > 480 else (31 if total_text_len > 380 else 32))
			rubric_font_size = 24 if body_font_size <= 29 else 25
		PRESET_EXTRA_LARGE:
			heading_font_size = 44
			subheading_font_size = 29
			fruit_font_size = 30
			citation_font_size = 29
			body_font_size = 38 if total_text_len > 580 else (40 if total_text_len > 480 else (42 if total_text_len > 380 else 44))
			rubric_font_size = 31 if body_font_size <= 38 else 33
		_:
			heading_font_size = 34
			subheading_font_size = 22
			fruit_font_size = 18
			citation_font_size = 17

	var font_bold: FontFile = load("res://assets/fonts/EBGaramond-Bold.ttf") as FontFile
	var font_reg: FontFile = load("res://assets/fonts/EBGaramond-Regular.ttf") as FontFile

	var sub_text: String = str(page_data.get("subheading", mys.get("ordinal_label", "")))
	if subheading_label != null:
		subheading_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		subheading_label.text = sub_text
		subheading_label.add_theme_font_size_override("font_size", subheading_font_size)

	var head_text: String = str(page_data.get("heading", mys.get("title", "")))
	if heading_label != null:
		heading_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		heading_label.text = head_text
		heading_label.add_theme_font_size_override("font_size", heading_font_size)

	var fruit_name: String = str(mys.get("fruit", ""))
	var fruit_str: String = "Fruit of the Mystery: %s" % fruit_name
	if fruit_label != null:
		fruit_label.text = fruit_str
		fruit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fruit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fruit_label.add_theme_font_size_override("font_size", fruit_font_size)

		# Badge padding: 14 left + 14 right = 28px. Available badge width inside 656px card = 656px.
		var available_badge_w: float = 656.0
		var badge_margin_h: float = 28.0
		var max_fruit_label_w: float = available_badge_w - badge_margin_h
		var unwrapped_fruit_w: float = 0.0
		if font_reg != null:
			unwrapped_fruit_w = font_reg.get_string_size(fruit_str, HORIZONTAL_ALIGNMENT_CENTER, -1, fruit_font_size).x
		else:
			unwrapped_fruit_w = float(fruit_str.length() * fruit_font_size) * 0.6
		var target_label_w: float = ceilf(minf(unwrapped_fruit_w, max_fruit_label_w))
		fruit_label.custom_minimum_size = Vector2(target_label_w, 0.0)

		var fruit_badge: PanelContainer = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/FruitBadge") as PanelContainer
		if fruit_badge != null:
			fruit_badge.custom_minimum_size = Vector2(0.0, 0.0)

	var cite_str: String = str(mys.get("scripture_reference", ""))
	if scripture_citation_label != null:
		scripture_citation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		scripture_citation_label.text = cite_str
		scripture_citation_label.add_theme_font_size_override("font_size", citation_font_size)
	if scripture_text_label != null:
		scripture_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		scripture_text_label.text = "“%s”" % scrip_str
		scripture_text_label.add_theme_font_size_override("font_size", body_font_size)
		scripture_text_label.add_theme_constant_override("line_spacing", 2)

	if meditation_label != null:
		meditation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		meditation_label.text = med_str
		meditation_label.add_theme_font_size_override("font_size", body_font_size)
		meditation_label.add_theme_constant_override("line_spacing", 2)

	var decade_prayers: Array = page_data.get("decade_prayers", [])
	var sum_dec_heights: float = 0.0
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
			p_vbox.size_flags_vertical = Control.SIZE_FILL
			p_vbox.add_theme_constant_override("separation", 2)

			var p_h: float = 0.0
			var visible_count: int = 0

			var prayer_title: String = str(prayer_dict.get("title", pid.capitalize()))
			var rubric_label: Label = Label.new()
			rubric_label.name = "DecadeRubric"
			rubric_label.text = "%d× %s" % [reps, prayer_title]
			if font_bold != null:
				rubric_label.add_theme_font_override("font", font_bold)
			rubric_label.add_theme_font_size_override("font_size", rubric_font_size)
			rubric_label.add_theme_color_override("font_color", COLOR_CRIMSON)
			rubric_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			p_vbox.add_child(rubric_label)
			if font_bold != null:
				p_h += font_bold.get_multiline_string_size(rubric_label.text, HORIZONTAL_ALIGNMENT_LEFT, 656.0, rubric_font_size).y
				visible_count += 1

			var leader_str: String = str(prayer_dict.get("leader_text", ""))
			var response_str: String = str(prayer_dict.get("response_text", ""))
			if leader_str == "" and response_str == "":
				response_str = str(prayer_dict.get("text", ""))

			var text_label: Label = Label.new()
			text_label.name = "PrayerText"
			text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text_label.add_theme_font_size_override("font_size", body_font_size)
			text_label.add_theme_color_override("font_color", COLOR_CHARCOAL)
			text_label.add_theme_constant_override("line_spacing", 2)

			var resp_label: Label = Label.new()
			resp_label.name = "ResponseText"
			resp_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			resp_label.add_theme_font_size_override("font_size", body_font_size)
			resp_label.add_theme_color_override("font_color", COLOR_CHARCOAL)
			resp_label.add_theme_constant_override("line_spacing", 2)
			if font_bold != null:
				resp_label.add_theme_font_override("font", font_bold)

			if leader_str != "":
				text_label.text = leader_str
				text_label.visible = true
				if font_reg != null:
					text_label.add_theme_font_override("font", font_reg)
				p_vbox.add_child(text_label)
				if font_reg != null:
					var l_lines: int = int(ceilf(font_reg.get_multiline_string_size(leader_str, HORIZONTAL_ALIGNMENT_LEFT, 656.0, body_font_size).y / float(font_reg.get_height(body_font_size))))
					p_h += font_reg.get_multiline_string_size(leader_str, HORIZONTAL_ALIGNMENT_LEFT, 656.0, body_font_size).y + (maxi(0, l_lines - 1) * 2)
					visible_count += 1
			else:
				# Unison prayer: PrayerText is hidden, ResponseText displays entire prayer in bold
				text_label.text = ""
				text_label.visible = false
				if font_bold != null:
					text_label.add_theme_font_override("font", font_bold)
				p_vbox.add_child(text_label)

			if response_str != "":
				resp_label.text = response_str
				resp_label.visible = true
				p_vbox.add_child(resp_label)
				if font_bold != null:
					var r_lines: int = int(ceilf(font_bold.get_multiline_string_size(response_str, HORIZONTAL_ALIGNMENT_LEFT, 656.0, body_font_size).y / float(font_bold.get_height(body_font_size))))
					p_h += font_bold.get_multiline_string_size(response_str, HORIZONTAL_ALIGNMENT_LEFT, 656.0, body_font_size).y + (maxi(0, r_lines - 1) * 2)
					visible_count += 1
			else:
				resp_label.text = ""
				resp_label.visible = false
				p_vbox.add_child(resp_label)

			if visible_count > 1:
				p_h += float((visible_count - 1) * 2)

			sum_dec_heights += p_h
			decade_prayers_container.add_child(p_vbox)

	var header_h: float = 0.0
	if font_reg != null:
		header_h += font_reg.get_multiline_string_size(sub_text, HORIZONTAL_ALIGNMENT_CENTER, 656.0, subheading_font_size).y + 4.0
	if font_bold != null:
		header_h += font_bold.get_multiline_string_size(head_text, HORIZONTAL_ALIGNMENT_CENTER, 656.0, heading_font_size).y + 4.0
	if font_reg != null:
		header_h += font_reg.get_multiline_string_size(fruit_str, HORIZONTAL_ALIGNMENT_CENTER, 628.0, fruit_font_size).y + 8.0 + 4.0
	header_h += 2.0 # Divider

	var scripture_h: float = 8.0 # ScriptureContainer StyleBox margins
	if font_bold != null:
		scripture_h += font_bold.get_multiline_string_size(cite_str, HORIZONTAL_ALIGNMENT_LEFT, 636.0, citation_font_size).y + 2.0
	if font_reg != null:
		var scrip_lines: int = int(ceilf(font_reg.get_multiline_string_size("“%s”" % scrip_str, HORIZONTAL_ALIGNMENT_LEFT, 636.0, body_font_size).y / float(font_reg.get_height(body_font_size))))
		scripture_h += font_reg.get_multiline_string_size("“%s”" % scrip_str, HORIZONTAL_ALIGNMENT_LEFT, 636.0, body_font_size).y + (maxi(0, scrip_lines - 1) * 2)

	var meditation_h: float = 0.0
	if font_reg != null:
		var med_lines: int = int(ceilf(font_reg.get_multiline_string_size(med_str, HORIZONTAL_ALIGNMENT_LEFT, 656.0, body_font_size).y / float(font_reg.get_height(body_font_size))))
		meditation_h += font_reg.get_multiline_string_size(med_str, HORIZONTAL_ALIGNMENT_LEFT, 656.0, body_font_size).y + (maxi(0, med_lines - 1) * 2)

	var num_prayers: int = decade_prayers.size()
	var num_dec_gaps: int = maxi(1, num_prayers - 1)
	var applied_dec_sep: int = 6
	if text_size_preset == PRESET_NORMAL:
		var avail_for_dec: float = 1016.0 - (header_h + scripture_h + meditation_h + 30.0)
		var leftover_dec: float = avail_for_dec - sum_dec_heights
		applied_dec_sep = int(floor(leftover_dec / float(num_dec_gaps)))
		applied_dec_sep = maxi(applied_dec_sep, 6)
	else:
		applied_dec_sep = 14 if text_size_preset == PRESET_MOBILE else 18

	decade_prayers_container.add_theme_constant_override("separation", applied_dec_sep)

	var total_h: float = 64.0 + header_h + scripture_h + meditation_h + 30.0 + sum_dec_heights + float(num_dec_gaps * applied_dec_sep)
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
