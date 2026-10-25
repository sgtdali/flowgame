extends RefCounted
## Product icons (32x32 pixel art, catalog order) and a slot control that shows one icon
## at 32px with an optional count in the corner, like an inventory slot.

const PRODUCTS := preload("res://app/art/ui/product_icons.png")
const SIZE := 32
const ATLAS_ORDER := [
	"iron_ore", "copper_ore", "coal", "quartz",
	"pig_iron", "steel_ingot", "copper_ingot", "steel_plate",
	"steel_rod", "insulator", "fastener", "shaft",
	"gear", "bearing", "copper_wire", "metal_scrap",
	"housing", "coil", "gearbox", "circuit_board",
	"electric_motor", "sensor", "actuator", "plc"
]

static var _cache: Dictionary = {}

static func clear_cache() -> void:
	_cache.clear()

static func atlas_icon(index: int) -> Texture2D:
	var count := int(PRODUCTS.get_width() / SIZE)
	if index < 0 or index >= count:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = PRODUCTS
	atlas.region = Rect2(index * SIZE, 0, SIZE, SIZE)
	return atlas

static func _generated_product_icon(color_hex: String) -> Texture2D:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var base := Color.from_string(color_hex, Color("7fa6c4"))
	var light := base.lightened(0.32)
	var dark := base.darkened(0.38)
	var border := Color("0d161d")
	for y in range(5, 27):
		for x in range(5, 27):
			var dx := absi(x - 15) + absi(y - 15)
			if dx <= 12:
				if dx >= 11 or x == 5 or x == 26 or y == 5 or y == 26:
					img.set_pixel(x, y, border)
				elif x + y < 28:
					img.set_pixel(x, y, light)
				elif x + y > 33:
					img.set_pixel(x, y, dark)
				else:
					img.set_pixel(x, y, base)
	return ImageTexture.create_from_image(img)

static func product(sim: RefCounted, product_id: String) -> Texture2D:
	if _cache.has(product_id):
		return _cache[product_id]
	if not sim.catalog.products.has(product_id):
		return null
	var spec: Dictionary = sim.catalog.products[product_id]
	# A machine item (made by the machine factory) shows the machine's own picture.
	if spec.has("machine"):
		var art := machine(load("res://app/sprite_machine_card.gd").art_path(str(spec.machine)))
		_cache[product_id] = art
		return art
	var index: int = int(spec.get("icon_index", ATLAS_ORDER.find(product_id)))
	var tex := atlas_icon(index)
	if tex == null:
		tex = _generated_product_icon(str(spec.get("color", "7fa6c4")))
	_cache[product_id] = tex
	return tex

## The product icon shrunk to `size` px (averaged, not point-sampled), for products on a link.
static func small_product(sim: RefCounted, product_id: String, size: int = 8) -> Texture2D:
	var key := "%s@%d" % [product_id, size]
	if _cache.has(key):
		return _cache[key]
	var tex := product(sim, product_id)
	if tex == null:
		return null
	var img := tex.get_image()
	img.convert(Image.FORMAT_RGBA8)
	# Crop the padding first so the drawing itself fills the small square.
	var used := img.get_used_rect()
	if used.has_area():
		var side := maxi(used.size.x, used.size.y)
		var square := Rect2i(used.get_center() - Vector2i(side, side) / 2, Vector2i(side, side))
		var cropped := Image.create(side, side, false, Image.FORMAT_RGBA8)
		cropped.blit_rect(img, square, Vector2i.ZERO)
		img = cropped
	img.resize(size, size, Image.INTERPOLATE_TRILINEAR)
	var small := ImageTexture.create_from_image(img)
	_cache[key] = small
	return small

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
			draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color("f6f2ea"))
			draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("b5452f") if short else Color("3d3a33"))
