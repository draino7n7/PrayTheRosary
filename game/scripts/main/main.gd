class_name Main
extends Control
## Main application controller for Pray The Rosary.
## Orchestrates the continuous 50-page vertical scroll view, in-stream quick-jump bars,
## reading progress persistence (user://reading_progress.cfg), and texture virtualization.

signal page_changed(new_page_number: int)

const TOTAL_PAGES: int = 50
const ARTWORK_BUFFER_PAGES: int = 4
const WHEEL_SCROLL_STEP: int = 80
const COLOR_AMBIENT_ESPRESSO: Color = Color(0.0784314, 0.0627451, 0.0627451, 1.0) # #141010

const PAGE_CARD_SCENE: PackedScene = preload("res://scenes/ui/page_card.tscn")
const JUMP_BAR_SCENE: PackedScene = preload("res://scenes/ui/in_stream_jump_bar.tscn")

var data_loader: RosaryDataLoader = null
var progress_manager: ReadingProgressManager = null

var _page_cards: Dictionary = {} # int -> PageCard
var _jump_bars: Array[InStreamJumpBar] = []
var _stream_elements: Array[Node] = []
var _current_page: int = 1
var _scroll_tween: Tween = null
var _save_timer: Timer = null
var _is_restoring_initial_page: bool = false
var _is_initialized: bool = false

@onready var background: ColorRect = get_node_or_null("Background") as ColorRect
@onready var scroll_container: ScrollContainer = get_node_or_null("ScrollContainer") as ScrollContainer
@onready var page_container: VBoxContainer = get_node_or_null("ScrollContainer/PageContainer") as VBoxContainer
@onready var navigation_drawer: NavigationDrawer = get_node_or_null("NavigationDrawer") as NavigationDrawer


func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.screen_set_keep_on(true)

	_ensure_initialized()
	_setup_save_timer()
	_setup_scroll_listening()
	_setup_navigation_drawer()

	if _page_cards.is_empty():
		build_scroll_stream()

	var saved_page: int = progress_manager.load_progress()
	if saved_page > 1:
		_is_restoring_initial_page = true
		call_deferred("_restore_saved_page", saved_page)
	else:
		_update_virtualization(1)


func _input(event: InputEvent) -> void:
	if navigation_drawer == null or not navigation_drawer.is_open():
		handle_scroll_input(event)


