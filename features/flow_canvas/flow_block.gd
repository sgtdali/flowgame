class_name FlowBlock
extends GraphNode

## Akıştaki tek bir istasyonun GÖRÜNTÜSÜ.
##
## Görseli tamamen `block_type` arketipinden türer; sabit bir .tscn yoktur
## çünkü port sayısı reçeteye göre değişir (Montaj'ın iki girişi, Kalite
## Kontrol'ün iki çıkışı vardır).
##
## MİMARİ: Bu düğüm hiçbir şeye SAHİP DEĞİL. Faz 2'den itibaren kuyruklar ve
## ilerleme simülasyonda yaşayacak, burası sadece onu yansıtacak. Şimdilik
## tuttuğu tek kendi verisi kullanıcının verdiği ad.

## Port tipi — GraphEdit yalnızca aynı tipteki portların bağlanmasına izin verir.
const PORT_TYPE_MATERIAL: int = 0

signal params_changed(block: FlowBlock)

var block_type: BlockType = null

## Simülasyondaki istasyonun kimliği. Faz 3'te atanacak.
## GraphEdit düğüm adı KİMLİK DEĞİLDİR — ad değişebilir, id değişmez.
var sim_id: int = -1

## Kullanıcının verdiği ad (varsayılan: arketipin adı).
var block_label: String = ""

var _stat_keys: Dictionary = {}
var _stat_values: Dictionary = {}


## Bloğu bir arketipten kurar. `add_child` ÖNCESİNDE çağrılmalıdır.
func setup(type: BlockType) -> void:
	block_type = type
	block_label = type.display_name


func _ready() -> void:
	if block_type == null:
		push_error("FlowBlock: setup() çağrılmadan ağaca eklendi.")
		return
	custom_minimum_size = Vector2(210.0, 0.0)
	_apply_style()
	_build_rows()
	_refresh_header()
	_refresh_stats()


## --- Görünüm ---------------------------------------------------------------

func _apply_style() -> void:
	var accent: Color = block_type.accent_color

	var titlebar := StyleBoxFlat.new()
	titlebar.bg_color = accent
	titlebar.corner_radius_top_left = 5
	titlebar.corner_radius_top_right = 5
	titlebar.content_margin_left = 9.0
	titlebar.content_margin_right = 9.0
	titlebar.content_margin_top = 5.0
	titlebar.content_margin_bottom = 5.0
	add_theme_stylebox_override(&"titlebar", titlebar)

	var titlebar_sel: StyleBoxFlat = titlebar.duplicate()
	titlebar_sel.bg_color = accent.lightened(0.22)
	add_theme_stylebox_override(&"titlebar_selected", titlebar_sel)

	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.13, 0.15, 0.18, 0.97)
	panel.border_color = accent.darkened(0.25)
	panel.set_border_width_all(1)
	panel.corner_radius_bottom_left = 5
	panel.corner_radius_bottom_right = 5
	panel.content_margin_left = 9.0
	panel.content_margin_right = 9.0
	panel.content_margin_top = 7.0
	panel.content_margin_bottom = 7.0
	add_theme_stylebox_override(&"panel", panel)

	var panel_sel: StyleBoxFlat = panel.duplicate()
	panel_sel.border_color = accent.lightened(0.35)
	panel_sel.set_border_width_all(2)
	add_theme_stylebox_override(&"panel_selected", panel_sel)


## Port satırlarını ve bilgi ızgarasını oluşturur.
func _build_rows() -> void:
	var inputs: PackedStringArray = block_type.input_labels()
	var outputs: PackedStringArray = block_type.output_labels()
	var row_count: int = maxi(inputs.size(), outputs.size())
	var accent: Color = block_type.accent_color

	for i in row_count:
		var has_in: bool = i < inputs.size()
		var has_out: bool = i < outputs.size()

		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 14)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var left := Label.new()
		left.text = inputs[i] if has_in else ""
		left.add_theme_font_size_override(&"font_size", 12)
		left.add_theme_color_override(&"font_color", Color(0.72, 0.78, 0.85))
		row.add_child(left)

		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(spacer)

		var right := Label.new()
		right.text = outputs[i] if has_out else ""
		right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right.add_theme_font_size_override(&"font_size", 12)
		right.add_theme_color_override(&"font_color", Color(0.72, 0.78, 0.85))
		row.add_child(right)

		add_child(row)
		set_slot(i, has_in, PORT_TYPE_MATERIAL, accent, has_out, PORT_TYPE_MATERIAL, accent)

	var sep := HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep)

	add_child(_build_stats_grid())


