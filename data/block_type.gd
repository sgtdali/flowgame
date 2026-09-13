class_name BlockType
extends Resource

## Bir istasyon türünün ARKETİPİ.
##
## Oyuncunun tek tek düzenlediği değerleri tutmaz — bunlar istasyon TÜRÜNÜN
## özellikleri. Çalışma anındaki kuyruk ve ilerleme simülasyonda yaşar.
##
## Her tür için bir .tres -> res://data/block_types/

## Bloğun akış şemasındaki rolü.
enum Category {
	SOURCE,   ## Akışın başlangıcı — girdi istemez, durmadan üretir
	PROCESS,  ## Reçetesini işleyen normal istasyon
	INSPECT,  ## Ayırma noktası — fazladan bir Ret portu taşır
	BUFFER,   ## Tampon kuyruk — üretmez, sadece tutar ve geçirir
	SINK,     ## Akışın sonu — yutar ve satar, çıkışı yok
}

@export var id: StringName = &""
@export var display_name: String = "Yeni İstasyon"
@export var category: Category = Category.PROCESS
@export var accent_color: Color = Color(0.29, 0.64, 0.87)
@export var icon_char: String = "??"
@export_multiline var description: String = ""

@export_group("Üretim")
## Bu istasyonun işlediği reçete.
## BUFFER ve SINK için boştur — onlar üretmez, taşır veya yutar.
@export var recipe: Recipe = null

@export_group("Kuyruk")
## Girdi tamponunda ürün başına tutulabilecek en fazla adet.
@export var input_capacity: int = 4
## Çıktı tamponu. DOLU ÇIKTI ÜRETİMİ DURDURUR — tıkanma mekaniğinin kaynağı.
@export var output_capacity: int = 4

@export_group("Fire")
## Her kaçıncı ürünün Ret portuna gideceği. 0 = fire yok.
##
## Rastgele değil SAYAÇ: determinizm bedavaya gelir ve oyuncu örüntüyü
## öğrenip plan yapabilir. Rastgelelik burada yalnızca haksızlık hissi üretir.
@export var scrap_every_n: int = 0
## INSPECT istasyonunun Ret portundan çıkan ürün.
@export var reject_item: ItemType = null

@export_group("Ekonomi")
## Satın alma maliyeti.
@export var build_cost: int = 0


func category_label() -> String:
	match category:
		Category.SOURCE: return "Kaynak"
		Category.PROCESS: return "İşlem"
		Category.INSPECT: return "Kontrol"
		Category.BUFFER: return "Tampon"
		Category.SINK: return "Bitiş"
	return "Bilinmiyor"


## --- Portlar ---------------------------------------------------------------
##
## Portlar reçeteden TÜRER, elle yazılmaz — tek gerçek kaynağı.
## İki bilinçli istisna:
##   INSPECT  → reçetesinin çıktısına ek olarak bir Ret portu taşır
##   BUFFER/SINK → reçetesi yoktur, jenerik port taşır

func input_items() -> Array[ItemType]:
	var out: Array[ItemType] = []
	if recipe == null:
		return out  # jenerik giriş — tip kısıtı yok
	for slot: RecipeSlot in recipe.inputs:
		out.append(slot.item)
	return out


func output_items() -> Array[ItemType]:
	var out: Array[ItemType] = []
	if recipe == null:
		return out
	for slot: RecipeSlot in recipe.outputs:
		out.append(slot.item)
	if category == Category.INSPECT:
		out.append(reject_item)
	return out


func input_labels() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if category == Category.SOURCE:
		return out  # kaynak girdi istemez
	if recipe == null:
		out.append("Giriş")
		return out
	for slot: RecipeSlot in recipe.inputs:
		out.append(slot.label())
	return out


func output_labels() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if category == Category.SINK:
		return out  # bitiş noktasının çıkışı yok
	if recipe == null:
		out.append("Çıkış")
		return out
	if category == Category.INSPECT:
		# Ürün adı yerine karar adı daha okunur: hangi dal "uygun", hangisi "ret".
		out.append("Uygun")
		out.append("Ret")
		return out
	for slot: RecipeSlot in recipe.outputs:
		out.append(slot.label())
	return out
