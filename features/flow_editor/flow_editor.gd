class_name FlowEditor
extends Control

## ORKESTRATÖR. İş mantığı %0, bağlama %100.
##
## Tek görevi: bileşenlerden gelen YUKARI sinyalleri dinleyip diğer bileşenlere
## AŞAĞI komut vermek. Palet ile tuval, tuval ile denetçi birbirini tanımaz —
## hepsi buradan geçer.

@onready var _canvas: FlowCanvas = %Canvas
@onready var _palette: BlockPalette = %Palette
@onready var _inspector: BlockInspector = %Inspector
@onready var _status: Label = %Status
@onready var _save_dialog: FileDialog = %SaveDialog
@onready var _load_dialog: FileDialog = %LoadDialog
@onready var _notice_timer: Timer = %NoticeTimer


func _ready() -> void:
	_palette.block_requested.connect(_on_block_requested)
	_inspector.param_changed.connect(_on_param_changed)

	_canvas.block_selected.connect(_on_block_selected)
	_canvas.selection_cleared.connect(_on_selection_cleared)
	_canvas.graph_changed.connect(_refresh_status)
	_canvas.notice.connect(_on_notice)

	%ArrangeButton.pressed.connect(_on_arrange_pressed)
	%ClearButton.pressed.connect(_on_clear_pressed)
	%SaveButton.pressed.connect(_on_save_pressed)
	%LoadButton.pressed.connect(_on_load_pressed)

	_save_dialog.file_selected.connect(_on_save_path_selected)
	_load_dialog.file_selected.connect(_on_load_path_selected)
	_notice_timer.timeout.connect(_refresh_status)

	_build_sample_flow()


## --- Palet ve denetçiden gelenler -------------------------------------------

func _on_block_requested(type: BlockType) -> void:
	_canvas.add_block(type)


func _on_param_changed(key: StringName, value: Variant) -> void:
	_canvas.set_selected_param(key, value)


## --- Tuvalden gelenler ------------------------------------------------------

func _on_block_selected(block: FlowBlock) -> void:
	_inspector.show_block(block)


func _on_selection_cleared() -> void:
	_inspector.clear()


func _on_notice(text: String) -> void:
	_status.text = text
	_notice_timer.start()


## --- Üst bar ----------------------------------------------------------------

func _on_arrange_pressed() -> void:
	_canvas.arrange_nodes()


func _on_clear_pressed() -> void:
	_canvas.clear_graph()


func _on_save_pressed() -> void:
	_save_dialog.popup_centered_ratio(0.6)


func _on_load_pressed() -> void:
	_load_dialog.popup_centered_ratio(0.6)


## --- Dosya ------------------------------------------------------------------

func _on_save_path_selected(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_on_notice("Kaydedilemedi: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(_canvas.to_dict(), "\t"))
	file.close()
	_on_notice("Kaydedildi: %s" % path.get_file())


func _on_load_path_selected(path: String) -> void:
	if not FileAccess.file_exists(path):
		_on_notice("Dosya bulunamadı.")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is not Dictionary:
		_on_notice("Dosya okunamadı veya biçimi geçersiz.")
		return
	if _canvas.from_dict(parsed):
		_on_notice("Yüklendi: %s" % path.get_file())


## --- Durum çubuğu -----------------------------------------------------------

func _refresh_status() -> void:
	var summary: Dictionary = _canvas.get_summary()
	var text: String = "%d istasyon  ·  %d bağlantı" % [summary["blocks"], summary["connections"]]
	var bottleneck: String = String(summary["bottleneck_name"])
	if not bottleneck.is_empty():
		text += "  ·  Darboğaz: %s (%s / parça)" % [
			bottleneck, FlowBlock.format_duration(float(summary["bottleneck_s"]))
		]
	_status.text = text


## --- Açılış örneği ----------------------------------------------------------

## Uygulama boş bir tuvalle açılmasın diye örnek bir hat kurar.
## İki şeyi gösterir: Montaj'da iki ayrı hattın birleşmesi (Levha + Vida),
## ve Kalite Kontrol'ün Ret çıkışının Geri Dönüşüm üzerinden hatta geri
## beslenmesi.
func _build_sample_flow() -> void:
	var layout: Array = [
		[BlockCatalog.MADEN_OCAGI, Vector2(40, 220)],
		[BlockCatalog.ERITME, Vector2(300, 220)],
		[BlockCatalog.PRES, Vector2(560, 220)],
		[BlockCatalog.HADDE, Vector2(820, 220)],
		[BlockCatalog.KESIM, Vector2(1080, 220)],
		[BlockCatalog.MONTAJ, Vector2(1340, 220)],
		[BlockCatalog.KALITE, Vector2(1600, 220)],
		[BlockCatalog.SEVKIYAT, Vector2(1880, 140)],
		[BlockCatalog.GERI_DONUSUM, Vector2(1880, 400)],
	]

	var blocks: Array[FlowBlock] = []
	for entry: Array in layout:
		blocks.append(_canvas.add_block(entry[0] as BlockType, entry[1] as Vector2))

	# [kaynak indeksi, kaynak port, hedef indeksi, hedef port]
	var wires: Array = [
		[0, 0, 1, 0], [1, 0, 2, 0], [2, 0, 3, 0], [3, 0, 4, 0],
		[2, 0, 5, 0],  # Levha -> Montaj (girdi 1)
		[4, 0, 5, 1],  # Vida  -> Montaj (girdi 2)
		[5, 0, 6, 0],  # Gövde -> Kalite
		[6, 0, 7, 0],  # Uygun -> Sevkiyat
		[6, 1, 8, 0],  # Ret   -> Geri Dönüşüm
		[8, 0, 2, 0],  # Külçe -> Pres (geri besleme)
	]
	for wire: Array in wires:
		_canvas.connect_node(blocks[wire[0]].name, wire[1], blocks[wire[2]].name, wire[3])

	_refresh_status()
