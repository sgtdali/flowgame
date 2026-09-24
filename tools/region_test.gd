extends SceneTree

## Bölge haritası testi.
##
## Çalıştırma:
##   godot --headless --path . --script res://tools/region_test.gd
##
## Kanıtlar:
##   1. Çizimdeki her bölge düğümünün verisi ve şekli var
##   2. Çizim ile RegionCatalog aynı bölgeleri içeriyor
##   3. Bölgeler birbirinin üstüne binmiyor
##   4. Komşuluklar karşılıklı ve çizimde gerçekten değenlerle birebir aynı
##   5. Tam 1 başlangıç bölgesi var
##   6. Değerler tasarım belgesindeki aralıklarda (kaynak 1–3, fabrika alanı 2–4,
##      prototipte 2 şehir) ve para ayarları geçerli
##   7. Bölge açma kuralları (RegionState): komşuluk şartı, para yetmezliği,
##      para düşer, maliyet sırayla artar, açılan bölge kalıcı

const REGION_MAP_SCENE: String = "res://features/worldmap/RegionMap.tscn"
const MAP_CONFIG: MapConfig = preload("res://data/map_config.tres")
## İki bölgenin kesişim alanı bundan büyükse "üst üste biniyor" sayılır (px²).
const OVERLAP_TOLERANCE: float = 1.0
## "Değiyor" kontrolünde poligonların genişletildiği pay (px).
const TOUCH_MARGIN: float = 1.0
## Prototip kapsamı: 5 bölgenin 2'sinde şehir (tasarım belgesi).
const PROTOTYPE_CITY_COUNT: int = 2

var _failures: int = 0
var _checks: int = 0

## Beklenen kontrol sayısı: 5 bölge × 2 + 8 genel + 10 bölge açma.
## Derleme hatasında sessizce "geçti" demesin diye (bkz. sim_test.gd).
const EXPECTED_CHECKS: int = 28


func _initialize() -> void:
	print("")
	var scene: Node = (load(REGION_MAP_SCENE) as PackedScene).instantiate()
	var views: Array[RegionView] = []
	for child: Node in scene.get_children():
		if child is RegionView:
			views.append(child)

	_test_views(views)
	_test_matches_catalog(views)
	_test_no_overlap(views)
	_test_neighbors_mutual()
	_test_neighbors_match_drawing(views)
	_test_single_start()
	_test_value_ranges()
	_test_map_config()
	_test_unlock_rules()
	_test_unlock_cost_sequence()
	scene.free()

	print("")
	if _checks < EXPECTED_CHECKS:
		print("SONUC: yalnizca %d/%d kontrol calisti — test eksik kostu." % [
			_checks, EXPECTED_CHECKS])
		quit(1)
		return
	if _failures == 0:
		print("SONUC: %d/%d kontrol gecti." % [_checks, _checks])
	else:
		print("SONUC: %d/%d kontrol BASARISIZ." % [_failures, _checks])
	quit(1 if _failures > 0 else 0)


func _test_views(views: Array[RegionView]) -> void:
	for view: RegionView in views:
		_check("Veri bagli: %s" % view.name, view.data != null)
		_check("Sekil var: %s" % view.name, not view.get_polygons().is_empty())


func _test_matches_catalog(views: Array[RegionView]) -> void:
	var drawn: Array[StringName] = []
	for view: RegionView in views:
		if view.data != null:
			drawn.append(view.data.id)
	var listed: Array[StringName] = []
	for region: RegionData in RegionCatalog.all():
		listed.append(region.id)
	drawn.sort()
	listed.sort()
	_check("Cizim ve katalog ayni bolgeler", drawn == listed,
			"cizim=%s katalog=%s" % [drawn, listed])


