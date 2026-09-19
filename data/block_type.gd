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
}

@export var id: StringName = &""
@export var display_name: String = "New Workshop"
@export var category: Category = Category.PROCESS
@export var accent_color: Color = Color(0.29, 0.64, 0.87)
@export var icon_char: String = "??"
## Akış düğümünün başlığının altında gösterilecek istasyona özel illüstrasyon.
@export var node_image: Texture2D = null
@export_multiline var description: String = ""

@export_group("Crafting")
## Bu istasyonun işlediği reçete.
## BUFFER ve SINK için boştur — onlar üretmez, taşır veya yutar.
@export var recipe: Recipe = null

## Trade Depot gibi TALEP KAPILI geçiş noktaları için: dolu ise bu istasyon
## (category=BUFFER) HERHANGİ bir satılabilir ürünü 0. porttan kabul eder;
## 1. porttan gelen bu ürün TEK bir tipe kilitli değildir (bkz. FactorySim.
## _run_trade_depot). Elindeki 1 mal, `demand_required` kadar Talep birikince
## karşıya geçer — yani sürati DOĞRUDAN Talep'in ne kadar hızlı geldiğine
## (Trade Network'ün hızına) bağlıdır, tıpkı Eritme Ocağı'nın hızının cevher
## akışına bağlı olması gibi. null ise bu alan devre dışı, istasyon jenerik
## BUFFER gibi davranır.
@export var demand_item: ItemType = null
## Elde bekleyen 1 malı karşıya geçirmek için gereken Talep miktarı.
## Yalnızca `demand_item` doluyken anlamlı.
@export var demand_required: int = 1

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
## Sevkiyat istasyonunda seviye başına satış değerine eklenecek oran.
## Örn. 0.20: seviye 2'de mallar %20 daha değerli satılır.
@export var sale_value_bonus_per_level: float = 0.0
## Ulaşılabilecek en yüksek seviye. Küçük tutulur — bu "sade" bir
## geliştirme sistemi, sonsuz ölçeklenen bir güç eğrisi değil.
@export var max_level: int = 3

@export_group("Güç")
## Jeneratörün bu seviyedeki TEMEL güç kapasitesi (tick başına birim).
## >0 ise bu istasyon bir güç KAYNAĞIdır. Seviye başına artış mevcut
## `upgrade_rate_increment` alanını kullanır — madenin +cevher/dk deseniyle
## aynı mantık.
@export var power_output: int = 0
## Bu istasyonun tam hızda çalışmak için tick başına ihtiyaç duyduğu güç.
## >0 ise bu istasyon bir güç TÜKETİCİSİdir (bkz. Elektrikli Hadde).
## Yetersiz güçte üretim ORANTILI yavaşlar (bkz. FactorySim._run_producer);
## sıfır güçte hiç ilerlemez.
@export var power_required_per_tick: int = 0
## true ise bu istasyon Elektrik Satış Noktası'dır: girişi malzeme değil,
## güç sistemidir. Mevcut Sevkiyat (SINK) muhasebesini (accrued/collect)
## AYNEN kullanır — tahsilat mantığı çoğaltılmaz.
@export var sells_power: bool = false
## Sürekli güç akışını kaç enerji biriminde bir "bir birim elektrik" satışına
## çevireceği. Yalnızca `sells_power` için anlamlı.
@export var power_sale_batch: int = 100
## true ise bu istasyonun malzeme portu YOKTUR, yalnızca güç portu vardır
## (Jeneratör ve Elektrik Satış Noktası). Jenerik "Girdi/Çıktı" satırı bu
## istasyonlarda bastırılır — aksi hâlde hiçbir işe yaramayan bir malzeme
## portu görünürdü.
@export var power_only: bool = false


## Bu seviyede reçetenin süresi (tick, KESİRLİ). SUNUM (`FlowBlock`) ve
## MANTIK (`SimStation`) AYNI hesaba bakar — ikisi ayrışırsa ilerleme çubuğu
## ile "sonraki hız" yazısı uyuşmaz (bkz. DESIGN.md D29).
##
## SÜREYİ tam sayıya YUVARLAMAYIZ: `SimStation.progress_ticks` kesirli bir
## biriktirici olarak çalışır (bkz. orada) ve her üretim döngüsünden kalan
## küsuratı bir sonrakine taşır. Süre burada yuvarlansaydı (ör. seviye 10'da
## 1.25 tick'in 1'e düşmesi gibi) o hata HER döngüde tekrar edip birikir ve
## "3 seviyede bir 2 katına çık" gibi formüller yüksek seviyelerde sapardı.
##
## Ama HIZI (adet/saniye) yuvarlarız — bkz. `_snap_duration_to_whole_rate`:
## oyuncu "7.56/sn" gibi kesirli bir gerçek üretim hızı GÖRMEMELİ, seviye
## 1'in üzerindeki her seviyenin ortalama hızı tam sayı olmalı.
func duration_ticks_at_level(target_level: int) -> float:
	if recipe == null:
		return 0.0
	if target_level <= 1 or not upgradeable:
		return float(recipe.duration_ticks)
	var raw_duration: float
	if upgrade_rate_increment > 0.0:
		var base_per_min: float = float(GameConfig.TICKS_PER_SECOND) * 60.0 / float(recipe.duration_ticks)
		var target_per_min: float = base_per_min + upgrade_rate_increment * float(target_level - 1)
		if target_per_min <= 0.0:
			return float(recipe.duration_ticks)
		raw_duration = float(GameConfig.TICKS_PER_SECOND) * 60.0 / target_per_min
	else:
		var factor: float = pow(upgrade_duration_factor, target_level - 1)
		raw_duration = float(recipe.duration_ticks) * factor
	return _snap_duration_to_whole_rate(raw_duration)


