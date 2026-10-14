class_name BasePageCard
extends AspectRatioContainer
## Base class for 2:3 portrait page cards in the Pray The Rosary application.
## Enforces 2:3 aspect ratio, responsive dimensions, and zero visible page numbers.

const ASPECT_RATIO: float = 2.0 / 3.0
const DESIGN_WIDTH: float = 720.0
const DESIGN_HEIGHT: float = 1080.0
const DESIGN_SIZE: Vector2 = Vector2(DESIGN_WIDTH, DESIGN_HEIGHT)

# Canonical Rosary Palette Colors
const COLOR_PARCHMENT: Color = Color("FAF6EE")
const COLOR_CHARCOAL: Color = Color("1E1815")
const COLOR_CRIMSON: Color = Color("6B1D21")
const COLOR_UMBER: Color = Color("5C4338")
const COLOR_ANTIQUE_GOLD: Color = Color("B89130")
const COLOR_COVER_CRIMSON: Color = Color("4A1215")
const COLOR_COVER_DARK: Color = Color("2A090B")
const COLOR_COVER_GOLD: Color = Color("D4AF37")
const COLOR_COVER_IVORY: Color = Color("F7F2E7")

var page_number: int = 0
var page_type: String = ""
var page_data: Dictionary = {}
var data_loader: RosaryDataLoader = null


func _init() -> void:
	ratio = ASPECT_RATIO
	alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	custom_minimum_size = DESIGN_SIZE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_PASS


func bind_page_data(data: Dictionary, loader: RosaryDataLoader = null) -> void:
	page_data = data
	data_loader = loader
	page_number = int(data.get("page_number", 0))
	page_type = str(data.get("page_type", ""))
	_apply_page_data()
	configure_pass_through_mouse_filters(self)


func set_page_data(data: Dictionary, loader: RosaryDataLoader = null) -> void:
	bind_page_data(data, loader)


func _apply_page_data() -> void:
	# Virtual method implemented by subclasses
	pass


static func configure_pass_through_mouse_filters(node: Node) -> void:
	if node == null:
		return
	if node is BaseButton:
		(node as BaseButton).mouse_filter = Control.MOUSE_FILTER_PASS
	elif node is Control:
		var ctrl: Control = node as Control
		if ctrl is Label or ctrl is TextureRect or ctrl is ColorRect:
			ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			ctrl.mouse_filter = Control.MOUSE_FILTER_PASS
	for child: Node in node.get_children():
		configure_pass_through_mouse_filters(child)


func get_heading_text() -> String:
	return str(page_data.get("heading", page_data.get("title", "")))


func get_subheading_text() -> String:
	return str(page_data.get("subheading", page_data.get("subtitle", "")))


func has_visible_page_number() -> bool:
	return false
