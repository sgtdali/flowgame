class_name ProgressionState
extends RefCounted

## Oyuncunun ilerlemesi: harcanan para, açılmış araştırmalar, slot tavanı.
##
## Para BAKİYE olarak tutulmaz, TÜRETİLİR:
##     bakiye = başlangıç + simülasyonun toplam geliri - harcanan
## Böylece iki ayrı defter tutulmaz. Simülasyon geliri zaten deterministik
## olarak sayıyor; burada onun kopyasını tutsaydık er geç ayrışırlardı.

signal changed

## Araştırmanın oyuncuya görünen durumu.
enum Status {
	UNLOCKED,   ## alınmış
	AFFORDABLE, ## ön koşullar tamam, bedeli ödenebilir
	PENDING,    ## ön koşullar tamam, bedel henüz yetmiyor
	LOCKED,     ## ön koşullar tamamlanmamış
}

var spent: int = 0
var unlocked: Dictionary = {}   # araştırma id -> true

## Şimdiye kadar satın alınan geliştirme sayısı. İleride istatistik veya
## başarımlar için korunur; araştırma erişimine yapay kapı koymaz.
var upgrades_purchased: int = 0

## Ürün id'si (String) -> mevcut satış geliştirme seviyesi. Araştırma
## ağacının DIŞINDA, tekrar satın alınabilen küresel bir geliştirme (bkz.
## ItemType.sale_upgradeable) — Iron Ore'un satış fiyatını HER YERDE
## etkiler, tek bir istasyonu değil. Eksik anahtar = seviye 1 (taban fiyat).
var item_levels: Dictionary = {}


func balance(gross_revenue: int) -> int:
	return GameConfig.START_MONEY + gross_revenue - spent



func is_unlocked(node_id: StringName) -> bool:
	return unlocked.has(node_id)


## Bu istasyon türü kurulabilir mi? (Araştırma açmış mı?)
##
func is_block_available(type: BlockType, _tick_count: int = -1) -> bool:
	if type.unlocked_at_start:
		return true
	for node: ResearchNode in ResearchCatalog.all():
		if not unlocked.has(node.id):
			continue
		for block: BlockType in node.unlocks_blocks:
			if block.id == type.id:
				return true
	return false


func available_blocks(tick_count: int = -1) -> Array[BlockType]:
	var out: Array[BlockType] = []
	for type: BlockType in BlockCatalog.all():
		if is_block_available(type, tick_count):
			out.append(type)
	return out


func requirements_met(node: ResearchNode) -> bool:
	for required: String in node.requires:
		if not unlocked.has(StringName(required)):
			return false
	return true


func status_of(node: ResearchNode, gross_revenue: int, research_counts: Dictionary) -> Status:
	if unlocked.has(node.id):
		return Status.UNLOCKED
	if not requirements_met(node):
		return Status.LOCKED
	return Status.AFFORDABLE if _cost_met(node, gross_revenue, research_counts) else Status.PENDING


## Bedeli karşılanıyor mu? Para maliyetli araştırmada bakiyeye, ürün
## maliyetlide laboratuvara akıtılan miktara bakar.
func _cost_met(node: ResearchNode, gross_revenue: int, research_counts: Dictionary) -> bool:
	if node.is_item_cost():
		var progress: Array = item_progress(node, research_counts)
		return progress[0] >= progress[1]
	return balance(gross_revenue) >= node.cost_money


## Ürün maliyetli araştırmanın ilerlemesi: [akıtılan, gereken].
## Para maliyetli araştırmada [0, 0] döner.
func item_progress(node: ResearchNode, research_counts: Dictionary) -> Array:
	if not node.is_item_cost():
		return [0, 0]
	var have: int = 0
	var need: int = 0
	for slot: RecipeSlot in node.cost_items:
		have += int(research_counts.get(slot.item.id, 0))
		need += slot.count
	return [mini(have, need), need]


## Neden alınamıyor? Boş string = alınabilir.
func unlock_problem(node: ResearchNode, gross_revenue: int, research_counts: Dictionary) -> String:
	if unlocked.has(node.id):
		return "This knowledge is already discovered."
	if not requirements_met(node):
		return "Discover the earlier knowledge first."
	if node.is_item_cost():
		var progress: Array = item_progress(node, research_counts)
		if progress[0] < progress[1]:
			return "Goods delivered to the Scholars Hall: %d / %d." % [progress[0], progress[1]]
		return ""
	if balance(gross_revenue) < node.cost_money:
		return "Not enough gold. You need %s." % GameConfig.format_money(node.cost_money)
	return ""


## Araştırmayı alır. Başarısızsa sebebini döner, başarılıysa boş string.
##
## Ürün maliyetli araştırmada ürün GERİ ALINMAZ: laboratuvara akıtılan zaten
## harcanmış sayılır. Sayacı sıfırlamak, birden fazla ürün maliyetli araştırma
## eklendiğinde gerekecek — MVP'de tek tane var.
func try_unlock(node: ResearchNode, gross_revenue: int, research_counts: Dictionary) -> String:
	var problem: String = unlock_problem(node, gross_revenue, research_counts)
	if not problem.is_empty():
		return problem
	if not node.is_item_cost():
		spent += node.cost_money
	unlocked[node.id] = true
	changed.emit()
	return ""


## İstasyon kurmak için para düşer. Yetmezse false döner.
func try_pay(cost: int, gross_revenue: int) -> bool:
	if balance(gross_revenue) < cost:
		return false
	spent += cost
	changed.emit()
	return true


