class_name BalanceLib
extends RefCounted

## Denge araçlarının (balance_search.gd, balance_audit.gd) PAYLAŞTIĞI
## çekirdek: Sandbox, aşama tanımları, üç stratejinin gerçek istasyon/
## bağlantı planları. TEK kaynak — iki araç aynı mantığı kopyalayıp
## birbirinden ayrışma riskine girmesin diye buraya çıkarıldı.
##
## `tools/balance_search.gd`'nin dosya başı notundaki "NE YAPAR / NE YAPMAZ"
## kuralları burası için de geçerli: gerçek FactorySim/ProgressionState
## çağrılır, yaklaşık bir ekonomi modeli kurulmaz.

const ACTION_SECONDS := {
	"build": 6.0,
	"wire": 3.0,
	"unwire": 2.0,
	"staff": 2.5,
	"research_click": 1.5,
}

const TARGET_SAVINGS_MIN := 0.20
const TARGET_SAVINGS_MAX := 0.35

const MAX_STAGE_TICKS: int = GameConfig.TICKS_PER_SECOND * 60 * 90

## Bu koşumda kilitlenen/gecersiz olcum sayisi — cagiran arac okur.
var fail_count: int = 0


## Aday miktarlar KUCUK ve GEREKCELI (bkz. DESIGN.md D22/D23): mevcut
## deger ve mevcut degerin kabaca 1.5x-3x'i. Ilk iki asama ogretici olarak
## KISA kalmali. Son iki asama gercek kaynak rekabetinin oldugu asamalar.
func stage_defs() -> Array:
	return [
		{
			"name": "presleme", "node": ResearchCatalog.PRESLEME,
			"item": "cevher", "label": "Iron Ore", "reward_display": "Hammer Forge",
			"candidates": [24, 40, 60], "teaching": true,
		},
		{
			"name": "kalkan_zanaati", "node": ResearchCatalog.KALKAN_ZANAATI,
			"item": "levha", "label": "Iron Plate", "reward_display": "Shieldwright",
			"candidates": [15, 25, 40], "teaching": true,
		},
		{
			"name": "kask_zanaati", "node": ResearchCatalog.KASK_ZANAATI,
			"item": "kalkan", "label": "Iron Shield", "reward_display": "Helm Forge",
			"candidates": [35, 60, 90, 120], "teaching": false,
		},
		{
			"name": "kask_bantlama", "node": ResearchCatalog.KASK_BANTLAMA,
			"item": "kask", "label": "Iron Helm", "reward_display": "Helm Bander",
			"candidates": [20, 35, 55, 80], "teaching": false,
		},
	]


## --- Sandbox: gercek sim + progression, ölçüm defteri ile sarmalanmis ------

