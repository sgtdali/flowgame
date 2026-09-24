extends Node2D

## Harita ekranı: bölgeleri durumlarıyla gösterir, seçimi ve kamerayı yönetir.
##
## Kural hesaplamaz: bölge durumu RegionState'ten gelir. Tıklanan bölge,
## bölgelerin CollisionPolygon2D'lerine fizik sorgusuyla bulunur.

signal region_selected(region: RegionData)

const MIN_ZOOM: float = 0.6
const MAX_ZOOM: float = 3.0
const ZOOM_STEP: float = 1.15
## Kamera haritadan en fazla bu kadar dışarı kayabilir (px).
const PAN_MARGIN: float = 300.0

@onready var camera: Camera2D = $Camera2D
@onready var region_map: Node2D = $RegionMap
@onready var map_bounds: Control = $RegionMap/MapBounds

var state: RegionState = RegionState.new()
var selected: RegionView = null

var _panning: bool = false
var _target_zoom: Vector2 = Vector2.ONE


func _ready() -> void:
	# Area2D'lerin fare üzerine gelme sinyalleri için gerekli.
	get_viewport().physics_object_picking = true
	_target_zoom = camera.zoom
	refresh_statuses()


func _process(delta: float) -> void:
	camera.zoom = camera.zoom.lerp(_target_zoom, minf(delta * 12.0, 1.0))


func refresh_statuses() -> void:
	for view: RegionView in _views():
		if view.data != null:
			view.set_status(state.status(view.data.id))


func _unhandled_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		if button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at_mouse(ZOOM_STEP)
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at_mouse(1.0 / ZOOM_STEP)
		elif button.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_panning = button.pressed
		elif button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			_select(_region_at(get_global_mouse_position()))
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _panning:
		camera.position -= motion.relative / camera.zoom
		_clamp_camera()


func _select(view: RegionView) -> void:
	if selected != null:
		selected.set_selected(false)
	selected = view
	if selected != null:
		selected.set_selected(true)
	region_selected.emit(selected.data if selected != null else null)


func _region_at(world_point: Vector2) -> RegionView:
	var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query.position = world_point
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for hit: Dictionary in get_world_2d().direct_space_state.intersect_point(query):
		var view: RegionView = hit["collider"] as RegionView
		if view != null:
			return view
	return null


func _views() -> Array[RegionView]:
	var out: Array[RegionView] = []
	for child: Node in region_map.get_children():
		if child is RegionView:
			out.append(child)
	return out


func _zoom_at_mouse(factor: float) -> void:
	var before: float = _target_zoom.x
	var after: float = clampf(before * factor, MIN_ZOOM, MAX_ZOOM)
	_target_zoom = Vector2(after, after)
	var mouse_world: Vector2 = get_global_mouse_position()
	camera.position += (mouse_world - camera.position) * (1.0 - before / after)
	_clamp_camera()


func _clamp_camera() -> void:
	var bounds: Rect2 = Rect2(map_bounds.position, map_bounds.size).grow(PAN_MARGIN)
	camera.position = camera.position.clamp(bounds.position, bounds.end)
