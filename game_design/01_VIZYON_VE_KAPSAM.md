# Vizyon ve Kapsam

**Son güncelleme:** 21.09.2026  
**Sahibi:** Oyun Tasarımı  
**İlgili belgeler:** [Ana oynanış döngüsü](02_ANA_OYNANIS_DONGUSU.md), [İlerleme ve açılışlar](03_ILERLEME_VE_ACILISLAR.md), [Tasarım ilkeleri](04_TASARIM_ILKELERI.md), [Ürünler ve tarifler](06_URUNLER_VE_TARIFLER.md)

## Güncel kararlar

- Oyun, node tabanlı üretim ve lojistik yönetim oyunudur.
- Oyuncu, aynı kalıcı dünyada fabrikalar ve lojistik bağlantıları kurarak
  şehirlerin taleplerini karşılayan büyüyen bir sanayi şirketini yönetir.
- Dünya haritası ile fabrika içi üretim ekranı ayrı katmanlardır.
- Asıl tasarım derinliği, fabrikaların içindeki çok aşamalı, dallanan ve
  birleşen üretim zincirlerinden gelir.
- Lojistik üretimi destekler; fabrika içi üretimden daha ayrıntılı bir yönetim
  alanına dönüşmez.
- Şehir teslimatları para kazandırır. Para fabrika, kapasite, lojistik ve yeni
  alan yatırımlarında kullanılır.
- Araştırma, üretilip `Research Campus`a taşınan Research Pack'lerle ilerler.
- Ana oyun, farklı sanayi kollarını kullanan çok aşamalı final endüstri
  projesiyle tamamlanır; dünya daha sonra sandbox olarak devam eder.
- Arayüz dili İngilizce, tasarım kayıtları Türkçedir.

## Aktif kapsam

- Elle tasarlanmış ve para yatırımıyla dallanarak açılan dünya alanları.
- Yeni şehirler, kaynak noktaları, madenler ve genel fabrika arsaları.
- Oyuncunun kurduğu fabrika içi üretim node ağları.
- Şehirlerde ortak ürün talepleri ve harita tarafından belirlenen uzmanlık
  talepleri.
- Fiziksel ürün talebi, sürekli `Demand Rate` ve teslimata dayalı gelir.
- Tek ürün taşıyan ve `Transfer Rate` ile sınırlanan tesisler arası lojistik.
- Ortak kademeli Research Pack'ler ve ileri aşamada dala özel pack'ler.
- Sanayi dallarına ayrılan teknoloji ağacı.
- Gıda, yapı malzemeleri, mekanik ürünler ve ileride seçilecek diğer sanayi
  aileleri.

## Kapsam dışı

- Beklemeyi ana ilerleme biçimi yapan idle/incremental yapı.
- Tek tek araç, sefer, trafik, rota uzunluğu veya seyahat süresi yönetimi.
- Lojistikte fiziksel mesafe hesabı.
- Arz fazlasına göre değişen dinamik piyasa fiyatı.
- Fabrika içinde node mesafesi, kablo uzunluğu veya fiziksel sıkışıklık
  bulmacası.
- İşçi, işe alma, açlık veya nüfus mikro yönetimi.
- Her gerçek endüstriyel ara parçayı zorunlu ürün olarak modelleme.
- Çevrimiçi rekabet ve canlı servis sistemleri.
