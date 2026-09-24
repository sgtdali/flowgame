# Görev 02 — Harita noktaları

Mod: **yazılım modu**. Kaynak: tasarım belgesi → "Harita noktaları", "Ham mal
satılmaz", "Geliştirme sırası 2". Bu dosya gereken kısıtları içerir.

## Kapsam

Var: tasarımla çelişen eski alanların düzeltilmesi, noktaların üretilip haritada
gösterilmesi, noktaya tıklayınca bilgisi.
Yok: hat, araç, fabrika kurma, akış, şehir talebi. Mevcut Iron & Ember kodu değişmez.

## Tasarım kısıtları

- Haritada üç tür nokta var: **ham madde alanı** (maden, orman, tarla), **fabrika
  arsası** ve **şehir**. Noktalar bölgelerin içindedir.
- Noktalar bölge verisinden üretilir: bölgenin her kaynağı için bir ham madde alanı,
  her fabrika alanı için bir arsa, şehri varsa bir şehir.
- Yerleşim **bir kez üretilir ve sabittir**; her oyunda aynıdır. Kullanıcı bir noktayı
  Godot'da elle kaydırabilir; üretim scripti tekrar çalışınca **elle kaydırılmış
  noktaya dokunmaz**, yalnızca eksik noktaları ekler, fazlaları siler.
- Kilitli bölgenin noktaları görünür (içerik açılmadan önce görülebilir), soluk çizilir.
- Arazi kavramı yok. Ham mal şehre satılmaz (bu görevde satış yok, yalnızca adlar).
- Arayüz metinleri İngilizce.

## Uygulama ile tasarım çelişkilerinin düzeltilmesi

- `RegionData.terrain` ve paneldeki "Terrain" satırı kaldırılır.
- Hammaddeler tasarımdaki adlarına döner:
  - `kereste` (Timber) → `tomruk` (**Logs**), orman
  - `tahil` (Grain) → `bugday` (**Wheat**), tarla
  - `demir_cevheri` (Iron Ore) aynı kalır, maden
- `RawResource`'a ham madde alanının türü eklenir (orman / tarla / maden) — alanın
  adı ve simgesi bundan gelir (ör. "Forest", "Farm", "Mine").

## Teknik yaklaşım

1. **Veri:** `features/worldmap/map_point.gd` → `class_name MapPoint extends Node2D`
   - `kind` (RESOURCE_SITE / FACTORY_PLOT / CITY), `resource: RawResource` (yalnızca
     ham madde alanında), `slot_index: int` (aynı bölgedeki aynı türden noktaları ayırır).
   - Noktalar çizim sahnesinde bölge düğümünün altında durur:
     `RegionMap.tscn → Area1/Points/<nokta>`. Konum sahnede saklanır (elle düzeltilebilir).
2. **Üretim:** `tools/generate_points.gd` (headless, tekrar çalıştırılabilir)
   - Bölge poligonunun içinde, kenardan ≥ 40 px ve diğer noktalardan ≥ 80 px uzakta
     aday noktalar; şehir bölgenin ortasına en yakın uygun yere, diğerleri şehirden
     uzaklaşacak şekilde (en uzak nokta seçimi). Rastgelelik yok → hep aynı sonuç.
   - Var olan noktaların konumuna dokunmaz.
3. **Görünüm:** tür başına ayrı simge (şehir: büyük daire, arsa: boş kare, ham madde
   alanı: hammadde renginde elmas) ve kısa etiket. Kilitli bölgede soluk.
4. **Seçim:** noktaya tıklama bölgeye tıklamadan önceliklidir (yarıçap kontrolü).
   Seçilen noktanın bilgisi panelde: tür, bölge, hammadde ve hızı (ham madde alanı),
   durum ("Empty plot" / şehir adı). Bölge paneli aynen kalır.

## Adımlar (her biri ayrı teslim)

1. Çelişkilerin düzeltilmesi: arazi kaldırılır, hammaddeler yeniden adlandırılır ve
   alan türü eklenir; `region_test.gd` güncellenir ve geçer.
2. `MapPoint` + `generate_points.gd` + üretilmiş noktalar. Test `tools/point_test.gd`:
   her bölgenin noktaları verisiyle birebir (kaynak sayısı, arsa sayısı, şehir), her
   nokta kendi bölgesinin içinde, noktalar arası asgari mesafe, üretim scripti ikinci
   kez çalışınca hiçbir konum değişmiyor.
3. Noktaların haritada çizilmesi, üzerine gelme, seçme ve nokta bilgi paneli.

## Kabul ölçütü

- Harita açılınca 5 bölgede toplam 7 ham madde alanı, 14 fabrika arsası ve 2 şehir görünür;
  Area1'in noktaları canlı, kilitli bölgelerinki soluk.
- Bir noktaya tıklayınca panel o noktanın bilgisini gösterir; boş alana tıklayınca
  bölge seçimi eskisi gibi çalışır.
- Bir noktayı editörde kaydırıp üretim scriptini tekrar çalıştırınca nokta yerinde kalır.
- `region_test.gd`, `point_test.gd` ve mevcut testler geçer (sim_test'teki 2 eski
  "Tikanma" hatası bu görevden önce de vardı).
