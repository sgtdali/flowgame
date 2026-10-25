---
tur: uygulama-kaydi
durum: prototip
guncelleme: 2026-10-26
---
# Uygulama durumu

Godot 4.7.2 prototipinde 2026-10-26 itibarıyla çalışan ve test edilen kısım. "Uygulandı" oynanışın doğrulandığı anlamına gelmez; sayılar ilk denemedir.

## Uygulanan kararlar

| Karar | Prototipte |
|---|---|
| K-002, K-003 | Sonsuz tuval üzerinde makine kartları; kartlar arasında ürün tipli port bağlantıları. |
| K-005 | Reçete işi / makine işleme hızı; çok girdili ve çok çıktılı reçeteler; girdiler başta tüketilir, çıktılar iş bitince eklenir; giriş/çıkış tamponları; eksik girdi ya da dolu çıkış yeni çevrimi bekletir. |
| K-006 | Kabul edebilen bağlı tüketicilere her ürün için otomatik eşit paylaşım (çıkış başına hatırlanan adil sıra). |
| K-035 | Ürün bağlantıya girer, 60 px/sn ilerler (aralarında en az 10 px), yolun sonunda hedefin girişi boşsa sayılır; hedef doluysa yolda sıraya girer. Yol uzunluğu tuvaldeki çizgiden gelir; uzunluğu olmayan bağlantı (simülasyon testleri) anlık aktarır. Silinen bağlantıdaki ürün çıkış kapasitesi kadar kaynağa döner. Ürünler çizgide 8x8 simgeyle çizilir. |
| K-034, K-036, K-037 | Bağlantıları Godot yerine oyun çizer: 16 px'lik bant ve dik çizgiler; çizgiler kartların etrafından dolaşır, üst üste binmez, kesişmede sonra çizilen üstten geçer. Yol bulucu (`app/link_router.gd`) her bağlantıyı çevresindeki kartlarla küçük bir ızgarada A* ile arar; kart oynayınca yalnız etkilenen bağlantılar yeniden hesaplanır; yollar tuval koordinatındadır, ekran dışındakiler çizilmez. |
| K-007, K-021 | 55 ürün, 23 makine türü, 63 reçete (+ Makine Fabrikası'nın makine reçeteleri). Beş modül ve Kurucu Çekirdek tanımlı; yeni ürünlerin piksel simgesi yok, renkten üretilen simge kullanılır. |
| K-022 | Tezgâh Atölyesi, tek Ergitme Fırını, dört montaj makinesi ve Modül Tesisi; yeni makineler yer tutucu görsel kullanır. |
| K-023 | Demir ağırlıklı başlangıç bedelleri ve yeni başlangıç kiti. |
| K-024 | Makine Fabrikası (AL-01): her sınırsız makine için kurulum bedelli reçete; çıktı kartta (3) ya da bağlı depoda birikir, alınınca taşınan makine olur. |
| K-025 | 63 araştırma; maden sınırı, makine ve el hızı, tampon ve depo kapasitesi araştırma etkileri; Laboratuvar 4 ve K4. Araştırma paneli 9 kolu satır satır gösterir ve kayar. |
| K-026, K-028 | Envanter ve üretim tek pencerede (I ya da C), akış haritası düzeni; kullanıldığı yerler 6 kart, fazlası adım adım kayar. Eski `inventory_window.gd` kaldırıldı. |
| K-031, K-032 | Pencere 1120x720 sabit, kapatma düğmeli; büyük öğe resmi 64 px; kuyruk en fazla 5 farklı öğe. Bütün pencere görselleri kullanıcının LibreSprite çizimleri (`app/art/ui/`, kaynaklar `art_src/ui/envanter_penceresi/`); Crafting Queue akış alanının altında, Quick Bar en altta, kendi çerçeveli bölümlerinde. |
| K-029 | Tarif kutusunda süre yerine reçetenin iş miktarı, çekiç simgesiyle. |
| K-027, K-030 | Kum taşı paleti; bütün oyun metinleri ve araştırma adları İngilizce; Pixelify Sans ve Nunito fontları (`app/fonts`, OFL); pencere dokusu ve kilitli makinelerde kategori simgesi. |
| K-017 | Döküm parçalar ayrı ürün (`cast_iron_gear`, `cast_iron_housing`); Gearbox döküm gövde ister. |
| K-018 | `Ana proje terminali` 1 `Founding Core` ister; çekirdek her modülden 4 ister (ilk tahmin). |
| K-008 | Laboratuvar 1–4 sürekli aynı ürünleri tüketip Kademe 1–4 puanı üretir; puan depoda birikir, aktif araştırma eksiğini depodan çeker. |
| K-009, K-016 | Tel sarım, montaj makineleri ve Modül Tesisi reçeteyi gelen ya da elle konan ürüne göre seçer, boşken tek genel girişi olur. Haddehane, pres, Tezgâh Atölyesi, dökümhane, Makine Fabrikası ve fırında (K-016) simgeli reçete ekranından ürün seçilir. |
| K-010 | Dört maden birer adetle başlar, maden genişletme araştırmalarıyla artar; sınır kurulu, envanterdeki ve üretim sırasındaki makineleri birlikte sayar. Serbest modda sınır yok. |
| K-011 | Envanter, malzemeli makine kurulumu, karttan/depodan elle alma, süreli el üretimi kuyruğu, başlangıç kiti, Depo kartı. |
| K-012 | Alttaki 10 yuvalı hızlı erişim çubuğu ve I ile açılan envanter penceresi; ikisi aynı envanteri paylaşır, öğeler hızlı erişime sabitlenir. |
| K-033 | Oyun Demir madeni → Ergitme fırını (Iron Ingot) kurulu ve bağlı başlar; Sıfırla da aynı başlangıca ve başlangıç kitine döner (K-013'ün yerine). |
| K-014 | Envanterden makine girişine sürükle-bırak; ağa bağlı olmayan makine elle çalışır. |
| K-015 | Kartta ürünler çerçeveli kutularda adetle (0'da boş, bar yok); seçili reçetenin girdileri boş kutuda saydam; üretilen ürün başlıkta. |

Ayrıntılar: [[Tasarım/Makine Kartları]], [[Tasarım/Araştırma Ekonomisi]], [[Tasarım/Envanter ve El Üretimi]], [[Tasarım/Teknoloji Ağacı]].

## Arayüz

- **Üst çubuk:** Araştırma ağacı (aktif araştırma ve yüzdesi), Serbest mod, Duraklat/Devam, oyun hızı (1× ↔ 4×), Ortala, Kaydet, Yükle, Sıfırla.
- **Makine kartı:** Başlıkta makinenin adı ve ürettiği ürün; 128×128 makine görseli; giriş ve çıkış kutuları (adet, boş girişte beklenen ürün saydam), çevrim çubuğu, durdurma düğmesi. Çıkış kutusuna tıklamak ürünü envantere alır; giriş kutusuna envanterden ürün bırakılır; bir girişin "+" düğmesi o ürünü yapan makineyi envanterden kurup bağlar.
- **Kart menüsü (sağ tık):** Ne üretilsin? (reçete ekranı), Durdur/Çalıştır, hız 20 ↔ 40 iş/sn, Envantere al, Kaldır (envantere); laboratuvarda araştırma hedefi seçimi.
- **Envanter ve üretim penceresi (I ya da C)** ve **hızlı erişim çubuğu (1–9, 0):** bkz. [[Tasarım/Envanter ve El Üretimi]]. Pencere el çizimi görsellerle kaplı (K-032); eski koyu çerçeve görseli (`panel_frame.png`) artık kullanılmıyor.
- **Bağlantılar:** 16 px'lik bant, üzerinde taşınan ürünler; sürükleme önizlemesi de aynı stilde (K-034 – K-036).
- **Araştırma paneli:** Kademeli araştırma ağacı, kademe puanı depoları, aktif araştırma seçimi, serbest mod.

## Geçici deney seçimleri

- Oyun başındaki maden–fırın çifti K-033 ile onaylı; konumları ve fırının Iron Ingot reçetesi asistan seçimi.
- Eski 8 kartlık başlangıç ağı (`Demir madeni` + `Kömür madeni` → iki `Ergitme fırını` (demir, çelik) → iki `Haddehane` → `Pres` → `Laboratuvar 1`) oyundan kalktı; yalnızca smoke testi ve kart görsel testleri onu `build_sample_network()` ile kurar.
- Bütün makinelerin işleme hızı 20 iş/sn; kart menüsünden 40'a çıkarılabilir. Tamponlar 6–12, Depo 100.
- `Talaş bertaraf ünitesi` yer tutucudur; bertaraf için kullanıcı kararı yoktur.
- Kurucu Çekirdek'e kadar tam bir oyun denenmedi; adetler ve süreler dengelenmedi.
- Bağlantı hızı (60 px/sn) ve ürün aralığı (10 px) ilk denemedir; bağlantının ayrıca kapasite sınırı yok. Bölge, enerji ve para uygulanmadı.
- Yol bulucunun sayıları (dönüş bedeli, şerit sayısı, kart boşluğu 4 px, arama alanı payları 80/320/1280 px) asistan seçimidir. Sürüklerken seyrek hesaplama (K-037'nin ertelenen 3. maddesi) uygulanmadı.
- Makine görsellerinin bir kısmı yer tutucudur; kart ve görsel kuralları `art_src/STANDART.md` içindedir.

## Kayıt

Tek yuvalı yerel kayıt (`user://workshop.json`), sürüm 4: kart konumları, reçeteler, bağlantılar (uzunluğu ve yoldaki ürünlerle; eski kayıtlarda bunlar boş gelir), tamponlar, çalışan işler, paylaşım sırası, araştırma ilerlemesi ve puan depoları, envanter, kurulmamış makineler, üretim sırası ve hızlı erişim. Sürüm 3 kayıtları başlangıç kitiyle yüklenir.

## Doğrulama kanıtı — 2026-10-26

- Motor: **4.7.2.stable.official**.
- `tests/test_production.gd`: 72 kontrol — ürünlerin ve 63 araştırmanın kilitlenmeden açılması, çevrim ve paylaşım, yan ürün geri kazanımı, laboratuvar puanları, kurulum sınırı, kayıt bütünlüğü; bağlantıda taşıma (önce yola girme, aralık, kayıtta saklanma, varınca sayılma, silinince kaynağa dönme ve çıkış kapasitesi).
- `tests/test_inventory.gd`: boş başlangıcın çıkmaz olmaması (kitten Laboratuvar 1'e), makineye elle koyma, başlangıç kiti, yerleştirme, el üretimi süresi ve iptal, sınır, karttan/depodan alma, depo portları, makine kaldırma, hızlı erişim kuralları ve kayıt; Makine Fabrikası; araştırma etkileri (maden sınırı, hız, tampon, depo, el hızı) ve kayıtları.
- `tests/test_auto_recipe.gd`: fırının ve aynı girdili makinelerin seçimli olması, reçetenin gelen ürüne göre seçilmesi (tel sarım, montaj makineleri) ve seçilen reçetenin korunması.
- `tests/test_chain_editor.gd`: Zincir Editörü'nün veri modeli.
- `tests/test_mine_visual.gd`, `tests/test_smelter_visual.gd`: makine kartı görselleri, animasyon, durdurma, hız ve port hizası.
- Pencereli smoke testi (`-- --smoke-test`, son çalıştırma K-037 sonrası, geçti): kayıt/yükleme, envanter ve üretim penceresinde bütün öğelerin listelenmesi, makinede yapılan ürün için CRAFT yerine açıklama, pencereden Tezgâh Atölyesi üretip hızlı erişimden yerleştirme, reçete ekranı ve kart menüsü, pencereden sabitleme, araştırma paneli, sınır, çıkıştan alma, "+" ile üretici kurma. Smoke testi maden–fırın başlangıcını denetleyip yeni bir oyunda örnek ağı kurarak devam eder.
- Bağlantı yolları (geçici betikle, 2026-10-26): örnek ağ ve üç farklı yerleşimde üst üste binen çizgi ve kart altından geçen çizgi 0. 500 sade kart ve 936 bağlantıda ilk hesap 0,5 sn, kart sürüklerken kare başına ortalama 11 ms (en kötü 19 ms), değişiklik yokken 2,5 ms. Ekran görüntüleri `artifacts/` altındadır.
- Doğrulanmayanlar: fiziksel fareyle oynanış testi, denge, gerçek oyun kartlarıyla büyük ağ performansı (Godot'nun 500 kartı çizmesi ölçülmedi).

## Çalıştırma ve kaynaklar

Depo kökündeki `Baslat.cmd` oyunu açar; `README.md` kontrolleri ve komutları anlatır. Simülasyon `sim/production_sim.gd`, katalog `data/prototype.json`, arayüz `app/` (`main.gd`, `flow_graph.gd` (bağlantıların çizimi), `link_router.gd` (bağlantı yolları), `sprite_machine_card.gd`, `craft_screen.gd` (envanter ve üretim penceresi), `inventory_bar.gd`, `inventory_slot.gd`, `machine_menu.gd`, `recipe_picker.gd`, `research_panel.gd`).

İlgili: [[Yönetim/Karar Defteri]], [[Tasarım/Prototip ve Doğrulama]].
