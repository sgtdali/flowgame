---
tur: sistem
durum: karma
guncelleme: 2026-10-24
---
# Envanter ve el üretimi

Oyuncunun taşıdığı ürünler ve kurulmamış makineler, makine kurmanın bedeli, el ile üretim ve hammadde sınırı bu notta toplanır. Onaylı kurallar karar defterindeki kayıtlara dayanır; prototipteki sayılar ve ayrıntılar ilk denemedir.

## Onaylı kurallar

### Envanter ve malzemeli kurulum — K-011

- Oyuncunun bir envanteri vardır; envanterde hem ürünler hem kurulmamış makineler tutulur.
- Makineler malzemeyle üretilir; envanterdeki makine tuvale yerleştirilir. Kaldırılan makine, içindeki ürünlerle birlikte envantere döner.
- Üretilen ürün envantere kendiliğinden geçmez. Oyuncu isterse makine kartında biriken çıktıyı ya da ağa bağlanan Depo kartında biriken ürünü envantere alır.
- Oyuncu üretim ekranından el ile üretim yapar. El üretimi süreli bir kuyruktur ve makinelerden yavaştır.
- Hammadde el ile çıkarılamaz; oyuncu bir başlangıç kitiyle başlar.

Envanter, makineleri kendiliğinden besleyen bir depo değildir: makineler ürünü ağ bağlantılarından ya da oyuncunun elle koyduğundan alır (K-014). Bu, [[Tasarım/Araştırma Ekonomisi]] notundaki "bütün haritadan malzeme çeken global envanter olmasın" önerisiyle çelişmez.

### Hızlı erişim ve envanter penceresi — K-012

- Ekranın altındaki çubuk hızlı kullanım içindir ve sabit 10 yuvadır.
- Envanterin tamamı ayrı açılan, geniş bir penceredir ve bir tuşla açılır.
- İki görünüm aynı envanteri paylaşır; oyuncu istediği öğeyi alttaki hızlı erişime sabitler.

K-012, K-011'in "ekranın altı envanterdir" maddesinin yerine geçti. Ayrı envanter penceresi K-026 ile üretim ekranıyla birleşti.

### Envanter ve üretim tek pencere — K-026, K-028, K-029

- Envanter ve el üretimi tek penceredir. Solda oyundaki bütün öğeler durur: elde olanlar adediyle, olmayanlar soluk. Sağda seçilen öğe üretilir (K-026).
- Pencere bir akış haritasıdır: seçilen öğe ortada, girdileri solda, kullanıldığı yerler sağda, aralarında çizgiler. Kullanıldığı yerler 6 karta kadar tam görünür; fazlası birer kart adımla kayar ve çizgiler görünen kartlara gider (K-028).
- Elle ve makinede üretim arasında fark gösterilmez: her reçetenin sabit iş gereksinimi vardır, el ve makineler yalnızca iş gücünde ayrılır. Bu sayı simgeyle gösterilir (K-029).
- Pencerenin boyutu sabittir ve kapatma düğmesi vardır; büyük öğe resmi 64 px'tir. El üretimi kuyruğu en fazla 5 farklı öğe alır (K-031).
- Pencerenin bütün görselleri kullanıcının LibreSprite çizimleridir. Crafting Queue akış alanının altında, Quick Bar en altta kendi çerçeveli bölümlerindedir; boş kuyruk boş yuvalar gösterir. CRAFT ve PLACE yan yanadır (K-032).

### Kurulu başlangıç — K-033 (K-013'ün yerine)

Oyun bir Demir madeni ve bir Ergitme fırını kurulu başlar; diğer makineleri oyuncu başlangıç kitiyle üretip yerleştirir. K-013'teki boş tuval kuralı bununla değişti.

### Makine girişine elle koyma — K-014

Oyuncu envanterdeki bir ürünü, uygunsa bir makine kartının girişine bırakabilir; ağa bağlı olmayan makineler de böyle elle çalıştırılır.

### Hammadde sınırı — K-010

Madenler (demir, bakır, kömür, kuvars) oyun başında birer adet kurulabilir. **2026-10-26'dan beri (K-043, K-044):** sınırı haritadaki dağlar belirler; her kaynaktan 3 dağ, her dağa bir maden. Her makine türü bir kurulum sınırı taşıyabilir; sınırı olmayan makineler serbesttir. Maden sınırı araştırmayla artar: her maden için II ve III araştırmaları sınırı birer artırır (K-025).

