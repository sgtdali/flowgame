---
tur: tasarim-ozeti
durum: karma
guncelleme: 2026-10-23
---
# Güncel tasarım

## Açıkça seçilmiş temel

Oyuncu, sonsuz bir çalışma alanı üzerinde node tabanlı üretim kartları yerleştirir ve bunları bağlar. Kartlar **makineleri** temsil eder. Soyut proses kartı yaklaşımı yerine makine kartı yaklaşımı seçilmiştir. Kart başına makine sayısı henüz kararlaştırılmamıştır.

**Araştırma kademeli laboratuvarlarla yapılır (K-008, K-001'in yerine geçti):** Her laboratuvar araştırmadan bağımsız olarak hep aynı ürünleri tüketir ve kendi kademesinin araştırma puanını üretir. Puanlar depoda birikir; araştırmanın fiyatı kademe puanlarıyla yazılır. Araştırma değiştirmek laboratuvar hatlarını bozmaz. Ayrıntılar [[Tasarım/Araştırma Ekonomisi]] notundadır.

Bu seçimlerin dayanakları [[Yönetim/Karar Defteri]] ve [[Kaynaklar/02 - Bu Sohbetteki Kararlar]] içindedir.

**Üretim modeli de seçildi (K-005):** Reçete girdi/çıktı miktarlarını ve gereken işi tanımlar. Süre, gereken işin uygun makinenin saniyelik işleme hızına bölünmesiyle bulunur. Küçük giriş/çıkış tamponları kullanılır; bütün girdiler ve çıktı alanı hazırsa işlem başlar. Girdiler başlangıçta tüketilir, çıktılar iş tamamlanınca oluşur. Tampon boyutları ve makine gruplama açıktır. Ayrıntılar [[Tasarım/Makine Kartları#Onaylı üretim modeli — K-005|Makine kartları]] notundadır.

**Temel ürün paylaşımı seçildi (K-006):** Bir çıkış aynı ürünü kabul edebilen bağlı tüketiciler arasında otomatik eşit paylaşılır. Giriş tamponu dolu tüketicinin payı diğerlerine gider. Hepsi doluysa ürün çıkış tamponunda birikir; yeni çevrime yer kalmadığında üretim bekler. Oyuncunun hat başına oran veya hız girmesi gerekmez. Ayrıntılar [[Tasarım/Ana Proje ve Ürün Dağıtımı#Onaylı otomatik eşit paylaşım — K-006|Ürün dağıtımı]] notundadır.

**24 ürünlük üretim ağı ve 9 araştırmalık teknoloji ağacı ilk taslağı kaydedildi (K-007):** 5 katmanlı 24 ilişkili ürün, bunları işleyen makine türleri (`Ergitme Fırını`, `Çelik Fırını`, `Haddehane`, `Pres`, `Torna`, `CNC`, `Dökümhane`, `Tel Çekme / Sarım Makinesi`, `Montaj İstasyonu`) ve 9 araştırmalık teknoloji ağacı (`A-01` – `A-09`) ilk taslak olarak belirlendi. Kalite sistemi (A/B/C) şu aşamada kapsam dışı bırakıldı. Sayısal reçete miktarları ve montaj makinelerinin alt ayrımı açıktır. Ayrıntılar [[Tasarım/Ürün ve Üretim Ağı]] ve [[Tasarım/Teknoloji Ağacı]] notlarındadır.

**Reçete seçimi (K-009, K-016):** Girdileri farklı reçeteli makinelerde (pres, tel sarım, montaj) oyuncu reçete seçmez; makine bağlanan ürüne göre üretir. Aynı girdiden farklı ürün yapan makinelerde ve fırınlarda simgeli reçete ekranından ürün seçilir.

**Makine kartı gösterimi (K-015):** Ürünler kartta çerçeveli kutularda adetle görünür; seçili reçetenin girdileri boş kutuda saydamdır; üretilen ürün çıktı kutusundan ayrı gösterilir.

**Hammadde sınırlıdır (K-010):** Madenler oyun başında birer adet kurulabilir.

**Envanter, malzemeli kurulum ve el üretimi (K-011, K-012):** Oyuncu ürünleri ve kurulmamış makineleri bir envanterde taşır. Makineler malzemeyle üretilir ve envanterden tuvale yerleştirilir; kaldırılan makine envantere döner. Üretim envantere kendiliğinden geçmez; oyuncu karttaki çıktıyı veya Depo'daki ürünü isterse alır. El üretimi süreli bir kuyruktur; hammadde el ile çıkarılamaz, oyuncu başlangıç kitiyle başlar. Alttaki çubuk 10 yuvalı hızlı erişimdir; envanterin tamamı ayrı bir pencerededir ve oyuncu istediği öğeyi hızlı erişime sabitler. Oyun boş tuvalle başlar (K-013). Oyuncu envanterdeki ürünü uygun bir makinenin girişine elle koyabilir; ağa bağlı olmayan makine de böyle çalışır (K-014). Ayrıntılar [[Tasarım/Envanter ve El Üretimi]] notundadır.

## Üzerinde çalışılan yön

Kullanıcı, alternatif prosesler fikrine olumlu yaklaşmıştır. Aynı ürünün farklı yöntemlerle üretilmesi; kapasite, kaynak verimi, kalite ve yan ürünler üzerinden kararlar doğurabilir. Bu yön olumlu karşılanmıştır; bütün alt kurallar onaylanmış değildir.

Sonsuz canvas'ın sınırsız kaynak ve zahmetsiz kapasite artışına dönüşmesi bir tasarım sorunudur. Buna çözüm olarak ekonomik bölgeler ve kapasitesi sınırlı bölgeler arası taşımacılık önerilmiştir. Kullanıcı bunu “fena fikir değil” diye karşılamıştır; kesin bölge modeli, kaynak limitleri ve taşıma kuralları açık kalmıştır.

Ana proje, araştırma ve fabrika genişlemesinin ortak ürünleri tüketmesi önerilmiştir. Hangi nihai projenin yapılacağı bilinmiyor. Kaynak metinde daha önce konuşulduğu belirtilen dört hikâye senaryosunun içerikleri bulunmuyor.

## Hedeflenen oyuncu deneyimi

Oyuncu yalnızca daha fazla kart yerleştirerek değil, üretim yöntemini, kapasite paylaşımını ve kaynak erişimini değiştirerek sorun çözer. Büyüme yeni yetenekler ve daha büyük hedeflerle teşvik edilir. Zorunlu süre sınırı koymama ve yavaş üretimle de ilerleme önerileri bu yönü destekler.

## Henüz seçilmemiş olanlar

- Tek makine veya aynı tip makine grubu olarak kart ölçeği.
- Kalite sistemi: sınıf sayısı, kabul kuralları ve dönüşüm yöntemleri.
- Bölge edinme, kaynak kapasitesini artırma ve taşıma yatırımı bedelleri.
- Para/satış ekonomisinin olup olmayacağı. Makine kurma bedelinin malzeme olduğu K-011 ile seçildi; miktarlar dengelenmedi.
- Kurulum sınırlarının araştırmayla artıp artmayacağı.
- Enerji ve özel proses altyapısının kapsamı.
- İleri öncelik araçları; temel paylaşım K-006 ile, araştırma değiştirme ve puan deposu K-008 ile seçildi.
- Nihai hedef, ilk ürün listesi ve ilk prototipin kesin kapsamı.

## Yetki ve doğrulama sınırı

Godot prototipi K-002 – K-016 kararlarını uyguluyor ve otomatik testlerle (üretim, envanter, otomatik reçete, kart görselleri) ve pencereli smoke testiyle doğrulanıyor. Başlangıç ağı, sayılar, tampon boyutları, kurulum bedelleri ve tek işli kartlar geçici uygulama seçimleridir; yeni tasarım onayı sayılmaz. Kapsam ve kanıt [[Yönetim/Uygulama Durumu]] içinde tutulur. Oynanış dengesi ve büyük ağ performansı doğrulanmadı. Kaynak konuşmadaki rakip oyun iddiaları güncel olarak doğrulanmamıştır. Eski Git geçmişi güncel ürün kararı kaynağı değildir.

Sıradaki tartışma için [[Yönetim/Açık Sorular]]; test için [[Tasarım/Prototip ve Doğrulama]].