class Sandbox:
	var sim: FactorySim
	var prog: ProgressionState
	var ids: Dictionary = {}
	var extra: Dictionary = {}
	var action_seconds: float = 0.0
	var action_scale: float = 1.0
	var halted: bool = false
	var fail_reason: String = ""
	var starved_ticks: int = 0
	var _watch_id: int = -1

	## Teshis: bu sandbox'ta, PARA BEKLEME yuzunden gecen toplam tick.
	## "hangi kisitin belirleyici oldugu" sorusuna (denetim raporu) somut
	## cevap vermek icin — uretim/akis bekleme suresinden AYRI tutulur.
	var money_wait_ticks: int = 0

	func _init(scale: float = 1.0) -> void:
		sim = FactorySim.new()
		prog = ProgressionState.new()
		action_scale = scale

	func clone() -> Sandbox:
		var sb := Sandbox.new(action_scale)
		sb.sim.from_dict(sim.to_dict())
		sb.prog.from_dict(prog.to_dict())
		sb.ids = ids.duplicate()
		sb.extra = extra.duplicate()
		sb.action_seconds = action_seconds
		sb._watch_id = _watch_id
		sb.money_wait_ticks = money_wait_ticks
		return sb

	func act(kind: String) -> void:
		action_seconds += float(ACTION_SECONDS.get(kind, 0.0)) * action_scale

	func build(type: BlockType) -> int:
		if halted or type == null:
			return -1
		if not prog.try_pay(type.build_cost, sim.revenue):
			var t0: int = sim.tick_count
			if not run_until(func() -> bool: return prog.balance(sim.revenue) >= type.build_cost,
					"para birikimi: %s" % type.display_name):
				return -1
			money_wait_ticks += sim.tick_count - t0
			prog.try_pay(type.build_cost, sim.revenue)
		var id: int = sim.add_station(type)
		act("build")
		return id

	func wire(a: int, ap: int, b: int, bp: int) -> void:
		if halted or a < 0 or b < 0:
			return
		if not sim.connect_stations(a, ap, b, bp):
			var an: String = sim.get_station(a).type.display_name if sim.get_station(a) != null else "?"
			var bn: String = sim.get_station(b).type.display_name if sim.get_station(b) != null else "?"
			fail("baglanti kurulamadi %d:%d(%s) -> %d:%d(%s) (%s) | ids=%s" % [
				a, ap, an, b, bp, bn, sim.connection_problem(a, ap, b, bp), ids])
			return
		act("wire")

	func unwire(a: int, ap: int, b: int, bp: int) -> void:
		if halted:
			return
		sim.disconnect_stations(a, ap, b, bp)
		act("unwire")

	func staff(id: int) -> void:
		if halted or id < 0:
			return
		var st: SimStation = sim.get_station(id)
		if st == null or not st.type.requires_worker():
			return
		if sim.workers_assigned() >= sim.workers_total:
			if not run_until(func() -> bool: return sim.food >= GameConfig.RECRUIT_FOOD_COST,
					"yiyecek (isci alimi)"):
				return
			if not sim.recruit_worker():
				fail("isci alinamadi: yiyecek yetersiz")
				return
		sim.set_worker(id, true)
		act("staff")

	func run_until(predicate: Callable, label: String) -> bool:
		if halted:
			return false
		var t: int = 0
		while not predicate.call():
			sim.tick()
			t += 1
			if _watch_id >= 0:
				var st: SimStation = sim.get_station(_watch_id)
				if st != null and st.status == SimStation.Status.STARVED:
					starved_ticks += 1
			if t > MAX_STAGE_TICKS:
				fail("zaman asimi: %s" % label)
				return false
		return true

	func fail(reason: String) -> void:
		if halted:
			return
		halted = true
		fail_reason = reason


## --- Ortak temel: gida hatti + baslangic demir hatti + Ar-Ge Sarayi --------
func build_baseline(money_offset: int, action_scale: float) -> Sandbox:
	var sb := Sandbox.new(action_scale)
	sb.prog.spent = money_offset

	var farm: int = sb.build(BlockCatalog.FARM)
	var mill: int = sb.build(BlockCatalog.MILL)
	var bakery: int = sb.build(BlockCatalog.BAKERY)
	var granary: int = sb.build(BlockCatalog.GRANARY)
	sb.wire(farm, 0, mill, 0)
	sb.wire(mill, 0, bakery, 0)
	sb.wire(bakery, 0, granary, 0)
	sb.staff(farm)
	sb.staff(mill)
	sb.staff(bakery)

	var maden1: int = sb.build(BlockCatalog.MADEN_OCAGI)
	var sevkiyat: int = sb.build(BlockCatalog.SEVKIYAT)
	sb.wire(maden1, 0, sevkiyat, 0)
	sb.staff(maden1)
	var eritme1: int = sb.build(BlockCatalog.ERITME)
	sb.staff(eritme1)
	sb.unwire(maden1, 0, sevkiyat, 0)
	sb.wire(maden1, 0, eritme1, 0)
	sb.wire(eritme1, 0, sevkiyat, 0)

	var lab: int = sb.build(BlockCatalog.ARGE_LAB)

	sb.ids = {
		"farm": farm, "mill": mill, "bakery": bakery, "granary": granary,
		"maden1": maden1, "eritme1": eritme1, "sevkiyat": sevkiyat, "lab": lab,
	}
	sb._watch_id = eritme1
	return sb


func node_with_quantity(base_node: ResearchNode, quantity: int) -> ResearchNode:
	var node: ResearchNode = base_node.duplicate(true)
	node.cost_items[0].count = quantity
	return node


## Bir asama tamamlaninca, laboratuvara giden akisi SATISA geri baglar —
## bkz. balance_search.gd'nin ayni isimli eski fonksiyonundaki NEDEN notu.
func reroute_lab_outputs_to_market(sb: Sandbox) -> void:
	if sb.halted or not sb.ids.has("lab") or not sb.ids.has("sevkiyat"):
		return
	for link: SimLink in sb.sim.links():
		if link.to_id == sb.ids.lab:
			sb.unwire(link.from_id, link.from_port, sb.ids.lab, 0)
			sb.wire(link.from_id, link.from_port, sb.ids.sevkiyat, 0)


