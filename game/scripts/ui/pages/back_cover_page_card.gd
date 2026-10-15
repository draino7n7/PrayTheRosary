class_name BackCoverPageCard
extends BasePageCard
## Page 50 Back Cover Card: Crimson and gold palette with papal epigraph, synopsis, and Marian counsel.

@onready var title_label: Label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/TitleLabel") as Label
@onready var subtitle_label: Label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/SubtitleLabel") as Label
@onready var epigraph_quote_label: Label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/EpigraphContainer/EpigraphQuoteLabel") as Label
@onready var epigraph_attr_label: Label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/EpigraphContainer/EpigraphAttrLabel") as Label
@onready var synopsis_label: Label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/SynopsisLabel") as Label
@onready var counsel_quote_label: Label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/CounselContainer/CounselQuoteLabel") as Label
@onready var counsel_attr_label: Label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/CounselContainer/CounselAttrLabel") as Label


func _ready() -> void:
	if not page_data.is_empty():
		_apply_page_data()


func _apply_page_data() -> void:
	if title_label == null:
		title_label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/TitleLabel") as Label
	if subtitle_label == null:
		subtitle_label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/SubtitleLabel") as Label
	if epigraph_quote_label == null:
		epigraph_quote_label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/EpigraphContainer/EpigraphQuoteLabel") as Label
	if epigraph_attr_label == null:
		epigraph_attr_label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/EpigraphContainer/EpigraphAttrLabel") as Label
	if synopsis_label == null:
		synopsis_label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/SynopsisLabel") as Label
	if counsel_quote_label == null:
		counsel_quote_label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/CounselContainer/CounselQuoteLabel") as Label
	if counsel_attr_label == null:
		counsel_attr_label = get_node_or_null("CardPanel/MarginContainer/InnerBorder/InnerMargin/VBoxContainer/CounselContainer/CounselAttrLabel") as Label

	if title_label != null:
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var raw_title: String = str(page_data.get("title", "PRAY THE ROSARY"))
		title_label.text = raw_title.to_upper()

	if subtitle_label != null:
		subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		subtitle_label.text = str(page_data.get("subtitle", "A Contemplative Visual Guide to the Twenty Mysteries"))

	var epigraph: Dictionary = page_data.get("epigraph", {})
	if epigraph_quote_label != null:
		epigraph_quote_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		epigraph_quote_label.text = "“%s”" % str(epigraph.get("quote", ""))
		epigraph_quote_label.add_theme_constant_override("line_spacing", 3)
	if epigraph_attr_label != null:
		epigraph_attr_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		epigraph_attr_label.text = "— %s" % str(epigraph.get("attribution", ""))

	if synopsis_label != null:
		synopsis_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		synopsis_label.text = str(page_data.get("synopsis", ""))
		synopsis_label.add_theme_constant_override("line_spacing", 3)

	var counsel: Dictionary = page_data.get("marian_counsel", {})
	if counsel_quote_label != null:
		counsel_quote_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		counsel_quote_label.text = "“%s”" % str(counsel.get("quote", ""))
		counsel_quote_label.add_theme_constant_override("line_spacing", 3)
	if counsel_attr_label != null:
		counsel_attr_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		counsel_attr_label.text = "— %s" % str(counsel.get("attribution", ""))


func get_heading_text() -> String:
	if title_label != null and title_label.text != "":
		return title_label.text
	return str(page_data.get("title", "PRAY THE ROSARY")).to_upper()


func get_subheading_text() -> String:
	if subtitle_label != null and subtitle_label.text != "":
		return subtitle_label.text
	return str(page_data.get("subtitle", ""))
