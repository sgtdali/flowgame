---
tur: degisiklik-gunlugu
durum: etkin
guncelleme: 2026-10-26
---
# Değişiklik günlüğü

## 2026-10-20 — İlk aktarım

- Paylaşılan konuşma tam metin olarak kaynaklara alındı.
- Doğrudan ürün tüketen araştırma, canvas üzerinde kart üretimi ve makine kartı seçimi karar defterine işlendi.
- Alternatif prosesler ve bölgesel lojistik yönleri, onaylı ayrıntılar gibi sunulmadan konu notlarına aktarıldı.
- Tasarımın konu notları, üç görsel pano, açık sorular ve iki şablon oluşturuldu.
- Harici eklenti gerektirmeyen yerel Obsidian ayarları hazırlandı.
- Mevcut çalışma klasöründe eski oyun dosyaları bulunmadığı görüldü; Git'teki eski içerik geri yüklenmedi.
- Doğrulama: 23 Markdown notu, 3 Canvas; 70 wikilink, tüm Canvas dosya hedefleri, düğüm/ok kimlikleri ve JSON dosyaları kontrol edildi; bozuk hedef bulunmadı. Ham kaynak kopyası byte düzeyinde eşleşti.
- Obsidian kasa kaydı, mevcut kayıtlar korunup yapılandırma yedeklenerek eklendi. Başlatma sonrasında uygulamada `Error` başlıklı pencere görüldü; panonun Obsidian içinde açılışı görsel olarak doğrulanamadı. Dosya doğrulaması uygulama içi görsel doğrulama değildir.
- Kullanıcının Git geçmişini temizleme isteği için yerel `.git` kaldırma işlemi otomatik onay denetimince engellendi; mevcut geçmiş sıfırlanmadı.

## 2026-10-20 — Makine üretim modeli onayı

- K-005: Reçetenin gereken işi ve uygun makinenin saniyelik işleme hızıyla çevrim süresi hesaplanması onaylandı. Tamponlu çevrim ve girdi/çıktı zamanlaması Makine Kartları notuna işlendi.
- Kaynak, karar defteri, güncel özet, simülasyon notu ve açık sorular birlikte güncellendi. Sayılar örnek olarak korundu; tampon boyutları ve gruplama açık bırakıldı.
- Ana pano ve makine/proses panosuna karar özeti eklendi; mevcut kart konumları ve kimlikleri korundu.

## 2026-10-20 — Otomatik eşit paylaşım onayı

- K-006: Kabul edebilen bağlı tüketicilere otomatik eşit ürün paylaşımı onaylandı. Dolu tüketicinin payı diğerlerine aktarılır; bütün tüketiciler doluysa üreticinin çıkışı birikir ve yeni çevrim yer bekler.
- Ürün dağıtımı notu, karar defteri, güncel özet, açık sorular, kaynak kaydı ve araştırma/üretim panosu güncellendi. Tarihsel 40/60/20 örneğinin dağıtım kuralı olmadığı netleştirildi.
- Kart ölçeği kullanıcının isteği doğrultusunda açık bırakıldı.

## 2026-10-20 — İlk çalışan üretim atölyesi

- Kullanıcının oyunu oluşturmaya başlama talebiyle Godot 4.7.2 projesi kuruldu. K-005 üretim çevrimi ve K-006 otomatik eşit paylaşım küçük örnek ağda uygulandı.
- 32 simülasyon kontrolü, headless ve OpenGL arayüz smoke testleri geçti; pencere görüntüsü incelendi. Kartlar, bağlantılar ve kayıt/yükleme kullanılabilir.
- [[Yönetim/Uygulama Durumu]] oluşturuldu; geçici örnek değerler ve henüz uygulanmayan sistemler onaylı kararlardan ayrıldı. Mevcut kart ölçeği seçimi açık kaldı.

## 2026-10-20 — Makine kütüphanesi ve seçili makine paneli

- Mockup referansıyla, makine görselleri kullanılmadan sol arama/ekleme kütüphanesi ve sağ canlı ayrıntı/kontrol paneli uygulandı. Katalogdaki mevcut üç tür kullanılır.
- Seçim, stoklar, çevrim hesabı, durdur/çalıştır, silme ve yüklemede panel güncellemeleri test edildi. Kütüphane ve kart seçimi viewport fare olaylarıyla doğrulandı. Mevcut 32 üretim kontrolü geçti.
- [[Yönetim/Uygulama Durumu]] ve proje README'si güncellendi; yeni makine reçeteleri veya ekonomi kararı eklenmedi.

## 2026-10-20 — 24 ürünlük üretim ağı ve 9 araştırmalık teknoloji ağacı ilk taslağı

