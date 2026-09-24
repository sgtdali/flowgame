extends RefCounted

## Bölge verisine göre çizim sahnesindeki noktaları eşitler (bkz. generate_points.gd).
##
## Kurallar (görev 02):
##   - Her bölgede: kaynak başına bir ham madde alanı, fabrika alanı başına bir
##     arsa, şehri varsa bir şehir.
##   - Var olan noktanın KONUMUNA dokunulmaz (elle kaydırılmış olabilir);
##     yalnızca eksikler eklenir, fazlalar silinir.
##   - Yeni nokta: bölge içinde, kenardan EDGE_MARGIN uzakta, bölge adının
##     üstünde değil. Şehir bölge adına en yakın yere; diğerleri var olan
##     noktalardan en uzak yere (en uzak nokta seçimi). Rastgelelik yok.

const EDGE_MARGIN: float = 40.0
## Aynı bölgedeki iki nokta arası hedef en küçük mesafe. Sağlanamazsa uyarı verilir.
const MIN_SPACING: float = 80.0
const GRID_STEP: float = 10.0
## Bölge adının çevresindeki boş alan (adın ortasına göre yarı genişlik/yükseklik);
## noktanın kendi alt yazısı da adın üstüne binmesin diye yüksekliği geniş.
const LABEL_HALF_EXTENTS: Vector2 = Vector2(90.0, 55.0)
const POINTS_NODE: String = "Points"


## `scene_root`: RegionMap sahnesinin kökü (ağaca eklenmemiş olabilir).
## Dönüş: {added, removed, kept: int, warnings: PackedStringArray}
static func sync(scene_root: Node) -> Dictionary:
	var report: Dictionary = {"added": 0, "removed": 0, "kept": 0, "warnings": PackedStringArray()}
	for child: Node in scene_root.get_children():
		var view: RegionView = child as RegionView
		if view != null and view.data != null:
			_sync_region(view, scene_root, report)
	return report


static func point_key(kind: MapPoint.Kind, slot_index: int) -> String:
	return "%d_%d" % [kind, slot_index]


static func _sync_region(view: RegionView, scene_root: Node, report: Dictionary) -> void:
	var region: RegionData = view.data
	var points_root: Node2D = view.get_node_or_null(POINTS_NODE) as Node2D
	if points_root == null:
		points_root = Node2D.new()
		points_root.name = POINTS_NODE
		view.add_child(points_root)
		points_root.owner = scene_root

	# İstenen noktalar, yerleştirme sırasıyla: şehir, ham madde alanları, arsalar.
	var wanted: Array[Dictionary] = []
	if region.has_city():
		wanted.append({"kind": MapPoint.Kind.CITY, "slot": 0, "resource": null, "name": "City"})
	for i: int in region.resources.size():
		wanted.append({"kind": MapPoint.Kind.RESOURCE_SITE, "slot": i,
				"resource": region.resources[i], "name": "Site%d" % (i + 1)})
	for i: int in region.factory_slots:
		wanted.append({"kind": MapPoint.Kind.FACTORY_PLOT, "slot": i, "resource": null,
				"name": "Plot%d" % (i + 1)})
	var wanted_keys: Dictionary = {}
	for want: Dictionary in wanted:
		wanted_keys[point_key(want["kind"], want["slot"])] = want

	# Var olanlar: istenmeyen ya da kopya olanı sil, kalanı güncelle.
	var existing: Dictionary = {}
	for child: Node in points_root.get_children():
		var point: MapPoint = child as MapPoint
		if point == null:
			continue
		var key: String = point_key(point.kind, point.slot_index)
		if not wanted_keys.has(key) or existing.has(key):
			points_root.remove_child(point)
			point.free()
			report["removed"] += 1
			continue
		existing[key] = point
		point.resource = wanted_keys[key]["resource"]
		report["kept"] += 1

	var placed: Array[Vector2] = []
	for point: MapPoint in existing.values():
		placed.append(point.position)
	var candidates: Array[Vector2] = _candidates(view)
	var label_pos: Vector2 = view.get_label_position()

	for want: Dictionary in wanted:
		var key: String = point_key(want["kind"], want["slot"])
		if existing.has(key):
			continue
		var pos: Vector2 = _pick(candidates, placed, label_pos, want["kind"] == MapPoint.Kind.CITY)
		var spacing: float = _min_distance(pos, placed)
		if spacing < MIN_SPACING:
			report["warnings"].append("%s/%s: en yakin noktaya %.0f px (hedef %.0f)" % [
					view.name, want["name"], spacing, MIN_SPACING])
		var point: MapPoint = MapPoint.new()
		point.name = want["name"]
		point.kind = want["kind"]
		point.slot_index = want["slot"]
		point.resource = want["resource"]
		point.position = pos
		points_root.add_child(point)
		point.owner = scene_root
		placed.append(pos)
		report["added"] += 1


## Bölge içinde, kenardan EDGE_MARGIN uzakta ve bölge adının dışındaki ızgara noktaları.
static func _candidates(view: RegionView) -> Array[Vector2]:
	var polygons: Array[PackedVector2Array] = view.get_polygons()
	var label_rect: Rect2 = Rect2(view.get_label_position() - LABEL_HALF_EXTENTS,
			LABEL_HALF_EXTENTS * 2.0)
	var out: Array[Vector2] = []
	if polygons.is_empty():
		return out
	var bounds: Rect2 = Rect2(polygons[0][0], Vector2.ZERO)
	for poly: PackedVector2Array in polygons:
		for p: Vector2 in poly:
			bounds = bounds.expand(p)
	var y: float = snappedf(bounds.position.y, GRID_STEP)
	while y <= bounds.end.y:
		var x: float = snappedf(bounds.position.x, GRID_STEP)
		while x <= bounds.end.x:
			var p: Vector2 = Vector2(x, y)
			if not label_rect.has_point(p):
				for poly: PackedVector2Array in polygons:
					if Geometry2D.is_point_in_polygon(p, poly) and _edge_distance(p, poly) >= EDGE_MARGIN:
						out.append(p)
						break
			x += GRID_STEP
		y += GRID_STEP
	return out


## Şehir: bölge adına en yakın aday. Diğerleri: yerleşmiş noktalara en uzak aday
## (hiç nokta yoksa bölge adına en yakın). Eşitlikte ilk aday — sonuç hep aynı.
static func _pick(candidates: Array[Vector2], placed: Array[Vector2], label_pos: Vector2,
		near_label: bool) -> Vector2:
	var best: Vector2 = label_pos
	var best_score: float = -INF
	for c: Vector2 in candidates:
		var score: float
		if near_label or placed.is_empty():
			score = -c.distance_to(label_pos)
		else:
			score = _min_distance(c, placed)
		if score > best_score:
			best_score = score
			best = c
	return best


static func _min_distance(p: Vector2, others: Array[Vector2]) -> float:
	var best: float = INF
	for o: Vector2 in others:
		best = minf(best, p.distance_to(o))
	return best


static func _edge_distance(p: Vector2, poly: PackedVector2Array) -> float:
	var best: float = INF
	for i: int in poly.size():
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[(i + 1) % poly.size()]
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)))
	return best