## Bu istasyonu bir sonraki seviyeye geliştirmenin maliyeti. Zaten en üst
## seviyedeyse veya geliştirilemiyorsa 0 döner — çağıran `can_upgrade` ile
## önce kontrol etmeli.
## Saf (içerik-türevi) — bir ProgressionState örneğine gerek duymaz, sunum
## katmanı (bkz. FlowBlock) doğrudan `ProgressionState.upgrade_cost(...)`
## diye çağırabilir.
static func upgrade_cost(type: BlockType, current_level: int) -> int:
	if not type.upgradeable or current_level >= type.max_level:
		return 0
	return roundi(float(type.upgrade_base_cost) * pow(type.upgrade_cost_growth, current_level - 1))


static func can_upgrade(type: BlockType, current_level: int) -> bool:
	return type.upgradeable and current_level < type.max_level


## Neden geliştirilemiyor? Boş string = geliştirilebilir.
func upgrade_problem(station: SimStation, gross_revenue: int) -> String:
	if not station.type.upgradeable:
		return "This workshop cannot be upgraded."
	if station.level >= station.type.max_level:
		return "Already at the highest level."
	var cost: int = upgrade_cost(station.type, station.level)
	if balance(gross_revenue) < cost:
		return "Not enough gold. You need %s." % GameConfig.format_money(cost)
	return ""


## İstasyonu bir seviye geliştirir. Kalıcıdır (bkz. SimStation.level) — yeni
## bir para birimi, bakım maliyeti veya işçi taşıma GEREKMEZ (bkz. D27).
func try_upgrade(station: SimStation, gross_revenue: int) -> String:
	var problem: String = upgrade_problem(station, gross_revenue)
	if not problem.is_empty():
		return problem
	var cost: int = upgrade_cost(station.type, station.level)
	spent += cost
	station.level += 1
	upgrades_purchased += 1
	changed.emit()
	return ""


## İstasyon sökülünce maliyetinin bir kısmı geri döner.
## Tam iade olsaydı oyuncu bedava deneyebilirdi ve yanlış kurulumun bedeli
## kalmazdı; hiç iade olmasaydı deneme yapmaya korkardı.
func refund(cost: int) -> void:
	spent -= cost / 2
	changed.emit()


## --- Ürün satış geliştirmesi (araştırma ağacının DIŞINDA) -------------------
##
## `station.level`'ın aksine bu bir istasyona değil ÜRÜNE bağlıdır — Iron
## Ore'u nerede satarsan sat (Collector, ileride başka bir satış noktası)
## aynı yükseltilmiş fiyatla satılır. Bu yüzden `item_levels` burada,
## SimStation'da değil yaşar.

func item_level(item: ItemType) -> int:
	return int(item_levels.get(String(item.id), 1))


## Saf (içerik-türevi) — `BlockType.upgrade_cost`/`sale_value_multiplier_
## at_level` ile AYNI desen, bkz. orada.
static func item_sale_multiplier(item: ItemType, current_level: int) -> float:
	return 1.0 + item.sale_bonus_per_level * float(maxi(0, current_level - 1))


static func item_upgrade_cost(item: ItemType, current_level: int) -> int:
	if not item.sale_upgradeable or current_level >= item.sale_max_level:
		return 0
	return roundi(float(item.sale_upgrade_base_cost) * pow(item.sale_upgrade_cost_growth, current_level - 1))


static func can_upgrade_item(item: ItemType, current_level: int) -> bool:
	return item.sale_upgradeable and current_level < item.sale_max_level


## Neden geliştirilemiyor? Boş string = geliştirilebilir.
func item_upgrade_problem(item: ItemType, gross_revenue: int) -> String:
	var level: int = item_level(item)
	if not item.sale_upgradeable:
		return "This good cannot be upgraded."
	if level >= item.sale_max_level:
		return "Already at the highest level."
	var cost: int = item_upgrade_cost(item, level)
	if balance(gross_revenue) < cost:
		return "Not enough gold. You need %s." % GameConfig.format_money(cost)
	return ""


## Ürünün satış fiyatını bir seviye yükseltir. Kalıcıdır (kayıtta yer alır,
## bkz. to_dict/from_dict).
func try_upgrade_item(item: ItemType, gross_revenue: int) -> String:
	var problem: String = item_upgrade_problem(item, gross_revenue)
	if not problem.is_empty():
		return problem
	var level: int = item_level(item)
	var cost: int = item_upgrade_cost(item, level)
	spent += cost
	item_levels[String(item.id)] = level + 1
	upgrades_purchased += 1
	changed.emit()
	return ""


func reset() -> void:
	spent = 0
	unlocked.clear()
	upgrades_purchased = 0
	item_levels.clear()
	changed.emit()


func to_dict() -> Dictionary:
	var ids: PackedStringArray = PackedStringArray()
	for node_id: StringName in unlocked:
		ids.append(String(node_id))
	return {
		"spent": spent, "unlocked": ids, "upgrades_purchased": upgrades_purchased,
		"item_levels": item_levels.duplicate(),
	}


func from_dict(data: Dictionary) -> void:
	spent = int(data.get("spent", 0))
	unlocked.clear()
	for node_id: String in data.get("unlocked", []):
		unlocked[StringName(node_id)] = true
	upgrades_purchased = int(data.get("upgrades_purchased", 0))
	item_levels.clear()
	for item_id: String in data.get("item_levels", {}):
		item_levels[item_id] = int(data["item_levels"][item_id])
	changed.emit()
