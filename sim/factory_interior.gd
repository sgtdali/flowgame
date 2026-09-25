class_name FactoryInterior
extends FactorySim

## Bir fabrikanın içi: eski oyunun parça simülasyonu + haritayla bağlantı.
##
## FactorySim'e yalnızca kapıları ve iki stoğu ekler (tasarım belgesi,
## "Fabrika stokları"):
##   Giriş stoğu: hatların getirdiği mal. O malın giriş kapısı buradan çeker.
##   Çıkış stoğu: çıkış kapısının koyduğu mal. Fabrikadan çıkan hatlar buradan alır.
## Stoklar haritadaki gibi kesirli (birim), editördeki parçalar tam sayıdır;
## kapılar yalnızca tam birimleri geçirir.
##
## Haritadaki özet için giren/çıkan mal oyun dakikası pencereleriyle ölçülür
## (`roll_minute`). Uyarı: bir çıkış stoğu doluysa ya da işleyiciler geçen
## dakikanın yarısından fazlasında girdi beklediyse (görev 05, K6).
##
## Saat haritanın oyun saatidir: `advance(dakika)` oyun saniyesi başına
## GameConfig.TICKS_PER_SECOND adım koşar (eski oyundaki hız; tarif süreleri
## buna göre yazılı).

var config: MapConfig
## Mal başına stok sınırı (giriş ve çıkış ayrı ayrı).
var capacity: int

var _input_stock: Dictionary = {}   # Good -> float
var _output_stock: Dictionary = {}  # Good -> float
var _input_gates: Dictionary = {}   # Good -> istasyon id
var _tick_accumulator: float = 0.0
## Bu ve geçen dakika hatlardan giren / hatlara çıkan: Good -> birim.
var _in_now: Dictionary = {}
var _out_now: Dictionary = {}
var _in_last: Dictionary = {}
var _out_last: Dictionary = {}
## Bu dakikada adım sayısı ve bir işleyicinin girdi beklediği adım sayısı.
var _ticks_now: int = 0
var _starved_ticks_now: int = 0
var _starved_last_minute: bool = false


func _init(p_config: MapConfig) -> void:
	config = p_config
	capacity = p_config.point_stock_capacity


## Oyun saatini `minutes` kadar ilerletir; biriken tam adımlar koşulur.
func advance(minutes: float) -> void:
	_tick_accumulator += minutes * 60.0 * float(GameConfig.TICKS_PER_SECOND)
	while _tick_accumulator >= 1.0:
		_tick_accumulator -= 1.0
		tick()


func tick() -> void:
	super.tick()
	_ticks_now += 1
	for station: SimStation in stations():
		if _is_processor(station) and station.status == SimStation.Status.STARVED:
			_starved_ticks_now += 1
			break


## --- Haritadaki özet -------------------------------------------------------------

## Geçen tam oyun dakikasında hatlardan giren (birim).
func input_last_minute(good: Good) -> float:
	return float(_in_last.get(good, 0.0))


## Geçen tam oyun dakikasında hatlara çıkan (birim).
func output_last_minute(good: Good) -> float:
	return float(_out_last.get(good, 0.0))


## Özette gösterilecek mallar: kapısı, stoğu ya da son dakikada hareketi olanlar.
func summary_goods() -> Array[Good]:
	var out: Array[Good] = []
	for good: Good in _input_gates.keys():
		out.append(good)
	for good: Good in output_goods():
		if not out.has(good):
			out.append(good)
	return out


## Dakika dolunca ölçümleri kaydırır.
func roll_minute() -> void:
	_in_last = _in_now
	_out_last = _out_now
	_in_now = {}
	_out_now = {}
	_starved_last_minute = _ticks_now > 0 and _starved_ticks_now * 2 > _ticks_now
	_ticks_now = 0
	_starved_ticks_now = 0


## Haritada uyarı işareti yanmalı mı?
func has_warning() -> bool:
	return output_full() or _starved_last_minute


## Herhangi bir malın çıkış stoğu dolu mu?
func output_full() -> bool:
	for good: Good in _output_stock.keys():
		if output_stock(good) >= float(capacity):
			return true
	return false


## Geçen dakikanın çoğunda bir işleyici girdi mi bekledi?
func starved_last_minute() -> bool:
	return _starved_last_minute


static func _is_processor(station: SimStation) -> bool:
	return station.type is not FactoryGate and station.type.category == BlockType.Category.PROCESS


## --- Stoklar ------------------------------------------------------------------

func input_stock(good: Good) -> float:
	return float(_input_stock.get(good, 0.0))


func output_stock(good: Good) -> float:
	return float(_output_stock.get(good, 0.0))