Dayanak: [[Yönetim/Karar Defteri#K-010 — Hammadde kaynakları sınırlıdır|K-010]], [[Yönetim/Karar Defteri#K-011 — Oyuncu envanteri, malzemeli kurulum ve el üretimi|K-011]], [[Yönetim/Karar Defteri#K-012 — Hızlı erişim çubuğu ve envanter penceresi|K-012]], [[Yönetim/Karar Defteri#K-026 — Envanter ve el üretimi tek pencerede|K-026]], [[Yönetim/Karar Defteri#K-028 — Envanter penceresi akış haritası düzeninde|K-028]], [[Yönetim/Karar Defteri#K-029 — Elle ve makinede aynı iş miktarı, simgeyle gösterilir|K-029]], [[Yönetim/Karar Defteri#K-031 — Envanter penceresi sabit boyutlu; kuyruk en fazla 5 farklı öğe|K-031]], [[Yönetim/Karar Defteri#K-032 — Envanter penceresinin elle çizilmiş görünümü|K-032]], [[Yönetim/Karar Defteri#K-033 — Oyun demir madeni ve ergitme fırını kurulu başlar|K-033]].

## Prototipteki karşılığı (ilk deneme, dengelenmemiş)

| Konu | Prototipte |
|---|---|
| Başlangıç | Tuvalde Demir madeni → Ergitme fırını (Iron Ingot) kurulu ve bağlıdır (K-033). Kit (K-023): 30 demir levha, 20 demir çubuk, 6 çelik levha, 6 bağlantı elemanı; Bakır madeni, Kuvars ocağı ve Depo birer adet. Kit demir ve kömür madenini, ergitme fırınını ve Laboratuvar 1'i üretmeye yeter (testle denetlenir). |
| Kurulum bedeli | K-023: başlangıç makineleri demirden (ör. maden 6 demir levha + 4 demir çubuk), sonrakiler kendi aşamasının ürünlerinden (ör. Mekanik Montaj 6 çelik levha + 4 dişli + 4 rulman + 6 bağlantı elemanı, Modül Tesisi 20 çelik levha + 10 demir şasi + 4 dişli kutusu). Liste `data/prototype.json` içindedir. |
| El üretimi | Hız 10 iş/sn (makineler 20). Makine yapımı 50 iş, yani 5 sn. El ile yapılabilen reçeteler haddehane, pres, Tezgâh Atölyesi, tel sarım ve dört montaj makinesinin reçeteleridir; fırın, döküm, maden ve Modül Tesisi reçeteleri el ile yapılamaz. Malzeme sıraya alınırken düşer; iptal edilen işin malzemesi geri döner. |
| Kurulum sınırı | Sınır kurulu, envanterdeki ve üretim sırasındaki makineleri birlikte sayar; sınırı dolan makine üretilemez ve yerleştirilemez. Serbest modda sınır yoktur. |
| Depo | Her bağlı ürün için ayrı giriş açan, ürün başına 100 tutan kart (kapasite araştırmalarıyla büyür). Ürünü kendisi işlemez; oyuncu içindekini envantere alır. Makine Fabrikası'nın ürettiği makineleri de tutar. |
| Makine Fabrikası | K-024: AL-01 ile açılır. Reçete ekranından seçilen makineyi kurulum bedelinden 2,5 sn'de üretir; madenler gibi sınırlı makineleri üretmez. Çıktıda en fazla 3 makine birikir; bağlı depoya da gider. Alınan makine envantere taşınan makine olarak geçer. |
| Karttan alma | Çıkış kutusuna tıklamak ya da kart menüsündeki "Envantere al" çıktıyı envantere taşır. |
| Makineye koyma | Hızlı erişimden ya da envanter penceresinden ürünü giriş kutusuna sürükle-bırak; varsayılan girişe sığdığı kadar, Shift ile 1 adet. Normal giriş yalnızca kendi ürününü, otomatik makinenin genel girişi reçetesi olan her ürünü, depo her ürünü alır. Envanter penceresi açıkken sürüklenen ürün arkadaki karta bırakılabilir. |
| Envanter yuvası | Envanterin yuva veya ağırlık sınırı yoktur. |
| Hızlı erişim | 10 yuva, 1–9 ve 0 tuşları. Makine yuvası tıklanınca ya da numarasına basılınca makine yerleştirilir. Sayısı sıfıra inen öğe yuvasında soluk kalır. Yeni gelen öğe boş yuva varsa ilk boş yuvaya kendiliğinden girer; oyuncunun çıkardığı öğe kendiliğinden geri gelmez. |
| Envanter ve üretim penceresi | I ya da C ile açılır (oyunda "Inventory and Crafting"). Solda 23 makine ve 55 ürün; başlıklarda elde olan/toplam sayısı, araştırılmamış öğede asma kilit, araştırılmamış makinede çizim yerine kategori simgesi. Ortada seçilen öğe: resim, envanterdeki adet, üreten makine, tarif, çekiç simgesiyle iş miktarı, CRAFT (Shift: 5 adet) ve elde makine varsa PLACE. Solda girdi kartları (elde/gereken, eksikse kırmızı; hammaddede çıkaran maden), sağda kullanıldığı ürün ve makine kartları. Her karta tıklamak o öğeyi ortaya getirir. Akış alanının altında en fazla 5 gruplu üretim sırası (boş yerler silik yuva), en altta hızlı erişimin kopyası (K-031, K-032). Görsellerin kaynakları ve 9-slice payları `art_src/ui/envanter_penceresi/README.md` içinde. Sabitleme: hızlı erişim yuvasına sürükleme, sağ tık ya da öğenin üstündeyken numara tuşu; makine çift tıkla yerleştirilir. |
| Kayıt | Envanter, kurulmamış makineler, üretim sırası ve hızlı erişim kayda girer (kayıt sürümü 4). |

Bu satırlar, kararlara dayanan maddeler dışında kullanıcı kararı değildir; I ve C tuşları, otomatik yuvaya girme ve el ile yapılabilen reçete listesi asistanın prototip seçimidir.

## Açık kalanlar

- Makine Fabrikası'nın dengesi (bedeli, hızı, açılış zamanı) denenmedi ([[Yönetim/Karar Defteri#K-024 — Makine Fabrikası|K-024]]).

- Kurulum sınırlarının araştırmayla veya başka yolla artması (K-010'daki "belki").
- Envanterin bir taşıma sınırı olup olmayacağı.
- Kurulum bedellerinin ve el üretimi hızının dengesi.
- Depo kapasitesi ve depoların ağda ara stok olarak kullanılıp kullanılmayacağı.

Bağlantılar: [[Tasarım/Makine Kartları]], [[Tasarım/Arayüz ve Büyük Ağ Yönetimi]], [[Yönetim/Uygulama Durumu]], [[Yönetim/Açık Sorular]].
