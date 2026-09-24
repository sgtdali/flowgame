# Görev 01 — 5 bölgelik harita, tıklama, bilgi paneli, bölge açma

Mod: **yazılım modu**. Kaynak: `game_design/TASARIM_DOKUMANI.md` → "Harita katmanı",
"Para değerleri", "Prototip kapsamı / Geliştirme sırası 2". Bu dosya gereken
kısıtları içerir.

## Kapsam

Var: haritanın çizimi, bölgeye tıklama ve fareyle üzerine gelme, bilgi paneli, para ile bölge açma.
Yok: fabrika, hat, akış, şehir talebi, araştırma. Mevcut Iron & Ember kodu
(`features/game`, `sim/factory_sim.gd` vb.) **değişmez**; ana sahne değişmez.

## Kararlar (kullanıcı onaylı)

- Harita elle çizilmiştir: `features/worldmap/RegionMap.tscn`, kökün altında
  her bölge bir düğüm (`Area1`…`Area5`), içinde bir veya daha fazla `Polygon2D`.
  Kullanıcı çizimi değiştirebilir; kod poligonları bu sahneden okur, kopyalamaz.
- Başlangıçta 1 bölge açık.
- Komşuluk şartı var: yalnızca açık bir bölgeye komşu olan kilitli bölge açılabilir.
- Açılan bölge bir daha kilitlenmez.
- Bölge açma maliyeti bölgeye değil sıraya bağlıdır: ilk satın alınan 500,
  sonraki her biri +250 (500, 750, 1.000, 1.250). Başlangıç parası 1.000.
- Kilitli bölgenin içeriği açılmadan önce görülebilir.

## Bölge değerleri (YER TUTUCU — tasarımda değişecek)

Belgedeki aralıklara uyar: kaynak 1–3, fabrika alanı 2–4, 5 bölgenin 2'sinde şehir,
prototip hammaddeleri Kereste / Tahıl / Demir cevheri.

| Düğüm | id | Arazi | Kaynaklar | Fabrika alanı | Şehir | Başlangıçta açık |
|---|---|---|---|---|---|---|
| Area1 | area1 | Düz | Kereste, Tahıl | 3 | Var | Evet |
| Area2 | area2 | Tepelik | Demir cevheri | 2 | Yok | Hayır |
| Area3 | area3 | Düz | Kereste | 3 | Yok | Hayır |
| Area4 | area4 | Düz | Tahıl, Kereste | 4 | Var | Hayır |
| Area5 | area5 | Dağlık | Demir cevheri | 2 | Yok | Hayır |

Komşuluklar çizimden: 1–2, 1–3, 2–3, 2–4, 2–5, 3–5, 4–5.
Hammadde çıkarım hızı (belgeden): Kereste 20, Tahıl 20, Demir cevheri 20 birim/dk.

## Teknik yaklaşım

1. **Veri** (`data/`):
   - `raw_resource.gd` → `RawResource`: id, ad, çıkarım hızı (birim/dk). `.tres`: `data/raw_resources/`.
   - `region_data.gd` → `RegionData`: id, ad, arazi, kaynaklar (`Array[RawResource]`),
     fabrika alanı, şehir adı (boş = şehir yok), komşular (`Array[StringName]`), başlangıçta açık.
     `.tres`: `data/regions/`.
   - `map_config.gd` → `MapConfig`: başlangıç parası, ilk açma maliyeti, artış. `.tres`: `data/map_config.tres`.
   - Poligon `RegionData` içinde tutulmaz; çizim sahnesi tek kaynaktır.
2. **Çizimi veriye bağlama:** Çizimdeki her bölge düğümü `Area2D` olur ve
   `features/worldmap/region_view.gd` script'i alır (`@export var data: RegionData`).
   Kullanıcının `Polygon2D`'leri olduğu gibi kalır; `CollisionPolygon2D` ve sınır
   `Line2D`'si çalışırken bu poligonlardan üretilir (belge: Area2D + Polygon2D +
   CollisionPolygon2D + Line2D).
3. **Kurallar** (`sim/region_state.gd`, arayüzsüz): para, açık bölgeler,
   `unlock_cost()`, `can_unlock(id)` (olmuyorsa nedeni), `unlock(id)`.
4. **Sahne:** `features/worldmap/WorldMap.tscn` → çizim sahnesi + kamera (sağ/orta
   tık kaydırma, tekerlek yakınlaştırma) + arayüz. Test için bu sahne F6 ile açılır.
5. **Görünüm:** açık bölge canlı renk, kilitli soluk, açılabilir kilitli ama
   belirgin kenarlık; üzerine gelince hafif vurgu, seçilince kalın kenarlık.
6. **Bilgi paneli** (sağda): ad, durum (açık / kilitli / açılabilir), arazi, kaynaklar ve
   hızları, şehir, fabrika alanı, komşular, açma maliyeti, açma butonu (koşul
   yoksa pasif ve nedeni yazılı). Üst çubukta para.

## Adımlar (her biri ayrı teslim)

1. Veri sınıfları, 5 bölge + 3 hammadde + harita ayarı `.tres`, çizim düğümlerinin
   `Area2D` + `region_view.gd`'ye çevrilmesi. Test `tools/region_test.gd`:
   her bölgenin verisi ve poligonu var, poligonlar üst üste binmiyor, komşuluklar
   karşılıklı ve çizimde gerçekten değiyor, tam 1 başlangıç bölgesi, değerler
   belgedeki aralıklarda.
2. `WorldMap.tscn`: bölgeler durum renkleriyle görünür, fareyle üzerine gelme, seçme, kamera.
3. Bilgi paneli.
4. `RegionState` + açma butonu + para göstergesi; teste ekle: komşusu kapalı bölge
   açılamaz, para yetmezse açılamaz, para düşer, maliyet sırayla artar, açılan kalıcı.

## Kabul ölçütü

- Sahne açılınca Area1 açık; Area2 ve Area3 açılabilir, Area4 ve Area5 kilitli görünür.
- Herhangi bir bölgeye tıklayınca panel doğru bilgiyi gösterir.
- Area2 açılınca para 1.000 → 500 olur, Area4 ve Area5 açılabilir hale gelir;
  sonraki açmanın maliyeti 750 görünür ve para yetmediği için buton pasif olur.
- `region_test.gd` ve mevcut testler geçer (sim_test'teki 2 eski "Tikanma" hatası
  bu görevden önce de vardı).
