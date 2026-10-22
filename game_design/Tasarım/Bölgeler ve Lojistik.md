---
tur: sistem
durum: yon-olarak-olumlu
guncelleme: 2026-10-20
---
# Bölgeler ve lojistik

## Çözülecek sorun

Kullanıcının tespiti: Factorio'da kaynak konumları ve uzak kaynaklara ulaşma ihtiyacı büyümeyi şekillendiriyor. Sonsuz canvas üzerinde ekonomik bir konum yoksa her kapasite sorunu daha fazla kart kurularak çözülebilir. Üretim yöntemleri arasında tercih yapma ihtiyacı zayıflayabilir.

Bu soruna önerilen yanıt endüstriyel bölgeler ve sınırlı lojistik kapasitesidir. Kullanıcı fikri temkinli olumlu karşılamıştır; uygulanacak bölge modeli kesinleşmemiştir.

## Önerilen iki konum ayrımı

**Canvas konumu:** Kartın oyuncunun çalışma alanında nerede çizildiği. Düzenleme ve okunabilirlik içindir.

**Ekonomik bölge:** Makinenin hangi kaynaklara ve taşıma altyapısına eriştiği. Kartın canvas üzerinde taşınması ekonomik bölgeyi değiştirmez. Gerçek bölge transferinin maliyeti ve kuralları açıktır.

Bu modelde yan yana çizilmiş iki kart farklı bölgelerde olabilir; bağlantıları bölgeler arası kapasite kullanır. Bölgelerin görünür coğrafi harita olması zorunlu değildir; canvas üzerinde çerçevelenmiş gruplar bir görselleştirme seçeneğidir.

## Üç kısıt önerisi

| Kısıt | Oyuncunun kararı | Durum |
|---|---|---|
| Kaynak erişimi | Yeni kaynak/bölgeye yönelmek | İlk deney için öneri |
| Taşıma kapasitesi | Ham veya işlenmiş ürün taşımak, hattı büyütmek | İlk deney için öneri |
| Proses altyapısı | Enerji, soğutma veya özel tesis yatırımı | Daha ileri aşama önerisi |

Kaynak toplamının tükenip tükenmeyeceği ile dakikalık çıkarma kapasitesinin sınırlı olması ayrı kararlardır. Konuşmadaki örnekler öncelikle akış kapasitesi kullanır; kaynakların kesinlikle sonsuz olduğu sonucu çıkarılamaz.

## Sayısal örnek: cevher mi levha mı taşınmalı?

Varsayımlar: Demir Havzası 30 cevher/dk çıkarır. Örnek dönüşümde 2 cevher → 1 çelik levha olur. Merkezle bağlantı 8 birim/dk taşır. Merkez 12 levha/dk ister. Taşıma hesabında her adet eşit birim sayılmıştır.

| Seçenek | Merkeze ulaşan ürün | Sonuç |
|---|---|---|
| 8 cevher/dk taşı, merkezde işle | 4 levha/dk | Taşıma hammadde üzerinde dar boğaz |
| Havzada işle, 8 levha/dk taşı | 8 levha/dk | Yerinde işleme daha fazla bitmiş ürün ulaştırır |
| Havzada işle, taşıma kapasitesini 16'ya çıkar | 15 levha/dk | Bu kez 30 cevher/dk kaynak sınırı belirleyici |

Bu seçeneklerin kurulumu ve maliyeti verilmediği için hepsinin eşit derecede cazip stratejiler olduğu söylenemez. Örnek, işlenmiş ürün taşımanın kapasite kullanımına etkisini gösterir. Gerçek reçete veya dengelenmiş senaryo değildir.

## Lojistik gelişimi önerisi

Temel yük bağlantıları → yük terminalleri → toplu taşımacılık → otomatik dağıtım ağı → entegre lojistik merkezleri.

İlerleme yalnızca daha yüksek kapasite sunmamalı. Bir girdiyi birkaç bölge arasında talebe göre paylaşmak veya ürün filtrelemek gibi yeni yönetim yetenekleri de açabilir. Araç, tren, yol bulma veya fiziksel konveyör simülasyonu bu öneri için zorunlu değildir.

## Henüz çözülmeyenler

- Bölgeler nasıl keşfedilir veya açılır? Yeni bölgeye yatırımın bedeli ne?
- Aynı ürün farklı bölgelerde nasıl avantaj kazanır?
- Yerel bağlantılar da kapasiteye veya mesafeye bağlı mı?
- Taşıma anlık hız tahsisi mi, teslimat gecikmeli sevkiyat mı?
- Kapasite her yönde ayrı mı, çift yönlü ortak mı?
- Ürünler adet, kütle, hacim veya soyut yük katsayısıyla mı hesaplanır?
- Birden fazla tüketici kıt kapasiteyi nasıl paylaşır?

İlk bölge deneyi için [[Tasarım/Prototip ve Doğrulama]]; ürün paylaşımı için [[Tasarım/Ana Proje ve Ürün Dağıtımı]].
