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

@export_group("Fabrika ve şehir")
## Geçici sabit fabrika: kurulum fiyatı ve dakikalık bakımı.
@export var factory_cost: int = 300
@export var factory_upkeep: int = 3
## Arsaya fabrika kurarken seçilebilecek tarifler.
@export var factory_recipes: Array[ProcessRecipe] = []
## Her noktada mal başına stok sınırı (şehirde sınır yok).
@export var point_stock_capacity: int = 50
## Şehirlerin başlangıç seviyesi (köy).
@export var starting_city_level: CityLevel

@export_group("Fabrika içi")
## Fabrika editörünün paletindeki bloklar (işleyici, ayırıcı, depo).
@export var factory_blocks: Array[BlockType] = []
## Giriş ve çıkış kapısı şablonları; her malın kapısı bunlardan üretilir.
@export var gate_in: FactoryGate
@export var gate_out: FactoryGate
## Paletteki "Output: <mal>" kapılarının malları.
@export var factory_goods: Array[Good] = []
