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

## Düğümün çerçevesinin anlattığı şey.
##
## Durum artık YAZIYLA değil RENKLE anlatılıyor: tuvale bakan oyuncu her
## düğümü tek tek okumak zorunda kalmadan sorunun nerede olduğunu görmeli.
enum Display {
	RUNNING,   ## yeşil — üretiyor
	IDLE,      ## turuncu — malzeme veya yer bekliyor
	UNWIRED,   ## kırmızı — bir portu boşta, akışa katılamıyor
	UNSTAFFED,
	HUNGRY,
}

const COLOR_RUNNING := Color(0.55, 0.73, 0.43)
const COLOR_IDLE := Color(0.86, 0.64, 0.32)
const COLOR_UNWIRED := Color(0.78, 0.38, 0.31)
const COLOR_UNSTAFFED := Color(0.50, 0.49, 0.44)
const COLOR_HUNGRY := Color(0.73, 0.43, 0.24)

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
var worker_assigned: bool = false

## Denetçi panelinin okuduğu, simülasyondan yansıtılan canlı değerler —
## `worker_assigned` ile AYNI desen (bkz. `render_state`). Denetçi
## `FlowCanvas.block_selected` sinyaliyle doğrudan bu bloktan okuyor,
## GameController'dan geçmiyor — o yüzden ihtiyaç duyduğu her canlı değer
## buraya yansıtılmalı.
var level: int = 1
var market_accrued: int = 0

var _stat_keys: Dictionary = {}
var _stat_values: Dictionary = {}
var _progress: ProgressBar = null
var _panel_style: StyleBoxFlat = null
var _worker_button: Button = null
var _upgrade_button: Button = null
var _collect_button: Button = null

## Son yazılan değerler. Label.text atamak font shaping tetikler; 80 düğüm ×
## 4 satır × 60 kare = saniyede 19.200 gereksiz shaping demek. Değişmediyse
## yazmıyoruz.
var _last_text: Dictionary = {}
var _last_display: int = -1
var _last_unwired: int = -1

## Bu istasyonun üretim hızı. Sunum verisi — simülasyonda yeri yok.
var _rate := RateMeter.new()

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

	var sep := HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep)

	_progress = ProgressBar.new()
	_progress.max_value = 1.0
	_progress.step = 0.001
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(0.0, 6.0)
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_progress)

	add_child(_build_stats_grid())
	_build_action_buttons()


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
		[&"worker", "Worker"],
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


## İşçi ata / Yükselt / Tahsil Et düğmeleri — düğümün kendi altında, sağ
## paneli beklemeden tıklanabilir olsunlar diye burada yaşarlar (bkz.
## DESIGN.md D27/D28 — sağ panel artık denetçi değil araştırma ağacı).
func _build_action_buttons() -> void:
	_worker_button = Button.new()
	_worker_button.pressed.connect(func() -> void: action_requested.emit(self, &"worker"))
	add_child(_worker_button)

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
	_set_row_visible(&"in", block_type.category != BlockType.Category.SOURCE)
	_set_row_visible(&"out", block_type.category != BlockType.Category.SINK and block_type.category != BlockType.Category.RESEARCH and block_type.category != BlockType.Category.FOOD)
	_set_row_visible(&"worker", block_type.requires_worker())
	_set_row_visible(&"market", block_type.category == BlockType.Category.SINK)
	_set_row_visible(&"level", block_type.upgradeable)
	_write(&"worker", "No")
	_write(&"rate", "—")
	_write(&"in", "0 / %d" % block_type.input_capacity)
	_write(&"out", "0 / %d" % block_type.output_capacity)
	_write(&"market", "0 gold")
	_write(&"level", "1 / %d" % block_type.max_level)

	_worker_button.visible = block_type.requires_worker()
	_worker_button.text = "Assign worker"
	_upgrade_button.visible = block_type.upgradeable
	if block_type.upgradeable:
		_refresh_upgrade_button(1)
	_collect_button.visible = block_type.category == BlockType.Category.SINK


