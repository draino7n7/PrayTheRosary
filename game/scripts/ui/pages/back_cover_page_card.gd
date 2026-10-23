class_name BackCoverPageCard
extends BasePageCard
## Page 50 Back Cover Card: Crimson and gold palette with papal epigraph, synopsis, and Marian counsel.

@onready var title_label: Label = _resolve_title_label()
@onready var subtitle_label: Label = _resolve_subtitle_label()
@onready var epigraph_container: PanelContainer = _resolve_epigraph_container()
@onready var epigraph_quote_label: Label = _resolve_epigraph_quote_label()
@onready var epigraph_attr_label: Label = _resolve_epigraph_attr_label()
@onready var synopsis_label: Label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/SynopsisLabel") as Label
@onready var counsel_container: PanelContainer = _resolve_counsel_container()
@onready var counsel_quote_label: Label = _resolve_counsel_quote_label()
@onready var counsel_attr_label: Label = _resolve_counsel_attr_label()
@onready var main_vbox: VBoxContainer = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer") as VBoxContainer


func _ready() -> void:
	if not page_data.is_empty():
		_apply_page_data()


func _apply_page_data() -> void:
	if title_label == null:
		title_label = _resolve_title_label()
	if subtitle_label == null:
		subtitle_label = _resolve_subtitle_label()
	if epigraph_container == null:
		epigraph_container = _resolve_epigraph_container()
	if epigraph_quote_label == null:
		epigraph_quote_label = _resolve_epigraph_quote_label()
	if epigraph_attr_label == null:
		epigraph_attr_label = _resolve_epigraph_attr_label()
	if synopsis_label == null:
		synopsis_label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/SynopsisLabel") as Label
	if counsel_container == null:
		counsel_container = _resolve_counsel_container()
	if counsel_quote_label == null:
		counsel_quote_label = _resolve_counsel_quote_label()
	if counsel_attr_label == null:
		counsel_attr_label = _resolve_counsel_attr_label()
	if main_vbox == null:
		main_vbox = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer") as VBoxContainer

	if epigraph_container != null:
		epigraph_container.size_flags_vertical = Control.SIZE_FILL
	if synopsis_label != null:
		synopsis_label.size_flags_vertical = Control.SIZE_FILL
	if counsel_container != null:
		counsel_container.size_flags_vertical = Control.SIZE_FILL

	var raw_title: String = str(page_data.get("title", "PRAY THE ROSARY"))
	if title_label != null:
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_label.text = raw_title.to_upper()

	var subtitle_text: String = str(page_data.get("subtitle", "A Contemplative Visual Guide to the Twenty Mysteries"))
	if subtitle_label != null:
		subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		subtitle_label.text = subtitle_text

	var epigraph: Dictionary = page_data.get("epigraph", {})
	var epigraph_quote: String = "“%s”" % str(epigraph.get("quote", ""))
	var epigraph_attr: String = "— %s" % str(epigraph.get("attribution", ""))
	if epigraph_quote_label != null:
		epigraph_quote_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		epigraph_quote_label.text = epigraph_quote
		epigraph_quote_label.add_theme_constant_override("line_spacing", 3)
	if epigraph_attr_label != null:
		epigraph_attr_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		epigraph_attr_label.text = epigraph_attr

	var synopsis_text: String = str(page_data.get("synopsis", ""))
	if synopsis_label != null:
		synopsis_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		synopsis_label.text = synopsis_text
		synopsis_label.add_theme_constant_override("line_spacing", 3)

	var counsel: Dictionary = page_data.get("marian_counsel", {})
	var counsel_quote: String = "“%s”" % str(counsel.get("quote", ""))
	var counsel_attr: String = "— %s" % str(counsel.get("attribution", ""))
	if counsel_quote_label != null:
		counsel_quote_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		counsel_quote_label.text = counsel_quote
		counsel_quote_label.add_theme_constant_override("line_spacing", 3)
	if counsel_attr_label != null:
		counsel_attr_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		counsel_attr_label.text = counsel_attr

	var font_bold: FontFile = load("res://assets/fonts/EBGaramond-Bold.ttf") as FontFile
	var font_reg: FontFile = load("res://assets/fonts/EBGaramond-Regular.ttf") as FontFile

	var inner_w: float = 650.0
	var quote_w: float = inner_w - 28.0
	var callout_pad_v: float = 24.0

	var head_h: float = 0.0
	if font_bold != null:
		head_h += font_bold.get_height(38) + 8.0
	if font_reg != null:
		head_h += font_reg.get_multiline_string_size(subtitle_text, HORIZONTAL_ALIGNMENT_CENTER, inner_w, 22).y + 8.0
	head_h += 2.0 # Divider

	var epi_h: float = callout_pad_v
	if font_reg != null:
		var eq_lines: int = int(ceilf(font_reg.get_multiline_string_size(epigraph_quote, HORIZONTAL_ALIGNMENT_LEFT, quote_w, 22).y / float(font_reg.get_height(22))))
		epi_h += font_reg.get_multiline_string_size(epigraph_quote, HORIZONTAL_ALIGNMENT_LEFT, quote_w, 22).y + float(maxi(0, eq_lines - 1) * 3) + 6.0
		epi_h += font_reg.get_multiline_string_size(epigraph_attr, HORIZONTAL_ALIGNMENT_RIGHT, quote_w, 17).y

	var syn_h: float = 0.0
	if font_reg != null:
		var syn_lines: int = int(ceilf(font_reg.get_multiline_string_size(synopsis_text, HORIZONTAL_ALIGNMENT_LEFT, inner_w, 20).y / float(font_reg.get_height(20))))
		syn_h += font_reg.get_multiline_string_size(synopsis_text, HORIZONTAL_ALIGNMENT_LEFT, inner_w, 20).y + float(maxi(0, syn_lines - 1) * 3)

	var coun_h: float = callout_pad_v
	if font_reg != null:
		var cq_lines: int = int(ceilf(font_reg.get_multiline_string_size(counsel_quote, HORIZONTAL_ALIGNMENT_LEFT, quote_w, 22).y / float(font_reg.get_height(22))))
		coun_h += font_reg.get_multiline_string_size(counsel_quote, HORIZONTAL_ALIGNMENT_LEFT, quote_w, 22).y + float(maxi(0, cq_lines - 1) * 3) + 6.0
		coun_h += font_reg.get_multiline_string_size(counsel_attr, HORIZONTAL_ALIGNMENT_RIGHT, quote_w, 17).y

	var total_content_h: float = head_h + epi_h + syn_h + coun_h
	var avail_h: float = 1016.0
	var leftover_h: float = avail_h - total_content_h
	var sep: int = int(floor(leftover_h / 3.0))
	sep = maxi(sep, 16)
	if main_vbox != null:
		main_vbox.add_theme_constant_override("separation", sep)