- K-007: 5 katmanlı 24 ilişkili ürün, bunları işleyen makine türleri ve Kademe 0 başlangıç durumundan 3 paralel kolla ilerleyen 9 araştırmalık (`A-01` – `A-09`) teknoloji ağacı ilk taslak olarak kaydedildi; kalite sistemi (A/B/C) şu aşamada kapsam dışı bırakıldı.
- [[Tasarım/Ürün ve Üretim Ağı]] oluşturuldu ve üretim akış şeması eklendi; [[Tasarım/Teknoloji Ağacı]] araştırma akış şeması ve kademe tablolarıyla güncellendi.
- [[Yönetim/Karar Defteri]], [[Kaynaklar/02 - Bu Sohbetteki Kararlar]], [[00 - Başlangıç]], [[01 - Güncel Tasarım]], [[Tasarım/Prosesler Kalite ve Yan Ürünler]], [[Yönetim/Açık Sorular]] ve ana tasarım panosu güncellendi.
- Kullanıcının “bunları oyuna uygula şimdi” talebiyle 24 ürün, çok girdili/çıktılı reçeteler, reçete seçimi ve 9 araştırmalık teknoloji ağacı (`A-01` – `A-09`) Godot projesine uygulandı; 63 simülasyon kontrolü ve arayüz smoke testleri geçti.

Yeni kayıt biçimi: `Tarih — değişen kural; karar kimliği; etkilenen konu notu; varsa eski karar bağlantısı.`

## 2026-10-22 — Araştırma ve reçete modeli

- K-008: Kademeli laboratuvar ve depolanabilir araştırma puanı onaylandı; K-001 yerine geçti olarak işaretlendi. Araştırma Ekonomisi notunun onaylı bölümü güncellendi, eski model tarihsel bölüme alındı.
- K-009: Girdisi farklı reçeteli makinelerde reçetenin gelen ürüne göre belirlenmesi, aynı girdili makinelerde simgeli reçete ekranı onaylandı.
- Prototip (`data/prototype.json`, `sim/production_sim.gd`) bu iki karara göre güncellendi; fiyat ve laboratuvar girdileri dengelenmemiş ilk denemedir.

## 2026-10-23 — Maden sınırı ve envanter

- K-010: Madenlerin oyun başında birer adetle sınırlanması onaylandı. Prototipte makinelere `build_limit` alanı eklendi; sınır kurulu, envanterdeki ve üretim kuyruğundaki makineleri birlikte sayar, sınırı dolan maden üretilemez ve kurulamaz.
- K-011: Oyuncu envanteri, malzemeli makine kurulumu, karttan/depodan elle alma ve süreli el üretimi onaylandı. Prototipte alttaki inşa çubuğu envanter çubuğuyla, makine seçimi kategorili üretim ekranıyla (C) değiştirildi; Depo makinesi eklendi; kayıt biçimi 4'e çıktı (3 okunmaya devam eder).

## 2026-10-23 — Üretim ekranı görünümü

- Kullanıcı, Codex'in dört taslağından (`art_src/craft_ekrani_stil/`) A tarzını seçti: koyu çerçeve, amber vurgu, sağda seçili öğenin ayrıntı paneli. Bu bir arayüz görünümü seçimidir, oyun kuralı değişmedi; karar defterine işlenmedi.
- Prototipte üretim ekranında kutuya tıklamak artık seçer, ÜRET düğmesi sıraya ekler (Shift: 5). Üretilemeyen öğede düğme kapanır ve nedeni yazılır. Üretim sırası (× ile iptal) ve envanter pencerenin içinde de gösterilir.
- Pencere çerçevesi ve zemini kullanıcının LibreSprite'ta pencerenin gerçek boyutunda çizdiği görselden 16 px kesim paylı 9-slice olarak alındı (`art_src/ui/menu_cerceve/`).

## 2026-10-23 — Hızlı erişim ve envanter penceresi

- K-012: Alttaki çubuğun 10 yuvalı hızlı erişim olması, envanterin tamamının ayrı bir pencerede (I) açılması ve oyuncunun istediği öğeyi hızlı erişime sabitlemesi onaylandı. K-011'in 1. maddesi değişti olarak işaretlendi.
- Prototipte sabitlemeler simülasyonda tutulur ve kayda girer (`hotbar`, kayıt sürümü 4 kaldı; alanı olmayan eski kayıtlar yüklenir).

## 2026-10-23 — Belgeler prototiple eşitlendi

