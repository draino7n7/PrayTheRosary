class_name NavigationDrawer
extends CanvasLayer
## Floating Table of Contents and Navigation Drawer controller.
## Provides:
## - Persistent top-right floating menu button on CanvasLayer (layer >= 10).
## - Slide-out drawer with dimming scrim backdrop (closing on click or ui_cancel).
## - Prominent "Resume Last Page" button backed by ReadingProgressManager.
## - Top-level landmark navigation buttons (Pages 1, 2, 3, 4, 46, 48, 50).
## - Expandable Mystery Set accordions (Joyful, Luminous, Sorrowful, Glorious)
##   with dual-action rows:
##   * Disclosure arrow (▸ / ▾) expands/collapses the 5 individual mysteries.
##   * Mystery title button jumps immediately to the 1st mystery and closes drawer.
##   * 5 individual mystery buttons navigate to their respective prayer pages.
## - Dynamic Liturgical "Recommended Today" badge on today's recommended mystery set.

signal page_requested(page_number: int)
signal drawer_opened()
signal drawer_closed()

const COLOR_CRIMSON: Color = Color(0.4196, 0.1137, 0.1294, 1.0)       # #6B1D21
const COLOR_GOLD: Color = Color(0.7216, 0.5686, 0.1882, 1.0)          # #B89130
const COLOR_GOLD_BRIGHT: Color = Color(0.8314, 0.6863, 0.2157, 1.0)   # #D4AF37
const COLOR_PARCHMENT: Color = Color(0.9804, 0.9647, 0.9333, 1.0)     # #FAF6EE
const COLOR_PARCHMENT_ALT: Color = Color(0.9412, 0.9176, 0.8784, 1.0)
const COLOR_CHARCOAL: Color = Color(0.1176, 0.0941, 0.0824, 1.0)     # #1E1815
const COLOR_UMBER: Color = Color(0.3608, 0.2627, 0.2196, 1.0)         # #5C4338

const PANEL_WIDTH_NORMAL: float = 400.0
const PANEL_WIDTH_MOBILE: float = 560.0
const PANEL_WIDTH_EXTRA_LARGE: float = 680.0

const FONT_BOLD_PATH: String = "res://assets/fonts/EBGaramond-Bold.ttf"
const FONT_REGULAR_PATH: String = "res://assets/fonts/EBGaramond-Regular.ttf"
const FONT_SYMBOLS_PATH: String = "res://assets/fonts/NotoSansSymbols-Regular.ttf"

const LANDMARKS_TOP: Array[Dictionary] = [
	{"id": "front_cover", "label": "Front Cover (Page 1)", "page": 1},
	{"id": "history", "label": "History of the Rosary (Page 2)", "page": 2},
	{"id": "structure", "label": "Structure & How to Pray (Page 3)", "page": 3},
	{"id": "opening_prayers", "label": "The Opening Prayers (Page 4)", "page": 4}
]

const LANDMARKS_BOTTOM: Array[Dictionary] = [
	{"id": "closing_prayers", "label": "The Closing Prayers (Page 46)", "page": 46},
	{"id": "credits", "label": "Sacred Artwork Credits (Page 48)", "page": 48},
	{"id": "back_cover", "label": "Back Cover (Page 50)", "page": 50}
]

const MYSTERY_SET_DEFAULTS: Dictionary = {
	"joyful": {
		"title": "The Joyful Mysteries",
		"first_page": 6,
		"decades": [
			{"number": 1, "title": "The Annunciation", "page": 6},
			{"number": 2, "title": "The Visitation", "page": 8},
			{"number": 3, "title": "The Nativity of Our Lord", "page": 10},
			{"number": 4, "title": "The Presentation of Jesus in the Temple", "page": 12},
			{"number": 5, "title": "The Finding of Jesus in the Temple", "page": 14}
		]
	},
	"luminous": {
		"title": "The Luminous Mysteries",
		"first_page": 16,
		"decades": [
			{"number": 1, "title": "The Baptism of Jesus in the Jordan", "page": 16},
			{"number": 2, "title": "The Wedding Feast at Cana", "page": 18},
			{"number": 3, "title": "The Proclamation of the Kingdom of God", "page": 20},
			{"number": 4, "title": "The Transfiguration", "page": 22},
			{"number": 5, "title": "The Institution of the Eucharist", "page": 24}
		]
	},
	"sorrowful": {
		"title": "The Sorrowful Mysteries",
		"first_page": 26,
		"decades": [
			{"number": 1, "title": "The Agony in the Garden", "page": 26},
			{"number": 2, "title": "The Scourging at the Pillar", "page": 28},
			{"number": 3, "title": "The Crowning with Thorns", "page": 30},
			{"number": 4, "title": "The Carrying of the Cross", "page": 32},
			{"number": 5, "title": "The Crucifixion and Death of Our Lord", "page": 34}
		]
	},
	"glorious": {
		"title": "The Glorious Mysteries",
		"first_page": 36,
		"decades": [
			{"number": 1, "title": "The Resurrection of Our Lord", "page": 36},
			{"number": 2, "title": "The Ascension of Our Lord into Heaven", "page": 38},
			{"number": 3, "title": "The Descent of the Holy Spirit", "page": 40},
			{"number": 4, "title": "The Assumption of the Blessed Virgin Mary", "page": 42},
			{"number": 5, "title": "The Coronation of the Blessed Virgin Mary", "page": 44}
		]
	}
}

