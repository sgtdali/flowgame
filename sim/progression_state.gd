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

## Şimdiye kadar satın alınan geliştirme sayısı (bkz. `try_upgrade`).
## Erken oyun kilometre taşı bunu okur: oyuncu en az bir geliştirme
## almadan Ar-Ge Sarayı açılmaz (bkz. `GameConfig.MIN_UPGRADES_FOR_RESEARCH`,
## `BlockType.requires_first_upgrade`).
var upgrades_purchased: int = 0


func balance(gross_revenue: int) -> int:
	return GameConfig.START_MONEY + gross_revenue - spent



func is_unlocked(node_id: StringName) -> bool:
	return unlocked.has(node_id)


## Bu istasyon türü kurulabilir mi? (Araştırma açmış mı?)
##
## `tick_count`: yalnızca `requires_first_upgrade` taşıyan bloklar için
## anlamlı — erken oyun kilometre taşı (en az bir geliştirme) hiç
## karşılanmazsa GÜVENLİK AĞI olarak devreye giren uzun zamanlayıcı (bkz.
## `GameConfig.RESEARCH_FALLBACK_TICKS`). -1 = zamanlayıcı kontrolü atlanır
## (çağıran tick sayısını bilmiyorsa/önemsemiyorsa).
func is_block_available(type: BlockType, tick_count: int = -1) -> bool:
	if type.requires_first_upgrade:
		# KENDİ KENDİNE YETEN bir yol — `unlocked_at_start`'ın yerini alır,
		# ÜSTÜNE binmez. Eskiden "gate + normal kontrollere düş" şeklindeydi;
		# ama Ar-Ge Sarayı artık hiçbir araştırmanın unlocks_blocks'unda
		# YOK (bkz. D22/D27) — kapı geçilse bile normal kontroller hep false
		# dönüyordu. Bu yüzden kapı geçilince DOĞRUDAN true dönülür.
		var milestone_met: bool = upgrades_purchased >= GameConfig.MIN_UPGRADES_FOR_RESEARCH
		var timer_met: bool = tick_count >= 0 and tick_count >= GameConfig.RESEARCH_FALLBACK_TICKS
		return milestone_met or timer_met
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


func reset() -> void:
	spent = 0
	unlocked.clear()
	upgrades_purchased = 0
	changed.emit()


func to_dict() -> Dictionary:
	var ids: PackedStringArray = PackedStringArray()
	for node_id: StringName in unlocked:
		ids.append(String(node_id))
	return {"spent": spent, "unlocked": ids, "upgrades_purchased": upgrades_purchased}


func from_dict(data: Dictionary) -> void:
	spent = int(data.get("spent", 0))
	unlocked.clear()
	for node_id: String in data.get("unlocked", []):
		unlocked[StringName(node_id)] = true
	upgrades_purchased = int(data.get("upgrades_purchased", 0))
	changed.emit()
