# Tasarım İlkeleri

**Son güncelleme:** 21.09.2026  
**Sahibi:** Oyun Tasarımı  
**İlgili belgeler:** [Vizyon ve kapsam](01_VIZYON_VE_KAPSAM.md), [Ana oynanış döngüsü](02_ANA_OYNANIS_DONGUSU.md), [İlerleme ve açılışlar](03_ILERLEME_VE_ACILISLAR.md), [Ürünler ve tarifler](06_URUNLER_VE_TARIFLER.md)

## Güncel kararlar

- Üretim zinciri tasarlamak oyunun ana derinliğidir; yeni ürünler dallanma,
  birleşme, kapasite veya araştırma kararı yaratmalıdır.
- Yeni bir node yalnızca farklı görünmek veya zinciri uzatmak için eklenmez.
- Gerçek sanayide bulunan her ara parça oyunda ayrı ürün olmak zorunda değildir.
- Bir ürünün şehir talebi, Research Pack üretimi, ileri tarif veya final proje
  içinde açıklanabilir bir görevi olmalıdır.
- Fabrika içi karmaşıklık node akışından gelir; ekran mesafesi, kablo uzunluğu
  veya fiziksel sıkıştırma üretimi etkilemez.
- Genel fabrikalar serbest üretim düzenine izin verir; sonlu node slotu bütün
  üretimi tek fabrikada toplamanın önüne geçer.
- Lojistik okunabilir ve sınırlı kalır: bağlantı başına tek ürün, tek temel
  performans değeri olarak `Transfer Rate`, mesafe ve araç mikro yönetimi yok.
- Şehirler sınırsız satış noktaları değildir; fiziksel `Demand Rate` üstünde
  ürün tüketmez.
- Eski üretim yatırımları mümkün olduğunca değerini korur. Şehir talepleri
  birikir, ileri araştırmalar eski ortak pack'leri kullanabilir.
- Yeni dünya alanı yalnızca daha fazla boş yer değil; yeni kaynak, şehir
  uzmanlığı veya fabrika planı getirmelidir.
- Ayrıntı seviyesi üretim tarafında yüksek, lojistik tarafında kontrollü
  tutulur.
- Öngörülemeyen dağıtım, oran ve denge ayrıntıları makro tasarımı bloke etmez;
  prototip ve ekonomi modellemesinde kararlaştırılır.
- Gelecek fikri, kullanıcı onayı olmadan kararlaştırılmış kapsam gibi
  sunulamaz.

## Kritik bağlantılar ve kısıtlar

- Oyun idle bekleme veya pasif sayı artışı etrafında kurulamaz.
- Ürün çeşitliliği, oyuncuyu gerçek karar vermeyen uzun reçetelere boğamaz.
- Lojistik, üretim tasarımını gölgede bırakacak araç ve rota simülasyonuna
  dönüşemez.
- Şehir gelişimi kaybedilen ilerleme cezasına dönüşemez.
- İşçi, açlık ve nüfus mikro yönetimi ürün talebi sistemi üzerinden geri
  getirilemez.
- Final proje, yalnızca büyük miktarda tek ürün isteyen bir para/kapasite
  kontrolü olamaz; farklı sanayi kollarını anlamlı biçimde birleştirmelidir.
