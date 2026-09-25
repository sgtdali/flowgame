# Görev 06 — Olanı görmek: haritada işaretler, panellerde daha az yazı

Mod: **yazılım modu**. Kaynak: kullanıcıyla konuşma (anlaşılırlık; güzel görünüm,
renk uyumu ve animasyon bu görevin konusu değil). Oyun kuralı değişmez.

## Kapsam

Kullanıcının seçtiği yedi iş:

- **Olanı görmek:** hat gerçek akışı göstersin; satış şehirde görünsün; noktalarda stok çubuğu.
- **Az yazı, çok işaret:** mal simgeleri; panellerde çubuklar; üzerine gelince özet.

Yok: boş hattın nedenini haritada işaretlemek, fabrika bloklarını sadeleştirmek (bu sefer
seçilmedi), öğretici/hedef sistemi, renk ve animasyon çalışması.

## Uygulama kararları (onay bekliyor)

- **K1 — Hat etiketi:** kapasite yerine her yönde taşınan mal: mal simgesi + hız
  (ör. `[LG] 10 →` ve `← [FL] 5`). Hiçbir şey taşımayan yön yazılmaz. Kapasite hat
  panelinde kalır.
- **K2 — Boş hat:** iki yönde de bir şey taşımayan hat soluk gri ve kesik çizgiyle çizilir;
  araçları uçlarda park hâlinde bekler.
- **K3 — Araçlar:** en az bir yönde yük varsa araçlar gidip gelir. Yüklü gittiği yönde aracın
  içi taşıdığı malın renginde, boş döndüğü yönde içi boş (yalnızca çerçeve) çizilir. Bir yönde
  birden çok mal varsa en çok taşınanın rengi.
- **K4 — Şehir rozeti:** şehrin üstünde geçen dakikanın geliri küçük bir rozet: `+10/min`.
  Geçen dakika herhangi bir mal talebin %100'ünü aştıysa (yarı ya da onda bir fiyata
  satıldıysa) rozet turuncu olur. Gelir yoksa rozet görünmez.
- **K5 — Stok çubuğu:** ham madde alanının ve fabrikanın altında küçük doluluk çubuğu.
  Alanda: stok / 50. Fabrikada: en dolu çıkış stoğu / 50 (çıkış yoksa çubuk yok).
  Çubuk dolunca kırmızı (üretim duruyor).
- **K6 — Mal simgesi:** her mal renkli küçük bir kare + iki harf (LG Logs, WH Wheat,
  LB Lumber, FL Flour, IO Iron Ore). Renk ve harf malın verisinden gelir (görev 05'te eklendi).
  Haritada, panellerde ve üzerine gelince özette aynı simge.
- **K7 — Panellerde çubuklar:** "stock 32/50" satırları simge + çubuk + sayı olur.
  Şehir talebi: simge + çubuk (geçen dakika gelen / talep); çubukta %100 ve %150 çizgileri,
  tam fiyat / yarı fiyat / onda bir bölgeleri üç tonla. Hat panelinde her yön: simge + hız.
- **K8 — Üzerine gelince özet:** fare bir noktanın ya da hattın üzerinde durunca imlecin
  yanında küçük bir kutu: başlık + 2–4 satır (simge + sayı). Fabrikada uyarı varsa nedeni
  ("Output full", "Machines waiting for input") kutuda yazar. Tıklayınca açılan panel aynen kalır.

## Teknik yaklaşım

- Kural `sim/`'de: şehrin geçen dakika "doydu mu" bilgisi `CityMarket`'e, hat yönünde en çok
  taşınan mal `MapFlowSim`'e eklenir. Arayüz yalnızca okur.
- Görünüm `features/worldmap/`'te: mal simgesi için ortak bir çizim yardımcısı
  (`good_icon.gd`: haritada `draw_*`, panelde küçük bir Control), stok çubuğu `MapPoint`
  çiziminde, şehir rozeti `MapPoint`'te, hat görünümü `RouteView`'da, özet kutusu yeni
  `hover_card.gd`. Hiçbir dosya 300 satırı geçmez; `world_map.gd` (269) büyütülmez,
  gereken iş yeni dosyalara gider.
- Sayılar (çubuk boyu, renkler, kesik çizgi aralığı) sabit olarak dosya başında.

## Adımlar (her biri ayrı teslim)

1. **Hatlar ve şehir:** K1, K2, K3, K4. `flow_test.gd`'ye: hat yönünde en çok taşınan mal
   doğru; şehir talebi aşınca "doydu" bilgisi yanıyor, dakika dönünce sönüyor.
2. **Mal simgesi ve stok çubukları:** K5, K6 (haritada).
3. **Paneller:** K6, K7 (nokta, şehir, hat panelleri).
4. **Üzerine gelince özet:** K8.

## Kabul ölçütü

- Ormandan köye kurulan hat gri-kesik görünüyor, araçlar park hâlinde; ormandan fabrikaya
  giden hat `[LG] 10 →` yazıyor ve araçlar kahverengi gidip boş dönüyor.
- Köye talebinden fazla Lumber gidince şehir rozeti turuncuya dönüyor.
- Orman stoğu dolunca altındaki çubuk kırmızı.
- Paneli açmadan, yalnızca fareyi noktaların ve hatların üzerine getirerek zincirin
  çalışıp çalışmadığı anlaşılabiliyor.
- Tüm testler geçer (sim_test'teki 2 eski "Tikanma" hatası önceden de vardı).
