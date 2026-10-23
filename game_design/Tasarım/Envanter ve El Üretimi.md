---
tur: sistem
durum: karma
guncelleme: 2026-10-23
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

K-012, K-011'in "ekranın altı envanterdir" maddesinin yerine geçti.

### Boş başlangıç — K-013

Oyun boş tuvalle başlar; ilk makineleri oyuncu başlangıç kitiyle üretip yerleştirir.

### Makine girişine elle koyma — K-014

Oyuncu envanterdeki bir ürünü, uygunsa bir makine kartının girişine bırakabilir; ağa bağlı olmayan makineler de böyle elle çalıştırılır.

### Hammadde sınırı — K-010

Madenler (demir, bakır, kömür, kuvars) oyun başında birer adet kurulabilir. Her makine türü bir kurulum sınırı taşıyabilir; sınırı olmayan makineler serbesttir. Sınırın araştırmayla artırılması kullanıcının "belki" dediği bir yöndür, karar değildir.

Dayanak: [[Yönetim/Karar Defteri#K-010 — Hammadde kaynakları sınırlıdır|K-010]], [[Yönetim/Karar Defteri#K-011 — Oyuncu envanteri, malzemeli kurulum ve el üretimi|K-011]], [[Yönetim/Karar Defteri#K-012 — Hızlı erişim çubuğu ve envanter penceresi|K-012]].

## Prototipteki karşılığı (ilk deneme, dengelenmemiş)

| Konu | Prototipte |
|---|---|
| Başlangıç | Tuval boştur (K-013). Kit: 20 çelik levha, 10 bağlantı elemanı, 10 çelik külçe; Bakır madeni, Kuvars ocağı ve Depo birer adet. Kit demir ve kömür madenini, ergitme ve çelik fırınını üretmeye yeter; fırının külçesinden el ile levha, çubuk ve bağlantı elemanı yapılarak Laboratuvar 1'e ulaşılır (testle denetlenir). |
| Kurulum bedeli | Her makinenin malzeme listesi var; ör. maden 5 levha + 4 bağlantı elemanı, CNC 6 levha + 4 çubuk + 6 bağlantı elemanı, ana proje terminali 20 levha + 4 dişli kutusu + 6 devre kartı. Liste `data/prototype.json` içindedir. |
| El üretimi | Hız 10 iş/sn (makineler 20). Makine yapımı 50 iş, yani 5 sn. El ile yapılabilen reçeteler haddehane, pres, torna, CNC, tel sarım ve montaj makinelerinin reçeteleridir; fırın, döküm ve maden reçeteleri el ile yapılamaz. Malzeme sıraya alınırken düşer; iptal edilen işin malzemesi geri döner. |
| Kurulum sınırı | Sınır kurulu, envanterdeki ve üretim sırasındaki makineleri birlikte sayar; sınırı dolan makine üretilemez ve yerleştirilemez. Serbest modda sınır yoktur. |
| Depo | Her bağlı ürün için ayrı giriş açan, ürün başına 100 tutan kart. Ürünü kendisi işlemez; oyuncu içindekini envantere alır. |
| Karttan alma | Çıkış kutusuna tıklamak ya da kart menüsündeki "Envantere al" çıktıyı envantere taşır. |
| Makineye koyma | Hızlı erişimden ya da envanter penceresinden ürünü giriş kutusuna sürükle-bırak; varsayılan girişe sığdığı kadar, Shift ile 1 adet. Normal giriş yalnızca kendi ürününü, otomatik makinenin genel girişi reçetesi olan her ürünü, depo her ürünü alır. Envanter penceresi açıkken sürüklenen ürün arkadaki karta bırakılabilir. |
| Envanter yuvası | Envanterin yuva veya ağırlık sınırı yoktur. |
| Hızlı erişim | 10 yuva, 1–9 ve 0 tuşları. Makine yuvası tıklanınca ya da numarasına basılınca makine yerleştirilir. Sayısı sıfıra inen öğe yuvasında soluk kalır. Yeni gelen öğe boş yuva varsa ilk boş yuvaya kendiliğinden girer; oyuncunun çıkardığı öğe kendiliğinden geri gelmez. |
| Envanter penceresi | I ile açılır. Sabitleme: hızlı erişim yuvasına sürükleme, sağ tık ya da öğenin üstündeyken numara tuşu. |
| Üretim ekranı | C ile açılır; kategoriler, seçili öğenin tarifi, ÜRET düğmesi (Shift: 5 adet), üretim sırası ve envanter satırı. |
| Kayıt | Envanter, kurulmamış makineler, üretim sırası ve hızlı erişim kayda girer (kayıt sürümü 4). |

Bu satırların hiçbiri kullanıcı kararı değildir; I tuşu, otomatik yuvaya girme ve el ile yapılabilen reçete listesi asistanın prototip seçimidir.

## Açık kalanlar

- Makine üreten makineler onaylı bir yön ([[Yönetim/Karar Defteri#K-020 — Makine üreten makineler|K-020]]): oyuncu başta elle ürettiği makineleri zamanla kartlara ürettirecek. Tasarımı S-024'te açık.

- Kurulum sınırlarının araştırmayla veya başka yolla artması (K-010'daki "belki").
- Envanterin bir taşıma sınırı olup olmayacağı.
- Kurulum bedellerinin ve el üretimi hızının dengesi.
- Depo kapasitesi ve depoların ağda ara stok olarak kullanılıp kullanılmayacağı.

Bağlantılar: [[Tasarım/Makine Kartları]], [[Tasarım/Arayüz ve Büyük Ağ Yönetimi]], [[Yönetim/Uygulama Durumu]], [[Yönetim/Açık Sorular]].
