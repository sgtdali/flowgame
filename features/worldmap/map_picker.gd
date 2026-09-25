class_name MapPicker
extends RefCounted

## Haritada "fare nerede, altında ne var" sorularının cevabı: ekran → dünya
## dönüşümü, en yakın nokta, en yakın hat, altındaki bölge. Yalnızca bulur;
## seçim ya da kural bilmez.

## Hat çizgisine bu kadar yakın tıklama hattı bulur (dünya birimi).
const ROUTE_HIT_DISTANCE: float = 10.0

var points: Array[MapPoint] = []
var _map: Node2D
var _region_map: Node2D
var _route_builder: RouteBuilder


func _init(map: Node2D, region_map: Node2D, route_builder: RouteBuilder) -> void:
	_map = map
	_region_map = region_map
	_route_builder = route_builder
	for node: Node in region_map.find_children("*", "MapPoint", true, false):
		points.append(node as MapPoint)


## Olayın ekran konumunu dünya koordinatına çevirir (kamera ve yakınlaştırma dahil).
func to_world(screen_position: Vector2) -> Vector2:
	return _map.get_canvas_transform().affine_inverse() * screen_position


## Dünya noktasına en yakın, HIT_RADIUS içindeki nokta.
func point_at(world_point: Vector2) -> MapPoint:
	var best: MapPoint = null
	var best_distance: float = MapPoint.HIT_RADIUS
	for point: MapPoint in points:
		var distance: float = point.global_position.distance_to(world_point)
		if distance <= best_distance:
			best = point
			best_distance = distance
	return best


func route_at(world_point: Vector2) -> RouteView:
	return _route_builder.route_at(world_point, ROUTE_HIT_DISTANCE)


## Bölgelerin CollisionPolygon2D'lerine fizik sorgusuyla.
func region_at(world_point: Vector2) -> RegionView:
	var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query.position = world_point
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for hit: Dictionary in _map.get_world_2d().direct_space_state.intersect_point(query):
		var view: RegionView = hit["collider"] as RegionView
		if view != null:
			return view
	return null


func views() -> Array[RegionView]:
	var out: Array[RegionView] = []
	for child: Node in _region_map.get_children():
		if child is RegionView:
			out.append(child)
	return out


## Verilen bölgelerin dünya koordinatında kapladığı alan.
func regions_rect(region_ids: Array[StringName]) -> Rect2:
	var vertices: PackedVector2Array = []
	for view: RegionView in views():
		if view.data != null and region_ids.has(view.data.id):
			for poly: PackedVector2Array in view.get_polygons():
				vertices.append_array(view.global_transform * poly)
	if vertices.is_empty():
		return Rect2()
	var rect: Rect2 = Rect2(vertices[0], Vector2.ZERO)
	for vertex: Vector2 in vertices:
		rect = rect.expand(vertex)
	return rect