const MYSTERY_SET_ORDER: Array[String] = ["joyful", "luminous", "sorrowful", "glorious"]

var data_loader: RosaryDataLoader = null
var progress_manager: ReadingProgressManager = null

var _is_open: bool = false
var _saved_page: int = 1
var _expanded_mystery_sets: Dictionary = {
	"joyful": false,
	"luminous": false,
	"sorrowful": false,
	"glorious": false
}

var _section_buttons: Dictionary = {}           # String -> Button
var _mystery_set_title_buttons: Dictionary = {}  # String -> Button
var _mystery_set_arrow_buttons: Dictionary = {}  # String -> Button
var _mystery_set_containers: Dictionary = {}     # String -> VBoxContainer
var _mystery_set_badges: Dictionary = {}         # String -> Label
var _mystery_set_badge_panels: Dictionary = {}   # String -> PanelContainer
var _decade_buttons_by_set: Dictionary = {}      # String -> Array[Button]
var _decade_buttons_by_page: Dictionary = {}     # int -> Button

var _font_bold: Font = null
var _font_regular: Font = null
var _font_symbols: Font = null
var _anim_tween: Tween = null
var _is_built: bool = false
var text_size_preset: String = BasePageCard.PRESET_NORMAL
var _mystery_header: Label = null

@onready var floating_button: Button = get_node_or_null("FloatingButton") as Button
@onready var drawer_overlay: Control = get_node_or_null("DrawerOverlay") as Control
@onready var scrim: ColorRect = get_node_or_null("DrawerOverlay/Scrim") as ColorRect
@onready var drawer_panel: PanelContainer = get_node_or_null("DrawerOverlay/DrawerPanel") as PanelContainer
@onready var title_label: Label = get_node_or_null("DrawerOverlay/DrawerPanel/MarginContainer/MainVBox/HeaderHBox/TitleLabel") as Label
@onready var close_button: Button = get_node_or_null("DrawerOverlay/DrawerPanel/MarginContainer/MainVBox/HeaderHBox/CloseButton") as Button
@onready var drawer_scroll: ScrollContainer = get_node_or_null("DrawerOverlay/DrawerPanel/MarginContainer/MainVBox/DrawerScroll") as ScrollContainer
@onready var content_container: VBoxContainer = get_node_or_null("DrawerOverlay/DrawerPanel/MarginContainer/MainVBox/DrawerScroll/ContentContainer") as VBoxContainer
@onready var resume_button: Button = null


func _ready() -> void:
	_ensure_dependencies()
	_load_fonts()
	_resolve_nodes()

	if not _is_built:
		_build_drawer_items()

	_apply_text_size_preset()
	_connect_base_signals()
	update_liturgical_badge()
	update_resume_button()
	_update_overlay_state(false, false)


func _unhandled_input(event: InputEvent) -> void:
	if _is_open and event.is_action_pressed("ui_cancel"):
		close_drawer()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()


func _ensure_dependencies() -> void:
	if data_loader == null:
		data_loader = RosaryDataLoader.new()
		data_loader.load_all()
	elif not data_loader.is_loaded():
		data_loader.load_all()

	if progress_manager == null:
		progress_manager = ReadingProgressManager.new()


func _load_fonts() -> void:
	if ResourceLoader.exists(FONT_SYMBOLS_PATH):
		_font_symbols = load(FONT_SYMBOLS_PATH) as Font

	if ResourceLoader.exists(FONT_BOLD_PATH):
		var base_bold: Font = load(FONT_BOLD_PATH) as Font
		var fv_bold: FontVariation = FontVariation.new()
		fv_bold.base_font = base_bold
		if _font_symbols != null:
			fv_bold.fallbacks = [_font_symbols]
		_font_bold = fv_bold

	if ResourceLoader.exists(FONT_REGULAR_PATH):
		var base_reg: Font = load(FONT_REGULAR_PATH) as Font
		var fv_reg: FontVariation = FontVariation.new()
		fv_reg.base_font = base_reg
		if _font_symbols != null:
			fv_reg.fallbacks = [_font_symbols]
		_font_regular = fv_reg


