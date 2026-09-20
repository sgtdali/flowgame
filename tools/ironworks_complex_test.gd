extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	print("--- IRONWORKS COMPLEX MVP TEST ---")
	var progression := ProgressionState.new()
	_check("Industrial Organization, Rolling sonrası ek para istemeden alınabiliyor", _unlock_complex_research(progression))
	var sim := FactorySim.new()
	var extractor: int = sim.add_station(BlockCatalog.MINE_EXTRACTOR)
	var hearth: int = sim.add_station(BlockCatalog.ERITME)
	var mill: int = sim.add_station(BlockCatalog.PRES)
	var generator: int = sim.add_station(BlockCatalog.JENERATOR)

	# Bağlı mevcut hat, komplekse taşınmadan önce doğrulanır.
	sim.connect_stations(extractor, 0, hearth, 0)
	sim.connect_stations(hearth, 0, mill, 0)
	var complex_id: int = sim.create_complex([extractor, hearth, mill])
	_check("Bağlı üç makine kompleks oluşturabiliyor", complex_id > 0)
	_check("Kompleks üretim kapasitesi yaratmıyor", sim.station_count() == 4)
	_check("Doğrudan bağlı giriş Shared Bus'a çift bağlanamıyor", not sim.set_complex_material_mode(complex_id, hearth, 0, true, true).is_empty())

	# Oyuncu açıkça Shared Bus'a geçtiğinde direct linkler kaldırılır. Aynı
	# portun iki kaynaktan beslenmesi böylece hem API hem testte engellenir.
	sim.disconnect_stations(extractor, 0, hearth, 0)
	sim.disconnect_stations(hearth, 0, mill, 0)
	_check("Extractor çıkışı ortak havuza bağlanıyor", sim.set_complex_material_mode(complex_id, extractor, 0, false, true).is_empty())
	_check("Hearth girişi ortak havuza bağlanıyor", sim.set_complex_material_mode(complex_id, hearth, 0, true, true).is_empty())
	_check("Hearth çıkışı ortak havuza bağlanıyor", sim.set_complex_material_mode(complex_id, hearth, 0, false, true).is_empty())
	_check("Mill girişi ortak havuza bağlanıyor", sim.set_complex_material_mode(complex_id, mill, 0, true, true).is_empty())
	_check("Mill çıkışı ortak havuza bağlanıyor", sim.set_complex_material_mode(complex_id, mill, 0, false, true).is_empty())
	_check("Harici jeneratör Power Bus'a bağlanıyor", sim.connect_power_to_complex(generator, complex_id).is_empty())
	_check("Hadde Power Bus üyesi oluyor", sim.set_complex_power_bus_member(complex_id, mill, true).is_empty())

	var extractor_station: SimStation = sim.get_station(extractor)
	extractor_station.add_item(extractor_station.input, &"ham_cevher", 10000)
	var max_delivered: int = 0
	for tick in 180:
		sim.tick()
		max_delivered = maxi(max_delivered, sim.delivered_power(mill))
	var complex: IronworksComplex = sim.get_complex(complex_id)
	_check("Ortak havuz gerçek üretimle külçe/levha akıtıyor", int(complex.material_bus.get(&"levha", 0)) > 0)
	_check("Power Bus jeneratör kapasitesini aşmıyor", sim.power_used(generator) <= sim.power_capacity(generator))
	_check("Power Bus haddeye gerçek güç veriyor", max_delivered > 0)

	# Ingot Focus, doğrudan hatlara değil yalnızca shared-bus hadde tüketimine
	# etki eder; havuzdaki külçe sonraki ticklerde korunur.
	complex.material_bus[&"kulce"] = 5
	sim.set_complex_strategy(complex_id, IronworksComplex.Strategy.INGOT_FOCUS)
	var ingots_before: int = int(complex.material_bus.get(&"kulce", 0))
	sim.tick()
	_check("Ingot Focus ortak külçeyi haddeye harcamıyor", int(complex.material_bus.get(&"kulce", 0)) == ingots_before)

	var snapshot: Dictionary = sim.to_dict()
	var loaded := FactorySim.new()
	loaded.from_dict(JSON.parse_string(JSON.stringify(snapshot)) as Dictionary)
	_check("Save/load kompleks üyeliğini koruyor", loaded.get_complex(complex_id) != null and loaded.get_complex(complex_id).station_ids.size() == 3)
	_check("Save/load ortak stokları koruyor", int(loaded.get_complex(complex_id).material_bus.get(&"kulce", 0)) == ingots_before)
	for tick in 80:
		sim.tick()
		loaded.tick()
	_check("Save/load sonrası kompleks koşumu deterministik", sim.state_hash() == loaded.state_hash())

	print("SONUC: %d hata" % _failures)
	quit(1 if _failures > 0 else 0)


func _check(label: String, passed: bool) -> void:
	print("  %s  %s" % ["GECTI" if passed else "KALDI", label])
	if not passed:
		_failures += 1


func _unlock_complex_research(progression: ProgressionState) -> bool:
	var funds: int = 20000
	if not progression.try_unlock(ResearchCatalog.ELEKTRIFIKASYON, funds, {}).is_empty():
		return false
	if not progression.try_unlock(ResearchCatalog.PRESLEME, funds, {}).is_empty():
		return false
	return progression.try_unlock(ResearchCatalog.INDUSTRIAL_ORGANIZATION, funds, {}).is_empty() and progression.complexes_available()
