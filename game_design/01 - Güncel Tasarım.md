---
tur: tasarim-ozeti
durum: karma
guncelleme: 2026-10-20
---
# Güncel tasarım

## Açıkça seçilmiş temel

Oyuncu, sonsuz bir çalışma alanı üzerinde node tabanlı üretim kartları yerleştirir ve bunları bağlar. Kartlar **makineleri** temsil eder. Soyut proses kartı yaklaşımı yerine makine kartı yaklaşımı seçilmiştir. Kart başına makine sayısı henüz kararlaştırılmamıştır.

Araştırma ekonomisi için **B — gerçek ürünleri doğrudan tüketen araştırmalar** seçilmiştir. Ayrı bilim paketi üretmek yerine endüstriyel ürünler araştırmada kullanılır. Deney süreleri, tampon kuralları ve laboratuvar paylaşımı ayrıntıları tasarım önerisidir.

Bu seçimlerin dayanakları [[Yönetim/Karar Defteri]] ve [[Kaynaklar/02 - Bu Sohbetteki Kararlar]] içindedir.

**Üretim modeli de seçildi (K-005):** Reçete girdi/çıktı miktarlarını ve gereken işi tanımlar. Süre, gereken işin uygun makinenin saniyelik işleme hızına bölünmesiyle bulunur. Küçük giriş/çıkış tamponları kullanılır; bütün girdiler ve çıktı alanı hazırsa işlem başlar. Girdiler başlangıçta tüketilir, çıktılar iş tamamlanınca oluşur. Tampon boyutları ve makine gruplama açıktır. Ayrıntılar [[Tasarım/Makine Kartları#Onaylı üretim modeli — K-005|Makine kartları]] notundadır.

**Temel ürün paylaşımı seçildi (K-006):** Bir çıkış aynı ürünü kabul edebilen bağlı tüketiciler arasında otomatik eşit paylaşılır. Giriş tamponu dolu tüketicinin payı diğerlerine gider. Hepsi doluysa ürün çıkış tamponunda birikir; yeni çevrime yer kalmadığında üretim bekler. Oyuncunun hat başına oran veya hız girmesi gerekmez. Ayrıntılar [[Tasarım/Ana Proje ve Ürün Dağıtımı#Onaylı otomatik eşit paylaşım — K-006|Ürün dağıtımı]] notundadır.

**24 ürünlük üretim ağı ve 9 araştırmalık teknoloji ağacı ilk taslağı kaydedildi (K-007):** 5 katmanlı 24 ilişkili ürün, bunları işleyen makine türleri (`Ergitme Fırını`, `Çelik Fırını`, `Haddehane`, `Pres`, `Torna`, `CNC`, `Dökümhane`, `Tel Çekme / Sarım Makinesi`, `Montaj İstasyonu`) ve 9 araştırmalık teknoloji ağacı (`A-01` – `A-09`) ilk taslak olarak belirlendi. Kalite sistemi (A/B/C) şu aşamada kapsam dışı bırakıldı. Sayısal reçete miktarları ve montaj makinelerinin alt ayrımı açıktır. Ayrıntılar [[Tasarım/Ürün ve Üretim Ağı]] ve [[Tasarım/Teknoloji Ağacı]] notlarındadır.

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
- Makine kurma maliyeti, para/satış ekonomisinin olup olmayacağı.
- Enerji ve özel proses altyapısının kapsamı.
- Araştırma değiştirme, ortak stok ve varsa ileri öncelik araçları; temel paylaşım K-006 ile seçildi.
- Nihai hedef, ilk ürün listesi ve ilk prototipin kesin kapsamı.

## Yetki ve doğrulama sınırı

İlk Godot üretim prototipi oluşturuldu: K-005 ve K-006 küçük bir örnek ağda uygulanıp 32 simülasyon kontrolü ve arayüz smoke testiyle doğrulandı. Örnek besleyici, test tüketicileri, tampon boyutları ve tek işli kartlar geçici uygulama sınırlarıdır; yeni tasarım onayı sayılmaz. Kapsam ve kanıt [[Yönetim/Uygulama Durumu]] içinde tutulur. Sayısal örnekler nihai denge değerleri değildir. Kaynak konuşmadaki rakip oyun iddiaları güncel olarak doğrulanmamıştır. Eski Git geçmişi güncel ürün kararı kaynağı değildir.

Sıradaki tartışma için [[Yönetim/Açık Sorular]]; test için [[Tasarım/Prototip ve Doğrulama]].