func _resolve_nodes() -> void:
	if floating_button == null:
		floating_button = get_node_or_null("FloatingButton") as Button
	if floating_button != null:
		if _font_bold != null:
			floating_button.add_theme_font_override("font", _font_bold)
		_calibrate_floating_button_margins()
	if drawer_overlay == null:
		drawer_overlay = get_node_or_null("DrawerOverlay") as Control
	if scrim == null:
		scrim = get_node_or_null("DrawerOverlay/Scrim") as ColorRect
	if drawer_panel == null:
		drawer_panel = get_node_or_null("DrawerOverlay/DrawerPanel") as PanelContainer
	if title_label == null:
		title_label = get_node_or_null("DrawerOverlay/DrawerPanel/MarginContainer/MainVBox/HeaderHBox/TitleLabel") as Label
	if title_label != null and _font_bold != null:
		title_label.add_theme_font_override("font", _font_bold)
	if close_button == null:
		close_button = get_node_or_null("DrawerOverlay/DrawerPanel/MarginContainer/MainVBox/HeaderHBox/CloseButton") as Button
	if close_button != null and _font_bold != null:
		close_button.add_theme_font_override("font", _font_bold)
	if drawer_scroll == null:
		drawer_scroll = get_node_or_null("DrawerOverlay/DrawerPanel/MarginContainer/MainVBox/DrawerScroll") as ScrollContainer
	if drawer_scroll != null:
		drawer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		drawer_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	if content_container == null:
		content_container = get_node_or_null("DrawerOverlay/DrawerPanel/MarginContainer/MainVBox/DrawerScroll/ContentContainer") as VBoxContainer


func _calibrate_floating_button_margins() -> void:
	if floating_button == null:
		return
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var style: StyleBox = floating_button.get_theme_stylebox(state)
		if style != null:
			style.content_margin_left = 0.0
			style.content_margin_top = 12.0
			style.content_margin_right = 0.0
			style.content_margin_bottom = 0.0


func _connect_base_signals() -> void:
	if floating_button != null and not floating_button.pressed.is_connected(toggle_drawer):
		floating_button.pressed.connect(toggle_drawer)

	if close_button != null and not close_button.pressed.is_connected(close_drawer):
		close_button.pressed.connect(close_drawer)

	if scrim != null and not scrim.gui_input.is_connected(_on_scrim_gui_input):
		scrim.gui_input.connect(_on_scrim_gui_input)


func _build_drawer_items() -> void:
	if content_container == null:
		return

	# Clear previous items
	for child: Node in content_container.get_children():
		child.queue_free()

	_section_buttons.clear()
	_mystery_set_title_buttons.clear()
	_mystery_set_arrow_buttons.clear()
	_mystery_set_containers.clear()
	_mystery_set_badges.clear()
	_mystery_set_badge_panels.clear()
	_decade_buttons_by_set.clear()
	_decade_buttons_by_page.clear()

	# 1. Prominent "Resume Last Page" Action Button
	_build_resume_button()

	# 2. Separator
	content_container.add_child(_create_styled_divider())

	# 3. Top Landmark Section Buttons
	_build_landmark_group(LANDMARKS_TOP)

	# 4. Separator
	content_container.add_child(_create_styled_divider())

	# 5. Section Header for Mysteries
	_mystery_header = Label.new()
	_mystery_header.text = "THE TWENTY MYSTERIES"
	if _font_bold != null:
		_mystery_header.add_theme_font_override("font", _font_bold)
	_mystery_header.add_theme_font_size_override("font_size", 15)
	_mystery_header.add_theme_color_override("font_color", COLOR_UMBER)
	content_container.add_child(_mystery_header)

	# 6. Four Expandable Mystery Set Accordion Rows
	for set_id: String in MYSTERY_SET_ORDER:
		_build_mystery_set_row(set_id)

	# 7. Separator
	content_container.add_child(_create_styled_divider())

	# 8. Bottom Landmark Section Buttons
	_build_landmark_group(LANDMARKS_BOTTOM)

	BasePageCard.configure_pass_through_mouse_filters(content_container)
	_apply_text_size_preset()
	_is_built = true


func _build_resume_button() -> void:
	var resume_panel: PanelContainer = PanelContainer.new()
	resume_panel.name = "ResumeSection"

	var style_resume_panel: StyleBoxFlat = StyleBoxFlat.new()
	style_resume_panel.bg_color = Color(0.9608, 0.9412, 0.8980, 1.0)
	style_resume_panel.border_color = COLOR_CRIMSON
	style_resume_panel.border_width_left = 2
	style_resume_panel.border_width_top = 2
	style_resume_panel.border_width_right = 2
	style_resume_panel.border_width_bottom = 2
	style_resume_panel.corner_radius_top_left = 6
	style_resume_panel.corner_radius_top_right = 6
	style_resume_panel.corner_radius_bottom_right = 6
	style_resume_panel.corner_radius_bottom_left = 6
	style_resume_panel.content_margin_left = 12
	style_resume_panel.content_margin_top = 8
	style_resume_panel.content_margin_right = 12
	style_resume_panel.content_margin_bottom = 8
	resume_panel.add_theme_stylebox_override("panel", style_resume_panel)

	resume_button = Button.new()
	resume_button.name = "ResumeButton"
	resume_button.custom_minimum_size = Vector2(0, 46)
	resume_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resume_button.focus_mode = Control.FOCUS_NONE
	resume_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resume_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _font_bold != null:
		resume_button.add_theme_font_override("font", _font_bold)
	resume_button.add_theme_font_size_override("font_size", 17)
	resume_button.add_theme_color_override("font_color", COLOR_CRIMSON)
	resume_button.add_theme_color_override("font_hover_color", COLOR_GOLD_BRIGHT)
	resume_button.add_theme_color_override("font_pressed_color", COLOR_CHARCOAL)

	# Transparent flat button inside the styled container
	var flat_style: StyleBoxEmpty = StyleBoxEmpty.new()
	resume_button.add_theme_stylebox_override("normal", flat_style)
	resume_button.add_theme_stylebox_override("hover", flat_style)
	resume_button.add_theme_stylebox_override("pressed", flat_style)
	resume_button.add_theme_stylebox_override("focus", flat_style)

	resume_button.pressed.connect(_on_resume_button_pressed)
	resume_panel.add_child(resume_button)
	content_container.add_child(resume_panel)