- Yeni konu notu: [[Tasarım/Envanter ve El Üretimi]] (K-010, K-011, K-012 ve prototipteki ilk deneme değerleri). Başlangıç sayfasına, ana panoya ve K-010/K-011/K-012 kayıtlarına bağlandı.
- [[Yönetim/Uygulama Durumu]] baştan yazıldı: uygulanan kararlar K-002 – K-012, güncel arayüz, kayıt sürümü 4, testler ve smoke testi kapsamı. Eski sol kütüphane / sağ panel anlatımı kaldırıldı.
- [[01 - Güncel Tasarım]]: K-001 yerine K-008; K-009 – K-012 özetlendi; açık maddeler ve doğrulama sınırı güncellendi.
- [[Yönetim/Açık Sorular]]: S-011 ve S-012 K-008 ile kapandı, S-003 kısmen çözüldü; S-021 (kurulum sınırının artması), S-022 (envanter sınırı), S-023 (bedel ve el üretimi dengesi) eklendi.
- Konu notlarına prototip karşılıkları eklendi: Makine Kartları (K-009, kurulum bedeli ve sınırı, Depo), Teknoloji Ağacı, Ürün ve Üretim Ağı, Araştırma Ekonomisi, Ana Proje, Arayüz, Simülasyon İlkeleri, Prototip ve Doğrulama, Oyun Kimliği; Node Editör görseli tarihsel olarak işaretlendi.
- Panolar: ana panodaki seçimler kartı K-008 – K-012 ile güncellendi (K-001 çıkarıldı), yeni not kartı eklendi; döngü panosunda başlık ve genişleme kartı güncellendi, Otomasyon I örneği tarihsel işaretlendi. Mevcut kart konumları ve kimlikleri korundu.
- Depo kökündeki `README.md` ve `art_src/README.md` güncel prototipe göre yeniden yazıldı.
- Yeni kullanıcı kararı yok; prototip ayrıntıları karar olarak yazılmadı.

## 2026-10-23 — Boş başlangıç

- K-013: Oyunun boş tuvalle başlaması onaylandı. Prototipte hazır başlangıç ağı kaldırıldı; Sıfırla da boş tuvale döner. Eski ağ yalnızca testlerde `build_sample_network()` ile kurulur. Envanter testine kitten Laboratuvar 1'e ulaşılabildiğini denetleyen kontrol eklendi.
- Güncellenen notlar: [[Tasarım/Envanter ve El Üretimi]], [[Yönetim/Uygulama Durumu]]; `README.md`.

## 2026-10-23 — Makine kartı, elle besleme ve fırın reçetesi

