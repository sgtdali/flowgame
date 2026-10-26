---
tur: tasarim-ozeti
durum: karma
guncelleme: 2026-10-26
---
# Güncel tasarım

## Açıkça seçilmiş temel

Oyuncu, sonsuz bir çalışma alanı üzerinde node tabanlı üretim kartları yerleştirir ve bunları bağlar. Kartlar **makineleri** temsil eder. Soyut proses kartı yaklaşımı yerine makine kartı yaklaşımı seçilmiştir. Kart başına makine sayısı henüz kararlaştırılmamıştır.

**Araştırma kademeli laboratuvarlarla yapılır (K-008, K-001'in yerine geçti):** Her laboratuvar araştırmadan bağımsız olarak hep aynı ürünleri tüketir ve kendi kademesinin araştırma puanını üretir. Puanlar depoda birikir; araştırmanın fiyatı kademe puanlarıyla yazılır. Araştırma değiştirmek laboratuvar hatlarını bozmaz. Ayrıntılar [[Tasarım/Araştırma Ekonomisi]] notundadır.

Bu seçimlerin dayanakları [[Yönetim/Karar Defteri]] ve [[Kaynaklar/02 - Bu Sohbetteki Kararlar]] içindedir.

**Üretim modeli de seçildi (K-005):** Reçete girdi/çıktı miktarlarını ve gereken işi tanımlar. Süre, gereken işin uygun makinenin saniyelik işleme hızına bölünmesiyle bulunur. Küçük giriş/çıkış tamponları kullanılır; bütün girdiler ve çıktı alanı hazırsa işlem başlar. Girdiler başlangıçta tüketilir, çıktılar iş tamamlanınca oluşur. Tampon boyutları ve makine gruplama açıktır. Ayrıntılar [[Tasarım/Makine Kartları#Onaylı üretim modeli — K-005|Makine kartları]] notundadır.

**Temel ürün paylaşımı seçildi (K-006):** Bir çıkış aynı ürünü kabul edebilen bağlı tüketiciler arasında otomatik eşit paylaşılır. Giriş tamponu dolu tüketicinin payı diğerlerine gider. Hepsi doluysa ürün çıkış tamponunda birikir; yeni çevrime yer kalmadığında üretim bekler. Oyuncunun hat başına oran veya hız girmesi gerekmez. Ayrıntılar [[Tasarım/Ana Proje ve Ürün Dağıtımı#Onaylı otomatik eşit paylaşım — K-006|Ürün dağıtımı]] notundadır.

**24 ürünlük üretim ağı ve 9 araştırmalık teknoloji ağacı ilk taslağı kaydedildi (K-007):** 5 katmanlı 24 ilişkili ürün, bunları işleyen makine türleri (`Ergitme Fırını`, `Çelik Fırını`, `Haddehane`, `Pres`, `Torna`, `CNC`, `Dökümhane`, `Tel Çekme / Sarım Makinesi`, `Montaj İstasyonu`) ve 9 araştırmalık teknoloji ağacı (`A-01` – `A-09`) ilk taslak olarak belirlendi. Kalite sistemi (A/B/C) şu aşamada kapsam dışı bırakıldı. Sayısal reçete miktarları ve montaj makinelerinin alt ayrımı açıktır. Ayrıntılar [[Tasarım/Ürün ve Üretim Ağı]] ve [[Tasarım/Teknoloji Ağacı]] notlarındadır.

**Tek reçete ve farklı ürün ilkesi (K-017):** Her ürünün tek bir ana üretim tarifi vardır; aynı ürün için alternatif tarifler tanımlanmaz. Farklı yöntemler veya hammaddeler (örneğin döküm vs talaşlı imalat, pik demir vs çelik) aynı işlev grubunda olsalar bile farklı ürünler oluşturur (`Cast Iron Gear` vs `Steel Gear`, `Cast Iron Housing` vs `Steel Housing`). Demir ergitme kömürsüz yapılırken, çelik ergitme kömür katkısıyla çalışır; demir kolu levha, çubuk ve boru gibi ara ürünlerle genişletilmiştir. Ayrıntılar [[Tasarım/Ürün ve Üretim Ağı]] notundadır.

**Ana proje: Son Fabrika ve Kurucu Çekirdek (K-018):** Oyuncu endüstriyel çöküşten sonra kalan son otomatik fabrikayı yönetir ve sanayiyi yeniden başlatacak Kurucu Çekirdek'i üretir. Çekirdek ayrı bir üründür; beş endüstri modülünden (Metalürji, Hassas Mekanik, Elektrik, Elektronik, Otomasyon) montajla yapılır ve ana proje terminaline teslim edilir. Final proje her modülden çok sayıda ister ve oyuncuyu fabrikayı genişletmeye zorlar. Kimya modülü ileride; Exodus senaryosu fikir olarak saklanıyor. Ayrıntılar [[Tasarım/Ana Proje ve Ürün Dağıtımı]] notundadır.

**Kollar birbirine bağlı (K-019):** Ürün kolları bağımsız değildir; bazı reçeteler iki koldan malzeme ister.

**Makine üreten makineler (K-020):** Elle üretilen makine kartlarını üreten kartlar da olacak; oyuncu el üretimini zamanla otomatikleştirir. Tasarımı henüz yok.

**Makine düzeni (K-022):** Torna ve CNC tek Tezgâh Atölyesi oldu, çelik fırını Ergitme Fırını'na katıldı; montaj dört makineye (Mekanik, Elektrik, Elektronik, Robotik) ayrıldı, modüller Modül Tesisi'nde yapılır.

**Kurulum bedelleri ve kit (K-023):** Başlangıç makineleri demirden kurulur; her makine yalnız açıldığı anda yapılabilen şeyleri ister.

**Makine Fabrikası (K-024):** Makineleri kurulum bedelinden üreten kart; çıktı kartta ya da bağlı depoda birikir.

**63 araştırma (K-025):** 9 kolda 63 araştırma; maden sınırı araştırmayla artar, verim ve kapasite araştırmaları var, K4 puanı ve Laboratuvar 4 eklendi. Ayrıntılar [[Tasarım/Teknoloji Ağacı]] notundadır.

**Beş modülün reçete taslağı (K-021):** Ağ sondan başa kuruldu ve 55 ürüne çıktı; her ürün bir modüle, laboratuvara ya da kuruluma gider. Adetler ilk tahmindir. Ayrıntılar [[Tasarım/Ürün ve Üretim Ağı]] notundadır.

**Reçete seçimi (K-009, K-016):** Girdileri farklı reçeteli makinelerde (pres, tel sarım, montaj) oyuncu reçete seçmez; makine bağlanan ürüne göre üretir. Aynı girdiden farklı ürün yapan makinelerde ve fırınlarda simgeli reçete ekranından ürün seçilir.

**Makine kartı gösterimi (K-015):** Ürünler kartta çerçeveli kutularda adetle görünür; seçili reçetenin girdileri boş kutuda saydamdır; üretilen ürün çıktı kutusundan ayrı gösterilir.

**Hammadde sınırlıdır (K-010):** Madenler oyun başında birer adet kurulabilir. K-043 ve K-044 ile bu sınırı haritadaki dağlar belirliyor.

**Harita (K-043 – K-045):** Tuval, 500–600 kart alacak büyüklükte sınırlı bir haritadır. Her kaynaktan 3, toplam 12 dağ vardır; her maden ayrı bir dağa kurulur. Mesafe bilerek bedelsizdir, taşıma oyuncunun işi değildir. Haritada ormanlar, tepeler ve bir nehir süs olarak durur, hiçbir şeyi engellemez. Ayrıntılar [[Tasarım/Bölgeler ve Lojistik]] notundadır.

**Envanter, malzemeli kurulum ve el üretimi (K-011, K-012):** Oyuncu ürünleri ve kurulmamış makineleri bir envanterde taşır. Makineler malzemeyle üretilir ve envanterden tuvale yerleştirilir; kaldırılan makine envantere döner. Üretim envantere kendiliğinden geçmez; oyuncu karttaki çıktıyı veya Depo'daki ürünü isterse alır. El üretimi süreli bir kuyruktur; hammadde el ile çıkarılamaz, oyuncu başlangıç kitiyle başlar. Alttaki çubuk 10 yuvalı hızlı erişimdir; envanterin tamamı ayrı bir pencerededir ve oyuncu istediği öğeyi hızlı erişime sabitler. Oyun bir Demir madeni ve bir Ergitme fırını kurulu başlar (K-033, K-013'ün yerine). Oyuncu envanterdeki ürünü uygun bir makinenin girişine elle koyabilir; ağa bağlı olmayan makine de böyle çalışır (K-014). Envanter ve el üretimi tek penceredir; pencere seçilen öğeyi girdileri ve kullanıldığı yerlerle bir akış haritasında gösterir, reçetenin iş miktarı elle de makinede de aynıdır (K-026, K-028, K-029). Pencere sabit boyutlu, kuyruk en fazla 5 farklı öğe (K-031); bütün görselleri kullanıcının çizimleri (K-032). Ayrıntılar [[Tasarım/Envanter ve El Üretimi]] notundadır.

**Makine kartlarının görünümü (K-038 – K-042):** Kartta makine görseli 256 px'tir. Portlar durumu renkle gösteren 24 px'lik çemberlerdir: turuncu bağlı değil, yeşil akış var, kırmızı bağlı ama parça alamıyor. Malzeme kutuları çemberin 2 px içindedir. Kartın tamamı tek çerçevede, başlık çerçevenin içindedir; çerçeve görseli geçicidir. Ergitme fırını, Demir madeni ve Bakır madeni kullanıcının çizimleriyle ve hareketli parçalarıyla oyundadır. Ayrıntılar [[Tasarım/Makine Kartları]] notundadır.

**Görünüm ve dil (K-027, K-030):** Arayüz aydınlık Kum taşı paletindedir (bej tuval, kâğıt rengi kartlar, petrol yeşili ve bakır vurgu). Oyundaki bütün metinler İngilizcedir; başlıklarda Pixelify Sans, metinde Nunito kullanılır. Ayrıntılar [[Tasarım/Arayüz ve Büyük Ağ Yönetimi]] notundadır.

**Bağlantılar ve taşıma (K-034 – K-037):** Ürünler bağlantı boyunca gerçekten taşınır ve hedefe varınca sayılır; eşit paylaşım aynen geçerli (K-035). Bağlantılar 16 px'lik çok renkli bant olarak çizilir (K-034), üst üste binmez ve kartların etrafından dolaşır (K-036). Yollar büyük ağda da kasmayacak şekilde parça parça hesaplanır (K-037). Ayrıntılar [[Tasarım/Arayüz ve Büyük Ağ Yönetimi]] ve [[Tasarım/Ana Proje ve Ürün Dağıtımı]] notlarındadır.

## Üzerinde çalışılan yön

Kullanıcı, farklı üretim yöntemleri fikrine olumlu yaklaşmıştır. K-017 kararıyla bu durum aynı ürüne alternatif reçete vermek yerine, her yöntemin farklı bir ürün üretmesi (döküm dişli vs çelik dişli) şeklinde somutlaştırılmıştır. Bu ürünlerin hepsi K-021 ile bir modüle bağlandı; adet ve süre dengeleri açıktır.

Sonsuz canvas'ın sınırsız kaynak ve zahmetsiz kapasite artışına dönüşmesi bir tasarım sorunudur. Buna çözüm olarak ekonomik bölgeler ve kapasitesi sınırlı bölgeler arası taşımacılık önerilmiştir. Kullanıcı bunu “fena fikir değil” diye karşılamıştır; kesin bölge modeli, kaynak limitleri ve taşıma kuralları açık kalmıştır.

Ana proje, araştırma ve fabrika genişlemesinin ortak ürünleri tüketmesi önerilmiştir. Nihai proje K-018 ile Kurucu Çekirdek olarak seçildi; modül ve çekirdek adetlerinin dengesi açıktır.

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

Godot prototipi K-002 – K-045 kararlarının çoğunu uyguluyor ve otomatik testlerle (üretim, envanter, otomatik reçete, kart görselleri) ve pencereli smoke testiyle doğrulanıyor. Başlangıç ağı, sayılar, tampon boyutları, kurulum bedelleri ve tek işli kartlar geçici uygulama seçimleridir; yeni tasarım onayı sayılmaz. Kapsam ve kanıt [[Yönetim/Uygulama Durumu]] içinde tutulur. Oynanış dengesi ve gerçek kartlarla büyük ağ performansı doğrulanmadı. Kaynak konuşmadaki rakip oyun iddiaları güncel olarak doğrulanmamıştır. Eski Git geçmişi güncel ürün kararı kaynağı değildir.

Sıradaki tartışma için [[Yönetim/Açık Sorular]]; test için [[Tasarım/Prototip ve Doğrulama]].