func _build_landmark_group(landmarks: Array[Dictionary]) -> void:
	for lm: Dictionary in landmarks:
		var lm_id: String = str(lm.get("id", ""))
		var lm_label: String = str(lm.get("label", ""))
		var lm_page: int = int(lm.get("page", 1))

		var btn: Button = _create_standard_list_button(lm_label)
		btn.name = "Btn_%s" % lm_id
		btn.pressed.connect(_on_landmark_button_pressed.bind(lm_page))

		_section_buttons[lm_id] = btn
		content_container.add_child(btn)


func _build_mystery_set_row(set_id: String) -> void:
	var set_info: Dictionary = _get_mystery_set_info(set_id)
	var set_title: String = str(set_info.get("title", set_id.capitalize()))
	var first_page: int = int(set_info.get("first_page", 6))
	var decades: Array = set_info.get("decades", [])

	var set_box: VBoxContainer = VBoxContainer.new()
	set_box.name = "MysterySet_%s" % set_id
	set_box.add_theme_constant_override("separation", 4)

	# Dual-Action Row
	var row_hbox: HBoxContainer = HBoxContainer.new()
	row_hbox.name = "DualActionRow"
	row_hbox.add_theme_constant_override("separation", 6)

	# 1. Left Disclosure Arrow Button (▸ / ▾)
	var arrow_btn: Button = Button.new()
	arrow_btn.name = "ArrowButton"
	arrow_btn.custom_minimum_size = Vector2(38, 42)
	arrow_btn.text = "▸"
	arrow_btn.focus_mode = Control.FOCUS_NONE
	if _font_bold != null:
		arrow_btn.add_theme_font_override("font", _font_bold)
	arrow_btn.add_theme_font_size_override("font_size", 18)
	arrow_btn.add_theme_color_override("font_color", COLOR_GOLD)
	arrow_btn.add_theme_color_override("font_hover_color", COLOR_GOLD_BRIGHT)
	_apply_subtle_button_style(arrow_btn)
	arrow_btn.pressed.connect(_on_arrow_button_pressed.bind(set_id))
	_mystery_set_arrow_buttons[set_id] = arrow_btn
	row_hbox.add_child(arrow_btn)

	# 2. Mystery Set Title Button (jumps to 1st mystery and closes drawer)
	var title_btn: Button = Button.new()
	title_btn.name = "TitleButton"
	title_btn.text = set_title
	title_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_btn.custom_minimum_size = Vector2(0, 42)
	title_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_btn.focus_mode = Control.FOCUS_NONE
	title_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _font_bold != null:
		title_btn.add_theme_font_override("font", _font_bold)
	title_btn.add_theme_font_size_override("font_size", 18)
	title_btn.add_theme_color_override("font_color", COLOR_CHARCOAL)
	title_btn.add_theme_color_override("font_hover_color", COLOR_CRIMSON)
	_apply_subtle_button_style(title_btn)
	title_btn.pressed.connect(_on_mystery_set_title_pressed.bind(set_id, first_page))
	_mystery_set_title_buttons[set_id] = title_btn
	row_hbox.add_child(title_btn)

	# 3. Dynamic Liturgical "Recommended Today" Badge
	var badge_panel: PanelContainer = PanelContainer.new()
	badge_panel.name = "BadgePanel"
	var badge_style: StyleBoxFlat = StyleBoxFlat.new()
	badge_style.bg_color = Color(0.7216, 0.5686, 0.1882, 0.18)
	badge_style.border_color = COLOR_GOLD
	badge_style.border_width_left = 1
	badge_style.border_width_top = 1
	badge_style.border_width_right = 1
	badge_style.border_width_bottom = 1
	badge_style.corner_radius_top_left = 3
	badge_style.corner_radius_top_right = 3
	badge_style.corner_radius_bottom_right = 3
	badge_style.corner_radius_bottom_left = 3
	badge_style.content_margin_left = 6
	badge_style.content_margin_top = 2
	badge_style.content_margin_right = 6
	badge_style.content_margin_bottom = 2
	badge_panel.add_theme_stylebox_override("panel", badge_style)
	badge_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge_panel.visible = false

	var badge_lbl: Label = Label.new()
	badge_lbl.name = "BadgeLabel"
	badge_lbl.text = "★ Today"
	if _font_bold != null:
		badge_lbl.add_theme_font_override("font", _font_bold)
	badge_lbl.add_theme_font_size_override("font_size", 13)
	badge_lbl.add_theme_color_override("font_color", COLOR_GOLD_BRIGHT)
	badge_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge_panel.add_child(badge_lbl)

	_mystery_set_badges[set_id] = badge_lbl
	_mystery_set_badge_panels[set_id] = badge_panel
	row_hbox.add_child(badge_panel)

	set_box.add_child(row_hbox)

	# 4. Decades Sub-Container (Indented 5 Mysteries, initially collapsed)
	var decades_margin: MarginContainer = MarginContainer.new()
	decades_margin.name = "DecadesMargin"
	decades_margin.add_theme_constant_override("margin_left", 32)
	decades_margin.add_theme_constant_override("margin_top", 2)
	decades_margin.add_theme_constant_override("margin_bottom", 4)

	var decades_vbox: VBoxContainer = VBoxContainer.new()
	decades_vbox.name = "DecadesVBox"
	decades_vbox.add_theme_constant_override("separation", 2)
	decades_margin.add_child(decades_vbox)

	var decade_btns: Array[Button] = []
	for dec_val: Variant in decades:
		if not (dec_val is Dictionary):
			continue
		var dec_dict: Dictionary = dec_val as Dictionary
		var num: int = int(dec_dict.get("number", 1))
		var title: String = str(dec_dict.get("title", ""))
		var page: int = int(dec_dict.get("page", first_page))

		var dec_btn: Button = Button.new()
		dec_btn.name = "Decade_%d" % num
		dec_btn.text = "%d. %s" % [num, title]
		dec_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dec_btn.custom_minimum_size = Vector2(0, 36)
		dec_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		dec_btn.focus_mode = Control.FOCUS_NONE
		dec_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if _font_regular != null:
			dec_btn.add_theme_font_override("font", _font_regular)
		dec_btn.add_theme_font_size_override("font_size", 16)
		dec_btn.add_theme_color_override("font_color", COLOR_CHARCOAL)
		dec_btn.add_theme_color_override("font_hover_color", COLOR_CRIMSON)
		_apply_subtle_button_style(dec_btn)
		dec_btn.pressed.connect(_on_decade_button_pressed.bind(page))

		decade_btns.append(dec_btn)
		_decade_buttons_by_page[page] = dec_btn
		decades_vbox.add_child(dec_btn)

	_decade_buttons_by_set[set_id] = decade_btns
	_mystery_set_containers[set_id] = decades_vbox

	# Keep sub-list collapsed initially
	decades_margin.visible = false
	set_box.add_child(decades_margin)

	content_container.add_child(set_box)