- K-014: Envanterden makine girişine elle ürün koyma onaylandı; prototipte sürükle-bırak (sığdığı kadar, Shift: 1).
- K-015: Kartta ürünler çerçeveli kutularda adetle gösterilir (0'da boş, depolar dahil bar yok); seçili reçetenin girdileri boş kutuda saydam simgedir (silüet ayırt edilemediği için değiştirildi); üretilen ürün başlıkta.
- K-016: Fırınlarda reçeteyi oyuncu seçer; K-009'un fırın kısmı değişti olarak işaretlendi. Otomatik reçete testi tel sarım ve montaj üzerinden yeniden yazıldı.
- Güncellenen notlar: [[Tasarım/Makine Kartları]], [[Tasarım/Envanter ve El Üretimi]], [[Yönetim/Uygulama Durumu]], [[01 - Güncel Tasarım]], [[Yönetim/Açık Sorular]], ana pano; `README.md`.

## 2026-10-23 — Tek reçete ve farklı ürün ilkesi

- K-017: Her ürünün tek bir ana reçetesi olması kuralı getirildi. Aynı ürün için makinelerde alternatif reçete seçimi kaldırıldı; döküm veya talaşlı imalat gibi farklı yöntem ve malzemeler farklı ürünler (`Cast Iron Gear` vs `Steel Gear`, `Cast Iron Housing` vs `Steel Housing`) olarak ayrıldı.
- Demir ve çelik kolları netleştirildi: `Iron Ore -> Iron Ingot` (ergitme, kömürsüz); `Iron Ore + Coal -> Steel Ingot` (çelik fırını); talaş/hurda fırınlara geri beslenir. Demir kolu `Iron Plate`, `Iron Rod` ve `Iron Pipe` ara ürünleriyle genişletildi.
- Güncellenen notlar: [[Yönetim/Karar Defteri]], [[01 - Güncel Tasarım]], [[Tasarım/Ürün ve Üretim Ağı]], [[Tasarım/Prosesler Kalite ve Yan Ürünler]], [[Yönetim/Açık Sorular]].

## 2026-10-23 — Ana proje ve beş modülün reçeteleri

- K-018: Ana proje Son Fabrika seçildi. Kurucu Çekirdek ayrı bir üründür, beş modülden (Metalürji, Hassas Mekanik, Elektrik, Elektronik, Otomasyon) montajla yapılır, terminale teslim edilir; final proje her modülden çok sayıda ister. Exodus senaryosu ileride kullanılmak üzere [[Tasarım/Ana Proje ve Ürün Dağıtımı]] notuna yazıldı; kullanıcının paylaştığı dört senaryo da orada. S-014 kapandı.
- K-019: Ürün kolları birbirine bağlı; bazı reçeteler iki koldan malzeme ister.
- K-020: Makine üreten makineler onaylı yön olarak kaydedildi; tasarımı S-024'te açık.
- K-021: Beş modülün reçete taslağı adım adım onaylandı; ağ 24'ten 55 ürüne çıktı. Electrical Cabinet PLC'ye girer, döküm parçalar ayrı ürün, Gearbox döküm gövde ister. K-007'ye genişleme notu eklendi.
- [[Tasarım/Ürün ve Üretim Ağı]] `data/prototype.json`'dan yeniden üretildi (akış şeması, katalog, modüller). Güncellenen notlar: [[01 - Güncel Tasarım]], [[00 - Başlangıç]], [[Tasarım/Ana Proje ve Ürün Dağıtımı]], [[Tasarım/Teknoloji Ağacı]], [[Tasarım/Prosesler Kalite ve Yan Ürünler]], [[Tasarım/Envanter ve El Üretimi]], [[Yönetim/Uygulama Durumu]], [[Yönetim/Açık Sorular]] (S-024 – S-026 eklendi); `README.md`.
- Prototip: 31 yeni ürün ve reçete; makine ve araştırma atamaları geçici. Simülasyon testleri geçti; pencereli smoke testi ve oyun içi deneme yapılmadı.

## 2026-10-23 — Makineler, makine fabrikası ve 63 araştırma

- K-022: Torna ve CNC Tezgâh Atölyesi'nde birleşti, çelik fırını Ergitme Fırını'na katıldı; montaj Mekanik, Elektrik, Elektronik ve Robotik Montaj'a ayrıldı, modüller Modül Tesisi'nde yapılır. S-020 kısmen kapandı.
- K-023: Başlangıç makineleri demirden kurulur, her makine açıldığı anda yapılabilen şeyleri ister; yeni başlangıç kiti. Tel Sarım, Laboratuvar 2 ve 3'ün açılamayan bedelleri düzeltildi.
- K-024: Makine Fabrikası; K-020 uygulandı, S-024 kapandı.
- K-025: 9 araştırmanın yerine 9 kolda 63 araştırma; maden genişletme (S-021 kapandı), verim ve kapasite etkileri; Laboratuvar 4 ve K4. Araştırmalar arası açılış kopuklukları betikle denetlendi. K-007 ve K-010'a değişiklik notu eklendi.
- Zincir Editörü'ne reçete tablosu görünümü eklendi (araç; oyun kuralı değil).
- [[Tasarım/Teknoloji Ağacı]] 63 araştırmayla veriden yeniden yazıldı; eski ağaç tarihsel özet olarak kaldı. [[Tasarım/Ürün ve Üretim Ağı]] yeni makine adlarıyla yeniden üretildi. Güncellenen notlar: [[Tasarım/Makine Kartları]], [[Tasarım/Envanter ve El Üretimi]], [[Tasarım/Araştırma Ekonomisi]], [[Tasarım/Prosesler Kalite ve Yan Ürünler]], [[01 - Güncel Tasarım]], [[00 - Başlangıç]], [[Yönetim/Uygulama Durumu]], [[Yönetim/Açık Sorular]], ana pano; `README.md`.
- Bütün testler ve pencereli smoke testi geçti.

## 2026-10-24 — Envanter penceresi, aydınlık palet ve İngilizce arayüz

- K-026: Envanter ile el üretimi tek pencerede birleşti; oyundaki bütün öğeler görünür, olmayanlar soluk. K-012'ye değişiklik notu eklendi.
- K-027: Koyu mavi tema yerine aydınlık Kum taşı paleti; üç palet oyun içinde yan yana karşılaştırılıp A seçildi.
- K-028: Codex'ten alınan dört alternatiften D (akış haritası) uygulandı; kullanıldığı yerler 6 kart, fazlası adım adım kayar.
- K-029: Elle ve makinede aynı iş miktarı; tarif kutusunda süre yerine iş miktarı çekiç simgesiyle.
- K-030: Oyunun bütün metinleri ve araştırma adları İngilizce; Pixelify Sans ve Nunito fontları; pencereye perçinli kenar, başlık bandı ve ızgaralı harita zemini; kilitli makinelerde kategori simgesi.
- Prototipte ayrıca: Godot editörünün geri yazdığı eski `machine_card.tscn` yeniden silindi.
- Güncellenen notlar: [[Yönetim/Karar Defteri]], [[Tasarım/Envanter ve El Üretimi]], [[Tasarım/Arayüz ve Büyük Ağ Yönetimi]], [[01 - Güncel Tasarım]], [[Yönetim/Uygulama Durumu]], ana pano; `README.md`.
- Bütün testler ve pencereli smoke testi geçti; ekran görüntüleri incelendi. Fiziksel fareyle oyun içi deneme yapılmadı.

## 2026-10-24 – 2026-10-26 — El çizimi envanter penceresi, kurulu başlangıç, taşınan ürünler ve bağlantı yolları

- K-031: Envanter penceresi sabit boyutlu ve kapatma düğmeli; büyük öğe resmi 64 px; el üretimi kuyruğu en fazla 5 farklı öğe.
- K-032: Envanter penceresinin bütün görselleri kullanıcının LibreSprite çizimlerinden; kuyruk ve hızlı erişim kendi çerçeveli bölümlerinde, boş kuyrukta boş yuvalar. 18 kaynak dosya `art_src/ui/envanter_penceresi/` altında, oyundaki karşılıkları oradaki README'de.
- K-033: Oyun bir Demir madeni ve bir Ergitme fırını kurulu ve bağlı başlar; K-013'e değişiklik notu eklendi.
- K-034: Tuval bağlantıları 16 px'lik çok renkli bant; her 20 px'de ortadaki 8 px'i kesen, altındaki rengin koyusu dik çizgiler.
- K-035: Ürünler bağlantı boyunca 8x8 simgeyle gerçekten taşınır, hedefe varınca sayılır; silinen bağlantıdaki ürünler çıkış kapasitesi kadar kaynağa döner. K-006'ya değişiklik notu eklendi.
- K-036: Bağlantılar üst üste binmez, kesişmelerde köprü gibi geçer, kartların etrafından dolaşır.
- K-037: Yol hesabı yerel ızgarada, yalnız etkilenen çizgiler için ve tuval koordinatında; sürüklerken seyrek hesaplama ertelendi ve [[Tasarım/Arayüz ve Büyük Ağ Yönetimi]] notuna yazıldı. S-017 kısmen yanıtlandı.
- Güncellenen notlar: [[Yönetim/Karar Defteri]], [[Tasarım/Envanter ve El Üretimi]], [[Tasarım/Arayüz ve Büyük Ağ Yönetimi]], [[Tasarım/Ana Proje ve Ürün Dağıtımı]], [[01 - Güncel Tasarım]], [[Yönetim/Uygulama Durumu]], [[Yönetim/Açık Sorular]]; `README.md`.
- Bütün testler (üretimde 72 kontrol) ve pencereli smoke testi geçti; çizgi yolları dört yerleşimde ölçüldü (üst üste binme ve kart altından geçme 0). Fiziksel fareyle oyun içi deneme yapılmadı.

## 2026-10-26 — Makine kartlarının görünümü ve kullanıcı çizimi makineler

- K-038: Kartlardaki makine görseli 128'den 256 px'e çıktı; eski görseller 2 kat büyütülerek gösteriliyor.
- K-039: Portlar 24x24 durum çemberi: turuncu bağlı değil, yeşil akış var, kırmızı bağlı ama parça alamıyor.
- K-040: Malzeme kutuları çemberin 2 px içinde; kart 416 px genişliğinde.
- K-041: Kartın tamamı tek çerçevede, başlık içinde; görsel geçici, kullanıcı ayrı çizecek (S-028).
- K-042: Ergitme fırını (alevli), Demir madeni ve Bakır madeni (vagonlu, fenerli) kullanıcı çizimlerinden; yeni görseller onaysız oyuna konmaz. S-029 eklendi.
- Güncellenen notlar: [[Yönetim/Karar Defteri]], [[Tasarım/Makine Kartları]], [[Tasarım/Arayüz ve Büyük Ağ Yönetimi]], [[01 - Güncel Tasarım]], [[Yönetim/Uygulama Durumu]], [[Yönetim/Açık Sorular]]; `art_src/STANDART.md`, `README.md`.
- Bütün testler ve pencereli smoke testi geçti; ekran görüntüleri incelendi. Fiziksel fareyle oyun içi deneme yapılmadı.
