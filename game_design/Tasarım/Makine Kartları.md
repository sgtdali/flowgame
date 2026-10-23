---
tur: sistem
durum: karma
guncelleme: 2026-10-23
---
# Makine kartları

## Onaylı temel

Kartlar makineyi temsil eder. CNC, torna, pres ve fırın örnek makine türleridir; henüz nihai makine kataloğu değildir. Oyuncunun çalışma alanı node tabanlı kartların bağlandığı sonsuz canvas'tır. Dayanak: [[Yönetim/Karar Defteri]] K-002 ve K-003.

## Onaylı üretim modeli — K-005

Reçete bir çevrimde tüketilecek girdileri, üretilecek çıktıları ve **gereken iş miktarını** tanımlar. Makine **işleme birimi/sn cinsinden işleme hızına** sahiptir ve yalnızca uygun reçeteleri çalıştırabilir.

**Çevrim süresi (sn) = gereken iş / makinenin işleme hızı**

**Tam kapasite (ürün/dk) = çevrim başına çıktı × 60 / çevrim süresi (sn)**

“İşleme gücü” konuşmadaki geçici ifadedir. Reçete tarafına gereken iş, makine tarafına işleme hızı denir; oyuncuya gösterilecek nihai terim henüz seçilmedi. İşleme birimi stoklanan veya taşınan bir kaynak değildir; işlem boyunca tamamlanan çalışmanın ölçüsüdür. Enerji tüketimi ayrı bir konudur.

### Hesap örneği

| Özellik | Örnek değer |
|---|---|
| Girdi | 2 demir çubuk |
| Gereken iş | 100 işleme birimi |
| Makinenin işleme hızı | 20 işleme birimi/sn |
| Çevrim çıktısı | 1 dişli |
| Süre | 100 / 20 = 5 saniye |
| Kesintisiz kapasite | 12 dişli/dk |
| Kesintisiz girdi ihtiyacı | 24 demir çubuk/dk |

Hızı 40 birim/sn olan uygun makine aynı örnek reçeteyi 2,5 saniyede tamamlar; kapasitesi 24 dişli/dk olur. Sayılar ve örnek reçete denge değerleri olarak onaylanmamıştır; onaylanan hesaplama ve çalışma modelidir.

### Üretim çevrimi

1. Bağlı hatlardan gelen malzemeler küçük giriş tamponunda birikir.
2. Bir çevrimin bütün girdileri ve bütün çıktıları için yeterli çıkış alanı varsa işlem başlar.
3. Girdiler çevrim başında birlikte tüketilir; iş ilerlemesi görünür.
4. Gereken iş tamamlanınca reçetedeki çıktılar çıkış tamponuna eklenir. Çevrim çıktısı zorunlu olarak bir adet değildir; reçeteye bağlıdır.
5. Koşullar uygunsa sonraki çevrim otomatik başlar. Eksik girdi veya dolu çıkış tamponu yeni çevrimi bekletir.

Bir girdi eksikse diğerleri tüketilmeden tamponda bekler. Başlamış iş, girdileri başlangıçta tüketildiğinden yeni girdi akışı kesilse de tamamlanır. Enerji kesintisi veya makine arızası gibi başka kesinti türleri bu kararda tanımlanmadı.

### Makine uygunluğu ve gerçek hız

İşleme hızının yüksek olması bütün reçeteleri çalıştırma yeteneği vermez. Örneğin hızlı bir pres, CNC reçetesini sırf hızı nedeniyle yapamaz. Hangi makinenin hangi reçeteye uygun olduğu katalog düzeyinde henüz seçilmedi.

Tam kapasite yeterli girdi ve kesintisiz çıkış varsayar; gerçek üretim daha düşük olabilir. Oyuncuya çevrim süresi, kapasite, gerçekleşen üretim ve bekleme nedeni gösterilmesi önerildi; kesin arayüz düzeni seçilmedi.

### Açık kalan ayrıntılar

- Giriş ve çıkış tamponlarının sayısal kapasiteleri.
- Kart başına makine sayısı, paralel işler ve birden fazla reçete paylaşımı.
- Reçete değişimi, işlem iptali ve malzeme iadesi.
- Yan ürün boşaltma/bertaraf seçeneği ve bedeli (prototipte yer tutucu `Talaş bertaraf ünitesi` var; kullanıcı kararı yok).
- Farklı proses türleri için ayrı işleme kategorileri gerekip gerekmediği.
- Enerji, aşınma, kalite ve altyapının işleme hızına etkisi.