func _create_standard_list_button(label_text: String) -> Button:
	var btn: Button = Button.new()
	btn.text = label_text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 40)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.focus_mode = Control.FOCUS_NONE
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _font_bold != null:
		btn.add_theme_font_override("font", _font_bold)
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", COLOR_CHARCOAL)
	btn.add_theme_color_override("font_hover_color", COLOR_CRIMSON)
	btn.add_theme_color_override("font_pressed_color", COLOR_CRIMSON)
	_apply_subtle_button_style(btn)
	return btn


func _apply_subtle_button_style(btn: Button) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.9804, 0.9647, 0.9333, 0.5)
	normal.border_color = Color(0.7216, 0.5686, 0.1882, 0.3)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_right = 4
	normal.corner_radius_bottom_left = 4
	normal.content_margin_left = 10
	normal.content_margin_top = 4
	normal.content_margin_right = 10
	normal.content_margin_bottom = 4

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1.0, 0.9922, 0.9725, 1.0)
	hover.border_color = COLOR_GOLD_BRIGHT
	hover.border_width_left = 2
	hover.border_width_top = 2
	hover.border_width_right = 2
	hover.border_width_bottom = 2

	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = COLOR_PARCHMENT_ALT
	pressed.border_color = COLOR_CRIMSON

	var empty_focus: StyleBoxEmpty = StyleBoxEmpty.new()

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", empty_focus)


func _create_styled_divider() -> ColorRect:
	var divider: ColorRect = ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 1)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	divider.color = Color(0.7216, 0.5686, 0.1882, 0.45)
	return divider


func _get_mystery_set_info(set_id: String) -> Dictionary:
	if data_loader != null and data_loader.is_loaded():
		var set_dict: Dictionary = data_loader.get_mystery_set(set_id)
		if not set_dict.is_empty():
			var title_str: String = str(set_dict.get("title", ""))
			var decades_raw: Array = set_dict.get("decades", [])
			var formatted_decades: Array[Dictionary] = []
			var first_p: int = 6

			for i: int in range(decades_raw.size()):
				var dec_raw: Variant = decades_raw[i]
				if dec_raw is Dictionary:
					var dec_dict: Dictionary = dec_raw as Dictionary
					var page_num: int = int(dec_dict.get("left_page_number", 6 + i * 2))
					if i == 0:
						first_p = page_num
					formatted_decades.append({
						"number": int(dec_dict.get("decade_number", i + 1)),
						"title": str(dec_dict.get("title", "")),
						"page": page_num
					})

			return {
				"title": title_str,
				"first_page": first_p,
				"decades": formatted_decades
			}

	return MYSTERY_SET_DEFAULTS.get(set_id, {})


