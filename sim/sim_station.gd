class_name SimStation
extends RefCounted

## Simülasyondaki tek bir istasyonun DURUMU.
##
## Sahne ağacında yaşamaz, hiçbir görsel düğüm tanımaz. Bir `FlowBlock` bu
## durumu yansıtır ama sahibi burasıdır.

## Kalıcı kimlik. GraphEdit düğüm adı DEĞİL — ad değişebilir, id değişmez.
var id: int = -1
var type: BlockType = null

## Tamponlar: ürün id'si -> adet.
var input: Dictionary = {}
var output: Dictionary = {}

## Üretim durumu.
var producing: bool = false
## KESİRLİ ilerleme biriktiricisi (bkz. `duration_ticks_at_level`). Her tick
## 1.0 artar; süre dolunca üretim biter ve süre TAM OLARAK (yuvarlanmadan)
## düşülür — kalan küsurat bir sonraki döngüye taşınır. Bu yüzden `= 0`
## DEĞİL `-= duration` ile sıfırlanır: aksi hâlde her döngüde süre kesirliyse
## (ör. 1.25 tick) o küsurat kaybolur ve uzun vadeli hız formülden sapar.
var progress_ticks: float = 0.0
## Güç tüketen istasyonlarda (bkz. `type.power_required_per_tick`) BİRİKEN
## enerji. Malzeme hazır olduğu hâlde güç yetersizse `progress_ticks` yerine
## bu sayaç ilerler — yetersiz güç üretimi durdurmaz, oranlı yavaşlatır.
## Elektrik Satış Noktası da aynı sayaçla sürekli güç akışını kesikli satış
## birimlerine çevirir (bkz. FactorySim._run_power_sale).
var energy_ticks: int = 0
## Bu istasyona atanmış işçi sayısı. İlk işçi istasyonu çalıştırır; ilave
## işçilerin üretim etkisi bilinçli olarak daha sonraki denge turuna bırakıldı.

## Geliştirme seviyesi (1 = geliştirilmemiş). Yalnızca `type.upgradeable`
## olan istasyonlarda 1'den büyük olabilir. Kalıcıdır — kaydediliyor.
var level: int = 1

## Sevkiyat'ta TAHSİL EDİLMEMİŞ, o istasyona ait bekleyen para.
##
## Yalnızca SINK istasyonlarında anlamlı. Satış OTOMATİK olur (bkz.
## `FactorySim._run_sink`) ama para doğrudan harcanabilir kasaya değil BURAYA
## birikir — oyuncu "Tahsil Et" ile kasaya aktarana kadar harcanamaz. Satış
## HIZI göstergesi bu sayaca değil `consumed_total`'a bakar, o yüzden tahsilat
## tıklamaları hızı ETKİLEMEZ (bkz. DESIGN.md D27).
var accrued: int = 0

## Bu istasyonun ürettiği toplam parça. Fire sayacı buna bakar —
## rastgelelik yok, "her N üründen biri" deterministik olarak belirlenir.
var produced_total: int = 0

## Bu istasyonun YUTTUĞU toplam parça. Yalnızca Sevkiyat ve Ar-Ge
## Laboratuvarı için anlamlı — onlar üretmediği için `produced_total` hep
## sıfır kalır ve hız göstergesi boş görünürdü.
var consumed_total: int = 0

## Çıkış portu başına round-robin sayacı: port -> sıradaki bağlantı indeksi.
## Her port artık en fazla 1 bağlantı taşıyabildiği için pratikte hep 0'da
## kalır; birden fazla bağlantıya izin verilen tek yer buradaki kod yolu
## değil, Dağıtıcı'nın AYRI portlarıdır (bkz. next_output_port).
var next_link: Dictionary = {}

## Dağıtıcı gibi birden fazla ÇIKIŞ PORTU olan istasyonlarda, bir sonraki
## tick'te hangi portun ÖNCE denenecebeğini tutar.
##
## NEDEN GEREKLİ: tek bir parça birikmişken portlar sabit sırayla (0, 1, 2…)
## denenirse port 0 HER SEFERİNDE kazanır ve port 1 hiç beslenmez — ölçüldü,
## iki Hadde'ye bağlı bir Dağıtıcı'da ikincisi 3000 tick boyunca 0 üretti.
## Başlangıç portu her tick bir sonraki porta kaydırılınca (yalnızca bir
## gönderim başarılı olduğunda), az sayıda parça bile portlar arasında adil
## dönüşümlü dağılıyor.
var next_output_port: int = 0

## İstasyonun bu tick'teki durumu.
##
## AÇ ve TIKALI birbirinin TERSİ problemdir ve oyuncu bunları ayırt
## edebilmelidir:
##   AÇ KALDI (STARVED) → girdisi gelmiyor, ÖNCEKİ istasyon yavaş
##   TIKANDI (BLOCKED)  → çıktısını boşaltamıyor, SONRAKİ istasyon yavaş
## İkisini tek bir "blocked" bayrağında birleştirmek, oyunun asıl teşhis
## aracını kör eder.
enum Status { RUNNING, STARVED, BLOCKED, UNPOWERED }

var status: Status = Status.STARVED


## Port sayıları. Kurulumda bir kez hesaplanır: `input_labels()` her
## çağrıldığında yeni dizi ayırıyor, bunlar ise her karede sorulacak.
var input_port_count: int = 0
var output_port_count: int = 0


func _init(p_id: int = -1, p_type: BlockType = null) -> void:
	id = p_id
	type = p_type
	if type != null:
		input_port_count = type.input_labels().size()
		output_port_count = type.output_labels().size()


