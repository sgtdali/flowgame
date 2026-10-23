---
tur: soru-listesi
durum: etkin
guncelleme: 2026-10-23
---
# Açık sorular

Öncelik, bağımlılık sırasını gösteren çalışma önerisidir. Her tartışmada tek bir somut konu ele alınabilir.

| Kimlik | Soru | Neyi etkiler? | Durum |
|---|---|---|---|
| S-001 | Bir kart tek makine mi, aynı tip makine grubu mu? | Canvas ölçeği, genişleme maliyeti, arayüz | Açık |
| S-002 | Bir kart aynı anda tek reçete mi çalıştırır? | Kapasite paylaşımı, stok, zamanlama | Açık |
| S-003 | Yeni makine kurmanın ve mevcut kartı büyütmenin bedeli ne? | Ürün tüketimi, sınırsız çoğaltma sorunu | Kısmen çözüldü: makine malzemeyle üretilir (K-011), madenler birer adetle sınırlı (K-010); miktarlar dengelenmedi, kart büyütme açık |
| S-004 | Kaynak erişimi bölgelere mi bağlı; yeni bölge nasıl açılır? | Temel büyüme döngüsü | Açık |
| S-005 | Bölge kaynağı tükenir mi; çıkarma hızı nasıl artar? | Uzun vadeli genişleme | Açık |
| S-006 | Taşıma kapasitesi adet, kütle, hacim veya ürün ağırlığıyla mı ölçülür? | Yerinde işleme tercihi | Açık |
| S-007 | Aynı bölge içindeki bağlantılar hangi sınırlara sahip? | Yerel ve bölgesel lojistik ayrımı | Açık |
| S-008 | Kalite gerekli mi; gerekli ise hangi özellikleri temsil eder? | Tarif sayısı, anlaşılabilirlik | Şu aşamada kapsam dışı (K-007: “kaliteye gerek yok şu an”) |
| S-009 | Yan ürün boşaltma/bertaraf seçeneği var mı; bedeli ne? | Geri kazanım ve kilitlenme | Kısmen çözüldü: K-005 ile çıkış alanı yoksa yeni çevrim başlamaz; K-007 ile `Metal Talaşı → Çelik Külçe` geri kazanımı ilk taslağa girdi; prototipte yer tutucu `Talaş bertaraf ünitesi` var, bertaraf kararı ve bedeli açık |
| S-010 | Enerji, soğutma ve özel altyapı ilk sürüme girer mi? | Kapsam ve proses tercihi | Açık |
| S-011 | Laboratuvarlar ortak araştırmada hangi stok yapısını kullanır? | Paralellik ve kaynak yarışması | Çözüldü (K-008): laboratuvarlar kademe puanı üretir, puanlar ortak depoda birikir |
| S-012 | Araştırma değişirken çalışan deney ve ayrılmış malzeme ne olur? | Oyuncu kontrolü, kayıt | Çözüldü (K-008): laboratuvar araştırmadan bağımsız çalışır; değişim hatları bozmaz, puan depoda kalır |
| S-013 | Para, satış veya sipariş var mı? | Ekonominin tüketicileri | Açık |
| S-014 | Somut nihai proje ve ilk aşaması ne? | Uzun vadeli motivasyon | Açık |
| S-015 | İlk prototipte hangi ürün ve hangi alternatif yöntemler denenir? | Üretimin anlamlı tercih üretmesi | İlk taslak seçildi (K-007): 24 ürünlük ağ, `Dişli` ve `Gövde` alternatif yöntemleri, `Metal Talaşı` geri kazanımı; sayısal değerler açık |
| S-016 | İlk 60 dakika hangi başarılar ve darboğazlardan oluşur? | Öğrenme ve ilerleme temposu | Açık |
| S-017 | Hedef cihaz ve kabul edilebilir simülasyon/arayüz performansı ne? | Ölçek bütçesi | Açık |
| S-018 | Giriş/çıkış tamponlarının kapasitesi ne olacak? | Akış ve stok sınırı | Açık; tamponların varlığı K-005 ile onaylı |
| S-019 | Reçete değişimi veya çevrim iptalinde iş ve malzeme ne olur? | Oyuncu kontrolü ve stok bütünlüğü | Açık |
| S-020 | Farklı prosesler için ayrı işleme birimleri gerekir mi? | Uyumluluk ve dengeleme | Açık; makine-reçete uygunluğu K-005 ile onaylı |
| S-021 | Kurulum sınırları (ör. maden başına 1) araştırmayla veya başka yolla artar mı? | Hammadde dengesi, uzun vadeli büyüme | Açık; kullanıcı “belki” dedi (K-010) |
| S-022 | Envanterin taşıma veya yuva sınırı olacak mı? | Lojistik anlamı, Depo kartının rolü | Açık; prototipte sınır yok |
| S-023 | Kurulum bedelleri ve el üretimi hızı nasıl dengelenir? | İlk dakikaların temposu | Açık; prototip değerleri ilk deneme |