# --- Public Navigation & Open/Close API ---

func is_open() -> bool:
	return _is_open


func open_drawer(animate: bool = true) -> void:
	_is_open = true
	update_liturgical_badge()
	update_resume_button()
	_update_overlay_state(true, animate)
	drawer_opened.emit()


func close_drawer(animate: bool = true) -> void:
	_is_open = false
	_update_overlay_state(false, animate)
	drawer_closed.emit()


func toggle_drawer(animate: bool = true) -> void:
	if _is_open:
		close_drawer(animate)
	else:
		open_drawer(animate)


func _update_overlay_state(open: bool, animate: bool) -> void:
	if drawer_overlay == null or drawer_panel == null or scrim == null:
		return

	if _anim_tween != null and _anim_tween.is_valid():
		_anim_tween.kill()

	var is_headless: bool = (DisplayServer.get_name() == "headless")
	var panel_width: float = get_panel_width()
	drawer_panel.custom_minimum_size.x = panel_width

	if not animate or is_headless:
		drawer_overlay.visible = open
		scrim.modulate.a = 1.0 if open else 0.0
		drawer_panel.offset_left = -panel_width if open else 0.0
		drawer_panel.offset_right = 0.0 if open else panel_width
		return

	if open:
		drawer_overlay.visible = true
		scrim.modulate.a = 0.0
		drawer_panel.offset_left = 0.0
		drawer_panel.offset_right = panel_width

		_anim_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_anim_tween.tween_property(scrim, "modulate:a", 1.0, 0.22)
		_anim_tween.tween_property(drawer_panel, "offset_left", -panel_width, 0.22)
		_anim_tween.tween_property(drawer_panel, "offset_right", 0.0, 0.22)
	else:
		_anim_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_anim_tween.tween_property(scrim, "modulate:a", 0.0, 0.18)
		_anim_tween.tween_property(drawer_panel, "offset_left", 0.0, 0.18)
		_anim_tween.tween_property(drawer_panel, "offset_right", panel_width, 0.18)
		_anim_tween.chain().tween_callback(func() -> void:
			if not _is_open:
				drawer_overlay.visible = false
		)


# --- Accordion Expansion API ---

func is_mystery_set_expanded(set_id: String) -> bool:
	return _expanded_mystery_sets.get(set_id, false)


func toggle_mystery_set_expanded(set_id: String) -> void:
	var current: bool = is_mystery_set_expanded(set_id)
	set_mystery_set_expanded(set_id, not current)


func set_mystery_set_expanded(set_id: String, expanded: bool) -> void:
	_expanded_mystery_sets[set_id] = expanded

	var arrow_btn: Button = _mystery_set_arrow_buttons.get(set_id)
	if arrow_btn != null:
		arrow_btn.text = "▾" if expanded else "▸"

	var sub_vbox: VBoxContainer = _mystery_set_containers.get(set_id)
	if sub_vbox != null:
		var parent_margin: MarginContainer = sub_vbox.get_parent() as MarginContainer
		if parent_margin != null:
			parent_margin.visible = expanded
		else:
			sub_vbox.visible = expanded


# --- Liturgical Recommendation Badge API ---

func get_recommended_mystery_set() -> String:
	if data_loader != null:
		return data_loader.get_recommended_mystery_set_for_today()
	return "joyful"


func is_mystery_set_recommended(set_id: String) -> bool:
	return set_id == get_recommended_mystery_set()


func update_liturgical_badge() -> void:
	var rec_set: String = get_recommended_mystery_set()
	for set_id: String in MYSTERY_SET_ORDER:
		var is_rec: bool = (set_id == rec_set)
		var panel: PanelContainer = _mystery_set_badge_panels.get(set_id)
		if panel != null:
			panel.visible = is_rec
		var lbl: Label = _mystery_set_badges.get(set_id)
		if lbl != null:
			lbl.visible = is_rec


# --- Reading Progress & Resume Button API ---

func update_resume_button() -> void:
	if progress_manager != null:
		_saved_page = progress_manager.load_progress()
	else:
		_saved_page = 1

	_saved_page = clampi(_saved_page, 1, 50)
	var title: String = get_page_title(_saved_page)
	if resume_button != null:
		resume_button.text = "Resume Last Page: %s (Page %d)" % [title, _saved_page]


func get_saved_page() -> int:
	return _saved_page


func set_saved_page(page: int) -> void:
	_saved_page = clampi(page, 1, 50)
	var title: String = get_page_title(_saved_page)
	if resume_button != null:
		resume_button.text = "Resume Last Page: %s (Page %d)" % [title, _saved_page]


