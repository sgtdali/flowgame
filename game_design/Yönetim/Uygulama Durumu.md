---
tur: uygulama-kaydi
durum: prototip
guncelleme: 2026-10-20
---
# Uygulama durumu

## Endüstriyel üretim ve araştırma ağı — 2026-10-20

Kullanıcının “bunları oyuna uygula şimdi” talebi üzerine K-007 ilk taslağındaki **24 ürünlük üretim ağı**, **makine türleri** ve **9 araştırmalık teknoloji ağacı (`A-01` – `A-09`)** Godot 4.7.2 projesine uygulandı.

## Uygulanan temel

- **K-001 & K-007:** 5 katmanlı **24 ürün kataloğu**, ilgili makine türleri (`Demir/Bakır/Kömür Madeni`, `Kuvars Ocağı`, `Ergitme Fırını`, `Çelik Fırını`, `Haddehane`, `Pres`, `Torna`, `CNC Tezgâhı`, `Dökümhane`, `Tel Çekme ve Sarım`, `Montaj İstasyonu`, `Araştırma Laboratuvarı`, `Ana Proje Terminali`, `Talaş Bertaraf Ünitesi`) ve **9 araştırmalık (`A-01` – `A-09`) teknoloji ağacı** çalışır.
- **K-005:** Reçete işi / makine işleme hızı; çok girdili ve çok çıktılı reçeteler (`Torna` ve `CNC` işlemlerinden çıkan `Metal Talaşı` yan ürünü ve `Çelik Fırını`nda geri kazanımı); girdileri başlangıçta tüketme; çıktıları iş sonunda üretme; giriş/çıkış tamponları; eksik girdi ve dolu çıkışta yeni çevrimi bekletme.
- **K-006:** Kabul edebilen bağlı tüketicilere her çıkış ürünü için otomatik eşit paylaşım.
- **Çok portlu makine kartları ve reçete seçimi:** Makine kartlarında her girdi ve çıktı ürünü kendi renkli ve tipli portuna sahiptir. Sağdaki **Seçili Makine** panelinden makinenin açık reçeteleri arasında geçiş yapılabilir.
- **Teknoloji Ağacı paneli ve Serbest Mod:** 3 kademeli araştırma ağacı ekranından (`app/research_panel.gd`) aktif araştırma seçilebilir; laboratuvarlar seçili araştırmanın ürünlerini tüketerek yeni makineleri ve reçeteleri açar. İstenirse **Serbest Mod** düğmesiyle tüm kilitler anında açılabilir.
- Yerel tek yuvalı kayıt/yükleme (`version: 2`): kart konumları, seçili reçeteler, ağ bağlantıları, stoklar, çalışan işler, dağıtım sırası ve araştırma ilerlemesi korunur.

## Geçici deney seçimleri

Başlangıç ağı Kademe 0 makineleriyle 8 kart ve 10 bağlantı olarak kurulur: `Demir Madeni` + `Kömür Madeni` → `Ergitme Fırını (Pik Demir)` → `Çelik Fırını (Çelik Külçe)` → iki `Haddehane (Çelik Levha ve Çelik Çubuk)` → `Pres (Bağlantı Elemanı)` → `Araştırma Laboratuvarı (A-01: Talaşlı İmalat)`.

Reçetelerin girdi/çıktı sayıları, gereken iş değerleri, tampon boyutları (6–12) ve araştırma deney sayıları (8–15) ilk taslak uygulama değerleridir; nihai denge kararı sayılmaz. Üç alt montaj kategorisi bu uygulamada tek `Montaj İstasyonu` altında seçilebilir reçeteler olarak birleştirilmiştir. Bağlantılar anlık ve sınırsız aktarım yapar; bölgesel kaynak, taşıma kısıtı, enerji ve inşa bedeli henüz uygulanmadı.

## Doğrulama kanıtı

- Motor: **4.7.2.stable.official.ed1daf0bf**.
- `tests/test_production.gd`: **63 kontrol geçti**. Kademe 0'dan başlayarak 9 araştırmanın tamamının kilitlenmeden (deadlock olmadan) açıldığı ve 24 ürünün tamamının üretilebilir hale geldiği, çok girdili/çok çıktılı reçeteler, `Metal Talaşı` geri kazanımı, `Dökümhane` alternatif üretimi, çoklu laboratuvarda fazla deney başlatmama, araştırma değiştirme ve kayıt/yükleme bütünlüğü doğrulandı.
- Headless ve OpenGL Compatibility arayüz smoke testleri geçti; `artifacts/production-workshop.png` oluşturulup görsel olarak incelendi.

## Çalıştırma ve kaynaklar

Depo kökündeki `Baslat.cmd` oyunu açar. `README.md` kontrolleri ve doğrulama komutlarını anlatır. Oyun `project.godot`, arayüz `app/main.gd`, `app/machine_library.gd`, `app/machine_inspector.gd`, `app/research_panel.gd`, simülasyon `sim/production_sim.gd`, katalog verisi `data/prototype.json` içindedir.

İlgili tasarım: [[Tasarım/Ürün ve Üretim Ağı]], [[Tasarım/Teknoloji Ağacı]], [[Tasarım/Makine Kartları]], [[Tasarım/Ana Proje ve Ürün Dağıtımı]], [[Yönetim/Karar Defteri]].
