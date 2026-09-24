@tool
class_name MapPoint
extends Node2D

## Haritada bir nokta: ham madde alanı, fabrika arsası ya da şehir.
##
## Noktalar çizim sahnesinde bölge düğümünün altında durur
## (RegionMap.tscn → Area1/Points/...). tools/generate_points.gd bölge
## verisinden üretir; konum sahnede saklanır ve elle kaydırılabilir.
## Hangi bölgeye ait olduğu sahnedeki yerinden bellidir.

enum Kind { RESOURCE_SITE, FACTORY_PLOT, CITY }

@export var kind: Kind = Kind.FACTORY_PLOT:
	set(value):
		kind = value
		queue_redraw()
## Yalnızca ham madde alanında: çıkan hammadde.
@export var resource: RawResource
## Aynı bölgedeki aynı türden noktaları ayırır. Ham madde alanında
## RegionData.resources içindeki sırasıdır.
@export var slot_index: int = 0

## Editörde görünen geçici işaret (asıl simgeler harita görünümünde).
const EDITOR_RADIUS: float = 10.0


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var color: Color = Color(0.9, 0.9, 0.9)
	match kind:
		Kind.CITY:
			color = Color(0.95, 0.35, 0.3)
		Kind.RESOURCE_SITE:
			color = Color(0.3, 0.75, 0.35)
	draw_circle(Vector2.ZERO, EDITOR_RADIUS, color)
	draw_arc(Vector2.ZERO, EDITOR_RADIUS, 0.0, TAU, 24, Color.BLACK, 2.0)
