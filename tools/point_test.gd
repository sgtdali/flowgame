extends SceneTree

## Harita noktaları testi.
##
## Çalıştırma:
##   godot --headless --path . --script res://tools/point_test.gd
##
## Kanıtlar:
##   1. Her bölgenin noktaları verisiyle birebir: kaynak başına bir ham madde
##      alanı (doğru hammadde), şehir adı başına bir şehir (fabrikalar oyunda kurulur)
##   2. Her nokta kendi bölgesinin içinde
##   3. Noktalar birbirine fazla yakın değil (bölge sınırının iki yanı dahil)
##   4. Üretim tekrar çalışınca hiçbir şey değişmiyor
##   5. Elle kaydırılmış nokta yerinde kalıyor; silinen nokta geri geliyor
##   6. Kurallardaki nokta kaydı (MapPoints) sahnedeki noktalarla birebir aynı

const PointPlacer := preload("res://tools/point_placer.gd")
const REGION_MAP_SCENE: String = "res://features/worldmap/RegionMap.tscn"
## Test eşiği üretim hedefinden (80) düşük: kullanıcı noktaları elle
## yaklaştırabilir, bu bir hata değil. Bunun altı üst üste binme sayılır.
const MIN_POINT_DISTANCE: float = 40.0

var _failures: int = 0
var _checks: int = 0

## Beklenen kontrol sayısı: 4 bölge + 6 genel.
const EXPECTED_CHECKS: int = 10


func _initialize() -> void:
	print("")
	var root: Node = _load_scene()
	var views: Array[RegionView] = _views(root)
	_test_points_match_data(views)
	_test_points_inside_region(views)
	_test_spacing(views)
	_test_registry_matches_scene(views)
	root.free()
	_test_sync_is_stable()
	_test_manual_move_kept()
	_test_missing_point_restored()

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


func _test_points_match_data(views: Array[RegionView]) -> void:
	for view: RegionView in views:
		var region: RegionData = view.data
		var sites: Dictionary = {}
		var cities: int = 0
		var others: int = 0
		var bad: PackedStringArray = []
		for point: MapPoint in _points(view):
			match point.kind:
				MapPoint.Kind.RESOURCE_SITE:
					sites[point.slot_index] = point.resource
				MapPoint.Kind.CITY:
					cities += 1
				_:
					others += 1
		if sites.size() != region.resources.size():
			bad.append("alan=%d kaynak=%d" % [sites.size(), region.resources.size()])
		for i: int in region.resources.size():
			if sites.get(i) != region.resources[i]:
				bad.append("alan %d yanlis hammadde" % i)
		if others > 0:
			bad.append("beklenmeyen nokta=%d" % others)
		if cities != region.city_names.size():
			bad.append("sehir=%d ad=%d" % [cities, region.city_names.size()])
		_check("Noktalar veriyle ayni: %s" % view.name, bad.is_empty(), ", ".join(bad))


func _test_points_inside_region(views: Array[RegionView]) -> void:
	var bad: PackedStringArray = []
	for view: RegionView in views:
		for point: MapPoint in _points(view):
			if not _inside(view, _local(point)):
				bad.append("%s/%s" % [view.name, point.name])
	_check("Her nokta kendi bolgesinde", bad.is_empty(), ", ".join(bad))


func _test_spacing(views: Array[RegionView]) -> void:
	var all: Array[Dictionary] = []
	for view: RegionView in views:
		for point: MapPoint in _points(view):
			all.append({"name": "%s/%s" % [view.name, point.name],
					"pos": view.transform * _local(point)})
	var bad: PackedStringArray = []
	for i: int in all.size():
		for j: int in range(i + 1, all.size()):
			var d: float = (all[i]["pos"] as Vector2).distance_to(all[j]["pos"])
			if d < MIN_POINT_DISTANCE:
				bad.append("%s-%s=%.0f" % [all[i]["name"], all[j]["name"], d])
	_check("Noktalar birbirine fazla yakin degil (>= %.0f)" % MIN_POINT_DISTANCE,
			bad.is_empty(), ", ".join(bad))


