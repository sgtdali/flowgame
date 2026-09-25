class_name MapCamera
extends Camera2D

## Harita kamerası: sağ/orta tık sürükleyerek kaydırma, tekerlekle fareye doğru
## yakınlaştırma. Olayları "işlendi" diye işaretlemez; WorldMap de aynı sağ
## tıkı (hat kurmayı iptal) kullanabilir.

const MIN_ZOOM: float = 0.4
const MAX_ZOOM: float = 3.0
const ZOOM_STEP: float = 1.15
## Kamera haritadan en fazla bu kadar dışarı kayabilir (dünya birimi).
const PAN_MARGIN: float = 300.0
## Başlangıç bölgesine odaklanırken ekranın ne kadarını doldursun.
const FOCUS_FILL: float = 0.8

## Haritanın kapladığı alan (dünya koordinatı); WorldMap ayarlar.
var map_rect: Rect2 = Rect2()

var _panning: bool = false
var _target_zoom: Vector2 = Vector2.ONE


func _ready() -> void:
	_target_zoom = zoom


func _process(delta: float) -> void:
	zoom = zoom.lerp(_target_zoom, minf(delta * 12.0, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		if button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(button.position, ZOOM_STEP)
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(button.position, 1.0 / ZOOM_STEP)
		elif button.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_panning = button.pressed
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _panning:
		position -= motion.relative / zoom
		_clamp()


## Kamerayı `rect`e ortalar ve ekranı büyük ölçüde dolduracak kadar yakınlaşır.
func focus_rect(rect: Rect2) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var view: Vector2 = get_viewport_rect().size
	var fit: float = minf(view.x / rect.size.x, view.y / rect.size.y) * FOCUS_FILL
	var value: float = clampf(fit, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2(value, value)
	_target_zoom = zoom
	position = rect.get_center()
	_clamp()


func _zoom_at(screen_position: Vector2, factor: float) -> void:
	var before: float = _target_zoom.x
	var after: float = clampf(before * factor, MIN_ZOOM, MAX_ZOOM)
	_target_zoom = Vector2(after, after)
	var mouse_world: Vector2 = get_canvas_transform().affine_inverse() * screen_position
	position += (mouse_world - position) * (1.0 - before / after)
	_clamp()


func _clamp() -> void:
	if map_rect.size == Vector2.ZERO:
		return
	var bounds: Rect2 = map_rect.grow(PAN_MARGIN)
	position = position.clamp(bounds.position, bounds.end)
