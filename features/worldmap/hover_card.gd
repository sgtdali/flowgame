class_name HoverCard
extends PanelContainer

## Fare bir noktanın ya da hattın üzerindeyken imlecin yanında duran küçük
## özet kutusu: başlık + birkaç satır (simge + sayı). Satırlar panellerle aynı
## biçimdedir (PointDetails / InfoRows); tıklayınca açılan panel aynen kalır.
## Yalnızca gösterir; fareyi yakalamaz.

## İmleçten uzaklık ve ekran kenarına bırakılan pay.
const CURSOR_OFFSET: Vector2 = Vector2(18.0, 18.0)
const SCREEN_MARGIN: float = 8.0
const TITLE_SIZE: int = 15

var _title: Label
var _grid: GridContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override(&"font_size", TITLE_SIZE)
	box.add_child(_title)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_grid)
	hide()


## Üzerine gelinen noktanın ya da hattın özetini gösterir; ikisi de yoksa gizlenir.
func show_for(point: MapPoint, route: RouteView, panels: MapPanels, mouse_position: Vector2) -> void:
	if point != null:
		show_rows(point.describe(), panels.point_rows(point), mouse_position)
	elif route != null and is_instance_valid(route):
		var rows: Array[Dictionary] = [{"caption": "Distance",
				"text": MapUnits.km_text(route.route.distance)}]
		rows.append_array(panels.route_rows(route))
		show_rows("%s - %s" % [route.from_point.get_title(), route.to_point.get_title()],
				rows, mouse_position)
	else:
		hide()


## Kutuyu `rows` ile doldurur ve imlecin yanına koyar.
func show_rows(title: String, rows: Array[Dictionary], mouse_position: Vector2) -> void:
	_title.text = title
	InfoRows.fill(_grid, 0, rows)
	_grid.visible = not rows.is_empty()
	show()
	reset_size()
	follow(mouse_position)


## Kutuyu imlecin yanına taşır; ekrandan taşacaksa imlecin öbür yanına geçer.
func follow(mouse_position: Vector2) -> void:
	if not visible:
		return
	var screen: Vector2 = get_viewport_rect().size
	var pos: Vector2 = mouse_position + CURSOR_OFFSET
	if pos.x + size.x > screen.x - SCREEN_MARGIN:
		pos.x = mouse_position.x - CURSOR_OFFSET.x - size.x
	if pos.y + size.y > screen.y - SCREEN_MARGIN:
		pos.y = mouse_position.y - CURSOR_OFFSET.y - size.y
	position = pos.max(Vector2(SCREEN_MARGIN, SCREEN_MARGIN))