## `raw_duration` tick'inin ürettiği hızı (adet/sn) en yakın TAM SAYIYA
## kilitler, sonra o tam sayı hıza karşılık gelen süreyi geri döner.
##
## Dönen süre kendisi yine kesirli olabilir (ör. 0.833 tick) — bu SORUN
## DEĞİL: `SimStation.progress_ticks` küsuratı kayıpsız taşıdığı için
## (bkz. `duration_ticks_at_level` üstündeki not) uzun vadeli GERÇEK üretim
## ortalaması, sadece gösterimi değil, tam olarak bu tam sayıya oturur.
func _snap_duration_to_whole_rate(raw_duration: float) -> float:
	if raw_duration <= 0.0:
		return raw_duration
	var raw_rate: float = float(GameConfig.TICKS_PER_SECOND) / raw_duration
	var rounded_rate: float = maxf(1.0, roundf(raw_rate))
	return float(GameConfig.TICKS_PER_SECOND) / rounded_rate


func category_label() -> String:
	match category:
		Category.SOURCE: return "Gathering"
		Category.PROCESS: return "Crafting"
		Category.INSPECT: return "Inspection"
		Category.BUFFER: return "Storage"
		Category.SINK: return "Trade"
		Category.RESEARCH: return "Knowledge"
		Category.SPLITTER: return "Routing"
	return "Unknown"


func sale_value_multiplier_at_level(target_level: int) -> float:
	return 1.0 + sale_value_bonus_per_level * float(maxi(0, target_level - 1))


func is_power_generator() -> bool:
	return power_output > 0


func is_power_consumer() -> bool:
	return power_required_per_tick > 0


## Bu seviyede jeneratörün ürettiği güç. Geliştirme aynı ADDİTİF modeli
## kullanır (bkz. `duration_ticks_at_level`, DESIGN.md D29): maliyet katlanır,
## kapasite katlanmaz.
func power_output_at_level(target_level: int) -> int:
	if power_output <= 0:
		return 0
	if target_level <= 1 or not upgradeable:
		return power_output
	return power_output + roundi(upgrade_rate_increment * float(target_level - 1))


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


## Güç portunun satır indeksi — malzeme satırlarından hemen sonra gelir.
## `FlowBlock._build_rows()` VE bağlantı isteğini yorumlayan `GameController`
## AYNI bu değeri okur; ikisi ayrışırsa yanlış port güç sanılabilir.
func power_port_index() -> int:
	return maxi(input_labels().size(), output_labels().size())


func input_labels() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if category == Category.SOURCE:
		return out  # kaynak girdi istemez
	if power_only:
		return out  # yalnızca güç portu var, jenerik malzeme girişi yok
	if demand_item != null:
		out.append("Goods")
		out.append(demand_item.display_name)
		return out
	if recipe == null:
		out.append("Input")
		return out
	for slot: RecipeSlot in recipe.inputs:
		out.append(slot.label())
	return out


func output_labels() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if category == Category.SINK or category == Category.RESEARCH:
		return out  # bitiş noktasının çıkışı yok
	if power_only:
		return out  # yalnızca güç portu var, jenerik malzeme çıkışı yok
	if recipe == null:
		if output_port_count <= 1:
			out.append("Output")
		else:
			for i in output_port_count:
				out.append("Output %s" % char(65 + i))  # Çıkış A, B, C...
		return out
	if category == Category.INSPECT:
		# Kalite kontrolünde ürün SABİT, yalnızca dal değişir ("uygun"/"ret"
		# aynı ürünün iki hâli) — o yüzden karar adı okunur. Mine Extractor
		# gibi çıktısı zaten AYRI iki ürüne (Iron Ore/Coal) bölünen bloklarda
		# ise ürün adının kendisi daha açık, "Approved/Reject" yanıltıcı olur.
		if reject_item != null and not recipe.outputs.is_empty() and reject_item.id != recipe.outputs[0].item.id:
			out.append(recipe.outputs[0].label())
			out.append(reject_item.display_name)
			return out
		out.append("Approved")
		out.append("Reject")
		return out
	for slot: RecipeSlot in recipe.outputs:
		out.append(slot.label())
	return out
