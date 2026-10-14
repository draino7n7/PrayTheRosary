class_name InStreamJumpBar
extends MarginContainer
## In-stream action separator bar inserted directly into the 50-page continuous scroll stream.
## Supports:
## 1. Post-Opening Prayers Mystery Set selector (after Page 5) with 4 mystery set jump buttons
##    and an antique gold highlight/badge for today's recommended mystery set.
## 2. Post-Mystery-Set Closing Prayers jump button (after Pages 15, 25, 35, 45) targeting Page 46.

signal jump_requested(target_page: int)

const COLOR_CRIMSON: Color = Color(0.4196, 0.1137, 0.1294, 1.0) # #6B1D21
const COLOR_GOLD: Color = Color(0.7216, 0.5686, 0.1882, 1.0)    # #B89130
const COLOR_GOLD_BRIGHT: Color = Color(0.8314, 0.6863, 0.2157, 1.0) # #D4AF37
const COLOR_PARCHMENT: Color = Color(0.9804, 0.9647, 0.9333, 1.0) # #FAF6EE
const COLOR_CHARCOAL: Color = Color(0.1176, 0.0941, 0.0824, 1.0) # #1E1815
const COLOR_UMBER: Color = Color(0.3608, 0.2627, 0.2196, 1.0)   # #5C4338

var separator_data: Dictionary = {}
var separator_id: String = ""
var separator_type: String = ""
var after_page_number: int = 0
var prompt_text: String = ""
var recommended_mystery_set: String = ""

var _target_pages: Array[int] = []
var _button_nodes: Array[Button] = []
var _is_recommended_flags: Array[bool] = []

@onready var prompt_label: Label = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/PromptLabel") as Label
@onready var buttons_container: VBoxContainer = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer") as VBoxContainer


func _ready() -> void:
	if not separator_data.is_empty() and _button_nodes.is_empty():
		_apply_separator_data()


func bind_separator_data(data: Dictionary, loader: RosaryDataLoader = null) -> void:
	separator_data = data
	separator_id = str(data.get("id", ""))
	separator_type = str(data.get("type", ""))
	after_page_number = int(data.get("after_page_number", 0))
	prompt_text = str(data.get("prompt", ""))

	if loader != null:
		recommended_mystery_set = loader.get_recommended_mystery_set_for_today()
	else:
		recommended_mystery_set = ""

	_apply_separator_data()


func _apply_separator_data() -> void:
	if prompt_label == null:
		prompt_label = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/PromptLabel") as Label
	if buttons_container == null:
		buttons_container = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer") as VBoxContainer

	if prompt_label != null:
		prompt_label.text = prompt_text

	if buttons_container == null:
		return

	# Clear previous buttons
	for child: Node in buttons_container.get_children():
		child.queue_free()
	_button_nodes.clear()
	_target_pages.clear()
	_is_recommended_flags.clear()

	if separator_type == "mystery_set_selector":
		_build_mystery_set_buttons()
	elif separator_type == "closing_prayers_jump":
		_build_closing_prayers_button()


func _build_mystery_set_buttons() -> void:
	var targets: Array = separator_data.get("targets", [])
	for target_val: Variant in targets:
		if not (target_val is Dictionary):
			continue
		var target: Dictionary = target_val as Dictionary
		var label_str: String = str(target.get("label", ""))
		var set_id: String = str(target.get("mystery_set_id", ""))
		var target_page: int = int(target.get("target_page", 6))
		var is_rec: bool = (set_id != "" and set_id == recommended_mystery_set)

		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 48)
		btn.focus_mode = Control.FOCUS_NONE
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		if is_rec:
			btn.text = "%s   ★ Recommended Today" % label_str
			_apply_recommended_button_style(btn)
		else:
			btn.text = label_str
			_apply_standard_button_style(btn)

		var captured_page: int = target_page
		btn.pressed.connect(func() -> void: _on_button_pressed(captured_page))

		buttons_container.add_child(btn)
		_button_nodes.append(btn)
		_target_pages.append(target_page)
		_is_recommended_flags.append(is_rec)


