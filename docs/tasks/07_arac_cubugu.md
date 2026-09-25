# Görev 07 — Harita araç çubuğu (Route, Factory, Unlock)

Mod: **yazılım modu**. Kaynak: tasarım belgesi → "Harita arayüzü: araç çubuğu".
Bu dosya gereken kısıtları içerir. Oyun kuralı değişmez; neyin yapılabildiğini
yine `RouteState`, `FactorySites`, `RegionState` söyler.

## Kapsam

Var: ekranın altında araç çubuğu; üç alet (Route, Factory, Unlock); aletlere göre
haritada vurgu, fiyat etiketi ve soluklaştırma; geçersiz hedefte neden; kısayollar.
Yok: Research aleti (araştırma gelince), araç ekleme ve hat silme aleti (hat panelinde kalır),
genel bakış paneli.

## Tasarım kısıtları

- Çubuk ekranın altında; oyuncu önce aleti, sonra yeri seçer.

| Alet | Kısayol | Harita ne gösterir | Tıklayınca |
| --- | --- | --- | --- |
| Route | 1 | Hat kurulabilecek noktalar vurgulanır; ilk nokta seçilince fareye kadar önizleme ve fiyat | İki nokta seçilince hat kurulur |
| Factory | 2 | Kurulabilecek boş arsalarda fiyat etiketi ("+300") | Arsaya fabrika kurulur |
| Unlock | 3 | Açılabilir bölgelerde fiyat etiketi | Bölge açılır |

- Alet seçili kalır; Esc, sağ tık ya da aynı düğmeye tekrar basmak aleti bırakır.
- Alet seçiliyken kullanılamayan yer soluk kalır; oraya tıklanınca nedeni gösterilir.
- Alet seçili değilken tıklamak seçer ve bilgi panelini açar; paneldeki eylem düğmeleri kalır.
- Arayüz metinleri İngilizce.

## Uygulama kararları (onay bekliyor)

- **K1 — Yarım hat:** Route aletinde ilk nokta seçilmişken Esc / sağ tık önce yalnızca yarım
  hattı iptal eder (alet seçili kalır); ikinci Esc / sağ tık aleti bırakır. Hat kurulunca alet
  bir sonraki hattın ilk noktasını bekler.
- **K2 — Parası yetmeyen hedef:** kurallara göre kurulabilir ama para yetmiyorsa hedef soluk
  değil, fiyat etiketi **kırmızı** gösterilir (oyuncu neye biriktirdiğini görsün). Tıklanınca
  "Not enough money".
- **K3 — Neden gösterimi:** geçersiz hedefe tıklanınca neden üst çubuğun ortasında birkaç saniye
  kırmızı yazılır (ör. "Area 2 is locked"); fare üstündeyken de aynı neden ipucunda görünür.
- **K4 — Alet açıkken seçim:** alet seçiliyken panel açılmaz ve seçim yapılmaz; üzerine gelince
  özet kutusu çalışmaya devam eder. Fabrika ekranı açılınca alet bırakılır.
- **K5 — Route vurgusu:** hat başlatılabilen noktalar (açık bölgede) normal, diğerleri soluk.
  İlk nokta seçildikten sonra ona bağlanabilecek noktalar normal, bağlanamayanlar soluk.
- **K6 — Çubuk görünümü:** alt ortada üç büyük düğme: "Route [1]", "Factory [2]",
  "Unlock [3]"; seçili olan basılı görünür; üzerine gelince tek cümlelik açıklama.

## Teknik yaklaşım

- `world_map.gd` 292 satırda: girdi ve alet mantığı yeni dosyalara taşınır, bu dosya küçülür.
  - `features/worldmap/map_tools.gd` — geçerli alet, alet açıkken tıklama, Esc / sağ tık, kısayollar.
  - `features/worldmap/tool_bar.gd` — alt çubuk (yalnızca düğmeler ve sinyal).
  - `features/worldmap/tool_highlights.gd` — alete göre noktalara/bölgelere vurgu, soluklaştırma
    ve fiyat etiketi yazar (`MapPoint`, `RegionView`'a küçük görünüm fonksiyonları eklenir).
- Hedefin geçerliliği ve nedeni yalnızca sim'deki mevcut fonksiyonlardan gelir
  (`start_block_reason`, `build_block_reason`, `unlock_block_reason`); arayüz kural hesaplamaz.
- Hiçbir dosya 300 satırı geçmez.

## Adımlar (her biri ayrı teslim)

1. **Çubuk ve alet durumu:** alt çubuk, kısayollar, Esc / sağ tık, alet açıkken panel açılmaması;
   `world_map.gd`'nin bölünmesi. Route aleti mevcut hat kurma akışını kullanır.
2. **Factory ve Unlock aletleri:** arsalarda ve bölgelerde fiyat etiketleri, soluklaştırma,
   kırmızı fiyat, geçersiz hedefte neden.
3. **Route vurgusu:** başlatılabilir / bağlanabilir noktaların vurgusu, yarım hat iptali (K1).

## Kabul ölçütü

- Oyuncu hiçbir panele girmeden, yalnızca çubuk ve haritayla: bir fabrika kurabiliyor, iki hat
  çekebiliyor, bir bölge açabiliyor.
- Factory seçiliyken Area 1'deki boş arsalarda "+300" görünüyor, kilitli bölgelerdeki arsalar
  soluk; kilitli arsaya tıklayınca neden yazıyor.
- Unlock seçiliyken yalnızca açılabilir bölgelerde fiyat görünüyor.
- 1 / 2 / 3 / Esc ve sağ tık beklendiği gibi çalışıyor; alet seçili değilken her şey eskisi gibi.
- Tüm testler geçer (sim_test'teki 2 eski "Tikanma" hatası önceden de vardı).