func savings(minimum: Dictionary, other: Dictionary) -> float:
	if minimum.seconds_total <= 0.0:
		return 0.0
	return (minimum.seconds_total - other.seconds_total) / minimum.seconds_total


## --- Asama yürütücüsü: strateji baslangicini secip calistirir, olcer ------
func run_stage(base: Sandbox, stage: Dictionary, strategy: String, quantity: int) -> Dictionary:
	var sb: Sandbox = base.clone()
	var node: ResearchNode = node_with_quantity(stage.node, quantity)

	var t0: int = sb.sim.tick_count
	var money0: int = sb.prog.spent
	var workers0: int = sb.sim.workers_total
	var action0: float = sb.action_seconds
	var starved0: int = sb.starved_ticks
	var money_wait0: int = sb.money_wait_ticks

	match stage.name:
		"presleme": _stage_presleme(sb, strategy)
		"kalkan_zanaati": _stage_kalkan_zanaati(sb, strategy)
		"kask_zanaati": _stage_kask_zanaati(sb, strategy)
		"kask_bantlama": _stage_kask_bantlama(sb, strategy)
		_: sb.fail("bilinmeyen asama: %s" % stage.name)

	var ok: bool = sb.run_until(
		func() -> bool: return sb.prog.unlock_problem(node, 0, sb.sim.research_counts).is_empty(),
		"arastirma: %s (%s, adet=%d)" % [stage.name, strategy, quantity])
	if ok:
		sb.prog.try_unlock(node, 0, sb.sim.research_counts)
		sb.act("research_click")

	if not ok:
		fail_count += 1

	var result: Dictionary = {
		"stage": stage.name, "strategy": strategy, "quantity": quantity,
		"completed": ok, "deadlocked": not ok,
		"fail_reason": sb.fail_reason,
		"ticks": sb.sim.tick_count - t0,
		"seconds_sim": float(sb.sim.tick_count - t0) / float(GameConfig.TICKS_PER_SECOND),
		"action_seconds": sb.action_seconds - action0,
		"money_spent": sb.prog.spent - money0,
		"workers_recruited": sb.sim.workers_total - workers0,
		"starved_ticks": sb.starved_ticks - starved0,
		"money_wait_seconds": float(sb.money_wait_ticks - money_wait0) / float(GameConfig.TICKS_PER_SECOND),
	}
	result["seconds_total"] = result.seconds_sim + result.action_seconds
	result["_sandbox"] = sb
	return result


## --- Aşama stratejileri -----------------------------------------------------
##
## Ortak desen: MINIMUM en ucuz/en az kurulumlu (mevcut hatti bolme veya
## donusturme). HEDEFLI, paylasilan darbogazi ucuz bir ek istasyonla giderir
## (extra dict'te izlenir, sonraki asamalarda TEKRAR KULLANILIR). AYRI HAT,
## mevcut gelir hattina hic dokunmadan bagimsiz bir zincir kurar.
##
## ADALET KURALI (denetimde bulunup duzeltildi): bir stratejinin butun
## PARA GEREKTIREN satin almalari, MEVCUT gelir kesilmeden once yapilir.
## Once kesip sonra parasini beklemek, o stratejiyi YAPAY OLARAK yavas
## gosterir — bu satin alma sirasi kuralinin nedeni budur, her asamada
## tutarli uygulanir.

func _stage_presleme(sb: Sandbox, strategy: String) -> void:
	match strategy:
		"minimum":
			var dag: int = sb.build(BlockCatalog.DAGITICI)
			sb.unwire(sb.ids.maden1, 0, sb.ids.eritme1, 0)
			sb.wire(sb.ids.maden1, 0, dag, 0)
			sb.wire(dag, 0, sb.ids.eritme1, 0)
			sb.wire(dag, 1, sb.ids.lab, 0)
			sb.ids["dag_cevher"] = dag
		"targeted":
			var dag: int = sb.build(BlockCatalog.DAGITICI)
			var maden2: int = sb.build(BlockCatalog.MADEN_OCAGI)
			sb.staff(maden2)
			sb.unwire(sb.ids.maden1, 0, sb.ids.eritme1, 0)
			sb.wire(sb.ids.maden1, 0, dag, 0)
			sb.wire(maden2, 0, dag, 0)
			sb.wire(dag, 0, sb.ids.eritme1, 0)
			sb.wire(dag, 1, sb.ids.lab, 0)
			sb.ids["dag_cevher"] = dag
			sb.ids["maden2"] = maden2
			sb.extra["ore_boosted"] = true
		"separate":
			var maden2: int = sb.build(BlockCatalog.MADEN_OCAGI)
			sb.staff(maden2)
			sb.wire(maden2, 0, sb.ids.lab, 0)
			sb.ids["maden2"] = maden2


