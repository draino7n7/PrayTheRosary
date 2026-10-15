class_name PageCard
extends BasePageCard
## Master reusable 2:3 portrait page card component for all 50 sequential pages in Pray The Rosary.
## Dynamically hosts the specialized sub-card component for any of the 6 conceptual page types.

const COVER_SCENE: PackedScene = preload("res://scenes/ui/pages/cover_page_card.tscn")
const FRONT_MATTER_SCENE: PackedScene = preload("res://scenes/ui/pages/front_matter_page_card.tscn")
const PRAYER_SEQUENCE_SCENE: PackedScene = preload("res://scenes/ui/pages/prayer_sequence_page_card.tscn")
const MYSTERY_PRAYER_SCENE: PackedScene = preload("res://scenes/ui/pages/mystery_prayer_page_card.tscn")
const ARTWORK_SCENE: PackedScene = preload("res://scenes/ui/pages/artwork_page_card.tscn")
const CREDITS_SCENE: PackedScene = preload("res://scenes/ui/pages/credits_page_card.tscn")
const BACK_COVER_SCENE: PackedScene = preload("res://scenes/ui/pages/back_cover_page_card.tscn")

var current_sub_card: BasePageCard = null


static func create_for_page(data: Dictionary, loader: RosaryDataLoader = null) -> PageCard:
	var card: PageCard = PageCard.new()
	card.bind_page_data(data, loader)
	return card


func _ready() -> void:
	if not page_data.is_empty() and current_sub_card == null:
		_apply_page_data()
	configure_pass_through_mouse_filters(self)


func _apply_page_data() -> void:
	if current_sub_card != null:
		current_sub_card.queue_free()
		current_sub_card = null

	var scene_to_instantiate: PackedScene = _resolve_scene_for_page_type(page_type)
	if scene_to_instantiate == null:
		push_error("PageCard: Unsupported page_type '%s' for page %d" % [page_type, page_number])
		return

	var sub_instance: Node = scene_to_instantiate.instantiate()
	if not (sub_instance is BasePageCard):
		push_error("PageCard: Instantiated scene does not extend BasePageCard")
		return

	current_sub_card = sub_instance as BasePageCard
	current_sub_card.name = "SubCard_%s" % page_type
	current_sub_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current_sub_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(current_sub_card)
	current_sub_card.text_size_preset = text_size_preset
	current_sub_card.bind_page_data(page_data, data_loader)
	_sync_with_sub_card()
	configure_pass_through_mouse_filters(self)


func set_text_size_preset(preset: Variant) -> void:
	text_size_preset = normalize_preset(preset)
	if current_sub_card != null:
		current_sub_card.set_text_size_preset(text_size_preset)
	_sync_with_sub_card()


func _sync_with_sub_card() -> void:
	if current_sub_card != null and _is_text_page_type(page_type):
		var target_h: float = current_sub_card.custom_minimum_size.y
		if target_h > DESIGN_HEIGHT:
			custom_minimum_size = Vector2(DESIGN_WIDTH, target_h)
			ratio = DESIGN_WIDTH / target_h
		else:
			custom_minimum_size = DESIGN_SIZE
			ratio = ASPECT_RATIO
	else:
		custom_minimum_size = DESIGN_SIZE
		ratio = ASPECT_RATIO


func get_required_card_height() -> float:
	if current_sub_card != null:
		return current_sub_card.get_required_card_height()
	return custom_minimum_size.y


static func _is_text_page_type(p_type: String) -> bool:
	match p_type:
		"front_matter_spread_left", "front_matter_spread_right", "front_matter_spread", \
		"prayer_sequence_page", "mystery_prayer_page", \
		"credits_spread_left", "credits_spread_right", "credits_spread":
			return true
		_:
			return false


func _resolve_scene_for_page_type(p_type: String) -> PackedScene:
	match p_type:
		"front_cover", "cover":
			return COVER_SCENE
		"front_matter_spread_left", "front_matter_spread_right", "front_matter_spread":
			return FRONT_MATTER_SCENE
		"prayer_sequence_page":
			return PRAYER_SEQUENCE_SCENE
		"mystery_prayer_page":
			return MYSTERY_PRAYER_SCENE
		"artwork_page":
			return ARTWORK_SCENE
		"credits_spread_left", "credits_spread_right", "credits_spread":
			return CREDITS_SCENE
		"back_cover":
			return BACK_COVER_SCENE
		_:
			push_warning("PageCard: Unknown page_type '%s', defaulting to front_matter" % p_type)
			return FRONT_MATTER_SCENE


func get_sub_card() -> BasePageCard:
	return current_sub_card


func get_heading_text() -> String:
	if current_sub_card != null:
		return current_sub_card.get_heading_text()
	return super.get_heading_text()


func get_subheading_text() -> String:
	if current_sub_card != null:
		return current_sub_card.get_subheading_text()
	return super.get_subheading_text()


func get_artwork_texture() -> Texture2D:
	if current_sub_card is CoverPageCard:
		return (current_sub_card as CoverPageCard).get_artwork_texture()
	elif current_sub_card is ArtworkPageCard:
		return (current_sub_card as ArtworkPageCard).get_artwork_texture()
	return null


func load_artwork() -> void:
	if current_sub_card != null and current_sub_card.has_method("load_artwork"):
		current_sub_card.call("load_artwork")


func unload_artwork() -> void:
	if current_sub_card != null and current_sub_card.has_method("unload_artwork"):
		current_sub_card.call("unload_artwork")


func has_visible_page_number() -> bool:
	return false