func _resolve_epigraph_container() -> PanelContainer:
	return get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/EpigraphContainer") as PanelContainer


func _resolve_epigraph_quote_label() -> Label:
	var lbl: Label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/EpigraphContainer/EpigraphVBox/EpigraphQuoteLabel") as Label
	if lbl == null:
		lbl = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/EpigraphContainer/EpigraphQuoteLabel") as Label
	return lbl


func _resolve_epigraph_attr_label() -> Label:
	var lbl: Label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/EpigraphContainer/EpigraphVBox/EpigraphAttrLabel") as Label
	if lbl == null:
		lbl = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/EpigraphContainer/EpigraphAttrLabel") as Label
	return lbl


func _resolve_counsel_container() -> PanelContainer:
	return get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/CounselContainer") as PanelContainer


func _resolve_counsel_quote_label() -> Label:
	var lbl: Label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/CounselContainer/CounselVBox/CounselQuoteLabel") as Label
	if lbl == null:
		lbl = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/CounselContainer/CounselQuoteLabel") as Label
	return lbl


func _resolve_counsel_attr_label() -> Label:
	var lbl: Label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/CounselContainer/CounselVBox/CounselAttrLabel") as Label
	if lbl == null:
		lbl = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/CounselContainer/CounselAttrLabel") as Label
	return lbl


func _resolve_title_label() -> Label:
	var lbl: Label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/HeaderVBox/TitleLabel") as Label
	if lbl == null:
		lbl = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/TitleLabel") as Label
	return lbl


func _resolve_subtitle_label() -> Label:
	var lbl: Label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/HeaderVBox/SubtitleLabel") as Label
	if lbl == null:
		lbl = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/SubtitleLabel") as Label
	return lbl


func get_heading_text() -> String:
	if title_label != null and title_label.text != "":
		return title_label.text
	return str(page_data.get("title", "PRAY THE ROSARY")).to_upper()


func get_subheading_text() -> String:
	if subtitle_label != null and subtitle_label.text != "":
		return subtitle_label.text
	return str(page_data.get("subtitle", ""))
