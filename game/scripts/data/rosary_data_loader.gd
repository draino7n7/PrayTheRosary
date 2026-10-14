class_name RosaryDataLoader
extends RefCounted
## Loads, indexes, and hydrates the data-driven Rosary book architecture:
## - res://data/prayers.json
## - res://data/mysteries.json
## - res://data/book_layout.json

const PRAYERS_PATH: String = "res://data/prayers.json"
const MYSTERIES_PATH: String = "res://data/mysteries.json"
const BOOK_LAYOUT_PATH: String = "res://data/book_layout.json"

var prayers_data: Dictionary = {}
var mysteries_data: Dictionary = {}
var book_layout_data: Dictionary = {}

var _prayers_by_id: Dictionary = {}
var _mystery_sets_by_id: Dictionary = {}
var _mysteries_by_id: Dictionary = {}
var _spreads_by_number: Dictionary = {}
var _pages_by_number: Dictionary = {}
var _is_loaded: bool = false


func load_all() -> bool:
	prayers_data = _load_json_file(PRAYERS_PATH)
	if prayers_data.is_empty():
		return false

	mysteries_data = _load_json_file(MYSTERIES_PATH)
	if mysteries_data.is_empty():
		return false

	book_layout_data = _load_json_file(BOOK_LAYOUT_PATH)
	if book_layout_data.is_empty():
		return false

	_build_indexes()
	_is_loaded = true
	return true


func is_loaded() -> bool:
	return _is_loaded


func get_total_views() -> int:
	var summary: Dictionary = book_layout_data.get("pagination_summary", {})
	return int(summary.get("total_views", 0))


func get_total_interior_spreads() -> int:
	var summary: Dictionary = book_layout_data.get("pagination_summary", {})
	return int(summary.get("total_interior_spreads", 0))


func get_total_page_sides() -> int:
	var summary: Dictionary = book_layout_data.get("pagination_summary", {})
	return int(summary.get("total_page_sides", 0))


func get_index_tabs() -> Array:
	return book_layout_data.get("index_tabs", [])


func get_in_stream_separators() -> Array:
	var nav: Dictionary = book_layout_data.get("app_navigation_and_separators", {})
	return nav.get("in_stream_separators", [])


func get_front_cover() -> Dictionary:
	return book_layout_data.get("front_cover", {})


func get_back_cover() -> Dictionary:
	return book_layout_data.get("back_cover", {})


func get_prayer(prayer_id: String) -> Dictionary:
	return _prayers_by_id.get(prayer_id, {})


func get_all_prayers() -> Dictionary:
	return _prayers_by_id


func get_mystery_set(set_id: String) -> Dictionary:
	return _mystery_sets_by_id.get(set_id, {})


func get_mystery_set_order() -> Array[String]:
	var order: Array[String] = []
	var sets: Array = mysteries_data.get("mystery_sets", [])
	for mystery_set: Variant in sets:
		if mystery_set is Dictionary:
			order.append(str(mystery_set.get("id", "")))
	return order


func get_mystery_by_id(mystery_id: String) -> Dictionary:
	return _mysteries_by_id.get(mystery_id, {})


func get_spread(spread_number: int) -> Dictionary:
	return _spreads_by_number.get(spread_number, {})


func get_hydrated_spread(spread_number: int) -> Dictionary:
	var raw_spread: Dictionary = get_spread(spread_number)
	if raw_spread.is_empty():
		return {}

	var hydrated: Dictionary = raw_spread.duplicate(true)
	var spread_type: String = str(hydrated.get("type", ""))

	if spread_type == "mystery_spread":
		var mystery_id: String = str(hydrated.get("id", ""))
		var mystery: Dictionary = get_mystery_by_id(mystery_id)
		hydrated["mystery"] = mystery.duplicate(true)
		var resolved_prayers: Array[Dictionary] = []
		var sequence: Array = mysteries_data.get("decade_prayer_sequence", [])
		for item: Variant in sequence:
			if item is Dictionary:
				var entry: Dictionary = item.duplicate(true)
				var pid: String = str(entry.get("prayer_id", ""))
				entry["prayer"] = get_prayer(pid)
				resolved_prayers.append(entry)
		hydrated["decade_prayers"] = resolved_prayers
		hydrated["right_page"] = {
			"page_number": int(mystery.get("right_page_number", spread_number * 2 + 1)),
			"position": "recto",
			"heading": str(mystery.get("title", "")),
			"subheading": str(mystery.get("ordinal_label", "")),
			"artwork": mystery.get("artwork", {}).duplicate(true)
		}
	elif spread_type == "prayer_art_spread":
		var left_page: Dictionary = hydrated.get("left_page", {})
		var steps: Array = left_page.get("prayer_steps", [])
		for step: Variant in steps:
			if step is Dictionary:
				var pid: String = str(step.get("prayer_id", ""))
				step["prayer"] = get_prayer(pid)

	return hydrated


func get_page(page_number: int) -> Dictionary:
	return _pages_by_number.get(page_number, {})


func get_all_pages() -> Array[Dictionary]:
	var pages: Array[Dictionary] = []
	for p_num: int in range(1, get_total_page_sides() + 1):
		var p: Dictionary = get_page(p_num)
		if not p.is_empty():
			pages.append(p)
	return pages


