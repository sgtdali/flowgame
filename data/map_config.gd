class_name MapConfig
extends Resource

## Harita katmanının para ayarları. Tek dosya: res://data/map_config.tres
##
## Bölge açma maliyeti bölgeye değil sıraya bağlıdır: ilk satın alınan
## bölge `first_unlock_cost`, sonraki her biri `unlock_cost_step` fazlası.
## int — para her yerde tam sayı.

@export var starting_money: int = 1000
@export var first_unlock_cost: int = 500
@export var unlock_cost_step: int = 250
## Araç satılınca ya da hat silinince araç fiyatının geri verilen yüzdesi.
## Hat kurulum ücreti geri verilmez.
@export var vehicle_refund_percent: int = 50
