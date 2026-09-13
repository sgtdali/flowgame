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
var progress_ticks: int = 0

## Bu istasyonun ürettiği toplam parça. Fire sayacı buna bakar —
## rastgelelik yok, "her N üründen biri" deterministik olarak belirlenir.
var produced_total: int = 0

## Bu istasyonun YUTTUĞU toplam parça. Yalnızca Sevkiyat ve Ar-Ge
## Laboratuvarı için anlamlı — onlar üretmediği için `produced_total` hep
## sıfır kalır ve hız göstergesi boş görünürdü.
var consumed_total: int = 0

## Çıkış portu başına round-robin sayacı: port -> sıradaki bağlantı indeksi.
var next_link: Dictionary = {}

## İstasyonun bu tick'teki durumu.
##
## AÇ ve TIKALI birbirinin TERSİ problemdir ve oyuncu bunları ayırt
## edebilmelidir:
##   AÇ KALDI (STARVED) → girdisi gelmiyor, ÖNCEKİ istasyon yavaş
##   TIKANDI (BLOCKED)  → çıktısını boşaltamıyor, SONRAKİ istasyon yavaş
## İkisini tek bir "blocked" bayrağında birleştirmek, oyunun asıl teşhis
## aracını kör eder.
enum Status { RUNNING, STARVED, BLOCKED }

var status: Status = Status.STARVED


func _init(p_id: int = -1, p_type: BlockType = null) -> void:
	id = p_id
	type = p_type


## Girdi tamponundaki toplam adet. Jenerik istasyonlar (tampon, sevkiyat)
## kapasiteyi ürün başına değil, toplam üzerinden uygular.
func total_input() -> int:
	return _sum(input)


func total_output() -> int:
	return _sum(output)


func recipe() -> Recipe:
	return type.recipe


## İlerleme oranı (0.0 - 1.0). Sunumdaki ilerleme çubuğu için.
func progress_ratio() -> float:
	if not producing:
		return 0.0
	var recipe_ref: Recipe = recipe()
	if recipe_ref == null or recipe_ref.duration_ticks <= 0:
		return 0.0
	return clampf(float(progress_ticks) / float(recipe_ref.duration_ticks), 0.0, 1.0)


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
		Status.RUNNING: return "çalışıyor"
		Status.STARVED: return "aç"
		Status.BLOCKED: return "tıkalı"
	return "?"


static func _sum(buffer: Dictionary) -> int:
	var total: int = 0
	for count: int in buffer.values():
		total += count
	return total