func _test_no_overlap(views: Array[RegionView]) -> void:
	var bad: PackedStringArray = []
	for i: int in views.size():
		for j: int in range(i + 1, views.size()):
			var area: float = 0.0
			for a: PackedVector2Array in _world_polygons(views[i]):
				for b: PackedVector2Array in _world_polygons(views[j]):
					for piece: PackedVector2Array in Geometry2D.intersect_polygons(a, b):
						area += _area(piece)
			if area > OVERLAP_TOLERANCE:
				bad.append("%s/%s=%.1f" % [views[i].name, views[j].name, area])
	_check("Bolgeler ust uste binmiyor", bad.is_empty(), ", ".join(bad))


func _test_neighbors_mutual() -> void:
	var bad: PackedStringArray = []
	for region: RegionData in RegionCatalog.all():
		for other_id: StringName in region.neighbors:
			var other: RegionData = RegionCatalog.find_by_id(other_id)
			if other == null:
				bad.append("%s->%s (yok)" % [region.id, other_id])
			elif not other.neighbors.has(region.id):
				bad.append("%s->%s (geri yok)" % [region.id, other_id])
	_check("Komsuluklar karsilikli", bad.is_empty(), ", ".join(bad))


func _test_neighbors_match_drawing(views: Array[RegionView]) -> void:
	var bad: PackedStringArray = []
	for i: int in views.size():
		for j: int in range(i + 1, views.size()):
			var a: RegionData = views[i].data
			var b: RegionData = views[j].data
			if a == null or b == null:
				continue
			var touching: bool = _touches(views[i], views[j])
			var declared: bool = a.neighbors.has(b.id)
			if touching and not declared:
				bad.append("%s/%s degiyor ama komsu yazilmamis" % [a.id, b.id])
			elif declared and not touching:
				bad.append("%s/%s komsu yazilmis ama degmiyor" % [a.id, b.id])
	_check("Komsuluklar cizimle ayni", bad.is_empty(), ", ".join(bad))


func _test_single_start() -> void:
	var starts: PackedStringArray = []
	for region: RegionData in RegionCatalog.all():
		if region.starts_unlocked:
			starts.append(String(region.id))
	_check("Tam 1 baslangic bolgesi", starts.size() == 1, ", ".join(starts))


func _test_value_ranges() -> void:
	var bad: PackedStringArray = []
	var cities: int = 0
	for region: RegionData in RegionCatalog.all():
		if region.resources.size() < 1 or region.resources.size() > 3:
			bad.append("%s kaynak=%d" % [region.id, region.resources.size()])
		if region.resources.has(null):
			bad.append("%s bos kaynak" % region.id)
		if region.factory_slots < 2 or region.factory_slots > 4:
			bad.append("%s fabrika alani=%d" % [region.id, region.factory_slots])
		if region.has_city():
			cities += 1
	_check("Kaynak ve fabrika alani araliklarda", bad.is_empty(), ", ".join(bad))
	_check("Prototipte %d sehir" % PROTOTYPE_CITY_COUNT,
			cities == PROTOTYPE_CITY_COUNT, "sehir=%d" % cities)


func _test_map_config() -> void:
	_check("Para ayarlari gecerli",
			MAP_CONFIG.starting_money > 0 and MAP_CONFIG.first_unlock_cost > 0
			and MAP_CONFIG.unlock_cost_step >= 0)


