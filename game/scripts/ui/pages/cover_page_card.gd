class_name CoverPageCard
extends BasePageCard
## Page 1 Front Cover: Dedicated top header band with framed Murillo painting below.

@onready var header_container: Control = _resolve_header_container()
@onready var artwork_container: Control = _resolve_artwork_container()
@onready var cover_texture: TextureRect = _resolve_cover_texture()
@onready var title_label: Label = _resolve_title_label()
@onready var subtitle_label: Label = _resolve_subtitle_label()
@onready var divider: ColorRect = _resolve_divider()


func _ready() -> void:
	if not page_data.is_empty():
		_apply_page_data()


func _apply_page_data() -> void:
	if title_label == null:
		title_label = _resolve_title_label()
	if subtitle_label == null:
		subtitle_label = _resolve_subtitle_label()
	if cover_texture == null:
		cover_texture = _resolve_cover_texture()
	if header_container == null:
		header_container = _resolve_header_container()
	if artwork_container == null:
		artwork_container = _resolve_artwork_container()

	if title_label != null:
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var raw_title: String = str(page_data.get("title", "PRAY THE ROSARY"))
		title_label.text = raw_title.to_upper()

	if subtitle_label != null:
		subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var raw_subtitle: String = str(page_data.get("subtitle", "A Contemplative Visual Guide to the Twenty Mysteries"))
		subtitle_label.text = raw_subtitle

	load_artwork()


func load_artwork() -> void:
	if cover_texture == null:
		cover_texture = _resolve_cover_texture()
	if cover_texture != null:
		if cover_texture.texture != null:
			return
		var art: Dictionary = page_data.get("artwork", {})
		var tex_path: String = str(art.get("runtime_texture_path", "res://assets/images/cover.webp"))
		if ResourceLoader.exists(tex_path):
			var tex: Texture2D = load(tex_path) as Texture2D
			if tex != null:
				cover_texture.texture = tex


func unload_artwork() -> void:
	if cover_texture == null:
		cover_texture = _resolve_cover_texture()
	if cover_texture != null:
		cover_texture.texture = null


func get_artwork_texture() -> Texture2D:
	if cover_texture == null:
		cover_texture = _resolve_cover_texture()
	if cover_texture != null and cover_texture.texture == null:
		load_artwork()
	if cover_texture != null:
		return cover_texture.texture
	return null


func get_heading_text() -> String:
	if title_label == null:
		title_label = _resolve_title_label()
	if title_label != null and title_label.text != "":
		return title_label.text
	return str(page_data.get("title", "PRAY THE ROSARY")).to_upper()


func get_subheading_text() -> String:
	if subtitle_label == null:
		subtitle_label = _resolve_subtitle_label()
	if subtitle_label != null and subtitle_label.text != "":
		return subtitle_label.text
	return str(page_data.get("subtitle", ""))


func get_header_container() -> Control:
	if header_container == null:
		header_container = _resolve_header_container()
	return header_container


func get_artwork_container() -> Control:
	if artwork_container == null:
		artwork_container = _resolve_artwork_container()
	return artwork_container


func get_cover_texture() -> TextureRect:
	if cover_texture == null:
		cover_texture = _resolve_cover_texture()
	return cover_texture


func _resolve_header_container() -> Control:
	var node: Control = get_node_or_null("CardPanel/VBoxContainer/HeaderBand") as Control
	if node == null:
		node = get_node_or_null("CardPanel/VBoxContainer/HeaderContainer") as Control
	if node == null:
		node = get_node_or_null("CardPanel/HeaderBand") as Control
	return node


func _resolve_artwork_container() -> Control:
	var node: Control = get_node_or_null("CardPanel/VBoxContainer/ArtworkContainer") as Control
	if node == null:
		node = get_node_or_null("CardPanel/VBoxContainer/ArtFrame") as Control
	if node == null:
		node = get_node_or_null("CardPanel/ArtworkContainer") as Control
	return node


func _resolve_cover_texture() -> TextureRect:
	var tex_rect: TextureRect = get_node_or_null("CardPanel/VBoxContainer/ArtworkContainer/CoverTexture") as TextureRect
	if tex_rect == null:
		tex_rect = get_node_or_null("CardPanel/VBoxContainer/ArtFrame/CoverTexture") as TextureRect
	if tex_rect == null:
		tex_rect = get_node_or_null("CardPanel/CoverTexture") as TextureRect
	return tex_rect


func _resolve_title_label() -> Label:
	var lbl: Label = get_node_or_null("CardPanel/VBoxContainer/HeaderBand/TitleVBox/TitleLabel") as Label
	if lbl == null:
		lbl = get_node_or_null("CardPanel/VBoxContainer/HeaderContainer/TitleVBox/TitleLabel") as Label
	if lbl == null:
		lbl = get_node_or_null("CardPanel/TitleOverlay/TitleVBox/TitleLabel") as Label
	return lbl


func _resolve_subtitle_label() -> Label:
	var lbl: Label = get_node_or_null("CardPanel/VBoxContainer/HeaderBand/TitleVBox/SubtitleLabel") as Label
	if lbl == null:
		lbl = get_node_or_null("CardPanel/VBoxContainer/HeaderContainer/TitleVBox/SubtitleLabel") as Label
	if lbl == null:
		lbl = get_node_or_null("CardPanel/TitleOverlay/TitleVBox/SubtitleLabel") as Label
	return lbl


func _resolve_divider() -> ColorRect:
	var div: ColorRect = get_node_or_null("CardPanel/VBoxContainer/HeaderBand/TitleVBox/Divider") as ColorRect
	if div == null:
		div = get_node_or_null("CardPanel/TitleOverlay/TitleVBox/Divider") as ColorRect
	return div
