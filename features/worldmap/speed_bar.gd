class_name SpeedBar
extends HBoxContainer

## Üst çubuktaki oyun hızı düğmeleri (Pause / x1 / x2 / x4) ve oyun saati.
##
## Tasarım: 1 oyun dakikası = 1 gerçek dakika (x1). Simülasyon sabit
## adımlarla ilerler; her adımda `advanced(dt)` yayınlanır (dt oyun dakikası).

signal advanced(dt_minutes: float)

const SPEEDS: Array[int] = [0, 1, 2, 4]
const LABELS: Array[String] = ["Pause", "x1", "x2", "x4"]
## Bir simülasyon adımı: çeyrek oyun saniyesi.
const STEP_GAME_SECONDS: float = 0.25
## Bir karede en fazla bu kadar adım (takılmada donmayı önler).
const MAX_STEPS_PER_FRAME: int = 64

var speed: int = 1
var _buttons: Array[Button] = []
## Henüz simüle edilmemiş oyun saniyesi.
var _pending_seconds: float = 0.0


func _ready() -> void:
	var group: ButtonGroup = ButtonGroup.new()
	for i: int in SPEEDS.size():
		var button: Button = Button.new()
		button.text = LABELS[i]
		button.toggle_mode = true
		button.button_group = group
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(56.0, 0.0)
		button.button_pressed = SPEEDS[i] == speed
		button.pressed.connect(set_speed.bind(SPEEDS[i]))
		add_child(button)
		_buttons.append(button)


func set_speed(value: int) -> void:
	speed = value
	for i: int in _buttons.size():
		_buttons[i].set_pressed_no_signal(SPEEDS[i] == value)


func _process(delta: float) -> void:
	_pending_seconds += delta * speed
	var steps: int = 0
	while _pending_seconds >= STEP_GAME_SECONDS and steps < MAX_STEPS_PER_FRAME:
		_pending_seconds -= STEP_GAME_SECONDS
		steps += 1
		advanced.emit(STEP_GAME_SECONDS / 60.0)
	if steps == MAX_STEPS_PER_FRAME:
		_pending_seconds = 0.0
