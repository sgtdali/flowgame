---
tur: sistem
durum: oneri
guncelleme: 2026-10-26
---
# Arayüz ve büyük ağ yönetimi

## Amaç

Oyuncu büyük bir üretim ağında ne olduğunu, neyin eksik kaldığını ve hangi değişikliğin işe yarayacağını okuyabilmeli. Kart sayısının büyümesi bir yönetim yüküne dönüşmemeli. Aşağıdaki araçlar öneridir; uygulanmış özellikler değildir.

## Prototipte uygulanan arayüz

Aşağıdakiler çalışan prototipte var. Onaylı kural olanlar karar kimliğiyle işaretli; diğerleri uygulama seçimidir.

- **Reçete ekranı** (K-009): aynı girdili makinelerde ürün seçimi, girdileriyle birlikte.
- **Envanter ve üretim penceresi (I ya da C)** (K-026, K-028, K-029): oyundaki bütün öğeler ve akış haritası düzeninde seçilen öğenin girdileri, tarifi ve kullanıldığı yerler; 10 yuvalı hızlı erişim (K-012). Ayrıntılar [[Tasarım/Envanter ve El Üretimi]].
- **Görünüm** (K-027, K-030): aydınlık Kum taşı paleti (bej tuval, kâğıt rengi kartlar, petrol yeşili ve bakır vurgu); bütün metinler İngilizce; başlıklarda Pixelify Sans, metinde Nunito; envanter penceresinin görselleri kullanıcının LibreSprite çizimleri (K-032; K-030'daki perçinler kalktı).
- **Bağlantı çizgileri** (K-034, K-036): 16 px'lik çok renkli bant, her 20 px'de ortadaki 8 px'i kesen dik çizgiler. Çizgiler kartların etrafından dolaşır ve üst üste binmez; yan yana gidebilir, dik kesişmede biri köprü gibi üstten geçer. Aynı porttan çıkan (ya da aynı porta giren) bağlantılar tek bant gibi birleşir.
- **Taşınan ürünler** (K-035): ürünler bağlantı boyunca 8x8 simgeyle ilerler; hedefteki sayı ürün varınca artar.
- **Kart üstü göstergeler:** giriş/çıkış tamponları, çevrim ilerlemesi, durdurma; çıkışa tıklayınca envantere alma (K-011).
- **Kart menüsü (sağ tık):** reçete, durdur/çalıştır, hız, envantere al, kaldır.
- **Araştırma paneli:** kademeli ağaç ve puan depoları (K-008).

Aşağıdaki darboğaz, gerçekleşen hız ve büyük ağ araçlarının hiçbiri henüz uygulanmadı.

## Kart ve bağlantı okunabilirliği

Teorik kapasite ile gerçekleşen hız birlikte gösterilebilir. Örneğin 30/dk kapasitesi olan makinenin 8/dk üretmesi, tek başına sebebi açıklamaz. Eksik girdi, dolu çıkış, yetersiz taşıma, araştırma bekleme durumu gibi nedenler görünür olmalıdır. Enerji seçilirse enerji kesintisi de ayrı neden olur.

Bağlantı hattında hangi ürünün taşındığı, gerçek hız, kapasite ve ekonomik bölge geçişi gösterilebilir. Renk tek bilgi taşıyıcısı olmamalı; kısa etiket ve simgeyle desteklenmeli. Bu erişilebilirlik ayrıntısı kurulum önerisidir.

## Araştırma görünümü

| Bilgi | Neyi açıklıyor? |
|---|---|
| Tamamlanan/gerekli deney | Kalıcı ilerleme |
| Çalışan/kurulu laboratuvar | Kullanılan kapasite |
| Her ürün için gelen/dk | Ölçülen tedarik |
| Tam kapasite için ihtiyaç/dk | Hızlanmak için hedef |
| Stok ve çalışan deney | Kısa dönem tampon |
| Darboğaz ve koşullu kalan süre | Müdahale edilecek nokta |

Ürün satırına tıklayınca ilgili üretici ve taşıma hatlarının vurgulanması önerilir. Kalan süre geçmiş akıştan tahmin ediliyorsa hangi varsayımla hesaplandığı anlaşılmalıdır. Akış durmuşsa kesin bir bitiş saati uydurulmamalıdır.

## Ağ büyüyünce gerekli olabilecek araçlar

- Tesis gruplama ve katlama: ayrıntıyı gerektiğinde açmak.
- Kopyalama ve blueprint: tekrarlanan kurulum işini azaltmak.
- Ürün, makine, bölge ve duruma göre arama/filtreleme.
- Darboğazdan yukarı doğru tedarik zincirine gitme.
- Bölge bazında üretim/tüketim ve taşıma özeti.
- Bir ürünün bütün kullanım yerlerini görme.

Bir kartın çok makine temsil etmesi ile birkaç kartın görsel gruba alınması farklı özelliklerdir. Gruplama kararı kapasite modelini kendiliğinden belirlemez.

## Büyük ağda bağlantı yollarının hesabı — K-037

Bağlantı yolları her kart oynadığında baştan hesaplanırsa 500 kartlık bir ağda oyun donar. Uygulanan üç önlem:

1. **Yerel ızgara:** Her bağlantı yalnız iki ucunun çevresindeki kartlarla küçük bir ızgarada aranır. Yol bulunamazsa alan büyütülür (80, 320, 1280 px pay). Kartlar ve yollar tuval üzerinde 256 px'lik kovalarda tutulur.
2. **Yalnız etkilenen çizgiler:** Kart oynayınca o karta bağlı bağlantılar ve kartın eski ya da yeni yerinden geçen bağlantılar yeniden hesaplanır; diğerleri yolunu korur.
3. **Tuval koordinatı:** Yollar tuval koordinatında saklanır; yakınlaştırma ve kaydırma yalnız yeniden çizer. Ekranda görünmeyen çizgiler çizilmez.

Ölçüm (sade test kartları, 500 kart, 936 bağlantı): sürüklerken kare başına ortalama 11 ms, en kötü 19 ms; değişiklik yokken 2,5 ms; ilk hesap 0,5 sn.

### Ertelenen çözüm: sürüklerken seyrek hesaplama

Kullanıcı bu çözümü şimdilik istemedi (K-037); ileride gerekirse diye burada duruyor.

- **Ne:** Kart sürüklenirken ona bağlı çizgiler her karede akıllı yol bulmayla değil, basit köşeli yolla (`_step_route`) çizilir. Akıllı yol bulma kart bırakılınca bir kez yapılır; istenirse sürükleme sırasında saniyede birkaç kez de yapılabilir.
- **Ne kazandırır:** Sürükleme sırasında yol hesabı neredeyse sıfıra iner (60 yerine 1 hesap). Çizgilerin sürüklerken şerit değiştirip zıplaması da biter.
- **Bedeli:** Sürüklerken çizgiler bir an kartların üstünden geçip başka çizgilerle çakışabilir; bırakınca düzelir.
- **Ne zaman gerekir:** Sürükleme kare başına 16 ms'yi aşarsa. Olası durumlar: çok bağlantılı bir kart (ör. 20 makineye bağlı depo), uçları çok uzak bağlantılar, çizgi dolu bir bölgede sürükleme, gerçek kartlarla büyük ağ.
- **Nereye:** `app/flow_graph.gd` içindeki `_update_routes()`; sürüklenen kartı GraphEdit'in `begin_node_move` / `end_node_move` sinyalleriyle izleyip o kartın bağlantılarını sürükleme bitene kadar `_step_route` ile çizmek yeterli.

## Açık sınırlar

Canvas'ta bölgelerin çerçeve olarak çizilip çizilmeyeceği ve bütün bölgelerin aynı anda görünmesi seçilmedi. Her ayrıntıyı sürekli göstermek okunabilirliği azaltabilir; özet ve ayrıntı seviyelerinin ilk prototipte gözlenmesi gerekir.

Bkz. [[Tasarım/Makine Kartları]], [[Tasarım/Araştırma Ekonomisi]], [[Araştırma/Factory Planner ve Farklılaşma]]. Dayanak: [[Yönetim/Karar Defteri#K-034 — Tuvaldeki bağlantı çizgilerinin görünümü|K-034]], [[Yönetim/Karar Defteri#K-036 — Bağlantılar üst üste binmez, kartların etrafından dolaşır|K-036]], [[Yönetim/Karar Defteri#K-037 — Büyük ağda yol hesabı: yerel, parça parça, tuval koordinatında|K-037]].
