---
tur: soru-listesi
durum: etkin
guncelleme: 2026-10-26
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
| S-014 | Somut nihai proje ve ilk aşaması ne? | Uzun vadeli motivasyon | Çözüldü (K-018): Son Fabrika; beş modülden yapılan Kurucu Çekirdek |
| S-015 | İlk prototipte hangi ürün ve hangi alternatif yöntemler denenir? | Üretimin anlamlı tercih üretmesi | Çözüldü (K-007, K-017): Tek reçete ve farklı ürün ilkesi; döküm ve talaşlı ürünler (Cast Iron vs Steel) ayrıldı |
| S-016 | İlk 60 dakika hangi başarılar ve darboğazlardan oluşur? | Öğrenme ve ilerleme temposu | Açık |
| S-017 | Hedef cihaz ve kabul edilebilir simülasyon/arayüz performansı ne? | Ölçek bütçesi | Kısmen çözüldü (K-037): 500 kartta kart oynatmak kasmamalı; bağlantı yolları buna göre hesaplanıyor. Hedef cihaz ve gerçek kartlarla ölçüm açık; ertelenen çözüm [[Tasarım/Arayüz ve Büyük Ağ Yönetimi#Ertelenen çözüm: sürüklerken seyrek hesaplama|burada]] |
| S-018 | Giriş/çıkış tamponlarının kapasitesi ne olacak? | Akış ve stok sınırı | Açık; tamponların varlığı K-005 ile onaylı |
| S-019 | Reçete değişimi veya çevrim iptalinde iş ve malzeme ne olur? | Oyuncu kontrolü ve stok bütünlüğü | Açık |
| S-020 | Farklı prosesler için ayrı işleme birimleri gerekir mi? | Uyumluluk ve dengeleme | Kısmen çözüldü (K-022): montaj dört makineye ayrıldı, torna ve CNC birleşti |
| S-021 | Kurulum sınırları (ör. maden başına 1) araştırmayla veya başka yolla artar mı? | Hammadde dengesi, uzun vadeli büyüme | Çözüldü (K-025): maden genişletme araştırmaları her maden için sınırı +1, +1 artırır |
| S-022 | Envanterin taşıma veya yuva sınırı olacak mı? | Lojistik anlamı, Depo kartının rolü | Açık; prototipte sınır yok |
| S-023 | Kurulum bedelleri ve el üretimi hızı nasıl dengelenir? | İlk dakikaların temposu | Açık; prototip değerleri ilk deneme |
| S-024 | Makine üreten makineler nasıl çalışır: hangi kart hangi makineyi üretir, ne zaman açılır, çıktı nereye gider? | Otomasyona geçiş, K-020 | Çözüldü (K-024): tek Makine Fabrikası, kartta ya da bağlı depoda birikir, erken araştırma |
| S-025 | Kurucu Çekirdek ve modüller kaç adet ister, tam bir oyun ne kadar sürer? | Final projenin zorluğu, K-018 | Açık; prototipte her modülden 4 (ilk tahmin) |
| S-026 | Kimya modülü hangi hammaddelerle ve ne zaman eklenir? | Kurucu Çekirdek'in tamamlanması | Açık |
| S-027 | Bağlantıların taşıma hızı ve kapasitesi ne olmalı; araştırmayla artar mı? | Akış temposu, bağlantı sayısı | Açık; prototipte 60 px/sn ve 10 px aralık (K-035, asistan seçimi) |
| S-028 | Makine kartının kendi çerçevesi nasıl olacak? | Kartın görünümü, K-041 | Açık; kullanıcı çizecek, şimdilik envanter penceresinin çerçevesi kullanılıyor |
| S-029 | Diğer makinelerin 256 px'lik görselleri ne zaman ve nasıl çizilecek? | Kartların tutarlı görünümü, K-038 | Açık; 20 makine 128 px yer tutucunun büyütülmüşüyle duruyor |

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
| Oyun hazır bir ağla mı başlar? | Hayır: boş tuval ve başlangıç kiti | [[Yönetim/Karar Defteri#K-013 — Oyun boş tuvalle başlar|K-013]] |
| Ağa bağlı olmayan makine çalıştırılabilir mi? | Evet: envanterden girişe elle ürün konur | [[Yönetim/Karar Defteri#K-014 — Envanterden makine girişine elle malzeme konur|K-014]] |
| Fırının reçetesini kim seçer? | Oyuncu (K-009'un fırın kısmı değişti) | [[Yönetim/Karar Defteri#K-016 — Fırınlarda reçeteyi oyuncu seçer|K-016]] |
| Ana proje ne? | Son Fabrika: beş modülden yapılan Kurucu Çekirdek, terminale teslim | [[Yönetim/Karar Defteri#K-018 — Ana proje: Son Fabrika ve Kurucu Çekirdek|K-018]] |
| Ürün kolları bağımsız mı? | Hayır: bazı reçeteler iki koldan malzeme ister | [[Yönetim/Karar Defteri#K-019 — Kollar birbirine bağlı olur|K-019]] |
| Makineler hep elle mi üretilir? | Hayır: Makine Fabrikası makineleri üretir | [[Yönetim/Karar Defteri#K-024 — Makine Fabrikası|K-024]] |
| Montaj tek makine mi? | Hayır: Mekanik, Elektrik, Elektronik, Robotik Montaj ve Modül Tesisi | [[Yönetim/Karar Defteri#K-022 — Makine düzeni|K-022]] |
| Kaç araştırma var? | 9 kolda 63; maden sınırı araştırmayla artar, K4 laboratuvarı var | [[Yönetim/Karar Defteri#K-025 — 63 araştırmalık teknoloji ağacı|K-025]] |

Yeni cevap geldiğinde satırı ilgili karara bağla. Açık sorunun yanında bulunan öneri, cevap yerine geçmez.
