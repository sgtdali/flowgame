# Görev 04 — Akış simülasyonu, sabit fabrika, köy talebi (ilk para döngüsü)

Mod: **yazılım modu**. Kaynak: tasarım belgesi → "Lojistik ve akış modeli" (oyun saati,
stok ve kabul), "Geçici sabit fabrika", "Ekonomi" (doygunluk, ham mal satılmaz, borç),
"Geliştirme sırası 4". Bu dosya gereken kısıtları içerir.

## Kapsam

Var: oyun saati ve hız düğmesi, yatakların üretimi, noktalarda stok, hatlarda mal
akışı ve yük seçimi, arsaya tek tarifli fabrika kurma, köyün Kereste ve Un satın
alması (doygunluk fiyatıyla), bakımın paradan düşülmesi.
Yok: düğüm editörü, şehir büyümesi, kasaba talebi, araştırma, kaydetme.

Hedef: oyuncu Area1'de **orman → bıçkıhane → City A** zincirini kurup para kazanabilir.

## Tasarım kısıtları

- **Oyun saati:** 1 oyun dakikası = 1 gerçek dakika. Üst çubukta Pause / x1 / x2 / x4.
  Haritadaki araçlar da bu saatle hareket eder.
- **Yatak:** ham madde alanı hammaddesini sabit hızda (20/dk) kendi stoğuna koyar;
  stok dolunca üretim durur.
- **Stok:** her noktada mal başına 50 birim (yer tutucu). Şehrin stok sınırı yoktur.
- **Kabul:** hat bir malı yalnızca varış noktası kabul ediyorsa taşır. Fabrika kendi
  tarifinin girdilerini, şehir talep ettiği malları kabul eder; ham madde alanı ve boş
  arsa hiçbir şey kabul etmez. Kaynak tarafı: ham madde alanı hammaddesini, fabrika
  çıktısını verir; şehir hiçbir şey vermez.
- **Yük seçimi:** hattın her yönü için, taşınabilecek mallar arasından oran seçilir.
  Hat kurulunca (ya da uca fabrika kurulunca) taşınabilecek mallar eşit payla gelir.
  Bir malın arzı ya da varıştaki boş yeri payını dolduramazsa kalan pay diğerlerine geçer.
- **Hat kapasitesi:** Görev 03'teki formül; bir yöndeki toplam akış kapasiteyi aşamaz.
  İki yönün her biri kendi kapasitesini kullanır (araç gidişte ve dönüşte yük alır).
- **Geçici sabit fabrika:** boş arsaya kurulur (300), kurarken tarif seçilir, sonra değişmez.
  Tarifler: **Sawmill** (1 Logs → 1 Lumber, 10/dk), **Mill** (2 Wheat → 1 Flour, 10/dk).
  Fabrika bakımı 3/dk. Yalnızca açık bölgedeki arsaya kurulur.
- **Köy talebi:** Lumber 10/dk, Flour 10/dk; fiyat Lumber 1, Flour 1.
  **Doygunluk:** her oyun dakikası içinde talebin %100'üne kadar tam fiyat, %100–150 arası
  yarı fiyat, %150 üstü %10.
- **Ham mal satılmaz:** şehir Logs/Wheat/Iron Ore kabul etmez.
- **Bakım:** araç ve fabrika bakımı sürekli (dakika başı, oransal) paradan düşülür.
- **Borç:** para eksiye düşebilir; eksideyken alım yapılamaz, hiçbir şey durmaz.
- Arayüz metinleri İngilizce: Lumber, Flour, Sawmill, Mill, Village.

## Uygulama kararları (kullanıcı onaylı)

- **K1:** Mal hatta beklemez (yolda stok yok): bir yöndeki akış anında varışa geçer.
  Mesafenin etkisi zaten kapasitede. İlk teslimat gecikmesi yok (tasarımda da kaldırıldı).
- **K2:** Fabrika bu görevde yıkılamaz (geçici sabit fabrika; editör gelince yerini alır).
- **K3:** Aynı kaynaktan birden çok hat çekiyorsa, stok hatlar arasında kurulma sırasına göre
  paylaşılır (önce kurulan önce alır). Adil paylaşım gerekirse sonra.
