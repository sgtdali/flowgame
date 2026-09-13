class_name RecipeSlot
extends Resource

## Bir reçetedeki tek girdi veya çıktı: "Levha × 2".

@export var item: ItemType = null
@export var count: int = 1


## Port etiketi olarak gösterilir. Adet 1 ise sadece ürün adı.
func label() -> String:
	if item == null:
		return "?"
	if count <= 1:
		return item.display_name
	return "%s × %d" % [item.display_name, count]
