class_name FlowBlock
extends GraphNode

## Akıştaki tek bir istasyonun GÖRÜNTÜSÜ.
##
## Kartın sabit iskeleti `flow_block.tscn` sahnesinde, değişken port satırları
## ise reçeteye göre burada kurulur (Montaj'ın iki girişi, Kalite Kontrol'ün
## iki çıkışı vardır).
##
## MİMARİ: Bu düğüm hiçbir şeye SAHİP DEĞİL. Faz 2'den itibaren kuyruklar ve
## ilerleme simülasyonda yaşayacak, burası sadece onu yansıtacak. Şimdilik
## tuttuğu tek kendi verisi kullanıcının verdiği ad.

## Port tipi — GraphEdit yalnızca aynı tipteki portların bağlanmasına izin verir.
const PORT_TYPE_MATERIAL: int = 0
## Güç portu AYRI tiptedir: malzeme telleri ve güç telleri asla karışmaz,
## GraphEdit'in kendi tip denetimi bunu bedavaya sağlar (bkz. FlowCanvas).
const PORT_TYPE_POWER: int = 1
const COLOR_POWER := Color(0.93, 0.78, 0.24)

## Düğümün çerçevesinin anlattığı şey.
##
## Durum artık YAZIYLA değil RENKLE anlatılıyor: tuvale bakan oyuncu her
## düğümü tek tek okumak zorunda kalmadan sorunun nerede olduğunu görmeli.
enum Display {
	RUNNING,   ## yeşil — üretiyor
	IDLE,      ## turuncu — malzeme veya yer bekliyor
	UNWIRED,   ## kırmızı — bir portu boşta, akışa katılamıyor
}

const COLOR_RUNNING := Color(0.55, 0.73, 0.43)
const COLOR_IDLE := Color(0.86, 0.64, 0.32)
const COLOR_UNWIRED := Color(0.78, 0.38, 0.31)

signal params_changed(block: FlowBlock)

## Düğüm üstündeki Yükselt/Tahsil Et düğmesine basıldığında yukarı bildirilir.
## `action`: &"upgrade" veya &"collect". Bkz. DESIGN.md D27 — bu iki eylem
## artık sağ paneldeki denetçide değil, doğrudan düğümün kendisinde yaşıyor.
signal action_requested(block: FlowBlock, action: StringName)

var block_type: BlockType = null

## Simülasyondaki istasyonun kimliği. Faz 3'te atanacak.
## GraphEdit düğüm adı KİMLİK DEĞİLDİR — ad değişebilir, id değişmez.
var sim_id: int = -1

## Kullanıcının verdiği ad (varsayılan: arketipin adı).
var block_label: String = ""

## Simülasyondan yansıtılan canlı değerler.
var level: int = 1
var market_accrued: int = 0

var _stat_keys: Dictionary = {}
var _stat_values: Dictionary = {}
var _progress: ProgressBar = null
var _panel_style: StyleBoxFlat = null
var _upgrade_button: Button = null
var _collect_button: Button = null

## "KAPILI" bloklara ÖZEL satırlar (bkz. `_uses_gate_layout`) — bunların
## kendi üretim temposu YOK: bir eşik dolunca ANINDA dönüşür/geçer (Eritme
## Ocağı: 60 cevher + 6 kömür, bkz. eritme.tres/r_kulce.tres; Trade Depot: 1
## mal + N Talep, bkz. `BlockType.demand_item`). Genel "Rate" istatistiği bu
## yüzden onlar için anlamsız — oyuncu bunun yerine canlı girdi/çıktı akış
## hızını ve dolum durumunu görür. Girdi sayısı bloğa göre değiştiği için
## (bkz. `_gate_slots`) satırlar DİZİ olarak tutulur.
var _gate_input_value_labels: Array[Label] = []
var _gate_output_value_label: Label = null
var _gate_current_labels: Array[Label] = []

## Son yazılan değerler. Label.text atamak font shaping tetikler; 80 düğüm ×
## 4 satır × 60 kare = saniyede 19.200 gereksiz shaping demek. Değişmediyse
## yazmıyoruz.
var _last_text: Dictionary = {}
var _last_display: int = -1
var _last_unwired: int = -1

## Son ÇALIŞIYOR görülen tick. Durum rozetini yumuşatmak için.
var _last_running_tick: int = -999999

