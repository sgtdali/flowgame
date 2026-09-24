extends SceneTree

## Harita noktalarını bölge verisinden üretir ve çizim sahnesine yazar.
##
## Çalıştırma:
##   godot --headless --path . --script res://tools/generate_points.gd
##
## Tekrar çalıştırmak güvenlidir: var olan noktaların konumuna dokunmaz
## (elle kaydırılmış olabilir), yalnızca eksikleri ekler, fazlaları siler.
## Bölge verisini (kaynak, fabrika alanı, şehir) değiştirdikten sonra çalıştır.
## Çalıştırmadan önce sahneyi Godot'da kaydet; açıkken çalıştırırsan Godot
## "dosya değişti" diye sorar, "yeniden yükle" de.

const PointPlacer := preload("res://tools/point_placer.gd")
const REGION_MAP_SCENE: String = "res://features/worldmap/RegionMap.tscn"


func _initialize() -> void:
	var packed: PackedScene = load(REGION_MAP_SCENE)
	var root: Node = packed.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	var report: Dictionary = PointPlacer.sync(root)
	for warning: String in report["warnings"]:
		print("  UYARI  %s" % warning)
	print("Nokta: %d eklendi, %d silindi, %d yerinde kaldi" % [
			report["added"], report["removed"], report["kept"]])

	# Sahnenin uid'si kaydedince düşmesin (başka sahneler uid ile başvurabilir).
	var uid: int = ResourceLoader.get_resource_uid(REGION_MAP_SCENE)
	var out: PackedScene = PackedScene.new()
	var err: Error = out.pack(root)
	if err == OK:
		err = ResourceSaver.save(out, REGION_MAP_SCENE)
	if err == OK and uid != ResourceUID.INVALID_ID:
		err = ResourceSaver.set_uid(REGION_MAP_SCENE, uid)
	root.free()
	print("Kayit: %s" % ("tamam" if err == OK else "HATA %d" % err))
	quit(0 if err == OK else 1)
