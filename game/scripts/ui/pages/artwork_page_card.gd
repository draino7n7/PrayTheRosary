class_name ArtworkPageCard
extends BasePageCard
## Odd Pages 5, 7..47 Sacred Artwork Cards: Top header and uncropped gold-framed masterpiece.
## Strictly zero captions and zero numerical page numbers.

@onready var subheading_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/SubheadingLabel") as Label
@onready var heading_label: Label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/HeadingLabel") as Label
@onready var art_frame: PanelContainer = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ArtFrame") as PanelContainer
@onready var artwork_texture: TextureRect = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ArtFrame/ArtworkTexture") as TextureRect


func _ready() -> void:
	if not page_data.is_empty():
		_apply_page_data()


func _apply_page_data() -> void:
	if subheading_label == null:
		subheading_label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/SubheadingLabel") as Label
	if heading_label == null:
		heading_label = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/HeaderVBox/HeadingLabel") as Label
	if art_frame == null:
		art_frame = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ArtFrame") as PanelContainer
	if artwork_texture == null:
		artwork_texture = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ArtFrame/ArtworkTexture") as TextureRect

	if subheading_label != null:
		subheading_label.text = str(page_data.get("subheading", ""))
	if heading_label != null:
		heading_label.text = str(page_data.get("heading", ""))

	if artwork_texture != null:
		var art: Dictionary = page_data.get("artwork", {})
		var tex_path: String = str(art.get("runtime_texture_path", ""))
		if tex_path != "" and ResourceLoader.exists(tex_path):
			var tex: Texture2D = load(tex_path) as Texture2D
			if tex != null:
				artwork_texture.texture = tex


func get_artwork_texture() -> Texture2D:
	if artwork_texture == null:
		artwork_texture = get_node_or_null("CardPanel/MarginContainer/VBoxContainer/ArtFrame/ArtworkTexture") as TextureRect
	if artwork_texture != null:
		return artwork_texture.texture
	return null


func has_caption() -> bool:
	return false