func _stage_kalkan_zanaati(sb: Sandbox, strategy: String) -> void:
	match strategy:
		"minimum":
			var pres: int = sb.build(BlockCatalog.PRES)
			sb.staff(pres)
			sb.unwire(sb.ids.eritme1, 0, sb.ids.sevkiyat, 0)
			sb.wire(sb.ids.eritme1, 0, pres, 0)
			sb.wire(pres, 0, sb.ids.lab, 0)
			sb.ids["pres1"] = pres
		"targeted":
			var pres: int = sb.build(BlockCatalog.PRES)
			sb.staff(pres)
			if not sb.extra.get("ore_boosted", false):
				var maden2: int = sb.build(BlockCatalog.MADEN_OCAGI)
				sb.staff(maden2)
				sb.wire(maden2, 0, sb.ids.eritme1, 0)
				sb.ids["maden2"] = maden2
				sb.extra["ore_boosted"] = true
			sb.unwire(sb.ids.eritme1, 0, sb.ids.sevkiyat, 0)
			sb.wire(sb.ids.eritme1, 0, pres, 0)
			sb.wire(pres, 0, sb.ids.lab, 0)
			sb.ids["pres1"] = pres
		"separate":
			var maden2: int = sb.build(BlockCatalog.MADEN_OCAGI)
			var eritme2: int = sb.build(BlockCatalog.ERITME)
			var pres2: int = sb.build(BlockCatalog.PRES)
			sb.staff(maden2)
			sb.staff(eritme2)
			sb.staff(pres2)
			sb.wire(maden2, 0, eritme2, 0)
			sb.wire(eritme2, 0, pres2, 0)
			sb.wire(pres2, 0, sb.ids.lab, 0)
			sb.ids["maden2"] = maden2
			sb.ids["eritme2"] = eritme2
			sb.ids["pres1"] = pres2


func _stage_kask_zanaati(sb: Sandbox, strategy: String) -> void:
	var ustasi: int = sb.build(BlockCatalog.KALKAN_USTASI)
	sb.staff(ustasi)
	sb.ids["kalkan_ustasi"] = ustasi

	match strategy:
		"minimum":
			var dag_kulce: int = sb.build(BlockCatalog.DAGITICI)
			var dag_kalkan: int = sb.build(BlockCatalog.DAGITICI)
			sb.unwire(sb.ids.pres1, 0, sb.ids.sevkiyat, 0)
			sb.unwire(sb.ids.eritme1, 0, sb.ids.pres1, 0)
			sb.wire(sb.ids.eritme1, 0, dag_kulce, 0)
			sb.wire(dag_kulce, 0, sb.ids.pres1, 0)
			sb.wire(dag_kulce, 1, ustasi, 0)
			sb.wire(sb.ids.pres1, 0, ustasi, 1)
			sb.wire(ustasi, 0, dag_kalkan, 0)
			sb.wire(dag_kalkan, 0, sb.ids.sevkiyat, 0)
			sb.wire(dag_kalkan, 1, sb.ids.lab, 0)
		"targeted":
			if not sb.extra.has("kulce_extra_id"):
				var maden2: int = sb.build(BlockCatalog.MADEN_OCAGI)
				var eritme2: int = sb.build(BlockCatalog.ERITME)
				sb.staff(maden2)
				sb.staff(eritme2)
				sb.wire(maden2, 0, eritme2, 0)
				sb.extra["kulce_extra_id"] = eritme2
				sb.ids["eritme2"] = eritme2
			var dag_kalkan: int = sb.build(BlockCatalog.DAGITICI)
			sb.unwire(sb.ids.pres1, 0, sb.ids.sevkiyat, 0)
			sb.wire(sb.ids.eritme2, 0, ustasi, 0)
			sb.wire(sb.ids.pres1, 0, ustasi, 1)
			sb.wire(ustasi, 0, dag_kalkan, 0)
			sb.wire(dag_kalkan, 0, sb.ids.sevkiyat, 0)
			sb.wire(dag_kalkan, 1, sb.ids.lab, 0)
		"separate":
			var maden2: int = sb.build(BlockCatalog.MADEN_OCAGI)
			var eritme2: int = sb.build(BlockCatalog.ERITME)
			var pres2: int = sb.build(BlockCatalog.PRES)
			var ustasi2: int = sb.build(BlockCatalog.KALKAN_USTASI)
			sb.staff(maden2); sb.staff(eritme2); sb.staff(pres2); sb.staff(ustasi2)
			sb.wire(maden2, 0, eritme2, 0)
			var dag2: int = sb.build(BlockCatalog.DAGITICI)
			sb.wire(eritme2, 0, dag2, 0)
			sb.wire(dag2, 0, pres2, 0)
			sb.wire(dag2, 1, ustasi2, 0)
			sb.wire(pres2, 0, ustasi2, 1)
			sb.wire(ustasi2, 0, sb.ids.lab, 0)
			sb.ids["kalkan_ustasi2"] = ustasi2
			sb.ids["maden2"] = maden2
			sb.ids["eritme2"] = eritme2
			sb.ids["pres2"] = pres2