## Girdi tamponundaki toplam adet. Jenerik istasyonlar (tampon, sevkiyat)
## kapasiteyi ürün başına değil, toplam üzerinden uygular.
func total_input() -> int:
	return _sum(input)


func total_output() -> int:
	return _sum(output)


func recipe() -> Recipe:
	return type.recipe


## Bu istasyonun GEÇERLİ seviyesindeki reçete süresi (tick). Hesap
## `BlockType.duration_ticks_at_level`'da yaşar — `FlowBlock` da AYNI
## fonksiyonu çağırır, ikisi ayrışırsa ilerleme çubuğu ile düğümün
## gösterdiği "sonraki hız" yazısı uyuşmaz.
func effective_duration_ticks() -> float:
	return type.duration_ticks_at_level(level)


## Güç sistemi enerji birimlerini TAM SAYI tutar (bkz. `energy_ticks`,
## FactorySim._run_powered_producer) — kesirli biriktirici oradaki mekanikle
## uyuşmaz. Güçle ilgili eşik hesapları bu yüzden YUVARLANMIŞ süreyi okur;
## FactorySim AYNI fonksiyonu çağırmalı, yoksa "TIKALI" eşiği ile ilerleme
## çubuğu ayrışır.
func effective_duration_ticks_rounded() -> int:
	return maxi(1, roundi(effective_duration_ticks()))


## İlerleme oranı (0.0 - 1.0). Sunumdaki ilerleme çubuğu için.
##
## Süresi 0 olan reçetelerde (bkz. Eritme Ocağı, DESIGN.md "Smelting Hearth
## redesign") üretim aynı tick içinde başlayıp bitiyor — `progress_ticks`'in
## gösterecek bir aralığı yok. Onun yerine girdi tamponunun ne kadar dolu
## olduğunu gösteririz: çubuk 6. cevher gelene dek dolar, dönüşümde sıfırlanır.
func progress_ratio() -> float:
	if type.is_power_consumer():
		if not producing:
			return 0.0
		var required: int = effective_duration_ticks_rounded() * type.power_required_per_tick
		if required <= 0:
			return 0.0
		return clampf(float(energy_ticks) / float(required), 0.0, 1.0)
	if type.demand_item != null:
		return _demand_fill_ratio()
	var duration: float = effective_duration_ticks()
	if duration <= 0.0:
		return _input_fill_ratio()
	if not producing:
		return 0.0
	return clampf(progress_ticks / duration, 0.0, 1.0)


## `progress_ratio`'nun süresiz reçeteler için baktığı girdi doluluğu.
## Eritme Ocağı artık İKİ girdi istiyor (60 cevher + 6 kömür, bkz.
## r_kulce.tres) — dönüşüm İKİSİ de tamamlanınca olur, o yüzden çubuk en
## DAR boğazı gösterir: hangi girdi daha az doluysa (en küçük oran) o,
## dönüşümü geciktiren gerçek darboğazdır.
func _input_fill_ratio() -> float:
	var r: Recipe = recipe()
	if r == null or r.inputs.is_empty():
		return 0.0
	var narrowest: float = 1.0
	for slot: RecipeSlot in r.inputs:
		if slot.count <= 0:
			continue
		var have: int = int(input.get(slot.item.id, 0))
		narrowest = minf(narrowest, float(have) / float(slot.count))
	return clampf(narrowest, 0.0, 1.0)


## Trade Depot gibi TALEP KAPILI bloklarda `progress_ratio`'nun baktığı
## dolgunluk. Elde bekleyen mal YOKSA çubuk boştur (satacak bir şey yok);
## varsa çubuk `demand_required` eşiğine göre Talep'in ne kadar biriktiğini
## gösterir — yani DOĞRUDAN Trade Network'ün hızıyla dolar, kendi başına bir
## zamanlayıcısı yoktur (bkz. `BlockType.demand_item` dokümantasyonu).
func _demand_fill_ratio() -> float:
	var demand_id: StringName = type.demand_item.id
	var has_goods: bool = false
	for key: StringName in input.keys():
		if key != demand_id and int(input[key]) > 0:
			has_goods = true
			break
	if not has_goods:
		return 0.0
	var required: int = maxi(1, type.demand_required)
	var have: int = int(input.get(demand_id, 0))
	return clampf(float(have) / float(required), 0.0, 1.0)


func add_item(buffer: Dictionary, item_id: StringName, count: int) -> void:
	buffer[item_id] = int(buffer.get(item_id, 0)) + count


## İstenen adedi düşer. Yeterli yoksa hiçbir şey yapmaz ve false döner.
func take_item(buffer: Dictionary, item_id: StringName, count: int) -> bool:
	var have: int = int(buffer.get(item_id, 0))
	if have < count:
		return false
	if have == count:
		buffer.erase(item_id)
	else:
		buffer[item_id] = have - count
	return true


## Hız göstergesinin baktığı sayaç. Üreten istasyonlarda üretim, yutan
## istasyonlarda tüketim.
func throughput_total() -> int:
	match type.category:
		BlockType.Category.SINK, BlockType.Category.RESEARCH:
			return consumed_total
	return produced_total


func status_label() -> String:
	return status_name(status)


static func status_name(value: Status) -> String:
	match value:
		Status.RUNNING: return "working"
		Status.STARVED: return "starved"
		Status.BLOCKED: return "blocked"
		Status.UNPOWERED: return "unpowered"
	return "?"


static func _sum(buffer: Dictionary) -> int:
	var total: int = 0
	for count: int in buffer.values():
		total += count
	return total
