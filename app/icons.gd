extends RefCounted
## Product icons (32x32 pixel art, catalog order) and a slot control that shows one icon
## at 32px with an optional count in the corner, like an inventory slot.

const PRODUCTS := preload("res://app/art/ui/product_icons.png")
const SIZE := 32

static var _cache: Dictionary = {}

static func product(sim: RefCounted, product_id: String) -> Texture2D:
	if _cache.has(product_id):
		return _cache[product_id]
	var index: int = sim.catalog.products.keys().find(product_id)
	if index < 0:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = PRODUCTS
	atlas.region = Rect2(index * SIZE, 0, SIZE, SIZE)
	_cache[product_id] = atlas
	return atlas

## First frame of a machine's 128x128 artwork, for inventory and craft slots.
static func machine(art_path: String) -> Texture2D:
	if _cache.has(art_path):
		return _cache[art_path]
	var atlas := AtlasTexture.new()
	atlas.atlas = load(art_path)
	atlas.region = Rect2(0, 0, 128, 128)
	_cache[art_path] = atlas
	return atlas

## Icon at 2x (32px) with a count drawn bottom-right when it is above one.
class Slot extends Control:
	var texture: Texture2D
	var count := 1
	## Inventory slots show the count even when it is one.
	var show_one := false
	## Drawn in red: a craft input the player does not have enough of.
	var short := false

	func _init(icon: Texture2D = null, amount: int = 1) -> void:
		texture = icon
		count = amount
		custom_minimum_size = Vector2(36, 36)
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if texture != null:
			draw_texture_rect(texture, Rect2((size - Vector2(32, 32)) * 0.5, Vector2(32, 32)), false)
		if count > 1 or (show_one and count == 1):
			var font := ThemeDB.fallback_font
			var text := str(count)
			var at := Vector2(size.x - 2 - font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x, size.y - 2)
			draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color("09131c"))
			draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("e0634b") if short else Color("dce9ef"))
