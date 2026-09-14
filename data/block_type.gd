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
	RESEARCH, ## Ar-Ge Laboratuvarı — yutar ama satmaz, araştırmaya sayar
	SPLITTER, ## Tek girişi birden fazla çıkışa dağıtır — BUFFER ile aynı
	          ## simülasyon mantığını kullanır, yalnızca çıkış port sayısı farklı
	FOOD,     ## Bread is deposited in the shared food ledger
}

@export var id: StringName = &""
@export var display_name: String = "New Workshop"
@export var category: Category = Category.PROCESS
@export var accent_color: Color = Color(0.29, 0.64, 0.87)
@export var icon_char: String = "??"
## Akış düğümünün başlığının altında gösterilecek istasyona özel illüstrasyon.
@export var node_image: Texture2D = null
@export var food_chain: bool = false
@export var food_item: ItemType = null
@export_multiline var description: String = ""

@export_group("Crafting")
## Bu istasyonun işlediği reçete.
## BUFFER ve SINK için boştur — onlar üretmez, taşır veya yutar.
@export var recipe: Recipe = null

@export_group("Kuyruk")
## Girdi tamponunda ürün başına tutulabilecek en fazla adet.
@export var input_capacity: int = 4
## Reçetesi olmayan istasyonların (BUFFER, SPLITTER) kaç çıkış portu olduğu.
## Yalnızca SPLITTER birden fazla kullanır — diğer her istasyonun çıkışı
## tek tele sınırlıdır, birden fazlaya dağıtmak için Dağıtıcı gerekir.
@export var output_port_count: int = 1
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
## Araştırma gerektirmeden, oyunun başında kullanılabilir mi?
@export var unlocked_at_start: bool = false
## Bu türden en fazla kaç örnek kurulabilir. 0 = sınırsız.
##
## Erken oyun deneyi (bkz. DESIGN.md D27): sınır ÜRETİM MİKTARINA değil
## KURULABİLECEK NODE ADEDİNE uygulanır — oyuncu "daha çok istasyon" yerine
## "mevcut istasyonu geliştir" seçeneğine yönlendirilir.
@export var max_instances: int = 0
## Bu blok, erken oyun kilometre taşı (en az bir geliştirme satın alınması,
## bkz. `GameConfig.MIN_UPGRADES_FOR_RESEARCH`) karşılanmadan kurulamaz mı?
## Yalnızca Ar-Ge Sarayı'nda kullanılıyor — araştırmanın oyuncu temel hattı
## deneyimlemeden erişilmesini engellemek için.
@export var requires_first_upgrade: bool = false

@export_group("Geliştirme")
## Bu istasyonun seviye atlayarak hızlandırılabilmesi.
@export var upgradeable: bool = false
## 1. seviyeden 2. seviyeye geçişin maliyeti. Sonraki seviyeler
## `upgrade_cost_growth` ile büyür.
@export var upgrade_base_cost: int = 0
## Her seviyede maliyetin çarpıldığı oran.
@export var upgrade_cost_growth: float = 1.6
## Her seviyede reçete süresinin çarpıldığı oran (0.85 = %15 daha hızlı).
## Yalnızca `upgrade_rate_increment <= 0` olan (yani ADDİTİF model
## KULLANMAYAN) bloklarda okunur — bkz. `duration_ticks_at_level`.
@export var upgrade_duration_factor: float = 0.85
## Seviye başına TEMEL hıza (dk başına adet) eklenen SABİT miktar.
##
## Maliyet katlanır ama hız KATLANMAZ — art arda geliştirmeler benzer
## mutlak kazanç verir, üstel bir güç eğrisi oluşmaz (bkz. DESIGN.md D29).
## 0 = bu blok eski çarpımsal modeli kullanır (`upgrade_duration_factor`).
@export var upgrade_rate_increment: float = 0.0
## Ulaşılabilecek en yüksek seviye. Küçük tutulur — bu "sade" bir
## geliştirme sistemi, sonsuz ölçeklenen bir güç eğrisi değil.
@export var max_level: int = 3


## Bu seviyede reçetenin süresi (tick). SUNUM (`FlowBlock`) ve MANTIK
## (`SimStation`) AYNI hesaba bakar — ikisi ayrışırsa ilerleme çubuğu ile
## "sonraki hız" yazısı uyuşmaz (bkz. DESIGN.md D29).
func duration_ticks_at_level(target_level: int) -> int:
	if recipe == null:
		return 0
	if target_level <= 1 or not upgradeable:
		return recipe.duration_ticks
	if upgrade_rate_increment > 0.0:
		var base_per_min: float = float(GameConfig.TICKS_PER_SECOND) * 60.0 / float(recipe.duration_ticks)
		var target_per_min: float = base_per_min + upgrade_rate_increment * float(target_level - 1)
		if target_per_min <= 0.0:
			return recipe.duration_ticks
		return maxi(1, roundi(float(GameConfig.TICKS_PER_SECOND) * 60.0 / target_per_min))
	var factor: float = pow(upgrade_duration_factor, target_level - 1)
	return maxi(1, roundi(float(recipe.duration_ticks) * factor))


func category_label() -> String:
	match category:
		Category.SOURCE: return "Gathering"
		Category.PROCESS: return "Crafting"
		Category.INSPECT: return "Inspection"
		Category.BUFFER: return "Storage"
		Category.SINK: return "Trade"
		Category.RESEARCH: return "Knowledge"
		Category.SPLITTER: return "Routing"
		Category.FOOD: return "Provisioning"
	return "Unknown"


func requires_worker() -> bool:
	return category == Category.SOURCE or category == Category.PROCESS or category == Category.INSPECT


## --- Portlar ---------------------------------------------------------------
##
## Portlar reçeteden TÜRER, elle yazılmaz — tek gerçek kaynağı.
## İki bilinçli istisna:
##   INSPECT  → reçetesinin çıktısına ek olarak bir Ret portu taşır
##   BUFFER/SINK → reçetesi yoktur, jenerik port taşır

func input_items() -> Array[ItemType]:
	var out: Array[ItemType] = []
	if category == Category.FOOD and food_item != null:
		out.append(food_item)
		return out
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
	if category == Category.FOOD and food_item != null:
		out.append(food_item.display_name)
		return out
	if recipe == null:
		out.append("Input")
		return out
	for slot: RecipeSlot in recipe.inputs:
		out.append(slot.label())
	return out


func output_labels() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if category == Category.SINK or category == Category.RESEARCH or category == Category.FOOD:
		return out  # bitiş noktasının çıkışı yok
	if recipe == null:
		if output_port_count <= 1:
			out.append("Output")
		else:
			for i in output_port_count:
				out.append("Output %s" % char(65 + i))  # Çıkış A, B, C...
		return out
	if category == Category.INSPECT:
		# Ürün adı yerine karar adı daha okunur: hangi dal "uygun", hangisi "ret".
		out.append("Approved")
		out.append("Reject")
		return out
	for slot: RecipeSlot in recipe.outputs:
		out.append(slot.label())
	return out