## SİMÜLASYONDAN GÖRÜNTÜYE TEK YAZMA NOKTASI.
##
## GameController her karede bunu çağırır. Blok simülasyonu kendisi
## SORGULAMAZ — durumu ona verilir.
func render_state(station: SimStation, tick: int, unwired_ports: int, auto_collect: bool = false) -> void:
	_progress.value = station.progress_ratio()
	worker_assigned = station.assigned_worker
	level = station.level
	market_accrued = station.accrued
	_write(&"worker", "Yes" if worker_assigned else "No")
	if block_type.requires_worker():
		_worker_button.text = "Worker assigned" if worker_assigned else "Assign worker"
	_rate.sample(tick, station.throughput_total())

	_write(&"rate", _rate_text())
	_write(&"in", "%d / %d" % [station.total_input(), block_type.input_capacity])
	_write(&"out", "%d / %d" % [station.total_output(), block_type.output_capacity])

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
	if station.status == SimStation.Status.UNSTAFFED:
		_apply_display(Display.UNSTAFFED, unwired_ports)
	elif station.status == SimStation.Status.HUNGRY:
		_apply_display(Display.HUNGRY, unwired_ports)
	elif unwired_ports > 0:
		_apply_display(Display.UNWIRED, unwired_ports)
	elif _smoothed_status(station, tick) == SimStation.Status.RUNNING:
		_apply_display(Display.RUNNING, 0)
	else:
		_apply_display(Display.IDLE, 0)


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


## "12.4/dk · %52" — gerçekleşen hız ve teorik tavana göre verim.
##
## Verim, oyuncunun asıl teşhis aracı: %100 çalışan bir istasyon darboğazdır
## (daha fazlası gerekiyor), %40 çalışan ise bekliyor demektir ve suç başka
## yerdedir. Durum rozeti nedenini, verim ise ne kadarını söyler.
func _rate_text() -> String:
	var actual: float = _rate.per_minute()
	var text: String = "%.1f/min" % actual
	var ceiling: float = _ceiling_per_minute()
	if ceiling > 0.0:
		text += "  %%%d" % roundi(clampf(actual / ceiling, 0.0, 1.0) * 100.0)
	return text


## Yükselt düğmesinin metni ve etkinliği — bkz. DESIGN.md D27. Statik bilgi
## (bir sonraki seviyenin hızı) denetçide değil burada: oyuncu düğmeye
## basmadan önce ne alacağını düğümün üstünde görmeli.
func _refresh_upgrade_button(level_now: int) -> void:
	if ProgressionState.can_upgrade(block_type, level_now):
		var cost: int = ProgressionState.upgrade_cost(block_type, level_now)
		var next_pace: String = _pace_text(level_now + 1)
		_upgrade_button.text = "Upgrade → %s (%s gold)" % [next_pace, GameConfig.format_money(cost)]
		_upgrade_button.disabled = false
	else:
		_upgrade_button.text = "Max level"
		_upgrade_button.disabled = true


## Belirtilen seviyede bu istasyonun teorik tavan hızı — yükselt düğmesinin
## "bir sonraki seviye ne kazandırır" bilgisini taşır.
func _pace_text(level_check: int) -> String:
	var ticks: int = block_type.duration_ticks_at_level(level_check)
	if ticks <= 0:
		return "—"
	var per_minute: float = float(GameConfig.TICKS_PER_SECOND) * 60.0 / float(ticks)
	return "%.1f/min" % per_minute


## Bu istasyonun MEVCUT seviyesinde hiç beklemeden çalışsa dakikada kaç
## üretebileceği. Geliştirme sonrası tavan da yükselir — sabit kalsaydı
## yükseltme sonrası verim %'si yanlışlıkla %100'e yapışık görünürdü.
func _ceiling_per_minute() -> float:
	var ticks: int = block_type.duration_ticks_at_level(level)
	if ticks <= 0:
		return 0.0
	return float(GameConfig.TICKS_PER_SECOND) * 60.0 / float(ticks)


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
		Display.UNSTAFFED:
			tint = COLOR_UNSTAFFED
			explanation = "Assign a worker to start this workshop."
		Display.HUNGRY:
			tint = COLOR_HUNGRY
			explanation = "No food for the workforce. Keep the food route running."
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