## Kabul senaryosu, gerçek harita ayarıyla (başlangıç 1.000, ilk açma 500).
func _test_unlock_rules() -> void:
	var state: RegionState = RegionState.new(MAP_CONFIG)
	var start_money: int = state.money
	_check("Baslangic parasi ayardan geliyor", start_money == MAP_CONFIG.starting_money,
			"para=%d" % start_money)

	# area4'ün açık komşusu yok (komşuları area2, area5).
	var locked_ok: bool = state.unlock(&"area4")
	_check("Komsusu kapali bolge acilamiyor, para dusmuyor",
			not locked_ok and state.money == start_money
			and state.status(&"area4") == RegionState.Status.LOCKED,
			"sonuc=%s para=%d" % [locked_ok, state.money])

	var cost: int = state.unlock_cost()
	var ok: bool = state.unlock(&"area2")
	_check("Acilabilir bolge aciliyor ve para dusuyor",
			ok and state.is_unlocked(&"area2") and state.money == start_money - cost,
			"sonuc=%s para=%d maliyet=%d" % [ok, state.money, cost])
	_check("Maliyet bir adim artti",
			state.unlock_cost() == cost + MAP_CONFIG.unlock_cost_step,
			"maliyet=%d" % state.unlock_cost())
	_check("Yeni komsular acilabilir oldu",
			state.status(&"area4") == RegionState.Status.AVAILABLE
			and state.status(&"area5") == RegionState.Status.AVAILABLE)

	# 1.000 − 500 = 500 kaldı, sonraki 750: yetmez.
	var money_before: int = state.money
	var poor_ok: bool = state.unlock(&"area4")
	_check("Para yetmezse acilamiyor ve nedeni soyleniyor",
			not poor_ok and state.money == money_before
			and state.unlock_block_reason(&"area4") == "Not enough money",
			"sonuc=%s neden='%s'" % [poor_ok, state.unlock_block_reason(&"area4")])

	var again_ok: bool = state.unlock(&"area2")
	_check("Acilmis bolge tekrar satin alinamiyor, kalici",
			not again_ok and state.money == money_before
			and state.status(&"area2") == RegionState.Status.UNLOCKED)


func _test_unlock_cost_sequence() -> void:
	var rich: MapConfig = MapConfig.new()
	rich.starting_money = 100000
	rich.first_unlock_cost = MAP_CONFIG.first_unlock_cost
	rich.unlock_cost_step = MAP_CONFIG.unlock_cost_step
	var state: RegionState = RegionState.new(rich)
	var paid: Array[int] = []
	# Komşuluk sırasıyla: area1 açık → area2 → area4 → area5 → area3.
	for region_id: StringName in [&"area2", &"area4", &"area5", &"area3"]:
		var before: int = state.money
		state.unlock(region_id)
		paid.append(before - state.money)
	var expected: Array[int] = []
	for i: int in 4:
		expected.append(rich.first_unlock_cost + rich.unlock_cost_step * i)
	_check("Maliyet sirasi 500, 750, 1000, 1250", paid == expected,
			"odenen=%s beklenen=%s" % [paid, expected])
	var all_open: bool = true
	for region: RegionData in RegionCatalog.all():
		all_open = all_open and state.is_unlocked(region.id)
	_check("Tum bolgeler acilabildi", all_open)
	_check("Hepsi acikken acilacak bolge kalmadi",
			state.unlock_block_reason(&"area3") == "Already unlocked")


## Bölgenin parçaları sahne kökünün koordinatında.
func _world_polygons(view: RegionView) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for poly: PackedVector2Array in view.get_polygons():
		out.append(view.transform * poly)
	return out


func _touches(a: RegionView, b: RegionView) -> bool:
	for pa: PackedVector2Array in _world_polygons(a):
		for grown: PackedVector2Array in Geometry2D.offset_polygon(pa, TOUCH_MARGIN):
			for pb: PackedVector2Array in _world_polygons(b):
				if not Geometry2D.intersect_polygons(grown, pb).is_empty():
					return true
	return false


func _area(poly: PackedVector2Array) -> float:
	var sum: float = 0.0
	for i: int in poly.size():
		var p: Vector2 = poly[i]
		var q: Vector2 = poly[(i + 1) % poly.size()]
		sum += p.x * q.y - q.x * p.y
	return absf(sum) * 0.5


func _check(label: String, passed: bool, detail: String = "") -> void:
	_checks += 1
	if passed:
		print("  GECTI  %s" % label)
	else:
		_failures += 1
		print("  KALDI  %s" % label)
		if detail != "":
			print("         %s" % detail)
