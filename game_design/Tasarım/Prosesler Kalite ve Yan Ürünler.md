---
tur: sistem
durum: yon-olarak-olumlu
guncelleme: 2026-10-20
---
# Prosesler, kalite ve yan ürünler

## Tasarım amacı

Aynı ürüne giden yöntemlerin farklı sonuçlar üretmesi hedefleniyor. Kullanıcı bu fikri “çok güzel fikir” diye karşılamıştır.

**K-007 ilk taslak durumu:** [[Tasarım/Ürün ve Üretim Ağı]] kapsamında **kalite sınıfları (A/B/C) şu aşamada kapsam dışı bırakılmıştır**. Alternatif yöntemler olarak `13. Dişli` (CNC ile Çelik Çubuktan vs. Dökümhane ile Pik Demirden) ve `17. Gövde` (Pres ile Çelik Levha + Bağlantı Elemanından vs. Dökümhane ile Pik Demirden) seçilmiş; `Torna` ve `CNC` işlemlerinden çıkan `16. Metal Talaşı` yan ürününün `Çelik Fırını`nda geri kazanılması ilk taslağa dahil edilmiştir. Sayısal girdi/çıktı ve hız değerleri henüz sabitlenmemiştir.

Makine kartları seçildiği için prosesler soyut bağımsız kartlar olmak zorunda değildir. Bir yöntem bir veya birden fazla makine kartının reçeteleriyle kurulabilir.

## Örnek: dişli üretimi

| Yöntem | Örnek zincir | Avantaj | Bedel |
|---|---|---|---|
| Talaşlı imalat | Çelik çubuk → CNC → dişli | Yüksek hassasiyet/kalite | Daha düşük kapasite, talaş |
| Döküm ve son işleme | Ergitme → döküm → taşlama → dişli | Yüksek kapasite | Ek süreçler, farklı çıktı kalitesi |
| Dövme ve son işleme | Dövme → son işleme → dişli | Daha az malzeme kaybı olasılığı | Özel altyapı ve işlem ihtiyacı |

Kaynak konuşmadaki 10/dk A kalite ve 30/dk B kalite karşılaştırması bir denge örneğidir. Endüstriyel doğruluk iddiası veya kabul edilmiş üretim verisi değildir. “Isıl işlem B'yi A'ya çıkarır” fikri de basitleştirilmiş oyun önerisidir; gerçek parçanın bütün kalite özelliklerini tek işlemle iyileştirme garantisi değildir.

## Kalite/spesifikasyon önerisi

Araştırma veya ana proje bazen herhangi bir ürün yerine belirli özellikte ürün isteyebilir. Örnekler: yüksek hassasiyetli dişli, belirli saflıkta kimyasal, belirli bileşimde alaşım.

Basit A/B/C sınıfları bir seçenek olarak önerilmiş; kesin sınıf sayısı seçilmemiştir. Saflık, dayanım ve hassasiyetin tek bir kalite eksenine sığdırılıp sığdırılmayacağı açık bir sorudur. Gereğinden fazla ürün varyantı, port ve stok karmaşası yaratabilir.

Kaliteli ürünün düşük kalite talebini karşılayıp karşılamadığı, girdilerin karışması ve kalite dönüşüm kaybı belirlenmemiştir. İlk prototipte mümkün olan en az sayıda varyantla kararın eğlenceli olup olmadığı test edilmelidir.

## Yan ürün ekonomisi önerisi

Bir işlemin artığı başka bir işlemin girdisi olabilir. CNC talaşı tekrar metal üretimine dönebilir; farklı proseslerin çok çıktılı olması endüstriler arasında bağ kurabilir. Ancak her yan ürün için faydalı kullanım bulunduğu henüz gösterilmemiştir.

Yan ürünün tasarım değeri, oyuncuya geri kazanım yatırımı ve kaynak tasarrufu arasında seçim sunmasıdır. Her hat için zorunlu atık temizleme işi yaratırsa tekrar yüküne dönüşebilir.

### Açık davranışlar

- Yan ürün deposu dolunca ana ürün üretimi duracak mı?
- Kontrollü boşaltma/bertaraf seçeneği bulunacak mı; bedeli ne?
- Geri kazanım aynı kaynağı sonsuz çoğaltan döngüler yaratmadan nasıl dengelenecek?
- Atık taşıma da bölgesel lojistik kapasitesi kullanacak mı?
- Kalite ve yan ürünler ilk prototipte birlikte mi, ayrı deneylerde mi sınanacak?

## Yöntemlerin birbirini geçersiz kılmaması

Yeni yöntemin her ölçütte daha iyi olması önerilen karar derinliğini azaltır. Bir yöntemin yüksek kapasite, diğerinin malzeme verimi veya uygun kalite nedeniyle seçilebilmesi hedeflenir. Bu hedefin gerçekleştiği oynanışla henüz doğrulanmadı.

Bkz. [[Tasarım/Prototip ve Doğrulama]], [[Tasarım/Makine Kartları]].
