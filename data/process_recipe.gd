class_name ProcessRecipe
extends Resource

## Geçici sabit fabrikanın tarifi (girdi → çıktı). Her tarif için bir .tres ->
## res://data/recipes_map/
##
## Eski oyunun Recipe sınıfından ayrıdır. Düğüm editörü gelince işleyici
## düğümleri de bu tarifleri kullanacak.

@export var id: StringName = &""
## Fabrikanın/tarifin adı (ör. "Sawmill").
@export var display_name: String = "New Recipe"
## Girdi malları; miktarları aynı sıradaki input_amounts'ta.
@export var inputs: Array[Good] = []
@export var input_amounts: Array[int] = []
@export var output: Good
@export var output_amount: int = 1
## Dakikada üretilen çıktı birimi (işleyici hızı).
@export var outputs_per_minute: float = 0.0


func input_amount(good: Good) -> int:
	var index: int = inputs.find(good)
	return input_amounts[index] if index >= 0 and index < input_amounts.size() else 0
