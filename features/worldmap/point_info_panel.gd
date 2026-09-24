class_name PointInfoPanel
extends PanelContainer

## Sağdaki nokta bilgi paneli. Seçili noktanın türünü, bölgesini ve
## içeriğini gösterir. Kural hesaplamaz: bölgenin durumu WorldMap'ten gelir.

const KIND_TEXT: Dictionary = {
	MapPoint.Kind.RESOURCE_SITE: "Resource site",
	MapPoint.Kind.FACTORY_PLOT: "Factory plot",
	MapPoint.Kind.CITY: "City",
}
const REGION_STATUS_TEXT: Dictionary = {
	RegionState.Status.UNLOCKED: "unlocked",
	RegionState.Status.AVAILABLE: "locked, available",
	RegionState.Status.LOCKED: "locked",
}

@onready var title_label: Label = %PointTitleLabel
@onready var kind_label: Label = %PointKindLabel
@onready var region_value: Label = %PointRegionValue
@onready var detail_caption: Label = %PointDetailCaption
@onready var detail_value: Label = %PointDetailValue


func _ready() -> void:
	hide()


func show_point(point: MapPoint, region_status: RegionState.Status) -> void:
	title_label.text = point.get_title()
	kind_label.text = KIND_TEXT[point.kind]
	var view: RegionView = point.get_region_view()
	var region_name: String = view.data.display_name if view != null and view.data != null else "?"
	region_value.text = "%s (%s)" % [region_name, REGION_STATUS_TEXT[region_status]]
	# Şehir talebi ayrı görev; şimdilik şehirde ayrıntı satırı yok.
	detail_caption.visible = point.kind != MapPoint.Kind.CITY
	detail_value.visible = detail_caption.visible
	match point.kind:
		MapPoint.Kind.RESOURCE_SITE:
			detail_caption.text = "Produces"
			detail_value.text = "%s  %d/min" % [point.resource.display_name,
					point.resource.extraction_per_minute] if point.resource != null else "-"
		MapPoint.Kind.FACTORY_PLOT:
			detail_caption.text = "Status"
			detail_value.text = "Empty"
	show()
	reset_size()