func get_page_title(page_number: int) -> String:
	match page_number:
		1:
			return "Front Cover"
		2:
			return "The History of the Holy Rosary"
		3:
			return "Structure of This Book & How to Pray"
		4:
			return "The Opening Prayers"
		46:
			return "The Closing Prayers"
		48:
			return "Sacred Artwork Credits"
		50:
			return "Back Cover"

	_ensure_dependencies()
	if data_loader != null and data_loader.is_loaded():
		var page_data: Dictionary = data_loader.get_page(page_number)
		if not page_data.is_empty():
			var heading: String = str(page_data.get("heading", ""))
			if heading != "":
				return heading
			var title: String = str(page_data.get("title", ""))
			if title != "":
				return title

	return "Page %d" % page_number


# --- Dependency Injection & Accessors ---

func set_text_size_preset(preset: Variant) -> void:
	text_size_preset = BasePageCard.normalize_preset(preset)
	_apply_text_size_preset()


func get_text_size_preset() -> String:
	return text_size_preset


func get_panel_width() -> float:
	match text_size_preset:
		BasePageCard.PRESET_MOBILE:
			return PANEL_WIDTH_MOBILE
		BasePageCard.PRESET_EXTRA_LARGE:
			return PANEL_WIDTH_EXTRA_LARGE
		_:
			return PANEL_WIDTH_NORMAL


func _apply_text_size_preset() -> void:
	var panel_width: float = get_panel_width()
	if drawer_panel != null:
		drawer_panel.custom_minimum_size.x = panel_width
		if _anim_tween != null and _anim_tween.is_valid():
			_anim_tween.kill()
		if _is_open:
			drawer_panel.offset_left = -panel_width
			drawer_panel.offset_right = 0.0
		else:
			drawer_panel.offset_left = 0.0
			drawer_panel.offset_right = panel_width

	# 1. TitleLabel ("Table of Contents"): 24pt / 32pt / 38pt
	if title_label != null:
		var title_font_size: int = 24
		match text_size_preset:
			BasePageCard.PRESET_MOBILE:
				title_font_size = 32
			BasePageCard.PRESET_EXTRA_LARGE:
				title_font_size = 38
			_:
				title_font_size = 24
		title_label.add_theme_font_size_override("font_size", title_font_size)

	# 2. CloseButton ("✕"): 22pt (40×40) / 28pt (48×48) / 34pt (56×56)
	if close_button != null:
		var close_font_size: int = 22
		var close_btn_size: Vector2 = Vector2(40, 40)
		match text_size_preset:
			BasePageCard.PRESET_MOBILE:
				close_font_size = 28
				close_btn_size = Vector2(48, 48)
			BasePageCard.PRESET_EXTRA_LARGE:
				close_font_size = 34
				close_btn_size = Vector2(56, 56)
			_:
				close_font_size = 22
				close_btn_size = Vector2(40, 40)
		close_button.add_theme_font_size_override("font_size", close_font_size)
		close_button.custom_minimum_size = close_btn_size

	# 3. ResumeButton: 17pt (min height 46) / 24pt (min height 58) / 30pt (min height 72), autowrap
	if resume_button != null:
		var resume_font_size: int = 17
		var resume_min_h: float = 46.0
		match text_size_preset:
			BasePageCard.PRESET_MOBILE:
				resume_font_size = 24
				resume_min_h = 58.0
			BasePageCard.PRESET_EXTRA_LARGE:
				resume_font_size = 30
				resume_min_h = 72.0
			_:
				resume_font_size = 17
				resume_min_h = 46.0
		resume_button.add_theme_font_size_override("font_size", resume_font_size)
		resume_button.custom_minimum_size = Vector2(0, resume_min_h)
		resume_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# 4. Landmark section buttons (_section_buttons): 17pt (min height 40) / 24pt (min height 52) / 30pt (min height 64), autowrap
	var landmark_font_size: int = 17
	var landmark_min_h: float = 40.0
	match text_size_preset:
		BasePageCard.PRESET_MOBILE:
			landmark_font_size = 24
			landmark_min_h = 52.0
		BasePageCard.PRESET_EXTRA_LARGE:
			landmark_font_size = 30
			landmark_min_h = 64.0
		_:
			landmark_font_size = 17
			landmark_min_h = 40.0
	for btn: Button in _section_buttons.values():
		if btn != null:
			btn.add_theme_font_size_override("font_size", landmark_font_size)
			btn.custom_minimum_size = Vector2(0, landmark_min_h)
			btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# 5. "THE TWENTY MYSTERIES" header (mystery_header): 15pt / 20pt / 25pt
	if _mystery_header != null:
		var header_font_size: int = 15
		match text_size_preset:
			BasePageCard.PRESET_MOBILE:
				header_font_size = 20
			BasePageCard.PRESET_EXTRA_LARGE:
				header_font_size = 25
			_:
				header_font_size = 15
		_mystery_header.add_theme_font_size_override("font_size", header_font_size)

	# 6. Mystery Set TitleButton & ArrowButton: 18pt (min height 42, arrow 38×42) / 25pt (min height 54, arrow 48×54) / 31pt (min height 66, arrow 56×66), autowrap on TitleButton
	var set_font_size: int = 18
	var set_min_h: float = 42.0
	var arrow_size: Vector2 = Vector2(38, 42)
	match text_size_preset:
		BasePageCard.PRESET_MOBILE:
			set_font_size = 25
			set_min_h = 54.0
			arrow_size = Vector2(48, 54)
		BasePageCard.PRESET_EXTRA_LARGE:
			set_font_size = 31
			set_min_h = 66.0
			arrow_size = Vector2(56, 66)
		_:
			set_font_size = 18
			set_min_h = 42.0
			arrow_size = Vector2(38, 42)
	for title_btn: Button in _mystery_set_title_buttons.values():
		if title_btn != null:
			title_btn.add_theme_font_size_override("font_size", set_font_size)
			title_btn.custom_minimum_size = Vector2(0, set_min_h)
			title_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for arrow_btn: Button in _mystery_set_arrow_buttons.values():
		if arrow_btn != null:
			arrow_btn.add_theme_font_size_override("font_size", set_font_size)
			arrow_btn.custom_minimum_size = arrow_size

	# 7. Liturgical "★ Today" BadgeLabel: 13pt / 18pt / 22pt
	var badge_font_size: int = 13
	match text_size_preset:
		BasePageCard.PRESET_MOBILE:
			badge_font_size = 18
		BasePageCard.PRESET_EXTRA_LARGE:
			badge_font_size = 22
		_:
			badge_font_size = 13
	for badge_lbl: Label in _mystery_set_badges.values():
		if badge_lbl != null:
			badge_lbl.add_theme_font_size_override("font_size", badge_font_size)

	# 8. Individual Mystery decade buttons (Decade_1..5): 16pt (min height 36) / 22pt (min height 48) / 28pt (min height 58), autowrap
	var decade_font_size: int = 16
	var decade_min_h: float = 36.0
	match text_size_preset:
		BasePageCard.PRESET_MOBILE:
			decade_font_size = 22
			decade_min_h = 48.0
		BasePageCard.PRESET_EXTRA_LARGE:
			decade_font_size = 28
			decade_min_h = 58.0
		_:
			decade_font_size = 16
			decade_min_h = 36.0
	for decade_btn: Button in _decade_buttons_by_page.values():
		if decade_btn != null:
			decade_btn.add_theme_font_size_override("font_size", decade_font_size)
			decade_btn.custom_minimum_size = Vector2(0, decade_min_h)
			decade_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func set_data_loader(loader: RosaryDataLoader) -> void:
	data_loader = loader
	if _is_built:
		update_liturgical_badge()
		update_resume_button()


