---
tur: uygulama-kaydi
durum: prototip
guncelleme: 2026-10-23
---
# Uygulama durumu

Godot 4.7.2 prototipinde 2026-10-23 itibarıyla çalışan ve test edilen kısım. "Uygulandı" oynanışın doğrulandığı anlamına gelmez; sayılar ilk denemedir.

## Uygulanan kararlar

| Karar | Prototipte |
|---|---|
| K-002, K-003 | Sonsuz tuval üzerinde makine kartları; kartlar arasında ürün tipli port bağlantıları. |
| K-005 | Reçete işi / makine işleme hızı; çok girdili ve çok çıktılı reçeteler; girdiler başta tüketilir, çıktılar iş bitince eklenir; giriş/çıkış tamponları; eksik girdi ya da dolu çıkış yeni çevrimi bekletir. |
| K-006 | Kabul edebilen bağlı tüketicilere her ürün için otomatik eşit paylaşım (çıkış başına hatırlanan adil sıra). |
| K-007 | 24 ürün, 19 makine türü, 32 reçete, 9 araştırma (`A-01` – `A-09`). Üç alt montaj türü tek `Montaj istasyonu` altında birleşik. |
| K-008 | Laboratuvar 1/2/3 sürekli aynı ürünleri tüketip Kademe 1/2/3 puanı üretir; puan depoda birikir, aktif araştırma eksiğini depodan çeker. |
| K-009 | Girdisi farklı reçeteli makineler (ergitme fırını, çelik fırını, pres, tel sarım, montaj) reçeteyi gelen ürüne göre seçer, boşken tek genel girişi olur. Aynı girdili makinelerde (haddehane, CNC, dökümhane) simgeli reçete ekranından ürün seçilir. |
| K-010 | Dört maden birer adetle sınırlı; sınır kurulu, envanterdeki ve üretim sırasındaki makineleri birlikte sayar. Serbest modda sınır yok. |
| K-011 | Envanter, malzemeli makine kurulumu, karttan/depodan elle alma, süreli el üretimi kuyruğu, başlangıç kiti, Depo kartı. |
| K-012 | Alttaki 10 yuvalı hızlı erişim çubuğu ve I ile açılan envanter penceresi; ikisi aynı envanteri paylaşır, öğeler hızlı erişime sabitlenir. |

Ayrıntılar: [[Tasarım/Makine Kartları]], [[Tasarım/Araştırma Ekonomisi]], [[Tasarım/Envanter ve El Üretimi]], [[Tasarım/Teknoloji Ağacı]].

## Arayüz

- **Üst çubuk:** Araştırma ağacı (aktif araştırma ve yüzdesi), Serbest mod, Duraklat/Devam, oyun hızı (1× ↔ 4×), Ortala, Kaydet, Yükle, Sıfırla.
- **Makine kartı:** 128×128 makine görseli, giriş ve çıkış göstergeleri, çevrim çubuğu, durdurma düğmesi. Çıkış göstergesine tıklamak ürünü envantere alır; bir girişin "+" düğmesi o ürünü yapan makineyi envanterden kurup bağlar.
- **Kart menüsü (sağ tık):** Ne üretilsin? (reçete ekranı), Durdur/Çalıştır, hız 20 ↔ 40 iş/sn, Envantere al, Kaldır (envantere); laboratuvarda araştırma hedefi seçimi.
- **Üretim ekranı (C):** Kategori sekmeleri, öğe kutuları, seçili öğenin resmi/açıklaması/tarifi, ÜRET düğmesi, üretim sırası ve envanter satırı. Çerçevesi kullanıcının LibreSprite'ta çizdiği 9-slice görseldir.
- **Envanter penceresi (I)** ve **hızlı erişim çubuğu (1–9, 0):** bkz. [[Tasarım/Envanter ve El Üretimi]].
- **Araştırma paneli:** Kademeli araştırma ağacı, kademe puanı depoları, aktif araştırma seçimi, serbest mod.

## Geçici deney seçimleri

- Başlangıç ağı 8 kart ve 9 bağlantıdır ve başlangıç kitinden ayrı, bedelsiz kurulur: `Demir madeni` + `Kömür madeni` → `Ergitme fırını (pik demir)` → `Çelik fırını (çelik külçe)` → iki `Haddehane` (levha, çubuk) → `Pres (bağlantı elemanı)` → `Laboratuvar 1`.
- Bütün makinelerin işleme hızı 20 iş/sn; kart menüsünden 40'a çıkarılabilir. Tamponlar 6–12, Depo 100.
- `Talaş bertaraf ünitesi` ve `Ana proje terminali` (A-09 sonrası, aktüatör + PLC tüketir) yer tutucudur; bertaraf ve ana proje için kullanıcı kararı yoktur.
- Bağlantılar anlık ve sınırsız aktarım yapar. Bölge, taşıma kısıtı, enerji ve para uygulanmadı.
- Makine görsellerinin bir kısmı yer tutucudur; kart ve görsel kuralları `art_src/STANDART.md` içindedir.

## Kayıt

Tek yuvalı yerel kayıt (`user://workshop.json`), sürüm 4: kart konumları, reçeteler, bağlantılar, tamponlar, çalışan işler, paylaşım sırası, araştırma ilerlemesi ve puan depoları, envanter, kurulmamış makineler, üretim sırası ve hızlı erişim. Sürüm 3 kayıtları başlangıç kitiyle yüklenir.

## Doğrulama kanıtı — 2026-10-23

- Motor: **4.7.2.stable.official**.
- `tests/test_production.gd`: 80 kontrol — ürünlerin ve araştırmaların kilitlenmeden açılması, çevrim ve paylaşım, yan ürün geri kazanımı, laboratuvar puanları, kurulum sınırı, kayıt bütünlüğü.
- `tests/test_inventory.gd`: başlangıç kiti, yerleştirme, el üretimi süresi ve iptal, sınır, karttan/depodan alma, depo portları, makine kaldırma, hızlı erişim kuralları ve kayıt.
- `tests/test_auto_recipe.gd`: reçetenin gelen ürüne göre seçilmesi ve seçilen reçetenin korunması.
- `tests/test_mine_visual.gd`, `tests/test_smelter_visual.gd`: makine kartı görselleri, animasyon, durdurma, hız ve port hizası.
- Pencereli smoke testi (`-- --smoke-test`): kayıt/yükleme, üretim ekranından CNC üretip hızlı erişimden yerleştirme, reçete ekranı ve kart menüsü, envanter penceresi ve sabitleme, araştırma paneli, sınır, çıkıştan alma, "+" ile üretici kurma. Ekran görüntüleri `artifacts/` altındadır.
- Doğrulanmayanlar: fiziksel fareyle oynanış testi, denge, büyük ağ performansı.

## Çalıştırma ve kaynaklar

Depo kökündeki `Baslat.cmd` oyunu açar; `README.md` kontrolleri ve komutları anlatır. Simülasyon `sim/production_sim.gd`, katalog `data/prototype.json`, arayüz `app/` (`main.gd`, `sprite_machine_card.gd`, `craft_screen.gd`, `inventory_bar.gd`, `inventory_window.gd`, `inventory_slot.gd`, `machine_menu.gd`, `recipe_picker.gd`, `research_panel.gd`).

İlgili: [[Yönetim/Karar Defteri]], [[Tasarım/Prototip ve Doğrulama]].