- **K4:** Doygunluk "oyun dakikası" pencereleriyle hesaplanır: her tam dakikada şehrin o
  dakikalık alımı sıfırlanır.
- **K5:** Para tam sayı kalır; kesirli gelir ve bakım ayrı bir birikimde toplanır, tam
  birim olunca paraya yansır.

## Teknik yaklaşım

1. **Veri** (`data/`):
   - `good.gd` → `Good` (id, ad, şehir fiyatı; 0 = satılmaz). `RawResource` bundan türer.
     `.tres`: `data/goods/kereste.tres` (Lumber), `un.tres` (Flour).
   - `process_recipe.gd` → `ProcessRecipe` (id, ad, girdiler ve miktarları, çıktı ve
     miktarı, dakikada çıktı). `.tres`: `data/recipes_map/bickihane.tres`, `degirmen.tres`.
   - `city_level.gd` → `CityLevel` (id, ad, talep edilen mallar ve dakikalık miktarları,
     doygunluk eşikleri ve çarpanları). `.tres`: `data/city_levels/koy.tres`.
   - `MapConfig`'e: fabrika fiyatı 300, fabrika bakımı 3, nokta stoğu 50.
2. **Nokta kaydı:** `sim/map_points.gd` — noktaların kimliğini ve türünü **bölge
   verisinden** üretir (`area1/Site1` → Logs yatağı, `area1/Plot1` → arsa, `area1/City`
   → şehir). Sahneyle aynı adlandırma kuralı; `point_test.gd` ikisinin eşleştiğini kontrol eder.
3. **Simülasyon** (arayüzsüz, `sim/`): `map_flow_sim.gd` (saat adımı: üretim → hatlar
   → fabrikalar → satış → bakım), `factory_sites.gd` (arsalardaki fabrikalar),
   `city_market.gd` (talep, doygunluk, satış geliri). Hat yük oranları `MapRoute`'a eklenir.
   Hiçbir dosya 300 satırı geçmez.
4. **Arayüz:** üst çubukta saat hızı düğmeleri ve dakikalık net gelir; arsa panelinde
   "Build factory" (iki tarif butonu); nokta panelinde stok, üretim, fabrika durumu, şehir
   talebi ve bu dakikaki satış; hat panelinde her yön için yük oranları.

## Adımlar (her biri ayrı teslim)

1. Veri sınıfları ve `.tres`'ler, nokta kaydı; `point_test.gd`'ye "kayıt sahneyle aynı" kontrolü.
2. Akış simülasyonu. Test `tools/flow_test.gd`: yatak 20/dk üretir ve 50'de durur; hat
   kapasitesini aşmaz; kabul edilmeyen mal taşınmaz (orman → şehir hattı boş kalır);
   yük oranı ve artan payın aktarımı; bıçkıhane 10/dk üretir, girdi yoksa durur; köy
   satışı ve doygunluk kademeleri; bakım düşer; para eksiye iner ve alımı engeller;
   aynı kurulum aynı sonucu verir (belirlilik).
3. Saat ve hız düğmeleri, fabrika kurma, panellerde stok/üretim/talep, gelir göstergesi,
   araçların oyun saatine bağlanması.
4. ~~Hat panelinde yük seçimi (her yön için mal oranları).~~ **Ertelendi** (kullanıcı onaylı):
   şu an hiçbir hattın bir yönünde birden fazla mal olmuyor (yatak ve sabit fabrika tek
   mal verir). Oran mantığı simülasyonda hazır ve testli; arayüzü düğüm editörüyle gelir.
   Hat paneli bu görevde yalnızca her yönde ne taşındığını ve hızını gösterir.

## Kabul ölçütü

- Area1'de ormandan bir arsaya hat, arsaya Sawmill, Sawmill'den City A'ya hat kurulunca
  para birkaç dakika içinde artmaya başlıyor; üst çubukta net gelir artı görünüyor.
- Ormandan doğrudan City A'ya kurulan hat hiçbir şey taşımıyor ve panel bunun nedenini söylüyor.
- Köye talebinden fazla Lumber gidince fiyat düşüyor (panelde görülür).
- Hız düğmeleriyle oyun duraklatılıp hızlandırılabiliyor.
- `flow_test.gd` ve tüm mevcut testler geçer (sim_test'teki 2 eski "Tikanma" hatası
  bu görevden önce de vardı).
