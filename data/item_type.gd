class_name ItemType
extends Resource

## Akışta taşınan bir ürün türü (cevher, külçe, levha...).
##
## Her ürün için bir .tres -> res://data/items/

@export var id: StringName = &""
@export var display_name: String = "New Good"
@export var color: Color = Color(0.6, 0.64, 0.68)
## Kısa kod. Emoji yerine iki harf: varsayılan font her glifi taşımıyor.
@export var icon_char: String = "??"

## Sevkiyat'tan satıldığında kazandırdığı para.
##
## int — float DEĞİL. Para float tutulursa her satışta minik yuvarlama
## hatası birikir ve saatler sonra bakiye kaymış olur.
@export var base_price: int = 0

## Ürün ağacındaki kademe. Yalnızca sıralama ve sunum için.
@export var tier: int = 0

@export_group("Satış Geliştirme")
## Bu ürünün satış fiyatı, araştırma ağacının DIŞINDA, tekrar satın
## alınabilen küresel bir geliştirmeyle yükseltilebiliyor mu? (bkz.
## ProgressionState.item_upgrade_cost/try_upgrade_item, GameController'daki
## üst bar düğmesi). Bir istasyonun kendi `sale_value_bonus_per_level`'ından
## (bkz. BlockType, Sevkiyat/Elektrik Satış Noktası'na özel) FARKLI — bu,
## TEK bir istasyonu değil, ürünün HER YERDEKİ satışını etkiler.
@export var sale_upgradeable: bool = false
## 1. seviyeden 2. seviyeye geçişin maliyeti. Sonraki seviyeler
## `sale_upgrade_cost_growth` ile büyür — `BlockType.upgrade_base_cost` ile
## AYNI desen.
@export var sale_upgrade_base_cost: int = 0
@export var sale_upgrade_cost_growth: float = 2.0
## Seviye başına satış fiyatına eklenen oran. 1.0 = +%100 (taban fiyatın
## katları hâlinde birikir — bkz. ProgressionState.item_sale_multiplier).
@export var sale_bonus_per_level: float = 0.0
@export var sale_max_level: int = 1
