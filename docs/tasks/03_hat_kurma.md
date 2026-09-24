# Görev 03 — Hat kurma, araçlar ve kapasite

Mod: **yazılım modu**. Kaynak: tasarım belgesi → "Lojistik ve akış modeli",
"Geliştirme sırası 3". Bu dosya gereken kısıtları içerir.

## Kapsam

Var: iki noktayı hatla bağlama, hatta araç ekleme/çıkarma, hattın kapasitesini
hesaplayıp gösterme, haritada hat ve gidip gelen görsel araçlar.
Yok: yük seçimi, mal akışı, fabrika kurma, şehir talebi, gelir (Görev 04 ve sonrası).

## Tasarım kısıtları

- Hat iki noktayı bağlar; yalnızca **açık bölgelerdeki** noktalar arasında kurulur.
  Hattın çizgisi kilitli bölgenin üstünden geçebilir.
- Mesafe iki nokta arasındaki düz uzaklıktır (harita birimi).
- İki nokta arasında **tek hat** olur; kapasite araç ekleyerek artar. Bir noktaya
  bağlanan hat sayısı sınırsızdır.
- Kapasite (birim/dk) = araç sayısı × araç yükü × hız ÷ (2 × mesafe). Yükleme süresi yok.
- Maliyet: hat kurulumu sabit, araç başına alış fiyatı ve dakika başı bakım.
  Kuruluma mesafe ücreti eklenmez.
- Hat çift yönlüdür (yük seçimi Görev 04'te; bu görevde yalnızca kapasite gösterilir).
- Araçlar yalnızca görseldir; simülasyonu etkilemez.
- Taşıma türleri (tasarım belgesindeki yer tutucu sayılar):

  | Tür | Yük | Hız (birim/dk) | Araç fiyatı | Araç bakımı (/dk) | Hat kurulumu | Açılış |
  |---|---|---|---|---|---|---|
  | At arabası | 10 | 300 | 50 | 1 | 20 | Başlangıç |
  | Kamyon yolu | 30 | 400 | 200 | 3 | 20 | Kademe 1 |

  Araştırma olmadığı için bu görevde yalnızca at arabası kurulabilir; kamyon verisi
  yine de eklenir.
- Arayüz metinleri İngilizce.

## Uygulama kararları (kullanıcı onaylı)

- **K1:** Yeni hat 1 araçla kurulur (20 + 50 = 70). Son araç çıkarılamaz; araçsız hat olmaz.
- **K2:** Araç çıkarınca alış fiyatının %50'si geri verilir. Hat silinince araçlarının
  %50'si geri verilir; kurulum ücreti geri verilmez.
- **K3:** Bakım bu görevde yalnızca **gösterilir**, paradan düşülmez. Zaman akışı ve
  gelir Görev 04'te gelince düşülmeye başlar (gelir yokken para eriyip gitmesin).
- **K4:** Her tür nokta her tür noktaya bağlanabilir (aynı nokta hariç). Hangi
  bağlantının anlamlı olduğunu akış (Görev 04) belirler.

## Teknik yaklaşım

1. **Para:** `sim/wallet.gd` → `Wallet` (para, `can_afford`, `spend`, `refund`).
   `RegionState` parasını buradan kullanır (şu an kendi içinde tutuyor); hat kuralları da
   aynı cüzdanı kullanır. Mevcut bölge testleri değişmeden geçmeli.
2. **Veri:** `data/transport_type.gd` → `TransportType` (id, ad, yük, hız, araç fiyatı,
   araç bakımı, hat kurulumu). `.tres`: `data/transport_types/at_arabasi.tres`, `kamyon.tres`.
3. **Kurallar:** `sim/route_state.gd` → `RouteState` (arayüzsüz). Noktalar sahneden
   bağımsız bir kimlikle bilinir: `"<bölge id>/<nokta adı>"` (ör. `area1/City`); mesafe
   hat kurulurken dışarıdan verilir. `build_block_reason(a, b)`, `build(...)`,
   `add_vehicle`, `remove_vehicle`, `remove_route`, `capacity_per_minute`,
   `upkeep_per_minute`.
4. **Görünüm:** `features/worldmap/route_view.gd` (hat çizgisi + ortasında "N/min"
   etiketi + gidip gelen araç simgeleri; araç sayısı kadar, hıza göre). Katman sırası:
   bölgeler → hatlar → araçlar → noktalar.
5. **Hat kurma akışı:** nokta panelinde "Build route" butonu → ikinci noktaya tıkla →
   hat kurulur. Beklerken fareyi takip eden önizleme çizgisi ve üst çubukta ipucu
   (kurulamıyorsa nedeni ve maliyet). Sağ tık veya Esc iptal eder.
6. **Hat paneli:** hatta tıklayınca: iki uç, mesafe, tür, araç sayısı, kapasite,
   bakım, "+ Vehicle" / "− Vehicle" / "Remove route" butonları (koşul yoksa pasif ve nedeni).
   Tıklama önceliği: nokta → hat → bölge.

## Adımlar (her biri ayrı teslim)

1. `Wallet`, `TransportType` + 2 `.tres`, `RouteState`. Test `tools/route_test.gd`:
   kilitli bölgedeki noktaya hat kurulamaz, aynı iki nokta arasına ikinci hat kurulamaz,
   aynı noktaya hat kurulamaz, para yetmezse kurulamaz, kurunca 70 düşer, kapasite
   formülü doğru (150 birim, 1 araç → 10/dk; 600 birim, 4 araç → 10/dk), araç ekleme/
   çıkarma ve iadeler doğru, son araç çıkarılamaz, bakım toplamı doğru.
2. Hat kurma akışı ve hatların haritada çizilmesi (önizleme, ipucu, iptal).
3. Hat seçimi, hat paneli, araç ekleme/çıkarma, hat silme ve görsel araçlar.

## Kabul ölçütü

- Area1'deki ormandan City A'ya hat kurulabiliyor; para 70 azalıyor; hat üzerinde
  kapasite ve gidip gelen bir at arabası görünüyor.
- Kilitli Area2'deki madene hat kurulamıyor, ipucu nedenini söylüyor; Area2 açılınca kurulabiliyor.
- Hatta araç eklenince kapasite ve araç sayısı artıyor, para düşüyor.
- Aynı iki nokta arasına ikinci hat kurulamıyor.
- `route_test.gd`, `region_test.gd`, `point_test.gd` ve mevcut testler geçer (sim_test'teki
  2 eski "Tikanma" hatası bu görevden önce de vardı).