func _build_closing_prayers_button() -> void:
	var button_label_str: String = str(separator_data.get("button_label", "Proceed to the Closing Prayers"))
	var target_page: int = int(separator_data.get("target_page", 46))

	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(0, 52)
	btn.focus_mode = Control.FOCUS_NONE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.text = "%s  →" % button_label_str

	_apply_closing_button_style(btn)

	var captured_page: int = target_page
	btn.pressed.connect(func() -> void: _on_button_pressed(captured_page))

	buttons_container.add_child(btn)
	_button_nodes.append(btn)
	_target_pages.append(target_page)
	_is_recommended_flags.append(false)


func _on_button_pressed(target_page: int) -> void:
	jump_requested.emit(target_page)


func _apply_standard_button_style(btn: Button) -> void:
	var style_normal: StyleBoxFlat = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.98, 0.965, 0.933, 0.9)
	style_normal.border_color = COLOR_GOLD
	style_normal.border_width_left = 1
	style_normal.border_width_top = 1
	style_normal.border_width_right = 1
	style_normal.border_width_bottom = 1
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_right = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.content_margin_left = 16.0
	style_normal.content_margin_right = 16.0
	style_normal.content_margin_top = 10.0
	style_normal.content_margin_bottom = 10.0

	var style_hover: StyleBoxFlat = style_normal.duplicate() as StyleBoxFlat
	style_hover.bg_color = Color(1.0, 0.99, 0.97, 1.0)
	style_hover.border_color = COLOR_GOLD_BRIGHT
	style_hover.border_width_left = 2
	style_hover.border_width_top = 2
	style_hover.border_width_right = 2
	style_hover.border_width_bottom = 2

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_color_override("font_color", COLOR_CHARCOAL)
	btn.add_theme_color_override("font_hover_color", COLOR_CRIMSON)
	btn.add_theme_font_size_override("font_size", 19)


func _apply_recommended_button_style(btn: Button) -> void:
	var style_rec: StyleBoxFlat = StyleBoxFlat.new()
	style_rec.bg_color = Color(0.96, 0.93, 0.85, 1.0)
	style_rec.border_color = COLOR_GOLD_BRIGHT
	style_rec.border_width_left = 2
	style_rec.border_width_top = 2
	style_rec.border_width_right = 2
	style_rec.border_width_bottom = 2
	style_rec.corner_radius_top_left = 4
	style_rec.corner_radius_top_right = 4
	style_rec.corner_radius_bottom_right = 4
	style_rec.corner_radius_bottom_left = 4
	style_rec.content_margin_left = 16.0
	style_rec.content_margin_right = 16.0
	style_rec.content_margin_top = 10.0
	style_rec.content_margin_bottom = 10.0

	var style_hover: StyleBoxFlat = style_rec.duplicate() as StyleBoxFlat
	style_hover.bg_color = Color(0.99, 0.96, 0.88, 1.0)
	style_hover.border_color = COLOR_GOLD_BRIGHT
	style_hover.border_width_left = 3
	style_hover.border_width_top = 3
	style_hover.border_width_right = 3
	style_hover.border_width_bottom = 3

	btn.add_theme_stylebox_override("normal", style_rec)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_color_override("font_color", COLOR_CRIMSON)
	btn.add_theme_color_override("font_hover_color", COLOR_CHARCOAL)
	btn.add_theme_font_size_override("font_size", 20)


func _apply_closing_button_style(btn: Button) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.965, 0.933, 1.0)
	style.border_color = COLOR_CRIMSON
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0

	var style_hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	style_hover.bg_color = Color(0.94, 0.90, 0.85, 1.0)
	style_hover.border_color = COLOR_GOLD_BRIGHT

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_color_override("font_color", COLOR_CRIMSON)
	btn.add_theme_color_override("font_hover_color", COLOR_CHARCOAL)
	btn.add_theme_font_size_override("font_size", 20)


func get_button_count() -> int:
	return _button_nodes.size()


func get_target_page_for_button(index: int) -> int:
	if index >= 0 and index < _target_pages.size():
		return _target_pages[index]
	return -1


func is_recommended_button(index: int) -> bool:
	if index >= 0 and index < _is_recommended_flags.size():
		return _is_recommended_flags[index]
	return false


func get_prompt_text() -> String:
	return prompt_text


func get_separator_id() -> String:
	return separator_id


func get_after_page_number() -> int:
	return after_page_number


func get_recommended_mystery_set() -> String:
	return recommended_mystery_set
