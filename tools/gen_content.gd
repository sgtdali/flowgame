extends SceneTree

## MVP içeriğini üreten önyükleme aracı.
##
## Çalıştırma:
##   godot --headless --path . --script res://tools/gen_content.gd
##
## Neden script? Tipli diziler (Array[RecipeSlot]) ve alt kaynaklar içeren
## .tres dosyalarını elle yazmak hataya açık. Godot'a ürettirince biçim
## garanti doğru olur. Üretilen dosyalar normal .tres — Inspector'dan
## düzenlenebilir. Bu araç yalnızca ilk kurulum ve toplu değişiklik içindir;
## tek tek ayar yapmak için Inspector kullanılır.
##
## DİKKAT: Bu araç data/items, data/recipes ve data/block_types altındaki
## dosyaların ÜZERİNE YAZAR. Inspector'da elle yaptığın ayarlar kaybolur.

const ITEMS_DIR := "res://data/items/"
const RECIPES_DIR := "res://data/recipes/"
const BLOCKS_DIR := "res://data/block_types/"

# Kategori kısaltmaları — okunurluk için.
const SOURCE := BlockType.Category.SOURCE
const PROCESS := BlockType.Category.PROCESS
const INSPECT := BlockType.Category.INSPECT
const BUFFER := BlockType.Category.BUFFER
const SINK := BlockType.Category.SINK


func _initialize() -> void:
	_ensure_dir(ITEMS_DIR)
	_ensure_dir(RECIPES_DIR)
	_ensure_dir(BLOCKS_DIR)

	var items: Dictionary = _build_items()
	var recipes: Dictionary = _build_recipes(items)
	_build_blocks(recipes, items)

	print("Üretildi: %d ürün, %d reçete, 10 istasyon." % [items.size(), recipes.size()])
	quit()


## --- Ürünler ---------------------------------------------------------------

func _build_items() -> Dictionary:
	var out: Dictionary = {}
	# id, ad, renk, kod, fiyat, kademe
	var rows: Array = [
		["cevher", "Cevher", Color(0.55, 0.47, 0.38), "CV", 2, 0],
		["kulce", "Külçe", Color(0.85, 0.55, 0.30), "KL", 10, 1],
		["levha", "Levha", Color(0.55, 0.68, 0.80), "LV", 28, 2],
		["cubuk", "Çubuk", Color(0.68, 0.72, 0.78), "CB", 26, 2],
		["vida", "Vida", Color(0.88, 0.78, 0.42), "VD", 20, 3],
		["govde", "Gövde", Color(0.42, 0.78, 0.55), "GV", 150, 4],
		["hurda", "Hurda", Color(0.52, 0.42, 0.45), "HR", 3, 0],
	]
	for row: Array in rows:
		var item := ItemType.new()
		item.id = StringName(row[0])
		item.display_name = row[1]
		item.color = row[2]
		item.icon_char = row[3]
		item.base_price = row[4]
		item.tier = row[5]
		out[row[0]] = _persist(item, ITEMS_DIR + row[0] + ".tres")
	return out


## --- Reçeteler --------------------------------------------------------------