## Kapanan sorular

Kart ölçeği (S-001) için kullanıcı bu aşamada karar vermek istemediğini belirtti; sıradaki zorunlu karar olarak dayatılmamalıdır.

| Soru | Sonuç | Dayanak |
|---|---|---|
| Makine kartı mı, proses kartı mı? | Makine kartı | [[Yönetim/Karar Defteri#K-003 — Kartlar makine olacak|K-003]] |
| Araştırma temel tüketim modeli? | Doğrudan ürün tüketimi — sonra K-008 ile değişti | [[Yönetim/Karar Defteri#K-001 — Doğrudan ürün tüketen araştırma|K-001]] (tarihsel) |
| Üretim çevrimi ve hız neye göre belirlenir? | Reçete işi / uygun makinenin işleme hızı; tamponlu çevrim | [[Yönetim/Karar Defteri#K-005 — İş miktarı ve makine işleme hızıyla üretim|K-005]] |
| Bir çıkış birden fazla tüketiciye nasıl paylaştırılır? | Kabul edebilen tüketiciler arasında otomatik eşit; dolu tüketicinin payı diğerlerine gider | [[Yönetim/Karar Defteri#K-006 — Otomatik eşit ürün paylaşımı|K-006]] |
| İlk ürün kataloğu, alternatif prosesler, kalite kapsamı ve araştırma ağacı? | 24 ürünlük üretim ağı ve 9 araştırmalık teknoloji ağacı ilk taslağı; kalite şu aşamada kapsam dışı | [[Yönetim/Karar Defteri#K-007 — 24 ürünlük üretim ağı ve 9 araştırmalık teknoloji ağacı ilk taslağı|K-007]] |
| Araştırma ürünü doğrudan mı tüketir? | Hayır artık: kademeli laboratuvarlar puan üretir, puan depolanır (K-001'in yerine geçti) | [[Yönetim/Karar Defteri#K-008 — Kademeli laboratuvarlar ve depolanabilir araştırma puanı|K-008]] |
| Makinenin reçetesini kim seçer? | Farklı girdili makinede gelen ürün; aynı girdili makinede oyuncu, reçete ekranından | [[Yönetim/Karar Defteri#K-009 — Reçete gelen ürüne göre belirlenir|K-009]] |
| Hammadde sınırsız mı? | Hayır: madenler oyun başında birer adet | [[Yönetim/Karar Defteri#K-010 — Hammadde kaynakları sınırlıdır|K-010]] |
| Oyuncunun envanteri ve makine kurma bedeli var mı? | Evet: envanter, malzemeli kurulum, elle alma, süreli el üretimi, başlangıç kiti | [[Yönetim/Karar Defteri#K-011 — Oyuncu envanteri, malzemeli kurulum ve el üretimi|K-011]] |
| Alttaki çubuk envanterin tamamı mı? | Hayır: 10 yuvalı hızlı erişim; envanter ayrı pencerede, öğeler sabitlenir | [[Yönetim/Karar Defteri#K-012 — Hızlı erişim çubuğu ve envanter penceresi|K-012]] |

Yeni cevap geldiğinde satırı ilgili karara bağla. Açık sorunun yanında bulunan öneri, cevap yerine geçmez.