## Çerçevenin gösterdiği durum. Alt çubuktaki sayım da buna bakar — yoksa
## düğüm yeşilken alt çubuk "2 boşta" der ve çelişirler.
var shown_display: Display = Display.UNWIRED


## Bloğu bir arketipten kurar. `add_child` ÖNCESİNDE çağrılmalıdır.
func setup(type: BlockType) -> void:
	block_type = type
	block_label = type.display_name


func _ready() -> void:
	if block_type == null:
		push_error("FlowBlock: added before setup() was called.")
		return
	custom_minimum_size = Vector2(210.0, 0.0)
	_apply_style()
	_build_rows()
	_refresh_header()
	_refresh_stats()


## Bu blok, reçetesi olan ama kendi SÜRESİ (temposu) olmayan türden mi?
## Eritme Ocağı (60 cevher + 6 kömür) VE Mine Extractor (1 ham cevher) AYNI
## aile: `duration_ticks = 0`, bir eşik dolunca ANINDA dönüşür, hızı tamamen
## girdinin ne kadar hızlı geldiğine bağlı. İsme göre DEĞİL, YAPIYA göre
## tespit edilir — yeni bir "anlık dönüşüm" bloğu eklendiğinde burada elle
## kayıt gerekmez.
func _is_instant_conversion_block() -> bool:
	return (
		block_type.recipe != null
		and not block_type.recipe.inputs.is_empty()
		and block_type.recipe.duration_ticks <= 0.0
	)


## Iron Mine, Trade Network gibi girdisiz kaynaklar: hiçbir şey
## biriktirmez, sadece durmadan üretir. İlerleme çubuğu (her ~1.7 tick'te bir
## sıfırlanıp dolan) ve "Output: x/y" satırı bu bloklarda GÖRSEL GÜRÜLTÜ —
## anlamlı bir bekleme/darboğaz göstermiyor, sadece titreşiyor. Bu yüzden
## SADECE Rate ve Level (varsa) gösterilir.
func _is_free_running_source() -> bool:
	return block_type.category == BlockType.Category.SOURCE


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
	panel.bg_color = Color(0.24, 0.18, 0.12, 0.98)
	panel.border_color = accent.darkened(0.25)
	panel.set_border_width_all(1)
	panel.corner_radius_bottom_left = 5
	panel.corner_radius_bottom_right = 5
	panel.content_margin_left = 9.0
	panel.content_margin_right = 9.0
	panel.content_margin_top = 7.0
	panel.content_margin_bottom = 7.0
	add_theme_stylebox_override(&"panel", panel)

	_panel_style = panel

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

	if block_type.node_image != null:
		add_child(_build_node_image())

	for i in row_count:
		var has_in: bool = i < inputs.size()
		var has_out: bool = i < outputs.size()

		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 14)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var left := Label.new()
		left.text = inputs[i] if has_in else ""
		left.add_theme_font_size_override(&"font_size", 12)
		left.add_theme_color_override(&"font_color", Color(0.88, 0.79, 0.61))
		row.add_child(left)

		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(spacer)

		var right := Label.new()
		right.text = outputs[i] if has_out else ""
		right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right.add_theme_font_size_override(&"font_size", 12)
		right.add_theme_color_override(&"font_color", Color(0.88, 0.79, 0.61))
		row.add_child(right)

		add_child(row)
		set_slot(i, has_in, PORT_TYPE_MATERIAL, accent, has_out, PORT_TYPE_MATERIAL, accent)

	if block_type.power_output > 0 or block_type.power_required_per_tick > 0 or block_type.sells_power:
		_build_power_row(row_count)

	if _uses_gate_layout():
		_build_gate_value_rows()

	var sep := HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sep.visible = not _is_free_running_source()
	add_child(sep)

	_progress = ProgressBar.new()
	_progress.max_value = 1.0
	_progress.step = 0.001
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(0.0, 6.0)
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress.visible = not _is_free_running_source()
	add_child(_progress)

	if _uses_gate_layout():
		_build_gate_fill_rows()

	add_child(_build_stats_grid())
	_build_action_buttons()


