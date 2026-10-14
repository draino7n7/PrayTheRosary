class_name CoverPageCard
extends BasePageCard
## Page 1 Front Cover: Full-bleed Murillo painting with gold/ivory title typography.

@onready var cover_texture: TextureRect = get_node_or_null("CardPanel/CoverTexture") as TextureRect
@onready var title_label: Label = get_node_or_null("CardPanel/TitleOverlay/TitleVBox/TitleLabel") as Label
@onready var subtitle_label: Label = get_node_or_null("CardPanel/TitleOverlay/TitleVBox/SubtitleLabel") as Label


func _ready() -> void:
	if not page_data.is_empty():
		_apply_page_data()


func _apply_page_data() -> void:
	if title_label == null:
		title_label = get_node_or_null("CardPanel/TitleOverlay/TitleVBox/TitleLabel") as Label
	if subtitle_label == null:
		subtitle_label = get_node_or_null("CardPanel/TitleOverlay/TitleVBox/SubtitleLabel") as Label
	if cover_texture == null:
		cover_texture = get_node_or_null("CardPanel/CoverTexture") as TextureRect

	if title_label != null:
		var raw_title: String = str(page_data.get("title", "PRAY THE ROSARY"))
		title_label.text = raw_title.to_upper()

	if subtitle_label != null:
		var raw_subtitle: String = str(page_data.get("subtitle", "A Contemplative Visual Guide to the Twenty Mysteries"))
		subtitle_label.text = raw_subtitle

	load_artwork()


func load_artwork() -> void:
	if cover_texture == null:
		cover_texture = get_node_or_null("CardPanel/CoverTexture") as TextureRect
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
		cover_texture = get_node_or_null("CardPanel/CoverTexture") as TextureRect
	if cover_texture != null:
		cover_texture.texture = null


func get_artwork_texture() -> Texture2D:
	if cover_texture == null:
		cover_texture = get_node_or_null("CardPanel/CoverTexture") as TextureRect
	if cover_texture != null and cover_texture.texture == null:
		load_artwork()
	if cover_texture != null:
		return cover_texture.texture
	return null


func get_heading_text() -> String:
	if title_label != null and title_label.text != "":
		return title_label.text
	return str(page_data.get("title", "PRAY THE ROSARY")).to_upper()


func get_subheading_text() -> String:
	if subtitle_label != null and subtitle_label.text != "":
		return subtitle_label.text
	return str(page_data.get("subtitle", ""))