func input_space(good: Good) -> float:
	return maxf(0.0, float(capacity) - input_stock(good))


## Hattan gelen malı giriş stoğuna koyar; sığan miktarı döndürür. İlk gelişte
## o malın giriş kapısı kendiliğinden kurulur.
func add_input(good: Good, amount: float) -> float:
	var accepted: float = minf(amount, input_space(good))
	if accepted <= 0.0:
		return 0.0
	_input_stock[good] = input_stock(good) + accepted
	_in_now[good] = float(_in_now.get(good, 0.0)) + accepted
	ensure_input_gate(good)
	return accepted


## Çıkış stoğundan en fazla `amount` alır; alınan miktarı döndürür.
func take_output(good: Good, amount: float) -> float:
	var taken: float = minf(amount, output_stock(good))
	if taken <= 0.0:
		return 0.0
	_output_stock[good] = output_stock(good) - taken
	_out_now[good] = float(_out_now.get(good, 0.0)) + taken
	return taken


## Çıkış kapısı olan ya da çıkış stoğunda mal bulunan mallar (önce kapı sırası).
func output_goods() -> Array[Good]:
	var out: Array[Good] = []
	for station: SimStation in stations():
		var gate: FactoryGate = station.type as FactoryGate
		if gate != null and gate.direction == FactoryGate.Direction.OUT and not out.has(gate.good):
			out.append(gate.good)
	for good: Good in _output_stock.keys():
		if output_stock(good) > 0.0 and not out.has(good):
			out.append(good)
	return out


## --- Kapılar ------------------------------------------------------------------

## `good` için giriş kapısının istasyon id'si; yoksa kurar.
func ensure_input_gate(good: Good) -> int:
	if _input_gates.has(good):
		return _input_gates[good]
	var id: int = add_station(config.gate_in.for_good(good))
	_input_gates[good] = id
	return id


func input_gate_id(good: Good) -> int:
	return int(_input_gates.get(good, -1))


## Oyuncunun yerleştirdiği çıkış kapısı.
func add_output_gate(good: Good) -> int:
	return add_station(config.gate_out.for_good(good))


## Giriş kapıları silinemez (kendiliğinden gelir); diğer her şey silinebilir.
func can_remove(id: int) -> bool:
	var station: SimStation = get_station(id)
	if station == null:
		return false
	var gate: FactoryGate = station.type as FactoryGate
	return gate == null or gate.direction != FactoryGate.Direction.IN


func remove_station(id: int) -> void:
	if can_remove(id):
		super.remove_station(id)


## --- Adım ---------------------------------------------------------------------

## FactorySim'in üretim fazı; kapılar kendi kuralıyla, diğerleri eskisi gibi.
func _phase_produce() -> void:
	for station: SimStation in stations():
		var gate: FactoryGate = station.type as FactoryGate
		if gate != null:
			if gate.direction == FactoryGate.Direction.IN:
				_run_input_gate(station, gate.good)
			else:
				_run_output_gate(station, gate.good)
			continue
		match station.type.category:
			BlockType.Category.BUFFER, BlockType.Category.SPLITTER:
				_run_buffer(station)
			BlockType.Category.SINK:
				_run_sink(station)
			BlockType.Category.RESEARCH:
				_run_research(station)
			_:
				_run_producer(station)


## Giriş stoğundaki tam birimleri kapının çıkış tamponuna geçirir.
func _run_input_gate(station: SimStation, good: Good) -> void:
	var moved: bool = false
	while station.total_output() < station.type.output_capacity and input_stock(good) >= 1.0:
		_input_stock[good] = input_stock(good) - 1.0
		station.add_item(station.output, good.id, 1)
		station.produced_total += 1
		moved = true
	if moved:
		station.status = SimStation.Status.RUNNING
	elif station.total_output() >= station.type.output_capacity:
		station.status = SimStation.Status.BLOCKED
	else:
		station.status = SimStation.Status.STARVED


## Kapıya gelen parçaları çıkış stoğuna koyar; stok doluysa parçalar kapıda
## bekler ve kapı dolunca geri tıkanma içeriye yayılır.
func _run_output_gate(station: SimStation, good: Good) -> void:
	var waiting: int = int(station.input.get(good.id, 0))
	if waiting <= 0:
		station.status = SimStation.Status.STARVED
		return
	var fits: int = mini(waiting, floori(float(capacity) - output_stock(good)))
	if fits <= 0:
		station.status = SimStation.Status.BLOCKED
		return
	station.take_item(station.input, good.id, fits)
	_output_stock[good] = output_stock(good) + float(fits)
	station.consumed_total += fits
	station.status = SimStation.Status.RUNNING