## Bilgi özeti: iki sütunlu ızgara.
##
## Tek satırlık `autowrap` Label KULLANILMAZ: genişliği henüz belli değilken
## Godot minimum yüksekliği "her karakter ayrı satıra düşerse" varsayımıyla
## hesaplar ve düğüm yüzlerce piksel uzar. Izgarada sarma gerekmez.
func _build_stats_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 10)
	grid.add_theme_constant_override(&"v_separation", 1)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var specs: Array = [
		[&"duration", "Süre"],
		[&"queue", "Kuyruk"],
		[&"scrap", "Fire"],
	]
	for spec: Array in specs:
		var key: StringName = spec[0]

		var name_label := Label.new()
		name_label.text = spec[1]
		name_label.add_theme_font_size_override(&"font_size", 11)
		name_label.add_theme_color_override(&"font_color", Color(0.47, 0.53, 0.60))
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var value_label := Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_label.add_theme_font_size_override(&"font_size", 11)
		value_label.add_theme_color_override(&"font_color", Color(0.76, 0.81, 0.87))
		value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

		grid.add_child(name_label)
		grid.add_child(value_label)
		_stat_keys[key] = name_label
		_stat_values[key] = value_label

	return grid


func _refresh_header() -> void:
	title = "%s  %s" % [block_type.icon_char, block_label]
	tooltip_text = "%s — %s\n%s" % [
		block_type.display_name, block_type.category_label(), block_type.description
	]


func _refresh_stats() -> void:
	if _stat_values.is_empty():
		return
	var recipe: Recipe = block_type.recipe
	_set_stat(&"duration", recipe != null,
		recipe.duration_text(GameConfig.TICKS_PER_SECOND) if recipe != null else "")
	_set_stat(&"queue", true, _queue_text())
	_set_stat(&"scrap", block_type.scrap_every_n > 0, "1 / %d" % block_type.scrap_every_n)


## Kaynağın girişi, bitişin çıkışı yoktur — olmayan tarafı göstermeyiz.
func _queue_text() -> String:
	match block_type.category:
		BlockType.Category.SOURCE:
			return "çıkış %d" % block_type.output_capacity
		BlockType.Category.SINK:
			return "giriş %d" % block_type.input_capacity
	return "%d / %d" % [block_type.input_capacity, block_type.output_capacity]


## Bir satırı gösterir/gizler. GridContainer gizli çocukları atladığı için
## etiket ve değer BİRLİKTE gizlenmeli, yoksa sütunlar kayar.
func _set_stat(key: StringName, shown: bool, value: String) -> void:
	var name_label: Label = _stat_keys[key]
	var value_label: Label = _stat_values[key]
	name_label.visible = shown
	value_label.visible = shown
	if shown:
		value_label.text = value


## --- Veri ------------------------------------------------------------------

## Denetçi panelinin çağırdığı tek giriş noktası.
##
## Artık yalnızca ad düzenlenebilir: süre, kapasite ve fire istasyon TÜRÜNÜN
## özellikleridir, tek bir kopyanın değil. Oyuncu bunları araştırmayla
## değiştirir, elle değil.
func set_param(key: StringName, value: Variant) -> void:
	match key:
		&"label":
			block_label = String(value)
			_refresh_header()
		_:
			push_warning("FlowBlock: bilinmeyen parametre '%s'" % key)
			return
	params_changed.emit(self)


## Kayıt için düz sözlük. Vector2 yerine ayrı float'lar — JSON'da tip kaybı olmasın.
func to_dict() -> Dictionary:
	return {
		"name": String(name),
		"type_id": String(block_type.id),
		"label": block_label,
		"x": position_offset.x,
		"y": position_offset.y,
	}


## Kayıttan geri yükler. `setup()` sonrasında, ağaca eklendikten sonra çağrılır.
func apply_dict(data: Dictionary) -> void:
	block_label = String(data.get("label", block_label))
	position_offset = Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0)))
	_refresh_header()
	_refresh_stats()
