class_name RegionView
extends Area2D

## Çizimdeki bir bölge düğümü (RegionMap.tscn → Area1, Area2...).
##
## Şekil, kullanıcının bu düğümün altına elle çizdiği Polygon2D'lerdir;
## birden fazla olabilir (ada, kopuk parça). Oyun verisi `data`'dadır.
## Çalışırken bu şekillerden tıklama alanı (CollisionPolygon2D) ve sınır
## çizgisi (Line2D) üretilir. Kural hesaplamaz: durumu dışarıdan alır.
## Tıklamayı WorldMap bulur (fizik sorgusu); bu düğüm yalnızca üzerine
## gelme vurgusunu kendisi yönetir.

@export var data: RegionData

## Durum renkleri: dolgu ve sınır.
const FILL_UNLOCKED: Color = Color(0.55, 0.78, 0.5)
const FILL_AVAILABLE: Color = Color(0.42, 0.46, 0.42)
const FILL_LOCKED: Color = Color(0.3, 0.32, 0.3)
const BORDER_UNLOCKED: Color = Color(0.18, 0.4, 0.18)
const BORDER_AVAILABLE: Color = Color(0.98, 0.8, 0.25)
const BORDER_LOCKED: Color = Color(0.16, 0.17, 0.16)
const BORDER_SELECTED: Color = Color(1.0, 1.0, 1.0)
const BORDER_WIDTH: float = 3.0
const BORDER_WIDTH_AVAILABLE: float = 5.0
const BORDER_WIDTH_SELECTED: float = 8.0
## Fare üzerindeyken dolgunun beyaza doğru açılma oranı.
const HOVER_LIGHTEN: float = 0.18

var _status: RegionState.Status = RegionState.Status.LOCKED
var _hovered: bool = false
var _selected: bool = false
var _shapes: Array[Polygon2D] = []
var _borders: Array[Line2D] = []


## Bölgenin parçaları, bu düğümün yerel koordinatında.
## Polygon2D'nin kendi kayması (position vb.) hesaba katılır.
func get_polygons() -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for child: Node in get_children():
		var shape: Polygon2D = child as Polygon2D
		if shape != null and shape.polygon.size() >= 3:
			out.append(shape.transform * shape.polygon)
	return out


func _ready() -> void:
	for child: Node in get_children():
		if child is Polygon2D:
			_shapes.append(child)
	for poly: PackedVector2Array in get_polygons():
		var collision: CollisionPolygon2D = CollisionPolygon2D.new()
		collision.polygon = poly
		add_child(collision)
		var border: Line2D = Line2D.new()
		border.points = poly
		border.closed = true
		border.joint_mode = Line2D.LINE_JOINT_ROUND
		add_child(border)
		_borders.append(border)
	_add_name_label()
	input_pickable = true
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	_refresh()


func set_status(value: RegionState.Status) -> void:
	_status = value
	_refresh()


func set_selected(value: bool) -> void:
	_selected = value
	_refresh()


func _on_hover(value: bool) -> void:
	_hovered = value
	_refresh()


func _refresh() -> void:
	var fill: Color = FILL_LOCKED
	var border_color: Color = BORDER_LOCKED
	var width: float = BORDER_WIDTH
	match _status:
		RegionState.Status.UNLOCKED:
			fill = FILL_UNLOCKED
			border_color = BORDER_UNLOCKED
		RegionState.Status.AVAILABLE:
			fill = FILL_AVAILABLE
			border_color = BORDER_AVAILABLE
			width = BORDER_WIDTH_AVAILABLE
	if _hovered:
		fill = fill.lerp(Color.WHITE, HOVER_LIGHTEN)
	if _selected:
		border_color = BORDER_SELECTED
		width = BORDER_WIDTH_SELECTED
	for shape: Polygon2D in _shapes:
		shape.color = fill
	for border: Line2D in _borders:
		border.default_color = border_color
		border.width = width
	# Kalın sınırlar komşunun sınırının altında kalmasın.
	z_index = 2 if _selected else (1 if _status == RegionState.Status.AVAILABLE else 0)


## Bölge adını en büyük parçanın ortasına yazar.
func _add_name_label() -> void:
	if data == null:
		return
	var biggest: PackedVector2Array = []
	for poly: PackedVector2Array in get_polygons():
		if poly.size() > biggest.size():
			biggest = poly
	if biggest.is_empty():
		return
	var center: Vector2 = Vector2.ZERO
	for point: Vector2 in biggest:
		center += point
	center /= biggest.size()
	var label: Label = Label.new()
	label.text = data.display_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(200.0, 0.0)
	label.position = center - Vector2(100.0, 14.0)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
