class_name ReadingProgressManager
extends RefCounted
## Manages persistence of the user's reading position in Pray The Rosary.
## Saves and loads the last-viewed page number (1..50) to user://reading_progress.cfg.

const DEFAULT_CONFIG_PATH: String = "user://reading_progress.cfg"
const SECTION_NAME: String = "reading_progress"
const KEY_PAGE_NUMBER: String = "last_page_number"
const KEY_UPDATED_AT: String = "updated_at"
const MIN_PAGE: int = 1
const MAX_PAGE: int = 50

var config_path: String = DEFAULT_CONFIG_PATH


func _init(custom_path: String = "") -> void:
	if custom_path != "":
		config_path = custom_path


func save_progress(page_number: int) -> bool:
	var clamped_page: int = clampi(page_number, MIN_PAGE, MAX_PAGE)
	var config: ConfigFile = ConfigFile.new()

	if FileAccess.file_exists(config_path):
		var err_load: Error = config.load(config_path)
		if err_load != OK:
			push_warning("ReadingProgressManager: Could not load existing config at %s, overwriting." % config_path)

	config.set_value(SECTION_NAME, KEY_PAGE_NUMBER, clamped_page)
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
		return clampi(int(val), MIN_PAGE, MAX_PAGE)
	return MIN_PAGE


func has_saved_progress() -> bool:
	if not FileAccess.file_exists(config_path):
		return false
	var config: ConfigFile = ConfigFile.new()
	if config.load(config_path) != OK:
		return false
	return config.has_section_key(SECTION_NAME, KEY_PAGE_NUMBER)


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