func set_progress_manager(manager: ReadingProgressManager) -> void:
	progress_manager = manager
	update_resume_button()


func get_title_label() -> Label:
	return title_label


func get_mystery_header() -> Label:
	return _mystery_header


func get_floating_button() -> Button:
	return floating_button


func get_close_button() -> Button:
	return close_button


func get_scrim() -> ColorRect:
	return scrim


func get_drawer_panel() -> PanelContainer:
	return drawer_panel


func get_resume_button() -> Button:
	return resume_button


func get_section_button(section_id: String) -> Button:
	return _section_buttons.get(section_id)


func get_mystery_set_title_button(set_id: String) -> Button:
	return _mystery_set_title_buttons.get(set_id)


func get_mystery_set_arrow_button(set_id: String) -> Button:
	return _mystery_set_arrow_buttons.get(set_id)


func get_mystery_set_container(set_id: String) -> VBoxContainer:
	return _mystery_set_containers.get(set_id)


func get_mystery_set_badge_label(set_id: String) -> Label:
	return _mystery_set_badges.get(set_id)


func get_mystery_button(set_id: String, decade_index: int) -> Button:
	var btns: Array = _decade_buttons_by_set.get(set_id, [])
	if decade_index >= 0 and decade_index < btns.size():
		return btns[decade_index] as Button
	return null


func get_mystery_button_by_page(page_number: int) -> Button:
	return _decade_buttons_by_page.get(page_number)


func get_first_page_for_mystery_set(set_id: String) -> int:
	var info: Dictionary = _get_mystery_set_info(set_id)
	return int(info.get("first_page", 6))


func get_font_bold() -> Font:
	return _font_bold


func get_font_regular() -> Font:
	return _font_regular


func get_font_symbols() -> Font:
	return _font_symbols


# --- Internal Signal Handlers ---

func _on_scrim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_drawer()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		close_drawer()
		if get_viewport() != null:
			get_viewport().set_input_as_handled()


func _on_resume_button_pressed() -> void:
	page_requested.emit(_saved_page)
	close_drawer()


func _on_landmark_button_pressed(page_number: int) -> void:
	page_requested.emit(page_number)
	close_drawer()


func _on_arrow_button_pressed(set_id: String) -> void:
	toggle_mystery_set_expanded(set_id)


func _on_mystery_set_title_pressed(set_id: String, first_page: int) -> void:
	page_requested.emit(first_page)
	close_drawer()


func _on_decade_button_pressed(page_number: int) -> void:
	page_requested.emit(page_number)
	close_drawer()
