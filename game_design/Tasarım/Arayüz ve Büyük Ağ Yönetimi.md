---
tur: sistem
durum: oneri
guncelleme: 2026-10-23
---
# Arayüz ve büyük ağ yönetimi

## Amaç

Oyuncu büyük bir üretim ağında ne olduğunu, neyin eksik kaldığını ve hangi değişikliğin işe yarayacağını okuyabilmeli. Kart sayısının büyümesi bir yönetim yüküne dönüşmemeli. Aşağıdaki araçlar öneridir; uygulanmış özellikler değildir.

## Prototipte uygulanan arayüz

Aşağıdakiler çalışan prototipte var. Onaylı kural olanlar karar kimliğiyle işaretli; diğerleri uygulama seçimidir.

- **Reçete ekranı** (K-009): aynı girdili makinelerde ürün seçimi, girdileriyle birlikte.
- **Üretim ekranı (C)** (K-011): kategoriler, seçili öğenin tarifi ve süresi, ÜRET düğmesi, üretim sırası. Görünüm, kullanıcının Codex taslakları arasından seçtiği "A" tarzıdır.
- **Envanter penceresi (I) ve 10 yuvalı hızlı erişim** (K-012): bkz. [[Tasarım/Envanter ve El Üretimi]].
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

## Açık sınırlar

Canvas'ta bölgelerin çerçeve olarak çizilip çizilmeyeceği ve bütün bölgelerin aynı anda görünmesi seçilmedi. Her ayrıntıyı sürekli göstermek okunabilirliği azaltabilir; özet ve ayrıntı seviyelerinin ilk prototipte gözlenmesi gerekir.

Bkz. [[Tasarım/Makine Kartları]], [[Tasarım/Araştırma Ekonomisi]], [[Araştırma/Factory Planner ve Farklılaşma]].
