class_name ResearchNode
extends Resource

## Araştırma ağacındaki tek kilit.
##
## İçeriği Faz 4'te doldurulacak; şema burada sabitleniyor.

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

## Ön koşul araştırmaların id'leri.
##
## Array[ResearchNode] DEĞİL: Godot'un resource yükleyicisi birbirine
## referans veren derin zincirlerde kırılganlaşıyor. Id ile gevşek bağlamak
## ayrıca düğüm silmeyi ve ağacı yeniden düzenlemeyi ucuzlatır.
@export var requires: PackedStringArray = PackedStringArray()

@export_group("Maliyet")
@export var cost_money: int = 0
## Doluysa bu araştırma parayla değil, Ar-Ge Laboratuvarı'na AKITILAN
## ürünle açılır. MVP'de yalnızca son araştırma bunu kullanır.
@export var cost_items: Array[RecipeSlot] = []

@export_group("Ödül")
@export var unlocks_blocks: Array[BlockType] = []
## Fabrika istasyon slotu limitine eklenen miktar.
@export var slot_bonus: int = 0


func is_item_cost() -> bool:
	return not cost_items.is_empty()