func _build_recipes(items: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	# id, girdiler [[ürün, adet]...], çıktılar, süre (tick)
	var rows: Array = [
		["r_cevher", [], [["cevher", 1]], 20],
		["r_kulce", [["cevher", 2]], [["kulce", 1]], 20],
		["r_levha", [["kulce", 1]], [["levha", 1]], 10],
		["r_cubuk", [["levha", 1]], [["cubuk", 1]], 15],
		["r_vida", [["cubuk", 1]], [["vida", 2]], 8],
		["r_govde", [["levha", 2], ["vida", 3]], [["govde", 1]], 25],
		["r_kalite", [["govde", 1]], [["govde", 1]], 6],
		["r_geri_donusum", [["hurda", 1]], [["kulce", 1]], 12],
	]
	for row: Array in rows:
		var recipe := Recipe.new()
		recipe.id = StringName(row[0])
		recipe.inputs = _slots(row[1], items)
		recipe.outputs = _slots(row[2], items)
		recipe.duration_ticks = row[3]
		out[row[0]] = _persist(recipe, RECIPES_DIR + row[0] + ".tres")
	return out


func _slots(rows: Array, items: Dictionary) -> Array[RecipeSlot]:
	var out: Array[RecipeSlot] = []
	for row: Array in rows:
		var slot := RecipeSlot.new()
		slot.item = items[row[0]]
		slot.count = row[1]
		out.append(slot)
	return out


## --- İstasyonlar ------------------------------------------------------------

func _build_blocks(recipes: Dictionary, items: Dictionary) -> void:
	var warm := Color(0.902, 0.494, 0.266)   # sıcak işlem
	var cool := Color(0.29, 0.624, 0.878)    # soğuk işlem
	var green := Color(0.31, 0.757, 0.651)
	var amber := Color(0.91, 0.706, 0.29)
	var violet := Color(0.643, 0.482, 0.831)
	var red := Color(0.878, 0.447, 0.361)

	# id, ad, kategori, renk, kod, reçete, giriş kap., çıkış kap., maliyet, açıklama
	var rows: Array = [
		["maden_ocagi", "Maden Ocağı", SOURCE, green, "MO", "r_cevher", 0, 8, 0,
			"Durmadan cevher üretir. Girdi istemez, akışın başlangıcıdır."],
		["eritme", "Eritme Fırını", PROCESS, warm, "ER", "r_kulce", 8, 4, 400,
			"İki cevheri eritip bir külçe döker."],
		["pres", "Pres", PROCESS, cool, "PR", "r_levha", 4, 4, 900,
			"Külçeyi levhaya dönüştürür."],
		["hadde", "Hadde", PROCESS, cool, "HD", "r_cubuk", 4, 4, 1500,
			"Levhayı inceltip çubuk çeker."],
		["kesim", "Kesim", PROCESS, cool, "KS", "r_vida", 4, 6, 2200,
			"Bir çubuktan iki vida keser."],
		["montaj", "Montaj", PROCESS, cool, "MT", "r_govde", 6, 4, 5000,
			"İki levha ve üç vidayı birleştirip gövde üretir. İki ayrı hattın buluştuğu yer."],
		["kalite", "Kalite Kontrol", INSPECT, amber, "QC", "r_kalite", 4, 4, 3500,
			"Gövdeleri ayırır. Her 8 üründen biri Ret portundan hurda olarak çıkar."],
		["depo", "Ara Depo", BUFFER, violet, "AD", "", 50, 50, 800,
			"Üretmez, tutar. İstasyonlar arası dengesizliği emer ve tıkanmayı geciktirir."],
		["geri_donusum", "Geri Dönüşüm", PROCESS, violet, "GD", "r_geri_donusum", 4, 4, 4000,
			"Hurdayı eritip külçeye çevirir. Fireyi hatta geri kazandırır."],
		["sevkiyat", "Sevkiyat", SINK, red, "SV", "", 8, 0, 0,
			"Gelen her ürünü satar. Akışın sonu — çıkışı yoktur."],
	]

	for row: Array in rows:
		var block := BlockType.new()
		block.id = StringName(row[0])
		block.display_name = row[1]
		block.category = row[2]
		block.accent_color = row[3]
		block.icon_char = row[4]
		block.recipe = recipes.get(row[5]) if row[5] != "" else null
		block.input_capacity = row[6]
		block.output_capacity = row[7]
		block.build_cost = row[8]
		block.description = row[9]
		if block.category == INSPECT:
			block.scrap_every_n = 8
			block.reject_item = items["hurda"]
		_persist(block, BLOCKS_DIR + row[0] + ".tres")


## --- Yardımcılar ------------------------------------------------------------

## Kaydeder ve kaynağın yolunu üstlenmesini sağlar.
## take_over_path şart: yolu olmayan bir kaynak, ona referans veren başka bir
## kaynağın içine GÖMÜLEREK yazılır (ext_resource yerine sub_resource).
func _persist(res: Resource, path: String) -> Resource:
	var err: int = ResourceSaver.save(res, path)
	if err != OK:
		push_error("Kaydedilemedi: %s (%s)" % [path, error_string(err)])
	res.take_over_path(path)
	return res


func _ensure_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)
