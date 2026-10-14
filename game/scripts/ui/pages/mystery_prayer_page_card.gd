class_name MysteryPrayerPageCard
extends BasePageCard
## Even Pages 6..44 Mystery Prayer Cards: Scripture, Meditation, Decade Prayers.

@onready var subheading_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/SubheadingLabel") as Label
@onready var heading_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/HeadingLabel") as Label
@onready var fruit_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/FruitBadge/FruitLabel") as Label
@onready var scripture_citation_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ScriptureContainer/ScriptureCitationLabel") as Label
@onready var scripture_text_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ScriptureContainer/ScriptureTextLabel") as Label
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
		scripture_citation_label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ScriptureContainer/ScriptureCitationLabel") as Label
	if scripture_text_label == null:
		scripture_text_label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ScriptureContainer/ScriptureTextLabel") as Label
	if meditation_label == null:
		meditation_label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/MeditationLabel") as Label
	if decade_prayers_container == null:
		decade_prayers_container = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/DecadePrayersContainer") as VBoxContainer

	var mys: Dictionary = page_data.get("mystery", {})

	if subheading_label != null:
		subheading_label.text = str(page_data.get("subheading", mys.get("ordinal_label", "")))
	if heading_label != null:
		heading_label.text = str(page_data.get("heading", mys.get("title", "")))

	if fruit_label != null:
		var fruit: String = str(mys.get("fruit", ""))
		fruit_label.text = "Fruit of the Mystery: %s" % fruit

	if scripture_citation_label != null:
		scripture_citation_label.text = str(mys.get("scripture_reference", ""))
	if scripture_text_label != null:
		var stext: String = str(mys.get("scripture_text", ""))
		scripture_text_label.text = "“%s”" % stext

	if meditation_label != null:
		meditation_label.text = str(mys.get("meditation", ""))

	if decade_prayers_container != null:
		for child: Node in decade_prayers_container.get_children():
			child.queue_free()

		var decade_prayers: Array = page_data.get("decade_prayers", [])
		var font_bold: FontFile = load("res://assets/fonts/EBGaramond-Bold.ttf") as FontFile
		var font_reg: FontFile = load("res://assets/fonts/EBGaramond-Regular.ttf") as FontFile

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
			p_vbox.add_theme_constant_override("separation", 2)

			var prayer_title: String = str(prayer_dict.get("title", pid.capitalize()))
			var rubric_label: Label = Label.new()
			rubric_label.name = "DecadeRubric"
			rubric_label.text = "%d× %s" % [reps, prayer_title]
			if font_bold != null:
				rubric_label.add_theme_font_override("font", font_bold)
			rubric_label.add_theme_font_size_override("font_size", 14)
			rubric_label.add_theme_color_override("font_color", COLOR_CRIMSON)
			p_vbox.add_child(rubric_label)

			var p_text: String = str(prayer_dict.get("text", ""))
			if p_text != "":
				var text_label: Label = Label.new()
				text_label.name = "PrayerText"
				text_label.text = p_text
				if font_reg != null:
					text_label.add_theme_font_override("font", font_reg)
				text_label.add_theme_font_size_override("font_size", 13)
				text_label.add_theme_color_override("font_color", COLOR_CHARCOAL)
				text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				p_vbox.add_child(text_label)

			decade_prayers_container.add_child(p_vbox)


func get_fruit_text() -> String:
	if fruit_label != null:
		return fruit_label.text
	var mys: Dictionary = page_data.get("mystery", {})
	return str(mys.get("fruit", ""))