func _stage_kask_bantlama(sb: Sandbox, strategy: String) -> void:
	var kask_ustasi: int = sb.build(BlockCatalog.KASK_USTASI)
	sb.staff(kask_ustasi)
	sb.ids["kask_ustasi"] = kask_ustasi

	match strategy:
		"minimum":
			var dag_levha: int = sb.build(BlockCatalog.DAGITICI)
			sb.unwire(sb.ids.pres1, 0, sb.ids.kalkan_ustasi, 1)
			sb.wire(sb.ids.pres1, 0, dag_levha, 0)
			sb.wire(dag_levha, 0, sb.ids.kalkan_ustasi, 1)
			sb.wire(dag_levha, 1, kask_ustasi, 0)
			var dag_kask: int = sb.build(BlockCatalog.DAGITICI)
			sb.wire(kask_ustasi, 0, dag_kask, 0)
			sb.wire(dag_kask, 0, sb.ids.sevkiyat, 0)
			sb.wire(dag_kask, 1, sb.ids.lab, 0)
		"targeted":
			var levha_source: int
			if sb.ids.has("eritme2"):
				# eritme2 onceki asamada (Kask Zanaati'nin HEDEFLI plani)
				# zaten kalkan_ustasi'nin kulce girdisine baglanmis olabilir
				# — tek cikis portu dolu. SAF "hep hedefli" politikasinda bu
				# HER ZAMAN boyle; "su ana kadar minimum" referansinda ise
				# eritme2 hic yok (bu dal hic tetiklenmez). Guvenli/tutarli
				# olmasi icin daima kucuk bir Dagitici ile pay ediyoruz.
				var pres2: int = sb.build(BlockCatalog.PRES)
				var dag_kulce2: int = sb.build(BlockCatalog.DAGITICI)
				sb.staff(pres2)
				sb.unwire(sb.ids.eritme2, 0, sb.ids.kalkan_ustasi, 0)
				sb.wire(sb.ids.eritme2, 0, dag_kulce2, 0)
				sb.wire(dag_kulce2, 0, sb.ids.kalkan_ustasi, 0)
				sb.wire(dag_kulce2, 1, pres2, 0)
				levha_source = pres2
				sb.ids["pres2"] = pres2
			else:
				var maden3: int = sb.build(BlockCatalog.MADEN_OCAGI)
				var eritme3: int = sb.build(BlockCatalog.ERITME)
				var pres2: int = sb.build(BlockCatalog.PRES)
				sb.staff(maden3); sb.staff(eritme3); sb.staff(pres2)
				sb.wire(maden3, 0, eritme3, 0)
				sb.wire(eritme3, 0, pres2, 0)
				levha_source = pres2
				sb.ids["pres2"] = pres2
			sb.wire(levha_source, 0, kask_ustasi, 0)
			var dag_kask: int = sb.build(BlockCatalog.DAGITICI)
			sb.wire(kask_ustasi, 0, dag_kask, 0)
			sb.wire(dag_kask, 0, sb.ids.sevkiyat, 0)
			sb.wire(dag_kask, 1, sb.ids.lab, 0)
		"separate":
			var maden3: int = sb.build(BlockCatalog.MADEN_OCAGI)
			var eritme3: int = sb.build(BlockCatalog.ERITME)
			var pres3: int = sb.build(BlockCatalog.PRES)
			sb.staff(maden3); sb.staff(eritme3); sb.staff(pres3)
			sb.wire(maden3, 0, eritme3, 0)
			sb.wire(eritme3, 0, pres3, 0)
			sb.wire(pres3, 0, kask_ustasi, 0)
			sb.wire(kask_ustasi, 0, sb.ids.lab, 0)
			sb.ids["maden3"] = maden3
			sb.ids["eritme3"] = eritme3
			sb.ids["pres3"] = pres3
