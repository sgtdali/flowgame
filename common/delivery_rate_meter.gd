extends RefCounted

## Coalesces nearby deliveries before estimating their per-minute rate.
## A bakery ships its two loaves on successive ticks; they are one batch.
const GROUP_GAP_TICKS: int = 2
const MAX_GROUP_TICKS: int = 6
const EVENT_ALPHA: float = 0.3

var _has_total: bool = false
var _last_total: int = 0
var _last_seen_tick: int = 0
var _pending_first_tick: int = -1
var _pending_last_tick: int = -1
var _pending_amount: int = 0
var _last_group_tick: int = -1
var _avg_interval: float = -1.0
var _avg_amount: float = 0.0


func sample(tick: int, total: int) -> void:
	if not _has_total:
		_has_total = true
		_last_total = total
		_last_seen_tick = tick
		return

	_last_seen_tick = tick
	var delta: int = total - _last_total
	_last_total = total

	if _pending_amount > 0 and (
		tick - _pending_last_tick > GROUP_GAP_TICKS
		or tick - _pending_first_tick >= MAX_GROUP_TICKS
	):
		_finish_group()

	if delta <= 0:
		return

	if _pending_amount == 0:
		_pending_first_tick = tick
	_pending_last_tick = tick
	_pending_amount += delta


func _finish_group() -> void:
	if _last_group_tick >= 0:
		var interval: float = float(_pending_first_tick - _last_group_tick)
		if _avg_interval < 0.0:
			_avg_interval = interval
			_avg_amount = float(_pending_amount)
		else:
			_avg_interval += (interval - _avg_interval) * EVENT_ALPHA
			_avg_amount += (float(_pending_amount) - _avg_amount) * EVENT_ALPHA
	_last_group_tick = _pending_first_tick
	_pending_first_tick = -1
	_pending_last_tick = -1
	_pending_amount = 0


func per_minute() -> float:
	if _avg_interval <= 0.0:
		return 0.0
	var elapsed: float = float(_last_seen_tick - _last_group_tick)
	var effective_interval: float = maxf(_avg_interval, elapsed)
	return _avg_amount / effective_interval * float(GameConfig.TICKS_PER_SECOND) * 60.0


func reset() -> void:
	_has_total = false
	_last_total = 0
	_last_seen_tick = 0
	_pending_first_tick = -1
	_pending_last_tick = -1
	_pending_amount = 0
	_last_group_tick = -1
	_avg_interval = -1.0
	_avg_amount = 0.0