func handle_scroll_input(event: InputEvent) -> void:
	_ensure_initialized()
	if event == null or scroll_container == null:
		return
	if navigation_drawer != null and navigation_drawer.is_open():
		return

	var delta_y: int = 0
	if event is InputEventScreenDrag:
		var drag_event: InputEventScreenDrag = event as InputEventScreenDrag
		delta_y = -int(round(drag_event.relative.y))
	elif event is InputEventMouseMotion:
		var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
		if (motion_event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			delta_y = -int(round(motion_event.relative.y))
	elif event is InputEventMouseButton:
		var button_event: InputEventMouseButton = event as InputEventMouseButton
		if button_event.pressed:
			var factor: float = button_event.factor if button_event.factor > 0.0 else 1.0
			if button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				delta_y = int(round(float(WHEEL_SCROLL_STEP) * factor))
			elif button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
				delta_y = -int(round(float(WHEEL_SCROLL_STEP) * factor))

	if delta_y == 0:
		return

	if _scroll_tween != null and _scroll_tween.is_valid():
		_scroll_tween.kill()

	var max_scroll: int = _get_max_scroll_vertical()
	scroll_container.scroll_vertical = clampi(scroll_container.scroll_vertical + delta_y, 0, max_scroll)


func _get_max_scroll_vertical() -> int:
	if scroll_container == null:
		return 0
	var fallback_max: int = get_target_scroll_for_page(TOTAL_PAGES)
	var v_bar: VScrollBar = scroll_container.get_v_scroll_bar()
	if v_bar != null:
		var min_required_max: float = float(fallback_max) + maxf(scroll_container.size.y, 1280.0)
		if v_bar.max_value < min_required_max:
			v_bar.max_value = min_required_max
		var bar_max: int = int(maxf(0.0, v_bar.max_value - v_bar.page))
		return maxi(bar_max, fallback_max)
	return fallback_max


func _ensure_initialized() -> void:
	if scroll_container == null:
		scroll_container = get_node_or_null("ScrollContainer") as ScrollContainer
	if page_container == null:
		page_container = get_node_or_null("ScrollContainer/PageContainer") as VBoxContainer
	if background == null:
		background = get_node_or_null("Background") as ColorRect
	if navigation_drawer == null:
		navigation_drawer = get_node_or_null("NavigationDrawer") as NavigationDrawer

	if progress_manager == null:
		progress_manager = ReadingProgressManager.new()

	if data_loader == null:
		data_loader = RosaryDataLoader.new()
		data_loader.load_all()
	elif not data_loader.is_loaded():
		data_loader.load_all()

	_is_initialized = true


func _setup_navigation_drawer() -> void:
	_ensure_initialized()
	if scroll_container != null:
		scroll_container.mouse_filter = Control.MOUSE_FILTER_STOP
	if navigation_drawer != null:
		navigation_drawer.set_data_loader(data_loader)
		navigation_drawer.set_progress_manager(progress_manager)
		if not navigation_drawer.page_requested.is_connected(_on_navigation_drawer_page_requested):
			navigation_drawer.page_requested.connect(_on_navigation_drawer_page_requested)
		if not navigation_drawer.drawer_opened.is_connected(_on_drawer_opened):
			navigation_drawer.drawer_opened.connect(_on_drawer_opened)
		if not navigation_drawer.drawer_closed.is_connected(_on_drawer_closed):
			navigation_drawer.drawer_closed.connect(_on_drawer_closed)


func _setup_save_timer() -> void:
	if _save_timer == null:
		_save_timer = Timer.new()
		_save_timer.name = "SaveDebounceTimer"
		_save_timer.one_shot = true
		_save_timer.wait_time = 0.6
		_save_timer.timeout.connect(_on_save_timer_timeout)
		add_child(_save_timer)


func _setup_scroll_listening() -> void:
	_ensure_initialized()
	if scroll_container != null:
		scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		var v_bar: VScrollBar = scroll_container.get_v_scroll_bar()
		if v_bar != null and not v_bar.value_changed.is_connected(_on_scroll_value_changed):
			v_bar.value_changed.connect(_on_scroll_value_changed)


func build_scroll_stream() -> void:
	_ensure_initialized()
	if page_container == null:
		push_error("Main: PageContainer node not found in scene tree")
		return

	page_container.mouse_filter = Control.MOUSE_FILTER_PASS

	# Clear any existing elements
	for child: Node in page_container.get_children():
		child.queue_free()
	_page_cards.clear()
	_jump_bars.clear()
	_stream_elements.clear()

	var all_pages: Array[Dictionary] = data_loader.get_all_pages()
	var separators: Array = data_loader.get_in_stream_separators()

	var seps_by_page: Dictionary = {}
	for sep_val: Variant in separators:
		if sep_val is Dictionary:
			var sep_dict: Dictionary = sep_val as Dictionary
			var after_p: int = int(sep_dict.get("after_page_number", -1))
			seps_by_page[after_p] = sep_dict

	for page_data: Dictionary in all_pages:
		var p_num: int = int(page_data.get("page_number", 0))

		# 1. Instantiate PageCard
		var card: PageCard = PAGE_CARD_SCENE.instantiate() as PageCard
		card.name = "Page_%d" % p_num
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		page_container.add_child(card)
		card.bind_page_data(page_data, data_loader)
		_page_cards[p_num] = card
		_stream_elements.append(card)

		# 2. Check for In-Stream Jump Bar immediately following this page
		if seps_by_page.has(p_num):
			var sep_data: Dictionary = seps_by_page[p_num]
			var jump_bar: InStreamJumpBar = JUMP_BAR_SCENE.instantiate() as InStreamJumpBar
			var sep_id: String = str(sep_data.get("id", "separator"))
			jump_bar.name = "Separator_%s" % sep_id
			jump_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			page_container.add_child(jump_bar)
			jump_bar.bind_separator_data(sep_data, data_loader)
			jump_bar.jump_requested.connect(_on_jump_requested)
			_jump_bars.append(jump_bar)
			_stream_elements.append(jump_bar)

	_get_max_scroll_vertical()


func _restore_saved_page(saved_page: int) -> void:
	_is_restoring_initial_page = false
	scroll_to_page(saved_page, false)


func scroll_to_page(page_number: int, animate: bool = true) -> void:
	_ensure_initialized()
	var clamped_page: int = clampi(page_number, 1, TOTAL_PAGES)
	var target_y: int = get_target_scroll_for_page(clamped_page)

	_current_page = clamped_page
	_update_virtualization(_current_page)
	if progress_manager != null:
		progress_manager.save_progress(_current_page)
	if navigation_drawer != null:
		navigation_drawer.set_saved_page(_current_page)
	page_changed.emit(_current_page)

	if scroll_container == null:
		return

	_get_max_scroll_vertical()

	if not animate or DisplayServer.get_name() == "headless":
		scroll_container.scroll_vertical = target_y
	else:
		if _scroll_tween != null and _scroll_tween.is_valid():
			_scroll_tween.kill()
		_scroll_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_scroll_tween.tween_property(scroll_container, "scroll_vertical", target_y, 0.45)


func get_target_scroll_for_page(page_number: int) -> int:
	_ensure_initialized()
	var clamped_page: int = clampi(page_number, 1, TOTAL_PAGES)
	if clamped_page == 1:
		return 0

	var card: PageCard = _page_cards.get(clamped_page)
	if card == null:
		return 0

	# When the node is already laid out by Godot's UI pipeline:
	if card.position.y > 0.0:
		return int(card.position.y)

	# Accurate fallback for headless testing where engine drawing passes are bypassed:
	if page_container == null:
		return 0

	var offset: float = 0.0
	var separation: float = float(page_container.get_theme_constant("separation"))
	for child: Node in page_container.get_children():
		if child == card:
			break
		if child is PageCard:
			offset += BasePageCard.DESIGN_HEIGHT + separation
		elif child is Control:
			offset += (child as Control).get_combined_minimum_size().y + separation
	return int(offset)


func get_current_page_number() -> int:
	_ensure_initialized()
	if _page_cards.is_empty():
		return 1

	var scroll_y: float = float(scroll_container.scroll_vertical) if scroll_container != null else 0.0
	var viewport_h: float = scroll_container.size.y if scroll_container != null else 1280.0
	var probe_y: float = scroll_y + maxf(viewport_h * 0.35, 120.0)

	var active_page: int = 1
	for p_num: int in range(1, TOTAL_PAGES + 1):
		var card: PageCard = _page_cards.get(p_num)
		if card == null:
			continue
		var card_top: float = card.position.y
		if card_top == 0.0 and p_num > 1:
			card_top = float(get_target_scroll_for_page(p_num))

		if card_top <= probe_y:
			active_page = p_num
		else:
			break

	return active_page


func _on_scroll_value_changed(_value: float) -> void:
	if _is_restoring_initial_page:
		return

	var active_page: int = get_current_page_number()
	if active_page != _current_page:
		_current_page = active_page
		_update_virtualization(_current_page)
		if navigation_drawer != null:
			navigation_drawer.set_saved_page(_current_page)
		page_changed.emit(_current_page)

		if _save_timer != null:
			_save_timer.start()


func _on_save_timer_timeout() -> void:
	if progress_manager != null:
		progress_manager.save_progress(_current_page)


func _on_jump_requested(target_page: int) -> void:
	scroll_to_page(target_page, true)


func _on_navigation_drawer_page_requested(target_page: int) -> void:
	scroll_to_page(target_page, true)


func _on_drawer_opened() -> void:
	if scroll_container != null:
		scroll_container.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_drawer_closed() -> void:
	if scroll_container != null:
		scroll_container.mouse_filter = Control.MOUSE_FILTER_STOP


func _update_virtualization(active_page: int) -> void:
	for p_num: int in _page_cards.keys():
		var card: PageCard = _page_cards[p_num]
		if abs(p_num - active_page) <= ARTWORK_BUFFER_PAGES:
			card.load_artwork()
		else:
			card.unload_artwork()


# Public inspector accessors for automated testing & QA:

func get_page_card(page_number: int) -> PageCard:
	return _page_cards.get(page_number)


func get_jump_bars() -> Array[InStreamJumpBar]:
	return _jump_bars


func get_stream_element_count() -> int:
	return _stream_elements.size()


func get_stream_elements() -> Array[Node]:
	return _stream_elements


func get_current_page() -> int:
	return _current_page


func get_navigation_drawer() -> NavigationDrawer:
	return navigation_drawer

