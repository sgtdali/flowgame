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


func balance(gross_revenue: int) -> int:
	return GameConfig.START_MONEY + gross_revenue - spent



func is_unlocked(node_id: StringName) -> bool:
	return unlocked.has(node_id)


## Bu istasyon türü kurulabilir mi? (Araştırma açmış mı?)
func is_block_available(type: BlockType) -> bool:
	if type.unlocked_at_start:
		return true
	for node: ResearchNode in ResearchCatalog.all():
		if not unlocked.has(node.id):
			continue
		for block: BlockType in node.unlocks_blocks:
			if block.id == type.id:
				return true
	return false


func available_blocks() -> Array[BlockType]:
	var out: Array[BlockType] = []
	for type: BlockType in BlockCatalog.all():
		if is_block_available(type):
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


## İstasyon sökülünce maliyetinin bir kısmı geri döner.
## Tam iade olsaydı oyuncu bedava deneyebilirdi ve yanlış kurulumun bedeli
## kalmazdı; hiç iade olmasaydı deneme yapmaya korkardı.
func refund(cost: int) -> void:
	spent -= cost / 2
	changed.emit()


func reset() -> void:
	spent = 0
	unlocked.clear()
	changed.emit()


func to_dict() -> Dictionary:
	var ids: PackedStringArray = PackedStringArray()
	for node_id: StringName in unlocked:
		ids.append(String(node_id))
	return {"spent": spent, "unlocked": ids}


func from_dict(data: Dictionary) -> void:
	spent = int(data.get("spent", 0))
	unlocked.clear()
	for node_id: String in data.get("unlocked", []):
		unlocked[StringName(node_id)] = true
	changed.emit()
