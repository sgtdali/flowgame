class_name TransportType
extends Resource

## Bir taşıma türü (at arabası, kamyon...). Her tür için bir .tres ->
## res://data/transport_types/
##
## Hat kapasitesi = araç sayısı × load × speed ÷ (2 × mesafe) (tasarım belgesi,
## "Araç turu"). Mesafe harita birimidir. Para alanları int.

@export var id: StringName = &""
@export var display_name: String = "New Transport"
## Bir aracın tek seferde taşıdığı birim.
@export var load: int = 0
## Harita birimi / dakika.
@export var speed: int = 0
@export var vehicle_price: int = 0
## Araç başına dakikalık bakım.
@export var vehicle_upkeep: int = 0
## Hat kurulum ücreti (mesafeden bağımsız).
@export var route_cost: int = 0
## Araştırma gelene kadar yalnızca başlangıçta açık türler kurulabilir.
@export var available_at_start: bool = false