func _test_registry_matches_scene(views: Array[RegionView]) -> void:
	var scene_points: Dictionary = {}
	for view: RegionView in views:
		for point: MapPoint in _points(view):
			var point_id: String = "%s/%s" % [view.data.id, point.name]
			scene_points[point_id] = [int(point.kind), point.resource]
	var registry: Dictionary = {}
	for info: MapPoints.Info in MapPoints.all():
		registry[String(info.id)] = [int(info.kind), info.resource]
	var bad: PackedStringArray = []
	for point_id: String in scene_points:
		if not registry.has(point_id):
			bad.append("kayitta yok: %s" % point_id)
		elif registry[point_id] != scene_points[point_id]:
			bad.append("farkli: %s" % point_id)
	for point_id: String in registry:
		if not scene_points.has(point_id):
			bad.append("sahnede yok: %s" % point_id)
	_check("Nokta kaydi sahneyle ayni (%d nokta)" % registry.size(), bad.is_empty(),
			", ".join(bad))


func _test_sync_is_stable() -> void:
	var root: Node = _load_scene()
	var before: Dictionary = _positions(root)
	var report: Dictionary = PointPlacer.sync(root)
	var after: Dictionary = _positions(root)
	_check("Uretim tekrar calisinca degisiklik yok",
			report["added"] == 0 and report["removed"] == 0 and before == after,
			"eklenen=%d silinen=%d" % [report["added"], report["removed"]])
	root.free()


func _test_manual_move_kept() -> void:
	var root: Node = _load_scene()
	var point: MapPoint = _points(_views(root)[0])[0]
	var moved: Vector2 = point.position + Vector2(13.0, 7.0)
	point.position = moved
	PointPlacer.sync(root)
	_check("Elle kaydirilan nokta yerinde kaliyor", point.position == moved,
			"konum=%s beklenen=%s" % [point.position, moved])
	root.free()


func _test_missing_point_restored() -> void:
	var root: Node = _load_scene()
	var view: RegionView = _views(root)[0]
	var count: int = _points(view).size()
	var victim: MapPoint = _points(view)[0]
	victim.get_parent().remove_child(victim)
	victim.free()
	var report: Dictionary = PointPlacer.sync(root)
	_check("Silinen nokta geri geliyor",
			report["added"] == 1 and _points(view).size() == count,
			"eklenen=%d sayi=%d/%d" % [report["added"], _points(view).size(), count])
	root.free()


func _load_scene() -> Node:
	return (load(REGION_MAP_SCENE) as PackedScene).instantiate()


func _views(root: Node) -> Array[RegionView]:
	var out: Array[RegionView] = []
	for child: Node in root.get_children():
		if child is RegionView:
			out.append(child)
	return out


func _points(view: RegionView) -> Array[MapPoint]:
	var out: Array[MapPoint] = []
	var holder: Node = view.get_node_or_null(PointPlacer.POINTS_NODE)
	if holder != null:
		for child: Node in holder.get_children():
			if child is MapPoint:
				out.append(child)
	return out


## Noktanın bölge düğümüne göre konumu (Points düğümü kaydırılmış olabilir).
func _local(point: MapPoint) -> Vector2:
	return (point.get_parent() as Node2D).transform * point.position


func _inside(view: RegionView, local_pos: Vector2) -> bool:
	for poly: PackedVector2Array in view.get_polygons():
		if Geometry2D.is_point_in_polygon(local_pos, poly):
			return true
	return false


func _positions(root: Node) -> Dictionary:
	var out: Dictionary = {}
	for view: RegionView in _views(root):
		for point: MapPoint in _points(view):
			out["%s/%s" % [view.name, point.name]] = point.position
	return out


func _check(label: String, passed: bool, detail: String = "") -> void:
	_checks += 1
	if passed:
		print("  GECTI  %s" % label)
	else:
		_failures += 1
		print("  KALDI  %s" % label)
		if detail != "":
			print("         %s" % detail)
