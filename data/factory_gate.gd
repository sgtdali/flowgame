class_name FactoryGate
extends BlockType

## Fabrika içindeki kapı: haritadaki hatlarla düğüm editörü arasındaki geçit.
##
## Her mal için bir kapı vardır. Veride yalnızca iki şablon durur
## (res://data/factory_blocks/gate_in.tres, gate_out.tres); belirli bir malın
## kapısı `for_good` ile şablondan üretilir.
##   IN  → giriş stoğundaki malı editöre verir (kaynak gibi: girişi yok).
##   OUT → editörden gelen malı çıkış stoğuna koyar (bitiş gibi: çıkışı yok).
## Kapının davranışı fabrika içi simülasyondadır; burada yalnızca veri var.

enum Direction { IN, OUT }

@export var direction: Direction = Direction.IN
## Kapının taşıdığı mal. Şablonda boştur.
@export var good: Good = null
## Görünen ad biçimi; %s mal adıdır (ör. "%s in" → "Logs in").
@export var name_format: String = "%s"


## Bu şablondan `good` malının kapısını üretir. Port tipi ve etiketi, tek
## slotlu bir tariften türer (girişte çıktı, çıkışta girdi olarak).
func for_good(p_good: Good) -> FactoryGate:
	var gate: FactoryGate = duplicate() as FactoryGate
	gate.good = p_good
	gate.id = StringName("%s_%s" % [id, p_good.id])
	gate.display_name = name_format % p_good.display_name
	gate.icon_char = p_good.icon_char
	var slot: RecipeSlot = RecipeSlot.new()
	slot.item = p_good
	slot.count = 1
	var gate_recipe: Recipe = Recipe.new()
	gate_recipe.id = gate.id
	gate_recipe.duration_ticks = 0.0
	if direction == Direction.IN:
		gate_recipe.outputs = [slot]
	else:
		gate_recipe.inputs = [slot]
	gate.recipe = gate_recipe
	return gate