## Ortak sol/sağ etiket satırı — port ve güç satırlarının kullandığı deseni
## Eritme Ocağı'nın özel satırları için tekrarlamamak adına burada toplar.
func _build_label_row(color: Color) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var left := Label.new()
	left.add_theme_font_size_override(&"font_size", 11)
	left.add_theme_color_override(&"font_color", color)
	row.add_child(left)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)

	var right := Label.new()
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_theme_font_size_override(&"font_size", 11)
	right.add_theme_color_override(&"font_color", color)
	row.add_child(right)

	add_child(row)
	return {"left": left, "right": right}


## Bu blok "KAPILI" mı — kendi temposu olmayan, bir eşik dolunca ANINDA
## dönüşen/geçen türden mi? Sabit reçeteli anlık-dönüşüm blokları (bkz.
## `_is_instant_conversion_block` — Eritme Ocağı, Mine Extractor) VE Trade
## Depot (değişken mal + Talep, bkz. `BlockType.demand_item`) AYNI aile —
## hepsi bu özel 4 satırlı düzeni alır (reçete satırı, canlı hız satırı,
## ilerleme çubuğu, dolum satırı).
func _uses_gate_layout() -> bool:
	return _is_instant_conversion_block() or block_type.demand_item != null


## "Kapılı" bir bloğun girdi tanımları — hem Eritme Ocağı'nın SABİT reçete
## girdileri hem Trade Depot'un TİPİ ÇALIŞMA ANINDA belli olan "herhangi bir
## mal + Talep" girdisi için TEK ortak kaynak. `item_id` boş (&"") ise o
## slotun ürünü sabit değildir — gerçek adedi `_gate_slot_have`'de aranır.
func _gate_slots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if block_type.demand_item != null:
		out.append({"label": "Goods", "target": 1, "item_id": &""})
		out.append({
			"label": block_type.demand_item.display_name,
			"target": maxi(1, block_type.demand_required),
			"item_id": block_type.demand_item.id,
		})
		return out
	if block_type.recipe != null:
		for slot: RecipeSlot in block_type.recipe.inputs:
			out.append({"label": slot.item.display_name, "target": slot.count, "item_id": slot.item.id})
	return out


## Bir "kapı" slotunun o anki dolu adedi. `item_id` boşsa (Trade Depot'un
## "herhangi bir mal" slotu) Talep HARİÇ ilk dolu anahtar aranır.
func _gate_slot_have(station: SimStation, slot: Dictionary) -> int:
	var item_id: StringName = slot["item_id"]
	if item_id != &"":
		return int(station.input.get(item_id, 0))
	var exclude: StringName = block_type.demand_item.id if block_type.demand_item != null else &""
	for key: StringName in station.input.keys():
		if key != exclude and int(station.input[key]) > 0:
			return int(station.input[key])
	return 0


## Reçete satırının (ör. Iron Ore/Coal/Iron Ingot, Goods/Demand/Output)
## hemen altında: HER girdi için bir satır — o anki ölçülen saniyelik akışı
## (bkz. `_update_gate_values`). "Output Value" tek değer olduğundan yalnızca
## İLK satırın sağında görünür. Bloğun kendi temposu olmadığından tek
## anlamlı "hız" budur.
func _build_gate_value_rows() -> void:
	_gate_input_value_labels.clear()
	var slots: Array[Dictionary] = _gate_slots()
	for i in maxi(1, slots.size()):
		var labels: Dictionary = _build_label_row(Color(0.88, 0.79, 0.61))
		labels["left"].text = "Input Value: —"
		_gate_input_value_labels.append(labels["left"])
		if i == 0:
			_gate_output_value_label = labels["right"]
			_gate_output_value_label.text = "Output Value: —"


## İlerleme çubuğunun hemen altında: HER girdi tamponundaki anlık sayı ve
## dönüşümü tetikleyen hedefi (bkz. `SimStation._input_fill_ratio`/
## `_demand_fill_ratio` — çubuğun kendisi zaten en dar boğazın oranını
## gösteriyor, bu satırlar çiğ sayıları kaynak başına ayrı ayrı verir).
func _build_gate_fill_rows() -> void:
	_gate_current_labels.clear()
	for slot: Dictionary in _gate_slots():
		var labels: Dictionary = _build_label_row(Color(0.94, 0.85, 0.67))
		labels["left"].text = "0"
		_gate_current_labels.append(labels["left"])
		labels["right"].text = str(slot["target"])