Dayanak: [[Yönetim/Karar Defteri#K-005 — İş miktarı ve makine işleme hızıyla üretim|K-005]], [[Kaynaklar/02 - Bu Sohbetteki Kararlar]]. Model Godot prototipinde uygulandı ve otomatik olarak doğrulandı; eğlenceli oynanış veya büyük ağ ölçeği henüz doğrulanmadı. Prototipte bütün makinelerin hızı 20 iş/sn'dir ve kart menüsünden 40'a çıkarılabilir; tamponlar 6–12 adettir. Kapsam: [[Yönetim/Uygulama Durumu]].

## Makine ve reçete ilişkisi

Makine türü hangi reçetelerin çalıştırılabileceğini belirler. Aynı makine türü farklı kartlarda farklı ürünler için kullanılabilir. Örneğin bir haddehane kartında levha, diğerinde çubuk üretilebilir.

### Onaylı reçete seçimi — K-009

- **Girdileri farklı reçeteler:** Oyuncu reçete seçmez; makine bağlanan ya da elle konan ürüne göre ne üreteceğini belirler. Boş makinenin tek bir genel girişi olur. Prototipte tel sarım ve dört montaj makinesi ile Modül Tesisi böyle çalışır.
- **Aynı girdiden farklı ürün ve fırınlar:** Kartın menüsünden açılan simgeli reçete ekranından ürün seçilir; ekran ürünün girdilerini de gösterir. Prototipte haddehane, pres, Tezgâh Atölyesi, dökümhane, Makine Fabrikası ve — K-016 ile — ergitme fırını böyledir. Seçili reçeteye uymayan ürün bağlanamaz ve konamaz.

Dayanak: [[Yönetim/Karar Defteri#K-009 — Reçete gelen ürüne göre belirlenir|K-009]], [[Yönetim/Karar Defteri#K-016 — Fırınlarda reçeteyi oyuncu seçer|K-016]]. Prototipte bir makinenin seçim biçimi katalogda zorlanabilir (`recipe_mode`).

### Makine düzeni — K-022

| Makine | Reçeteler |
|---|---|
| 4 maden | Cevher, kömür, kuvars |
| Ergitme Fırını | Iron Ingot, Steel Ingot, Copper Ingot, Industrial Glass, Silicon, hurdadan demir ve çelik |
| Haddehane | Iron Plate, Iron Rod, Iron Pipe, Steel Plate, Steel Rod |
| Pres | Fastener, Housing, Electrical Cabinet, Tank, Laminated Core |
| Tezgâh Atölyesi | Shaft, Gear, Bearing (+ Metal Scrap) |
| Dökümhane | Cast Iron Gear, Cast Iron Housing |
| Tel Sarım | Copper Wire, Coil, Cable |
| Mekanik Montaj | Valve, Iron Frame, Hydraulic Cylinder, Pump, Gearbox, Linear Guide, Precision Spindle, Hydraulic Power Unit, Hydraulic Press Unit |
| Elektrik Montaj | Electric Motor, Transformer, Switchgear |
| Elektronik Montaj | Circuit Board, Microchip, Display, Sensor, Control Computer, PLC |
| Robotik Montaj | Actuator, Robot Arm, Conveyor Line |
| Modül Tesisi | Beş modül ve Founding Core |
| Makine Fabrikası (K-024) | Sınırı olmayan her makine |
| Depo, Talaş İmha, Laboratuvar 1–4, Ana Proje Terminali | Kendi işleri |

Dayanak: [[Yönetim/Karar Defteri#K-022 — Makine düzeni|K-022]].

Giriş ve çıkış portları reçeteye göre ürün akışını gösterir. Bu model, makine türünü üretim operasyonundan ayırır. Araştırma bazen yeni makine, bazen mevcut makine için yeni reçete açabilir. Makine-reçete uygunluğu henüz detaylı veri tablosuna dönüşmemiştir.

## Kartta bulunabilecek bilgiler

| Alan | Oyuncuya faydası | Durum |
|---|---|---|
| Makine türü ve kart adı | Rolü tanımak | Öneri |
| Seçili reçete | Ne üretildiğini anlamak | Öneri |
| Girdi/çıktı portları | Akışı kurmak | Öneri |
| Teorik ve gerçekleşen üretim hızı | Kapasiteyi kullanımından ayırmak | Öneri |
| Çalışma/durma nedeni | Sorunu bulmak | Öneri |
| Tampon stoklar | Akış kesintisini anlamak | Öneri |
| Makine sayısı | Gruplama seçilirse ölçeği göstermek | Açık |
| Ekonomik bölge | Bölgesel model seçilirse kaynak erişimini göstermek | Açık |
| Enerji, kalite ve yan ürün | İlgili sistemler seçilirse karar vermek | Açık |

### Onaylı kart gösterimi — K-015

- Girişler ve çıkışlar çerçeveli kutulardır. Kutu 0 iken boştur; ürün geldikçe simgesi ve adedi görünür. Depolar dahil bar yoktur.
- Seçili reçetenin girdileri boş giriş kutularında saydamlaştırılmış simge olarak görünür; oyuncu hangi kutuya hangi malzemenin gireceğini görür.
- Makinenin ne ürettiği çıktı kutusunda değil, ayrı bir yerde görünür; prototipte kart başlığında, adın sağında.

Prototipte ayrıca: dolu tamponda kutu çerçevesi altın rengi; çevrim çubuğu ve durdurma düğmesi; çıkış kutusuna tıklamak ürünü envantere alır; envanterden giriş kutusuna ürün bırakılabilir (K-014); girişin "+" düğmesi o ürünün üreticisini kurup bağlar. Kutu boyutu, renkler ve başlık yerleşimi uygulama seçimidir; tablodaki "Öneri" durumlarını onaylamaz.

## Kurulum bedeli ve sınırı — K-010, K-011

Makineler malzemeyle üretilir ve oyuncunun envanterinden tuvale yerleştirilir; kaldırılan makine envantere döner (K-011). Madenler oyun başında birer adet kurulabilir; her makine türü bir kurulum sınırı taşıyabilir (K-010). Ayrıntılar ve prototipteki bedeller: [[Tasarım/Envanter ve El Üretimi]].

**Depo kartı (prototip):** Bağlanan her ürün için ayrı giriş açan, ürünü işlemeden biriktiren kart. Oyuncu içindekini envantere alır. Depo K-011'in "depodan da alınır" maddesine dayanır; kapasitesi (ürün başına 100) ilk denemedir.

## Açık seçim: tek makine veya grup

**Tek makine modeli:** Her kart tek fiziksel makineyi soyutlar. Kapasiteyi büyütmek için kart çoğaltılır. Başlangıçta anlaşılması kolay olabilir; büyük ağlarda tekrar ve görsel kalabalık riski vardır.

**Grup modeli önerisi:** Bir kart aynı tipte paralel makineleri temsil edebilir. Kapasite karttaki makine sayısı artırılarak büyür. Kart sayısı azalır; fakat maliyet, reçete paylaşımı ve paralel üretim kuralları açıkça tanımlanmalıdır.

Kaynak konuşmadaki örnek: 10 CNC'lik kart, tek makinenin 8 dişli/dk hızından toplam 80 dişli/dk üretebilir; 100 çelik/dk tüketip 20 talaş/dk çıkarabilir. **Bu değerler örnektir; onaylı reçete veya gerçek imalat verisi değildir.**

## Reçete paylaşımı konusunda iki ayrı öneri var

Konuşmada hem bir kartın tek reçete çalıştırıp farklı reçete için ayrı kart açması hem de aynı makine kapasitesinin farklı ürünlere paylaştırılması fikirleri geçiyor. Bunlar eşdeğer değildir. Hangisinin kullanılacağı seçilmedi; S-002 bunu izler.

## Tasarım sınırları

- Makine kartını canvas üzerinde taşımak üretim maliyeti veya lojistik avantajı yaratır mı, belirlenmedi.
- Bir makinenin reçetesi değiştirilince stoklara ve çalışan işlere ne olur, belirlenmedi.
- Makine kurma bedelinin malzeme olduğu K-011 ile seçildi; miktarlar dengelenmedi. Gruptaki makine sayısını artırmanın bedeli belirlenmedi.
- “İstediği kadar tesis kurabilmek” yönü kaynak ve altyapıdan bağımsız sınırsız üretim anlamına gelmez.

İlişkiler: [[Tasarım/Prosesler Kalite ve Yan Ürünler]], [[Tasarım/Bölgeler ve Lojistik]], [[Tasarım/Arayüz ve Büyük Ağ Yönetimi]].