func get_view_by_index(view_index: int) -> Dictionary:
	if view_index == 0:
		return get_front_cover()
	if view_index >= 1 and view_index <= get_total_interior_spreads():
		return get_hydrated_spread(view_index)
	if view_index == get_total_interior_spreads() + 1:
		return get_back_cover()
	return {}


func get_starting_spread_for_mystery_set(set_id: String) -> int:
	var mystery_set: Dictionary = get_mystery_set(set_id)
	return int(mystery_set.get("starting_spread", -1))


func get_recommended_mystery_set_for_weekday(weekday: int) -> String:
	match weekday:
		Time.WEEKDAY_MONDAY, Time.WEEKDAY_SATURDAY:
			return "joyful"
		Time.WEEKDAY_THURSDAY:
			return "luminous"
		Time.WEEKDAY_TUESDAY, Time.WEEKDAY_FRIDAY:
			return "sorrowful"
		Time.WEEKDAY_WEDNESDAY, Time.WEEKDAY_SUNDAY:
			return "glorious"
		_:
			return "joyful"


func _build_indexes() -> void:
	_prayers_by_id.clear()
	_mystery_sets_by_id.clear()
	_mysteries_by_id.clear()
	_spreads_by_number.clear()
	_pages_by_number.clear()

	var prayers_dict: Dictionary = prayers_data.get("prayers", {})
	for pid: String in prayers_dict.keys():
		var p_val: Variant = prayers_dict[pid]
		if p_val is Dictionary:
			_prayers_by_id[pid] = p_val

	var sets: Array = mysteries_data.get("mystery_sets", [])
	for set_val: Variant in sets:
		if set_val is Dictionary:
			var set_id: String = str(set_val.get("id", ""))
			_mystery_sets_by_id[set_id] = set_val
			var decades: Array = set_val.get("decades", [])
			for dec_val: Variant in decades:
				if dec_val is Dictionary:
					var dec_id: String = str(dec_val.get("id", ""))
					_mysteries_by_id[dec_id] = dec_val

	var spreads: Array = book_layout_data.get("spreads", [])
	for sp_val: Variant in spreads:
		if sp_val is Dictionary:
			var sp_num: int = int(sp_val.get("spread_number", 0))
			_spreads_by_number[sp_num] = sp_val

	# Build flat 1..50 pages index for continuous vertical scroll
	var front: Dictionary = get_front_cover().duplicate(true)
	front["page_type"] = "front_cover"
	_pages_by_number[1] = front

	for sp_num: int in range(1, get_total_interior_spreads() + 1):
		var h_spread: Dictionary = get_hydrated_spread(sp_num)
		var sp_type: String = str(h_spread.get("type", ""))
		var left_num: int = sp_num * 2
		var right_num: int = sp_num * 2 + 1

		if sp_type == "mystery_spread":
			var mys: Dictionary = h_spread.get("mystery", {})
			_pages_by_number[left_num] = {
				"page_number": left_num,
				"spread_number": sp_num,
				"page_type": "mystery_prayer_page",
				"heading": str(mys.get("title", "")),
				"subheading": str(mys.get("ordinal_label", "")),
				"mystery": mys,
				"decade_prayers": h_spread.get("decade_prayers", [])
			}
			_pages_by_number[right_num] = {
				"page_number": right_num,
				"spread_number": sp_num,
				"page_type": "artwork_page",
				"heading": str(mys.get("title", "")),
				"subheading": str(mys.get("ordinal_label", "")),
				"artwork": mys.get("artwork", {})
			}
		elif sp_type == "prayer_art_spread":
			var lp: Dictionary = h_spread.get("left_page", {}).duplicate(true)
			lp["spread_number"] = sp_num
			lp["page_type"] = "prayer_sequence_page"
			_pages_by_number[left_num] = lp

			var rp: Dictionary = h_spread.get("right_page", {}).duplicate(true)
			rp["spread_number"] = sp_num
			rp["page_type"] = "artwork_page"
			_pages_by_number[right_num] = rp
		else:
			var lp_other: Dictionary = h_spread.get("left_page", {}).duplicate(true)
			lp_other["spread_number"] = sp_num
			lp_other["page_type"] = sp_type + "_left"
			_pages_by_number[left_num] = lp_other

			var rp_other: Dictionary = h_spread.get("right_page", {}).duplicate(true)
			rp_other["spread_number"] = sp_num
			rp_other["page_type"] = sp_type + "_right"
			_pages_by_number[right_num] = rp_other

	var back: Dictionary = get_back_cover().duplicate(true)
	back["page_type"] = "back_cover"
	_pages_by_number[50] = back


func _load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("RosaryDataLoader: File does not exist: %s" % path)
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("RosaryDataLoader: Failed to open file: %s" % path)
		return {}

	var raw_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var err: Error = json.parse(raw_text)
	if err != OK:
		push_error("RosaryDataLoader: JSON parse error in %s at line %d: %s" % [
			path, json.get_error_line(), json.get_error_message()
		])
		return {}

	if not (json.data is Dictionary):
		push_error("RosaryDataLoader: Root of %s is not a Dictionary" % path)
		return {}

	return json.data
