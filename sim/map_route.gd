class_name MapRoute
extends RefCounted

## İki harita noktası arasındaki bir lojistik hattı (arayüzsüz veri).
##
## Nokta kimliği sahneden bağımsızdır: "<bölge id>/<nokta adı>" (ör. "area1/City").
## Hat çift yönlüdür; a ile b'nin sırası anlam taşımaz.

var a: StringName
var b: StringName
## Harita birimi (iki nokta arasındaki düz uzaklık).
var distance: float
var transport: TransportType
var vehicles: int = 0


func _init(point_a: StringName, point_b: StringName, route_distance: float,
		route_transport: TransportType) -> void:
	a = point_a
	b = point_b
	distance = route_distance
	transport = route_transport


func capacity_per_minute() -> float:
	return capacity_for(vehicles, transport, distance)


## Birim/dk: araç sayısı × yük × hız ÷ (2 × mesafe). Yükleme süresi yok.
## Kurulmamış bir hattın önizlemesi için de kullanılır.
static func capacity_for(vehicle_count: int, route_transport: TransportType,
		route_distance: float) -> float:
	if route_distance <= 0.0:
		return 0.0
	return vehicle_count * route_transport.load * route_transport.speed / (2.0 * route_distance)


func upkeep_per_minute() -> int:
	return vehicles * transport.vehicle_upkeep


func connects(point_a: StringName, point_b: StringName) -> bool:
	return (a == point_a and b == point_b) or (a == point_b and b == point_a)
