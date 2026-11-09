extends "res://singletons/item_service.gd"

# JSON 存储结构（按套组记录）：
# { "<set_id>": { "items": [ item my_id ... ], "weapons": [ weapon_id ... ] } }
var baninset_bans: Dictionary = {}
var baninset_item_ids: Dictionary = {}
var baninset_weapon_ids: Dictionary = {}
var baninset_save_path: String = "user://jonathanfox_baninitemset.json"

func _ready() -> void:
	baninset_load()

func baninset_is_banned(item) -> bool:
	if item is WeaponData:
		return baninset_weapon_ids.has(item.weapon_id)
	return baninset_item_ids.has(item.my_id)

func baninset_toggle(set_id: String, item) -> void:
	if set_id == "" or item is CharacterData or not (item is WeaponData or item is ItemData):
		return
	if not baninset_bans.has(set_id):
		baninset_bans[set_id] = {"items": [], "weapons": []}
	var bucket: Dictionary = baninset_bans[set_id]
	if item is WeaponData:
		var weapon_ids: Array = bucket.get("weapons", [])
		if weapon_ids.has(item.weapon_id):
			weapon_ids.erase(item.weapon_id)
		else:
			weapon_ids.append(item.weapon_id)
		bucket["weapons"] = weapon_ids
	else:
		var item_ids: Array = bucket.get("items", [])
		if item_ids.has(item.my_id):
			item_ids.erase(item.my_id)
		else:
			item_ids.append(item.my_id)
		bucket["items"] = item_ids
	_baninset_rebuild_flat()
	baninset_save()

func _baninset_rebuild_flat() -> void:
	baninset_item_ids = {}
	baninset_weapon_ids = {}
	for set_id in baninset_bans:
		var bucket: Dictionary = baninset_bans[set_id]
		for item_id in bucket.get("items", []):
			baninset_item_ids[item_id] = true
		for weapon_id in bucket.get("weapons", []):
			baninset_weapon_ids[weapon_id] = true

func baninset_save() -> void:
	var file = File.new()
	if file.open(baninset_save_path, File.WRITE) == OK:
		file.store_string(JSON.print(baninset_bans, "\t"))
		file.close()

func baninset_load() -> void:
	var file = File.new()
	if not file.file_exists(baninset_save_path):
		return
	if file.open(baninset_save_path, File.READ) != OK:
		return
	var text = file.get_as_text()
	file.close()
	var result = JSON.parse(text)
	if result.error != OK or typeof(result.result) != TYPE_DICTIONARY:
		return
	baninset_bans = {}
	for set_id in result.result:
		var bucket = result.result[set_id]
		if typeof(bucket) != TYPE_DICTIONARY:
			continue
		baninset_bans[str(set_id)] = {"items": bucket.get("items", []), "weapons": bucket.get("weapons", [])}
	_baninset_rebuild_flat()

func get_pool(item_tier: int, type: int) -> Array:
	var pool = .get_pool(item_tier, type)
	if baninset_item_ids.empty() and baninset_weapon_ids.empty():
		return pool
	var filtered_pool = []
	for item in pool:
		if not baninset_is_banned(item):
			filtered_pool.append(item)
	return filtered_pool

func _get_rand_item_for_wave(wave: int, player_index: int, type: int, args: GetRandItemForWaveArgs) -> ItemParentData:
	if baninset_item_ids.empty() and baninset_weapon_ids.empty():
		return ._get_rand_item_for_wave(wave, player_index, type, args)

	var player_run_data = RunData.players_data[player_index]
	var original_banned_items = player_run_data.banned_items
	var merged_banned_items = original_banned_items.duplicate()
	for item_id in baninset_item_ids:
		if not merged_banned_items.has(item_id):
			merged_banned_items.push_back(item_id)
	for weapon_id in baninset_weapon_ids:
		for weapon in get_weapons():
			if weapon.weapon_id == weapon_id and not merged_banned_items.has(weapon.my_id):
				merged_banned_items.push_back(weapon.my_id)

	player_run_data.banned_items = merged_banned_items
	var item = ._get_rand_item_for_wave(wave, player_index, type, args)
	player_run_data.banned_items = original_banned_items

	return item
