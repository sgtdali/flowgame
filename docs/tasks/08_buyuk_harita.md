# Görev 08 — Büyük harita ve serbest fabrika yeri

Mod: **yazılım modu**. Kaynak: tasarım belgesi → "Harita katmanı" (ölçek, bölge içeriği,
fabrika yeri, harita noktaları, bölge açma), "Harita arayüzü: araç çubuğu" (Factory satırı),
"Hat kurma" (altyapı yok), "Prototip kapsamı" (bölge satırı), "Geliştirme sırası 6".
Bu dosya gereken kısıtları içerir.

## Kapsam

Var: sabit arsaların kalkması, fabrikanın açık bölgede tıklanan yere kurulması, bölge
başına birden çok şehir, 12×12 km'lik kare harita ve 4 geniş bölge, mesafenin km gösterimi.
Yok: yol/ray altyapısı, şehir büyümesi, araştırma, kaydetme.

## Tasarım kısıtları

- **Ölçek:** harita 12×12 km; 1 harita birimi = 10 m (harita 1.200 × 1.200 birim). Mesafe
  oyuncuya km olarak gösterilir; hızlar oyun değeridir, oyuncu kapasiteyi (birim/dk) görür.
- **Bölgeler:** birkaç geniş bölge; her bölgede birden çok şehir ve kaynak yatağı, yerleri sabit.
  Oyun 1 açık bölgeyle başlar, komşu bölge parayla açılır.
- **Fabrika yeri:** açık bir bölgenin içinde oyuncunun seçtiği herhangi bir yere kurulur;
  sabit arsa yok. Yeri dengeleyen yalnızca mesafe. Kilitli bölgeye kurulamaz.
- **Araç çubuğu, Factory:** kurulabilecek alan (açık bölgeler) vurgulanır, fiyat imlecin
  yanında; tıklanan yere fabrika kurulur.
- **Prototip içeriği:** 4 geniş bölge (her biri yaklaşık 6×6 km); bölge başına 2–3 şehir
  (toplam yaklaşık 10) ve 4–6 kaynak yatağı; başlangıç bölgesinde 2 köy, yakında orman ve
  tarla, biraz uzakta demir.
- Altyapı yok: hat iki nokta arasında soyut düz çizgi.

## Uygulama kararları (onay bekliyor)

- **K1 — Noktaları kim yerleştirir:** bölge verisi hangi şehirlerin ve kaynakların olduğunu
  söyler; üretim scripti (`tools/generate_points.gd`) eksik noktaları bir kez haritaya koyar,
  siz Godot'da sürükleyerek yerlerini ayarlarsınız (bugünkü sistem, arsasız). Kural tarafı
  noktaları sahneden değil veriden bilir; `point_test` ikisinin eşleştiğini kontrol eder.
- **K2 — Fabrika üst üste:** fabrika başka bir noktanın üstüne kurulamaz (orada tıklamak o
  noktayı seçer). Başka bir en az mesafe kuralı yok.
- **K3 — Fabrika adı:** "Factory 1", "Factory 2"… (kurulma sırası).
- **K4 — km gösterimi:** hat panelinde mesafe, hat kurarken ipucunda ve özet kutusunda
  "1.2 km". Birim → metre çevrimi veride (`MapConfig`), koda gömülmez.
- **K5 — Ekran ölçeği:** yeni harita 1.200 × 1.200 birim çizilir; ekranda şimdiki gibi 2 kat
  büyütülür (noktalar sabit boyda). Mesafe harita biriminde kalır (9f4ebf3'teki düzeltme).
- **K6 — Yeni bölgelerin içeriği (öneri, çizimden sonra ayarlanabilir):**

  | Bölge | Şehir | Kaynak yatakları | Komşu |
  | --- | --- | --- | --- |
  | Area 1 (başlangıç) | 2 köy | Orman 2, Tarla 2, Demir 1 (uzak köşede) | 2, 3 |
  | Area 2 | 3 | Orman 1, Tarla 2, Demir 2 | 1, 4 |
  | Area 3 | 2 | Orman 3, Demir 1 | 1, 4 |
  | Area 4 | 3 | Tarla 2, Demir 2, Orman 1 | 2, 3 |

  Bölgeler 2×2 dizilir; komşuluk çizimden okunur. Şehir adları yer tutucu ("Ashford",
  "Brook"...); isterseniz siz verirsiniz. Tüm şehirler Köy seviyesinde başlar.
- **K7 — Eski harita:** 5 bölgelik çizim ve verisi silinir (git geçmişinde kalır).

## Teknik yaklaşım

- **Veri:** `RegionData`'da `factory_slots` ve tek `city_name` kalkar, yerine şehir adları
  listesi gelir. `MapConfig`'e birim başına metre. Nokta kimlikleri: `area1/Site1`,
  `area1/City1`, `area1/City2`; fabrikalar `area1/Factory1` (oyunda oluşur).
- **Kural (`sim/`):** `FactorySites.build(region_id)` yeni fabrikanın kimliğini döndürür; nokta
  türünü fabrikalar için `FactorySites`, diğerleri için `MapPoints` söyler. Arsa kavramı ve
  `FACTORY_PLOT` kalkar.
- **Arayüz:** Factory aleti tıklanan yere bir fabrika noktası (`MapPoint`) koyar; açık bölgeler
  vurgulanır, imleçte fiyat. Mesafe km olarak gösterilir.
- Testler yeni kurala ve yeni içeriğe göre güncellenir; hiçbir dosya 300 satırı geçmez.

## Adımlar (her biri ayrı teslim)

1. **Serbest fabrika (kural):** arsaların kalkması, `FactorySites.build(region_id)`, nokta türü,
   bölge başına şehir listesi; mevcut 5 bölgelik harita üzerinde (arsa noktaları sahneden
   silinir). Testler güncellenir. Bu adımda Factory aleti geçici olarak bölgeye tıklayınca
   bölgenin ortasına kurar.
2. **Serbest fabrika (arayüz) ve km:** Factory aleti tıklanan yere kurar, açık bölge vurgusu,
   imleçte fiyat, üst üste kurma engeli; mesafe km.
3. **Yeni harita:** siz 12×12 km'lik kare haritayı ve 4 bölgeyi çizersiniz (adım adım tarif
   ederim); ben bölge verisini (K6) yazar, noktaları üretirim; siz noktaları sürükleyip
   yerleştirirsiniz. Eski harita silinir, testler yeni içeriğe göre güncellenir.

## Kabul ölçütü

- Açık bir bölgede boş bir yere Factory aletiyle tıklayınca o noktaya fabrika kuruluyor;
  kilitli bölgeye tıklayınca "… is locked" yazıyor.
- Başlangıç bölgesinde 2 köy var; ikisi de ayrı ayrı mal alıyor ve ayrı doygunlukla satıyor.
- Hat panelinde ve hat kurarken mesafe km olarak görünüyor (ör. 120 birim → "1.2 km").
- Harita kare, 4 bölgeli; kamera başlangıç bölgesine odaklı açılıyor.
- Tüm testler geçer (sim_test'teki 2 eski "Tikanma" hatası önceden de vardı).