## Güç portu satırı — malzeme satırlarından hemen sonra, sabit tek satır.
## `block_type.power_port_index()` İLE AYNI indekste olmalı (bkz. orada).
func _build_power_row(row_index: int) -> void:
	var has_in: bool = block_type.power_required_per_tick > 0 or block_type.sells_power
	var has_out: bool = block_type.power_output > 0

	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var left := Label.new()
	left.text = "Power In" if has_in else ""
	left.add_theme_font_size_override(&"font_size", 12)
	left.add_theme_color_override(&"font_color", COLOR_POWER)
	row.add_child(left)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)

	var right := Label.new()
	right.text = "Power Out" if has_out else ""
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_theme_font_size_override(&"font_size", 12)
	right.add_theme_color_override(&"font_color", COLOR_POWER)
	row.add_child(right)

	add_child(row)
	set_slot(row_index, has_in, PORT_TYPE_POWER, COLOR_POWER, has_out, PORT_TYPE_POWER, COLOR_POWER)


## İllüstrasyon başlığın hemen altında, düğüm gövdesinin tam genişliğinde yaşar.
func _build_node_image() -> TextureRect:
	var image := TextureRect.new()
	image.texture = block_type.node_image
	image.custom_minimum_size = Vector2(0.0, 96.0)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


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

	# Canlı durum. Statik bilgi (süre, fire oranı) denetçi panelinde —
	# düğümün üstünde her kare değişen şeyler dursun.
	var specs: Array = [
		[&"rate", "Rate"],
		[&"in", "Input"],
		[&"out", "Output"],
		[&"power", "Power"],
		[&"level", "Level"],
		[&"market", "Market"],
	]
	for spec: Array in specs:
		var key: StringName = spec[0]

		var name_label := Label.new()
		name_label.text = spec[1]
		name_label.add_theme_font_size_override(&"font_size", 11)
		name_label.add_theme_color_override(&"font_color", Color(0.72, 0.59, 0.42))
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var value_label := Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_label.add_theme_font_size_override(&"font_size", 11)
		value_label.add_theme_color_override(&"font_color", Color(0.94, 0.85, 0.67))
		value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

		grid.add_child(name_label)
		grid.add_child(value_label)
		_stat_keys[key] = name_label
		_stat_values[key] = value_label

	return grid


## Yükselt/Tahsil Et düğmeleri doğrudan düğümün üstünde yaşar.
func _build_action_buttons() -> void:
	_upgrade_button = Button.new()
	_upgrade_button.pressed.connect(func() -> void: action_requested.emit(self, &"upgrade"))
	add_child(_upgrade_button)

	_collect_button = Button.new()
	_collect_button.text = "Collect"
	_collect_button.pressed.connect(func() -> void: action_requested.emit(self, &"collect"))
	add_child(_collect_button)
func _refresh_header() -> void:
	title = block_label
	tooltip_text = "%s — %s\n%s" % [
		block_type.display_name, block_type.category_label(), block_type.description
	]


## Simülasyon bağlanmadan önceki boş görünüm.
func _refresh_stats() -> void:
	if _stat_values.is_empty():
		return
	# Kaynağın girişi, bitişin çıkışı yoktur — olmayan satırı hiç göstermeyiz.
	var has_power: bool = block_type.power_output > 0 or block_type.power_required_per_tick > 0 or block_type.sells_power
	# "Kapılı" blokların kendi özel satırları (bkz. `_build_gate_value_rows`,
	# `_build_gate_fill_rows`) aynı bilgiyi zaten veriyor — jenerik
	# Rate/Input/Output burada tekrar görünmesin.
	var is_gated: bool = _uses_gate_layout()
	_set_row_visible(&"rate", not is_gated)
	# Kategoriye değil GERÇEKTEN port olup olmadığına bakılır — Mine
	# Extractor gibi girdisiz INSPECT'ler de (kaynak SOURCE olmasa bile)
	# boş "Input: 0/0" satırıyla kalmasın.
	# Girdisiz kaynaklar (Iron Mine, Trade Network) hiçbir şey
	# biriktirmez — "Output: x/y" onlarda anlamsız titreşen bir sayı, sadece
	# Rate ve Level (varsa) kalsın (bkz. `_is_free_running_source`).
	var is_source: bool = _is_free_running_source()
	_set_row_visible(&"in", not is_gated and not block_type.input_labels().is_empty())
	_set_row_visible(&"out", not is_gated and not is_source and block_type.category != BlockType.Category.SINK and block_type.category != BlockType.Category.RESEARCH and not block_type.power_only)
	_set_row_visible(&"power", has_power)
	_set_row_visible(&"market", block_type.category == BlockType.Category.SINK)
	_set_row_visible(&"level", block_type.upgradeable)
	_write(&"rate", "—")
	_write(&"in", "0 / %d" % block_type.input_capacity)
	_write(&"out", "0 / %d" % block_type.output_capacity)
	_write(&"power", "—")
	_write(&"market", "0 gold")
	_write(&"level", "1 / %d" % block_type.max_level)

	_upgrade_button.visible = block_type.upgradeable
	if block_type.upgradeable:
		_refresh_upgrade_button(1)
	_collect_button.visible = block_type.category == BlockType.Category.SINK


