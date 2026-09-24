class_name RegionInfoPanel
extends PanelContainer

## Sağdaki bölge bilgi paneli. Seçili bölgenin verisini gösterir.
##
## Kural hesaplamaz: bölgenin durumu WorldMap'ten (RegionState) gelir.
## Kilitli bölgenin içeriği de gösterilir (tasarım: açmadan önce görülebilir).

const STATUS_TEXT: Dictionary = {
	RegionState.Status.UNLOCKED: "Unlocked",
	RegionState.Status.AVAILABLE: "Available to unlock",
	RegionState.Status.LOCKED: "Locked — no unlocked neighbor",
}
const STATUS_COLOR: Dictionary = {
	RegionState.Status.UNLOCKED: Color(0.55, 0.85, 0.5),
	RegionState.Status.AVAILABLE: Color(0.98, 0.8, 0.25),
	RegionState.Status.LOCKED: Color(0.65, 0.67, 0.65),
}

@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel
@onready var terrain_value: Label = %TerrainValue
@onready var resources_value: Label = %ResourcesValue
@onready var city_value: Label = %CityValue
@onready var slots_value: Label = %SlotsValue
@onready var neighbors_value: Label = %NeighborsValue


func _ready() -> void:
	hide()


func show_region(region: RegionData, status: RegionState.Status) -> void:
	title_label.text = region.display_name
	status_label.text = STATUS_TEXT[status]
	status_label.add_theme_color_override("font_color", STATUS_COLOR[status])
	terrain_value.text = RegionData.terrain_name(region.terrain)
	resources_value.text = _resources_text(region)
	city_value.text = region.city_name if region.has_city() else "None"
	slots_value.text = str(region.factory_slots)
	neighbors_value.text = _neighbors_text(region)
	show()
	# İçerik kısaldığında panel eski boyunda kalmasın.
	reset_size()


func _resources_text(region: RegionData) -> String:
	var lines: PackedStringArray = []
	for resource: RawResource in region.resources:
		lines.append("%s  %d/min" % [resource.display_name, resource.extraction_per_minute])
	return "\n".join(lines) if not lines.is_empty() else "None"


func _neighbors_text(region: RegionData) -> String:
	var names: PackedStringArray = []
	for neighbor_id: StringName in region.neighbors:
		var neighbor: RegionData = RegionCatalog.find_by_id(neighbor_id)
		names.append(neighbor.display_name if neighbor != null else String(neighbor_id))
	return ", ".join(names) if not names.is_empty() else "None"
