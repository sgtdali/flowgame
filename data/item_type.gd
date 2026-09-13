class_name ItemType
extends Resource

## Akışta taşınan bir ürün türü (cevher, külçe, levha...).
##
## Her ürün için bir .tres -> res://data/items/

@export var id: StringName = &""
@export var display_name: String = "Yeni Ürün"
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
