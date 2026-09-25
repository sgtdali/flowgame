class_name MapSelection
extends RefCounted

## Haritada seçili ve üzerine gelinen şey: bölge, nokta ya da hat. Aynı anda
## en fazla biri seçilidir. Görünümlere seçili/vurgulu durumunu yazar;
## kural bilmez.

var region: RegionView = null
var point: MapPoint = null
var route: RouteView = null
var hovered_point: MapPoint = null
var hovered_route: RouteView = null


## Tıklanan yerdeki şeyi seçer; öncelik: nokta → hat → bölge.
func select_at(picker: MapPicker, world: Vector2) -> void:
	clear()
	point = picker.point_at(world)
	if point != null:
		point.set_selected(true)
		return
	route = picker.route_at(world)
	if route != null:
		route.set_selected(true)
		return
	region = picker.region_at(world)
	if region != null:
		region.set_selected(true)


func clear() -> void:
	if region != null:
		region.set_selected(false)
	if point != null:
		point.set_selected(false)
	if route != null and is_instance_valid(route):
		route.set_selected(false)
	region = null
	point = null
	route = null


func hover_point(value: MapPoint) -> void:
	if value == hovered_point:
		return
	if hovered_point != null:
		hovered_point.set_hovered(false)
	hovered_point = value
	if value != null:
		value.set_hovered(true)


func hover_route(value: RouteView) -> void:
	if value == hovered_route:
		return
	if hovered_route != null and is_instance_valid(hovered_route):
		hovered_route.set_hovered(false)
	hovered_route = value
	if value != null:
		value.set_hovered(true)