## SİMÜLASYONDAN GÖRÜNTÜYE TEK YAZMA NOKTASI.
##
## GameController her karede bunu çağırır. Blok simülasyonu kendisi
## SORGULAMAZ — durumu ona verilir.
func render_state(station: SimStation, tick: int, unwired_ports: int, auto_collect: bool = false, power_text: String = "", incoming_rates_per_sec: Array[float] = []) -> void:
	_progress.value = station.progress_ratio()
	level = station.level
	market_accrued = station.accrued

	_write(&"rate", _rate_text())
	_write(&"in", "%d / %d" % [station.total_input(), block_type.input_capacity])
	_write(&"out", "%d / %d" % [station.total_output(), block_type.output_capacity])
	if not power_text.is_empty():
		_write(&"power", power_text)
	if _uses_gate_layout():
		_update_gate_values(station, incoming_rates_per_sec)

	if block_type.upgradeable:
		_write(&"level", "%d / %d" % [station.level, block_type.max_level])
		_refresh_upgrade_button(station.level)
	if block_type.category == BlockType.Category.SINK:
		# Otomasyon açılınca manuel tahsilat anlamsızlaşır — düğmeyi ve
		# bekleyen-para satırını tamamen kaldırıyoruz (bkz. üst bar, aynı
		# mantık %CollectButton için de geçerli — DESIGN.md D27).
		_write(&"market", "%s gold" % GameConfig.format_money(station.accrued))
		_set_row_visible(&"market", not auto_collect)
		_collect_button.visible = not auto_collect
		_collect_button.disabled = station.accrued <= 0

	# Kurulum hatası akış sorununu bastırır: bir portu boştaysa oyuncunun
	# önce onu düzeltmesi gerekir, "aç kaldı" bilgisi o hâlde yanıltıcıdır.
	if unwired_ports > 0:
		_apply_display(Display.UNWIRED, unwired_ports)
	elif _smoothed_status(station, tick) == SimStation.Status.RUNNING:
		_apply_display(Display.RUNNING, 0)
	else:
		_apply_display(Display.IDLE, 0)


## "Kapılı" blokların (Eritme Ocağı, Trade Depot) kendi temposu yok — hızı
## tamamen girdilerin ne kadar hızlı geldiğine bağlı. Bu yüzden ÖLÇÜLMÜŞ
## (zamanla artan/yavaşça oturan) bir ortalama DEĞİL, üst istasyonlardan
## PORT BAŞINA GELEN GERÇEK HIZ (`GameController._incoming_rates`,
## formülden — anlık) kullanılır: bağlantı kurulur kurulmaz doğru değer
## görünür, yavaşça yükselmez. Çıktı, girdilerin `rate/slot.target` oranının
## EN KÜÇÜĞÜ — dönüşüm ancak HEPSİ yetiştiğinde olur (bkz. `_gate_slots`).
func _update_gate_values(station: SimStation, incoming_rates_per_sec: Array[float]) -> void:
	var slots: Array[Dictionary] = _gate_slots()
	if slots.is_empty():
		return
	var output_per_sec: float = INF
	for i in slots.size():
		var slot: Dictionary = slots[i]
		var rate: float = incoming_rates_per_sec[i] if i < incoming_rates_per_sec.size() else 0.0
		if i < _gate_input_value_labels.size():
			_gate_input_value_labels[i].text = "Input Value: %.2f/sec" % rate
		if i < _gate_current_labels.size():
			_gate_current_labels[i].text = str(_gate_slot_have(station, slot))
		var ratio: int = maxi(1, int(slot["target"]))
		output_per_sec = minf(output_per_sec, rate / float(ratio))
	if output_per_sec == INF:
		output_per_sec = 0.0
	_gate_output_value_label.text = "Output Value: %.2f/sec" % output_per_sec


