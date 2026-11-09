extends Node

const MOD_DIR = "JonathanFox-BanInItemSet"

func _init():
	var ext_dir = ModLoaderMod.get_unpacked_dir() + MOD_DIR + "/extensions/"
	ModLoaderMod.install_script_extension(ext_dir + "singletons/item_service.gd")
	ModLoaderMod.install_script_extension(ext_dir + "ui/menus/pages/menu_item_sets.gd")

func _ready():
	ModLoaderLog.success("BanInItemSet initialized", MOD_DIR)
