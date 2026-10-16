class_name PrayerSequencePageCard
extends BasePageCard
## Pages 4 & 46 Prayer Sequence Cards: The Opening Prayers and The Closing Prayers.

@onready var subheading_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/SubheadingLabel") as Label
@onready var heading_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/HeadingLabel") as Label
@onready var steps_container: VBoxContainer = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/PrayerStepsContainer") as VBoxContainer


func _ready() -> void:
	if not page_data.is_empty():
		_apply_page_data()


func _apply_page_data() -> void:
	if subheading_label == null:
		subheading_label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/SubheadingLabel") as Label
	if heading_label == null:
		heading_label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/HeadingLabel") as Label
	if steps_container == null:
		steps_container = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/PrayerStepsContainer") as VBoxContainer

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

	if steps_container != null:
		for child: Node in steps_container.get_children():
			steps_container.remove_child(child)
			child.free()

		var steps: Array = page_data.get("prayer_steps", [])
		var font_bold: FontFile = load("res://assets/fonts/EBGaramond-Bold.ttf") as FontFile
		var font_italic: FontFile = load("res://assets/fonts/EBGaramond-Italic.ttf") as FontFile
		var font_reg: FontFile = load("res://assets/fonts/EBGaramond-Regular.ttf") as FontFile

		# Calibrate font size between Page 4 (5 steps with long Creed) and Page 46 (4 steps)
		var is_five_step: bool = steps.size() >= 5
		var body_font_size: int = 18 if is_five_step else 22
		var rubric_font_size: int = 15 if is_five_step else 18
		var title_font_size: int = 19 if is_five_step else 23

		match text_size_preset:
			PRESET_MOBILE:
				body_font_size = 27 if is_five_step else 32
				rubric_font_size = 22 if is_five_step else 24
				title_font_size = 28 if is_five_step else 33
			PRESET_EXTRA_LARGE:
				body_font_size = 35 if is_five_step else 42
				rubric_font_size = 28 if is_five_step else 32
				title_font_size = 36 if is_five_step else 42
			_:
				body_font_size = 18 if is_five_step else 22
				rubric_font_size = 15 if is_five_step else 18
				title_font_size = 19 if is_five_step else 23

		var total_h: float = 64.0
		if font_italic != null:
			total_h += font_italic.get_multiline_string_size(sub_text, HORIZONTAL_ALIGNMENT_CENTER, 656.0, subheading_font_size).y + 4.0
		if font_bold != null:
			total_h += font_bold.get_multiline_string_size(head_text, HORIZONTAL_ALIGNMENT_CENTER, 656.0, heading_font_size).y + 4.0
		total_h += 2.0 + 14.0

		for step_val: Variant in steps:
			if not (step_val is Dictionary):
				continue
			var step: Dictionary = step_val
			var step_vbox: VBoxContainer = VBoxContainer.new()
			step_vbox.name = "Step_%d" % int(step.get("step_number", 0))
			step_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			step_vbox.add_theme_constant_override("separation", 3)

			# Rubric row: bead label + rubric
			var bead: String = str(step.get("bead_label", ""))
			var rubric: String = str(step.get("rubric", ""))
			var rubric_text: String = ""
			if bead != "":
				rubric_text = "[%s] %s" % [bead, rubric]
			else:
				rubric_text = rubric

			if rubric_text != "":
				var rubric_lbl: Label = Label.new()
				rubric_lbl.name = "StepRubric"
				rubric_lbl.text = rubric_text
				if font_italic != null:
					rubric_lbl.add_theme_font_override("font", font_italic)
				rubric_lbl.add_theme_font_size_override("font_size", rubric_font_size)
				rubric_lbl.add_theme_color_override("font_color", COLOR_UMBER)
				rubric_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				step_vbox.add_child(rubric_lbl)
				if font_italic != null:
					total_h += font_italic.get_multiline_string_size(rubric_text, HORIZONTAL_ALIGNMENT_LEFT, 656.0, rubric_font_size).y + 3.0

			# Prayer Title & Text
			var prayer: Dictionary = step.get("prayer", {})
			if prayer.is_empty() and data_loader != null:
				prayer = data_loader.get_prayer(str(step.get("prayer_id", "")))

			var title: String = str(prayer.get("title", ""))
			if title != "":
				var title_lbl: Label = Label.new()
				title_lbl.name = "PrayerTitle"
				title_lbl.text = title
				title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				if font_bold != null:
					title_lbl.add_theme_font_override("font", font_bold)
				title_lbl.add_theme_font_size_override("font_size", title_font_size)
				title_lbl.add_theme_color_override("font_color", COLOR_CRIMSON)
				step_vbox.add_child(title_lbl)
				if font_bold != null:
					total_h += font_bold.get_multiline_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, 656.0, title_font_size).y + 3.0

			var leader_str: String = str(prayer.get("leader_text", ""))
			var response_str: String = str(prayer.get("response_text", ""))
			if leader_str == "" and response_str == "":
				response_str = str(prayer.get("text", ""))

			var text_lbl: Label = Label.new()
			text_lbl.name = "PrayerText"
			text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text_lbl.add_theme_font_size_override("font_size", body_font_size)
			text_lbl.add_theme_color_override("font_color", COLOR_CHARCOAL)
			text_lbl.add_theme_constant_override("line_spacing", 2)

			var resp_lbl: Label = Label.new()
			resp_lbl.name = "ResponseText"
			resp_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			resp_lbl.add_theme_font_size_override("font_size", body_font_size)
			resp_lbl.add_theme_color_override("font_color", COLOR_CHARCOAL)
			resp_lbl.add_theme_constant_override("line_spacing", 2)
			if font_bold != null:
				resp_lbl.add_theme_font_override("font", font_bold)

			if leader_str != "":
				text_lbl.text = leader_str
				text_lbl.visible = true
				if font_reg != null:
					text_lbl.add_theme_font_override("font", font_reg)
				step_vbox.add_child(text_lbl)
				if font_reg != null:
					total_h += font_reg.get_multiline_string_size(leader_str, HORIZONTAL_ALIGNMENT_LEFT, 656.0, body_font_size).y
			else:
				# Unison prayer: PrayerText is hidden, ResponseText displays entire prayer in bold
				text_lbl.text = ""
				text_lbl.visible = false
				if font_bold != null:
					text_lbl.add_theme_font_override("font", font_bold)
				step_vbox.add_child(text_lbl)

			if response_str != "":
				resp_lbl.text = response_str
				resp_lbl.visible = true
				step_vbox.add_child(resp_lbl)
				if font_bold != null:
					total_h += font_bold.get_multiline_string_size(response_str, HORIZONTAL_ALIGNMENT_LEFT, 656.0, body_font_size).y
				if leader_str != "":
					total_h += 3.0
			else:
				resp_lbl.text = ""
				resp_lbl.visible = false
				step_vbox.add_child(resp_lbl)

			total_h += 8.0
			steps_container.add_child(step_vbox)

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


func get_step_count() -> int:
	if steps_container != null:
		return steps_container.get_child_count()
	var arr: Array = page_data.get("prayer_steps", [])
	return arr.size()
