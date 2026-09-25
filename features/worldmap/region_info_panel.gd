class_name RegionInfoPanel
extends PanelContainer

## Sağdaki bölge bilgi paneli. Seçili bölgenin verisini gösterir.
##
## Kural hesaplamaz: bölgenin durumu WorldMap'ten (RegionState) gelir.
## Kilitli bölgenin içeriği de gösterilir (tasarım: açmadan önce görülebilir).
## Açma butonu yalnızca istek gönderir; açmayı WorldMap → RegionState yapar.

signal unlock_requested(region_id: StringName)

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
@onready var resources_value: Label = %ResourcesValue
@onready var city_value: Label = %CityValue
@onready var neighbors_value: Label = %NeighborsValue
@onready var cost_caption: Label = %CostCaption
@onready var cost_value: Label = %CostValue
@onready var unlock_button: Button = %UnlockButton
@onready var reason_label: Label = %ReasonLabel

var _region_id: StringName = &""


func _ready() -> void:
	hide()
	unlock_button.pressed.connect(func() -> void: unlock_requested.emit(_region_id))


## `cost`: bir sonraki açmanın maliyeti. `block_reason`: açılamıyorsa nedeni, yoksa "".
func show_region(region: RegionData, status: RegionState.Status, cost: int,
		block_reason: String) -> void:
	_region_id = region.id
	title_label.text = region.display_name
	status_label.text = STATUS_TEXT[status]
	status_label.add_theme_color_override("font_color", STATUS_COLOR[status])
	resources_value.text = _resources_text(region)
	city_value.text = ", ".join(region.city_names) if region.has_city() else "None"
	neighbors_value.text = _neighbors_text(region)
	var locked: bool = status != RegionState.Status.UNLOCKED
	cost_caption.visible = locked
	cost_value.visible = locked
	unlock_button.visible = locked
	reason_label.visible = locked and not block_reason.is_empty()
	cost_value.text = format_money(cost)
	unlock_button.disabled = not block_reason.is_empty()
	reason_label.text = block_reason
	show()
	# İçerik kısaldığında panel eski boyunda kalmasın.
	reset_size()


func _resources_text(region: RegionData) -> String:
	var lines: PackedStringArray = []
	for resource: RawResource in region.resources:
		lines.append("%s (%s)  %d/min" % [resource.display_name,
				RawResource.site_name(resource.site_kind), resource.extraction_per_minute])
	return "\n".join(lines) if not lines.is_empty() else "None"


func _neighbors_text(region: RegionData) -> String:
	var names: PackedStringArray = []
	for neighbor_id: StringName in region.neighbors:
		var neighbor: RegionData = RegionCatalog.find_by_id(neighbor_id)
		names.append(neighbor.display_name if neighbor != null else String(neighbor_id))
	return ", ".join(names) if not names.is_empty() else "None"


## 1250 -> "1,250"
static func format_money(amount: int) -> String:
	var digits: String = str(absi(amount))
	var out: String = ""
	while digits.length() > 3:
		out = "," + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if amount < 0 else "") + digits + out
