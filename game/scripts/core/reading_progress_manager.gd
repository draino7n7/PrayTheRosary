class_name ReadingProgressManager
extends RefCounted
## Manages persistence of the user's reading position in Pray The Rosary.
## Saves and loads the last-viewed page number (1..50) to user://reading_progress.cfg.

const DEFAULT_CONFIG_PATH: String = "user://reading_progress.cfg"
const SECTION_NAME: String = "reading_progress"
const KEY_PAGE_NUMBER: String = "last_page_number"
const KEY_SCROLL_VERTICAL: String = "last_scroll_vertical"
const KEY_TEXT_SIZE_PRESET: String = "text_size_preset"
const KEY_UPDATED_AT: String = "updated_at"
const DEFAULT_TEXT_SIZE_PRESET: String = "normal"
const MIN_PAGE: int = 1
const MAX_PAGE: int = 50

var config_path: String = DEFAULT_CONFIG_PATH


func _init(custom_path: String = "") -> void:
	if custom_path != "":
		config_path = custom_path


func save_progress(page_number: int, scroll_vertical: int = -1) -> bool:
	var clamped_page: int = clampi(page_number, MIN_PAGE, MAX_PAGE)
	var config: ConfigFile = ConfigFile.new()

	if FileAccess.file_exists(config_path):
		var err_load: Error = config.load(config_path)
		if err_load != OK:
			push_warning("ReadingProgressManager: Could not load existing config at %s, overwriting." % config_path)

	config.set_value(SECTION_NAME, KEY_PAGE_NUMBER, clamped_page)
	if scroll_vertical >= 0:
		config.set_value(SECTION_NAME, KEY_SCROLL_VERTICAL, scroll_vertical)
	elif config.has_section_key(SECTION_NAME, KEY_SCROLL_VERTICAL):
		config.erase_section_key(SECTION_NAME, KEY_SCROLL_VERTICAL)

	config.set_value(SECTION_NAME, KEY_UPDATED_AT, int(Time.get_unix_time_from_system()))

	var err_save: Error = config.save(config_path)
	if err_save != OK:
		push_error("ReadingProgressManager: Failed to save progress to %s (error code %d)" % [config_path, err_save])
		return false
	return true


func load_progress() -> int:
	if not FileAccess.file_exists(config_path):
		return MIN_PAGE

	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(config_path)
	if err != OK:
		push_warning("ReadingProgressManager: Failed to load config from %s, defaulting to page 1" % config_path)
		return MIN_PAGE

	var val: Variant = config.get_value(SECTION_NAME, KEY_PAGE_NUMBER, MIN_PAGE)
	if val is int or val is float:
		var page: int = int(val)
		if page < MIN_PAGE or page > MAX_PAGE:
			return MIN_PAGE
		return page
	return MIN_PAGE


func load_scroll_offset() -> int:
	if not FileAccess.file_exists(config_path):
		return -1

	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(config_path)
	if err != OK:
		return -1

	var val: Variant = config.get_value(SECTION_NAME, KEY_SCROLL_VERTICAL, -1)
	if val is int or val is float:
		var offset: int = int(val)
		if offset >= 0:
			return offset
	return -1


func has_saved_progress() -> bool:
	if not FileAccess.file_exists(config_path):
		return false
	var config: ConfigFile = ConfigFile.new()
	if config.load(config_path) != OK:
		return false
	if not config.has_section_key(SECTION_NAME, KEY_PAGE_NUMBER):
		return false
	var val: Variant = config.get_value(SECTION_NAME, KEY_PAGE_NUMBER, null)
	if val is int or val is float:
		var p: int = int(val)
		return p >= MIN_PAGE and p <= MAX_PAGE
	return false


func save_text_size_preset(preset: Variant) -> bool:
	var normalized: String = BasePageCard.normalize_preset(preset)
	var config: ConfigFile = ConfigFile.new()

	if FileAccess.file_exists(config_path):
		var err_load: Error = config.load(config_path)
		if err_load != OK:
			push_warning("ReadingProgressManager: Could not load existing config at %s, overwriting." % config_path)

	config.set_value(SECTION_NAME, KEY_TEXT_SIZE_PRESET, normalized)
	config.set_value(SECTION_NAME, KEY_UPDATED_AT, int(Time.get_unix_time_from_system()))

	var err_save: Error = config.save(config_path)
	if err_save != OK:
		push_error("ReadingProgressManager: Failed to save text size preset to %s (error code %d)" % [config_path, err_save])
		return false
	return true


func load_text_size_preset() -> String:
	if not FileAccess.file_exists(config_path):
		return DEFAULT_TEXT_SIZE_PRESET

	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(config_path)
	if err != OK:
		push_warning("ReadingProgressManager: Failed to load config from %s, defaulting to preset 'normal'" % config_path)
		return DEFAULT_TEXT_SIZE_PRESET

	var val: Variant = config.get_value(SECTION_NAME, KEY_TEXT_SIZE_PRESET, DEFAULT_TEXT_SIZE_PRESET)
	return BasePageCard.normalize_preset(val)


func has_saved_text_size_preset() -> bool:
	if not FileAccess.file_exists(config_path):
		return false
	var config: ConfigFile = ConfigFile.new()
	if config.load(config_path) != OK:
		return false
	return config.has_section_key(SECTION_NAME, KEY_TEXT_SIZE_PRESET)


func clear_progress() -> bool:
	if not FileAccess.file_exists(config_path):
		return true
	var err: Error = DirAccess.remove_absolute(config_path)
	if err != OK:
		push_warning("ReadingProgressManager: Failed to remove config file at %s" % config_path)
		return false
	return true


func get_save_path() -> String:
	return config_path
