---
tur: degisiklik-gunlugu
durum: etkin
guncelleme: 2026-10-23
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
