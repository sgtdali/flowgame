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


## Birim/dk: araç sayısı × yük × hız ÷ (2 × mesafe). Yükleme süresi yok.
func capacity_per_minute() -> float:
	if distance <= 0.0:
		return 0.0
	return vehicles * transport.load * transport.speed / (2.0 * distance)


func upkeep_per_minute() -> int:
	return vehicles * transport.vehicle_upkeep


func connects(point_a: StringName, point_b: StringName) -> bool:
	return (a == point_a and b == point_b) or (a == point_b and b == point_a)