## Ham durum her tick değişir ve rozet okunmaz hâle gelir: %75 verimle
## çalışan bir istasyon ÇALIŞIYOR ile AÇ arasında titrer, çünkü zamanın
## dörtte birinde gerçekten bekliyordur. Son bir saniye içinde çalıştıysa
## ÇALIŞIYOR gösteririz; AÇ veya TIKALI ancak gerçekten takıldıysa çıkar.
func _smoothed_status(station: SimStation, tick: int) -> SimStation.Status:
	if station.status == SimStation.Status.RUNNING:
		_last_running_tick = tick
		return SimStation.Status.RUNNING
	if tick - _last_running_tick < GameConfig.TICKS_PER_SECOND:
		return SimStation.Status.RUNNING
	return station.status


## Doğrudan (ölçülmemiş) saniyelik hız — o anki seviyenin reçete süresinden
## hesaplanır. Bilinçli olarak RateMeter/geçmiş örnekleme KULLANMAZ: bir
## geliştirmeye basılınca değer o anda yeni seviyeye zıplasın, pencere
## dolana kadar yavaşça artıp azalmasın.
func _rate_text() -> String:
	var per_second: float = _rate_per_second(level)
	if per_second <= 0.0:
		return "—"
	return "%d/sec" % roundi(per_second)


func _rate_per_second(level_check: int) -> float:
	var ticks: float = block_type.duration_ticks_at_level(level_check)
	if ticks <= 0.0:
		return 0.0
	return float(GameConfig.TICKS_PER_SECOND) / ticks


## Yükselt düğmesinin metni ve etkinliği. Yalnızca fiyatı gösterir — bir
## sonraki seviyenin etkisini artık ayrıca yazmıyoruz.
func _refresh_upgrade_button(level_now: int) -> void:
	if ProgressionState.can_upgrade(block_type, level_now):
		var cost: int = ProgressionState.upgrade_cost(block_type, level_now)
		_upgrade_button.text = "Upgrade (%s gold)" % GameConfig.format_money(cost)
		_upgrade_button.disabled = false
	else:
		_upgrade_button.text = "Max level"
		_upgrade_button.disabled = true


## Çerçeve rengini ve açıklayıcı ipucunu günceller.
##
## Renk yazıdan hızlı okunur ama kendi kendini açıklamaz; ne anlama geldiğini
## düğümün üstüne gelince ipucu söyler.
func _apply_display(display: Display, unwired_ports: int) -> void:
	if display == _last_display and unwired_ports == _last_unwired:
		return
	_last_display = display
	_last_unwired = unwired_ports
	shown_display = display

	var tint: Color
	var explanation: String
	match display:
		Display.UNWIRED:
			tint = COLOR_UNWIRED
			explanation = "%d unlinked ports. Connect them to keep goods moving." % unwired_ports
		Display.RUNNING:
			tint = COLOR_RUNNING
			explanation = "Working."
		_:
			tint = COLOR_IDLE
			explanation = "Idle. Waiting for materials or room to send goods."

	if _panel_style != null:
		_panel_style.border_color = tint
		_panel_style.set_border_width_all(2)
	tooltip_text = "%s — %s
%s

%s" % [
		block_type.display_name, block_type.category_label(),
		block_type.description, explanation
	]


## Değişmediyse yazma — bkz. _last_text.
func _write(key: StringName, text: String) -> void:
	if _last_text.get(key, "") == text:
		return
	_last_text[key] = text
	(_stat_values[key] as Label).text = text


## Bir satırı gösterir/gizler. GridContainer gizli çocukları atladığı için
## etiket ve değer BİRLİKTE gizlenmeli, yoksa sütunlar kayar.
func _set_row_visible(key: StringName, shown: bool) -> void:
	(_stat_keys[key] as Label).visible = shown
	(_stat_values[key] as Label).visible = shown


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
			push_warning("FlowBlock: unknown parameter '%s'" % key)
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
