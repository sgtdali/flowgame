class_name InfoRows
extends RefCounted

## Panel ızgarasına (2 sütun: başlık, değer) PointDetails satırlarını yazar.
## Değer hücresi düz yazı satırında Label, simgeli/çubuklu satırda GoodBar'dır.
## Satırların türleri değişmediyse hücreler yeniden kurulmaz, yalnızca güncellenir.

const CAPTION_COLOR: Color = Color(0.7, 0.72, 0.7, 1)
const VALUE_MIN_WIDTH: float = 210.0


## `fixed_cells`: ızgaranın başındaki, dokunulmayacak hücre sayısı.
static func fill(grid: GridContainer, fixed_cells: int, rows: Array[Dictionary]) -> void:
	var cells: Array[Node] = grid.get_children()
	if not _same_shape(cells, fixed_cells, rows):
		for i: int in range(fixed_cells, cells.size()):
			grid.remove_child(cells[i])
			cells[i].queue_free()
		for row: Dictionary in rows:
			grid.add_child(_caption())
			grid.add_child(GoodBar.new() if row.has("goods") else _value_label())
		cells = grid.get_children()
	for r: int in rows.size():
		var row: Dictionary = rows[r]
		(cells[fixed_cells + r * 2] as Label).text = row["caption"]
		var value: Node = cells[fixed_cells + r * 2 + 1]
		if value is GoodBar:
			(value as GoodBar).set_data(row["goods"], row["fill"], row["text"],
					row.get("zones", PackedFloat32Array()), row.get("zone_colors", [] as Array[Color]))
		else:
			(value as Label).text = row["text"]


static func _same_shape(cells: Array[Node], fixed_cells: int, rows: Array[Dictionary]) -> bool:
	if cells.size() != fixed_cells + rows.size() * 2:
		return false
	for r: int in rows.size():
		if (cells[fixed_cells + r * 2 + 1] is GoodBar) != rows[r].has("goods"):
			return false
	return true


static func _caption() -> Label:
	var label: Label = Label.new()
	label.add_theme_color_override("font_color", CAPTION_COLOR)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label


static func _value_label() -> Label:
	var label: Label = Label.new()
	label.custom_minimum_size = Vector2(VALUE_MIN_WIDTH, 0.0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
