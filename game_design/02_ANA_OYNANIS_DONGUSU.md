# Ana Oynanış Döngüsü

**Son güncelleme:** 21.09.2026  
**Sahibi:** Oyun Tasarımı  
**İlgili belgeler:** [Vizyon ve kapsam](01_VIZYON_VE_KAPSAM.md), [İlerleme ve açılışlar](03_ILERLEME_VE_ACILISLAR.md), [Tasarım ilkeleri](04_TASARIM_ILKELERI.md)

## Ana döngü

1. Oyuncu şehir taleplerini, mevcut kaynakları ve açık fabrika arsalarını
   inceler.
2. Genel fabrikaların içine üretim node'ları kurar ve ürün akışlarını bağlar.
3. Kaynak noktalarını, fabrikaları, şehirleri ve `Research Campus`ı tek ürünlü
   lojistik bağlantılarıyla birbirine bağlar.
4. Şehirlerin sürekli taleplerini karşılayarak para kazanır ve şehir gelişimini
   ilerletir.
5. Parayı yeni fabrikalara, slot genişletmelerine, lojistik kapasitesine veya
   yeni dünya alanlarına yatırır.
6. Research Pack üretim hatları kurar, pack'leri `Research Campus`a taşır ve
   yeni üretim olanakları açar.
7. Açılan kaynaklar, ürünler ve şehir uzmanlıklarıyla ağı büyütür; sonunda
   çok aşamalı final endüstri projesini tamamlar.

## Birbirine bağlı ilerleme döngüleri

### Şehir ve para

Şehirler ürünleri kendi `Demand Rate` değerlerine kadar kabul eder ve teslimat
karşılığında para verir. Talep üstündeki ürün otomatik satılmaz; üretim ağında
geri basınç oluşturur. Para doğrudan şirket yatırımlarını mümkün kılar.

### Araştırma

Araştırma şehir gelişiminden veya pasif zamandan kazanılmaz. Oyuncu Research
Pack üretir, bunları `Research Campus`a taşır ve seçili teknolojinin istediği
pack bileşimini sürdürülebilir biçimde sağlar.

### Dünya genişlemesi

Oyuncu kazandığı parayla dallanan dünya haritasındaki yeni alanlardan birini
seçer. Yeni alan; yeni şehir, kaynak, maden ve fabrika arsalarını mevcut kalıcı
ağa ekler.

### Final proje

Yeterli dünya ve teknoloji ilerlemesinden sonra çok aşamalı final endüstri
projesi açılır. Her aşama farklı sanayi kollarından teslimatlar ister; biten
aşama geri alınmaz.

## Akış kuralları

- Her tesisler arası lojistik bağlantısı yalnızca bir ürün taşır.
- Lojistik mesafeyle değil `Transfer Rate` ile sınırlanır.
- Her şehir talebi sürekli bir `Demand Rate` olarak çalışır.
- Yetersiz tedarik şehir kademesini düşürmez; hizmeti ve sonraki gelişimi
  durdurur veya yavaşlatır.
- Kesin dağıtım öncelikleri, oranlar, fiyatlar ve eşikler ekonomi/prototip
  aşamasında kararlaştırılır.
