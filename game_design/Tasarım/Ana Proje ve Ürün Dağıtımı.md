---
tur: sistem
durum: karma
guncelleme: 2026-10-23
---
# Ana proje ve ürün dağıtımı

## Önerilen tüketim üçgeni

Aynı üretim çıktısı üç amaç için kullanılabilir:

- **Araştırma:** Yeni teknoloji ve üretim yeteneği açar.
- **Genişleme:** Yeni makineler ve altyapı kurarak gelecekteki kapasiteyi artırır.
- **Ana proje:** Oyuncunun somut uzun vadeli hedefine ilerleme sağlar.

Üçgenin iki ucu artık seçilmiş kurallara dayanıyor: araştırma laboratuvarları sürekli ürün tüketir (K-008), makine kurmak malzeme ister (K-011). Ana proje için kullanıcı kararı yoktur; prototipteki `Ana proje terminali` (A-09 sonrası, hassas aktüatör + PLC tüketir) yer tutucudur.

Bu model, ürünün değerini yalnızca satış fiyatına bağlamadan anlamlı tüketim yaratabilir. Ancak para veya satış ekonomisinin kesinlikle olmayacağı kararı verilmemiştir; kaynak konuşmada para gerekmeyen model asistan önerisidir.

## Örnek: elektrik motorları

Kaynak konuşmada 120 motor/dk üretimin 40/60/20 olarak üç amaca ayrılması örneklenmiştir. Bu tarihsel örnek, seçilmiş paylaşım kuralı değildir. K-006 ile temel paylaşım otomatik ve eşittir: üçünün de ürünü kabul edebildiği ve başka taşıma kısıtı olmadığı durumda ideal uzun dönem paylaşımı 40/40/40 olur. 40/60/20 gibi farklı gerçekleşen hızlar ancak tüketicilerin kabul durumları gibi koşullarla oluşabilir; oyuncuya oran girme zorunluluğu yoktur.

Araştırma, genişleme ve ana projenin aynı ürünleri kullanması tüketim üçgeni önerisidir. Bu tüketiciler arasında oyuncunun elle öncelik belirlemesi onaylanmadı. Temel otomatik paylaşımın üstünde hangi yönetim araçlarının bulunacağı ayrı bir tasarım konusudur.

## Onaylı otomatik eşit paylaşım — K-006

Oyuncu bağlantıları kurar; bağlantı başına oran veya hız girmek zorunda değildir. Bir üreticinin aynı ürün çıkışı, **o ürünü kabul edebilen bağlı tüketiciler arasında otomatik ve eşit paylaşılır**. Bu yerel çıkış paylaşımıdır; bütün ağın talebini küresel olarak optimize etme kararı değildir.

Giriş tamponu dolu tüketici dağıtıma katılmaz. Onun kullanamadığı pay, kabul edebilen diğer tüketicilere gider; boşa harcanmaz. Kabul edebilen tüketici kalmazsa ürün üreticinin çıkış tamponunda birikir. Çıkışta yeni çevrimin ürünlerine yer kalmayınca K-005 gereğince yeni üretim çevrimi başlamaz.

| Örnek durum: 10 dişli/dk, iki tüketici | Araştırmaya | Montaja |
|---|---:|---:|
| İkisi de kabul edebiliyor | 5/dk | 5/dk |
| Araştırmanın giriş tamponu dolu | 0/dk | 10/dk |
| İkisinin de giriş tamponu dolu | 0/dk | 0/dk |

Bu hızlar kesintisiz üretim ve başka taşıma kısıtı bulunmaması varsayımıyla uzun dönem örnekleridir. Tekil ürünlerin sırayla dağıtımı, kesirlerin hesabı ve eşitliğin hangi zaman aralığında korunacağı henüz belirlenmedi. Bağlantı sırası kalıcı gizli öncelik yaratmamalı; bunu sağlayan algoritma ayrıca seçilecektir.

**Açık sınırlar:** Bağlantı hız/gecikmesi, bir tüketicinin birden fazla üreticiden beslenmesi ve bölgesel kapasiteyle etkileşim ayrı tasarım konularıdır. Elle öncelik veya ağırlık verme özelliği onaylanmadı. İleri otomatik dağıtım teknolojileri önceki önerilerde geçer; temel otomatik eşit dağıtım artık teknoloji açılmasını bekleyen bir yetenek değildir.

Dayanak: [[Yönetim/Karar Defteri#K-006 — Otomatik eşit ürün paylaşımı|K-006]], [[Kaynaklar/02 - Bu Sohbetteki Kararlar]]. İlk Godot prototipinde çıkış başına hatırlanan adil sırayla uygulandı ve otomatik olarak doğrulandı. Çoklu kaynaklı ağ optimizasyonu ve oynanış dengesi doğrulanmadı. Kapsam: [[Yönetim/Uygulama Durumu]].

## Ana hedefin kimliği

Kaynak metinde “Son Fabrika” ve “Kurucu Çekirdek” örneği var. Bunlar seçilmiş nihai senaryo olarak kabul edilmez. Daha önce dört hikâye senaryosu konuşulduğu belirtiliyor; bu senaryoların tam içeriği eldeki kaynakta yoktur. Eksik içerik yeniden icat edilmemelidir.

Ana hedefin görünür aşamaları ve tatmin edici bir tamamlanma anı olması önerilir. İlk küçük proje aşamasının araştırmayla aynı ürünü tüketmesi, paylaşım problemini test etmek için kullanılabilir.

## Uzun vadeli tüketim

Araştırma ve ana proje bittikten sonra üretimin neden süreceği açık sorudur. Tekrarlanabilir büyük projeler ve endüstriyel araştırma programları seçenekler arasındadır. Sürekli bonus biriktirmek tek başına uzun vadeli motivasyon sayılmamalı.

Bağlantılar: [[Tasarım/Araştırma Ekonomisi]], [[Tasarım/Bölgeler ve Lojistik]], [[Tasarım/Oyun Kimliği ve Temel Döngü]].
