# İlerleme ve Açılışlar

**Son güncelleme:** 21.09.2026  
**Sahibi:** Oyun Tasarımı  
**İlgili belgeler:** [Vizyon ve kapsam](01_VIZYON_VE_KAPSAM.md), [Ana oynanış döngüsü](02_ANA_OYNANIS_DONGUSU.md), [Açık konular](05_ACIK_KONULAR.md), [Ürünler ve tarifler](06_URUNLER_VE_TARIFLER.md)

## Dünya ilerlemesi

- Dünya, elle tasarlanmış ve birbirine bağlanan alanlardan oluşur.
- Alanlar ayrı senaryo, ekonomi veya lojistik bölgesi değildir; aynı kalıcı
  üretim ağının parçalarıdır.
- Oyuncu, komşu alanların şehir uzmanlığını, kaynaklarını ve fabrika
  imkânlarını açmadan önce görebilir.
- Yeni alan para yatırımıyla açılır ve oyuncu dallanan seçenekler arasından
  genişleme yönünü belirler.
- Açılan eski alanlar çalışmaya devam eder; ürünler alanlar arasında özel bir
  mesafe veya gateway cezası olmadan taşınabilir.

## Şehir ilerlemesi

- Şehirler dört sabit gelişim kademesine sahiptir.
- Her şehir harita tarafından belirlenen ve baştan görülebilen tek bir kalıcı
  uzmanlık ailesine sahiptir.
- Her şehirde ortak ürün talepleri ile uzmanlık talepleri birlikte bulunur.
- Birinci kademede üç aktif ürün talebi vardır. Her yeni kademede bir yeni
  talep eklenir ve dördüncü kademede toplam altı aktif talebe ulaşılır.
- Eski talepler kapanmaz; mevcut taleplerin `Demand Rate` değeri de şehir
  geliştikçe büyüyebilir.
- Kademe atlamak için hem ortak hem uzmanlık taleplerinin sürdürülebilir biçimde
  karşılanması gerekir.
- Kazanılan şehir kademesi tedarik kesildiğinde geri alınmaz.

## Fabrika ilerlemesi

- Kaynak çıkarma noktalarının türü haritadaki kaynağa bağlıdır.
- Genel fabrika arsaları uzmanlık sınıfına sahip değildir.
- Bir fabrikaya araştırması açılmış herhangi bir üretim node'u kurulabilir.
- Her üretim node'u bir slot kullanır; bağlantılar slot tüketmez.
- Fabrikalar para yatırımıyla sınırlı sayıda genişletilebilir.
- Her fabrikanın sert bir maksimum node slotu vardır. Daha fazla kapasite için
  yeni fabrika arsası kullanılmalıdır.

## Araştırma ilerlemesi

- Teknoloji ağacı sanayi dallarına ayrılır ve oyuncu dal önceliğini seçer.
- Erken ve orta araştırmalar az sayıda ortak, kademeli Research Pack kullanır.
- İleri uzmanlık teknolojileri ortak pack'lere ek olarak dala özel Research
  Pack isteyebilir.
- İleri teknolojiler önceki ortak pack'leri kullanmaya devam edebilir; eski
  araştırma hatları geçersizleşmez.
- `Research Campus`, pack'lerin taşındığı özel tüketim tesisidir; oyuncunun
  tasarladığı ayrı bir iç node ekranına sahip değildir.

## Ana hedef

- Yeterli dünya ve teknoloji ilerlemesinden sonra çok aşamalı final endüstri
  projesi açılır.
- Aşamalar farklı ürün ve sanayi ailelerinden teslimat hedefleri ister;
  tamamlanan aşama kalıcıdır.
- Son aşamanın tamamlanması ana oyun için başarı koşuludur.
- Oyuncu başarıdan sonra aynı dünyada sandbox olarak devam edebilir.

## Büyük açılış kabul koşulları

Her yeni büyük açılış için şu sorular yanıtlanmalıdır:

1. Oyuncu daha önce yapamadığı neyi yapabilecek?
2. Hangi yeni kaynak, talep, fabrika kararı veya üretim ilişkisi oluşacak?
3. Açılış mevcut üretim ve lojistik ağını nasıl yeniden değerli kılacak?
4. Yeni karmaşıklık oyuncuya anlamlı bir planlama kararı veriyor mu?
5. Aynı işlev daha az node, ürün veya kural ile sağlanabilir mi?
