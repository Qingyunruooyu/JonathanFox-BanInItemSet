extends "res://ui/menus/pages/menu_item_sets.gd"

const BANISET_GRAY = Color(0.5, 0.5, 0.5, 0.6)
const BANISET_BASE_SET_ID = "base"

var _baninset_current_set_id: String = ""
var _baninset_base_update = null

func _ready():
	_baninset_add_base_entry()

func _baninset_add_base_entry() -> void:
	for child in update_entry_container.get_children():
		if child is UpdateEntryButton and child._get_update().id == BANISET_BASE_SET_ID:
			return
	var base_update = UpdateData.new()
	base_update.id = BANISET_BASE_SET_ID
	base_update.item_set = ItemService.base_game_item_set
	base_update.color = Color.white
	base_update.icon = preload("res://entities/units/enemies/abyss/basic/blobfish/blobfish.png")
	base_update.baner_logo = preload("res://ui/menus/title_screen/title_screen_background/ui_logo.png")
	base_update.baner_illu = preload("res://ui/menus/title_screen/title_screen_background/splash_art_mist_back.png")
	_baninset_base_update = base_update

	var button = update_entry_button_scene.instance()
	var btn = button.get_node("Button")
	btn.set_pressed_no_signal(true)
	button._set_entry(base_update)
	update_entry_container.add_child(button)
	update_entry_container.move_child(button, 0)
	if btn.is_connected("toggled", button, "_on_Button_toggled"):
		btn.disconnect("toggled", button, "_on_Button_toggled")
	btn.connect("focus_entered", self, "_focus", [button])
	btn.connect("toggled", self, "_baninset_keep_base_enabled", [button])

func _baninset_keep_base_enabled(button_pressed: bool, entry) -> void:
	if button_pressed:
		return
	entry.get_node("Button").set_pressed_no_signal(true)
	entry._set_entry(_baninset_base_update)

func _focus(_button) -> void:
	if _button != null:
		_baninset_current_set_id = _button._get_update().id
	._focus(_button)

func _process(delta):
	if not visible:
		return
	_baninset_refresh_masks()

func _input(event):
	if not visible:
		return
	var toggle_requested = false
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_LEFT and event.doubleclick:
			toggle_requested = true
		elif event.button_index == BUTTON_RIGHT:
			toggle_requested = true
	if toggle_requested:
		var element = _baninset_find_hovered_element()
		if element != null and element.item != null and not element.item.is_locked:
			ItemService.baninset_toggle(_baninset_current_set_id, element.item)

func _baninset_find_hovered_element():
	for inventory in _baninset_inventories():
		if inventory == null or not inventory.visible:
			continue
		for element in inventory._elements.get_children():
			if element.is_visible_in_tree() and element.get_global_rect().has_point(element.get_global_mouse_position()):
				return element
	return null

func _baninset_refresh_masks() -> void:
	for inventory in _baninset_inventories():
		if inventory == null or not inventory.visible:
			continue
		for element in inventory._elements.get_children():
			if element.item == null:
				continue
			if ItemService.baninset_is_banned(element.item):
				if not element._baned.visible or element._baned.modulate != BANISET_GRAY:
					element._baned.modulate = BANISET_GRAY
					element._baned.visible = true
			elif element._baned.visible:
				element._baned.visible = false

func _baninset_inventories() -> Array:
	return [inventory_weapons, inventory_items, inventory_meca_items, inventory_mutant_items]
