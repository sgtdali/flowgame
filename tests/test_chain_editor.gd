extends SceneTree
## Ürün Akış Editörünün (app/chain_editor.gd) veri modelini, bağlantı ekleme/çıkarma,
## adet değiştirme, yeni ürün oluşturma, öncül vurgulama ve gerçek simülasyonla
## (sim/production_sim.gd) uyumluluğunu doğrular.

const ChainEditor = preload("res://app/chain_editor.gd")
const Simulation = preload("res://sim/production_sim.gd")

func _init() -> void:
	var editor := ChainEditor.new()
	root.add_child(editor)
	await process_frame

	# 1. Başlangıçta yalnızca 27 ürün kartı oluşmuş olmalı (makine/laboratuvar düğümü olmamalı)
	assert(editor.catalog.products.size() == 55, "55 ürün yüklenmeli")
	assert(editor.nodes.size() == 55, "Tuvalde yalnızca 55 ürün kartı olmalı")
	assert(editor.nodes.has("gear"), "Dişli kartı tuvalde olmalı")
	assert(editor.nodes.has("pig_iron") and editor.nodes.has("coal"), "Pik demir ve kömür kartları tuvalde olmalı")
	assert(not editor.catalog.recipes["pig_iron"].inputs.has("coal"), "Pik demir reçetesinde kömür olmamalı (sadece demir cevheri)")

	# 2. Dişli (gear_cnc) reçetesine Çelik levha bağla ve adetleri (2 levha + 1 çubuk) olarak ayarla
	editor._add_recipe_input("gear", "gear_cnc", "steel_plate")
	editor.catalog.recipes["gear_cnc"].inputs["steel_plate"] = 2
	editor.catalog.recipes["gear_cnc"].inputs["steel_rod"] = 1
	editor._rebuild_single_node("gear")

	var gear_inputs: Dictionary = editor.catalog.recipes["gear_cnc"].inputs
	assert(int(gear_inputs.get("steel_plate", 0)) == 2, "Dişli için 2 çelik levha olmalı")
	assert(int(gear_inputs.get("steel_rod", 0)) == 1, "Dişli için 1 çelik çubuk olmalı")

	# 3. Yeni bir ürün oluştur ve mevcut ürünleri ona girdi olarak bağla
	editor.new_name_edit.text = "Titanyum Dişli"
	editor.new_id_edit.text = "titanium_gear"
	editor.new_tier_spin.value = 3
	editor._confirm_create_product()

	assert(editor.catalog.products.has("titanium_gear"), "Yeni ürün katalogda olmalı")
	assert(editor.catalog.recipes.has("titanium_gear"), "Yeni ürünün reçetesi oluşmalı")
	assert(editor.nodes.has("titanium_gear"), "Yeni ürünün kartı tuvalde oluşmalı")

	editor._add_recipe_input("titanium_gear", "titanium_gear", "steel_plate")
	editor._add_recipe_input("titanium_gear", "titanium_gear", "steel_plate") # 2 adet
	editor._add_recipe_input("titanium_gear", "titanium_gear", "steel_rod")   # 1 adet
	assert(int(editor.catalog.recipes["titanium_gear"].inputs["steel_plate"]) == 2, "2 çelik levha bağlanmış olmalı")
	assert(int(editor.catalog.recipes["titanium_gear"].inputs["steel_rod"]) == 1, "1 çelik çubuk bağlanmış olmalı")

	# 4. Doğrulama kontrolü sorunsuz geçmeli
	var issues := editor._validate_chain()
	assert(issues.is_empty(), "Zincir doğrulaması hatasız geçmeli: %s" % str(issues))

	# 5. Yeni ürünün ikonu hata vermeden üretilmeli
	var icon := editor.Icons.product(editor.sim_helper, "titanium_gear")
	assert(icon != null, "Yeni ürün için otomatik renkli ikon üretilmeli")

	# 6. Ürün silindiğinde referansları temizlenmeli
	editor._delete_product("titanium_gear")
	assert(not editor.catalog.products.has("titanium_gear"), "Silinen ürün katalogdan kalkmalı")
	assert(not editor.catalog.recipes.has("titanium_gear"), "Silinen ürünün reçetesi kalkmalı")

	# 7. Öncül vurgulama: Pik demir seçildiğinde sadece Demir cevheri öncül olmalı, Kömür öncül olmamalı
	var pig_ancestors := editor._compute_ancestors("pig_iron")
	assert(pig_ancestors.has("pig_iron") and pig_ancestors.has("iron_ore"), "Pik demirin öncülü demir cevheri olmalı")
	assert(not pig_ancestors.has("coal"), "Kömür pik demirin öncülü olmamalı")

	# Dişli seçildiğinde öncülleri parlak, ilgisiz ürünler soluk olmalı
	editor.highlight_ancestors = true
	editor._select_node("gear")
	var ancestors := editor._compute_ancestors("gear")
	assert(ancestors.has("gear") and ancestors.has("steel_rod") and ancestors.has("steel_ingot") and ancestors.has("iron_ore"), "Dişlinin tüm üst öncülleri bulunmalı")
	assert(not ancestors.has("copper_ore") and not ancestors.has("quartz"), "Bakır ve kuvars dişlinin öncülü olmamalı")
	assert(is_equal_approx(editor.nodes["gear"].modulate.a, 1.0), "Seçili düğüm tam opak olmalı")
	assert(is_equal_approx(editor.nodes["iron_ore"].modulate.a, 1.0), "Öncül hammadde tam opak olmalı")
	assert(editor.nodes["copper_ore"].modulate.a < 0.3, "Öncül olmayan düğümün opaklığı düşmeli")

	# Özellik kapatıldığında tüm düğümler tekrar tam opak olmalı
	editor.highlight_ancestors = false
	editor._update_ancestor_highlight()
	assert(is_equal_approx(editor.nodes["copper_ore"].modulate.a, 1.0), "Öncül vurgulama kapatıldığında tüm düğümler tam opak olmalı")

	print("PASS: test_chain_editor (tüm kontroller başarılı)")
	quit(0)
