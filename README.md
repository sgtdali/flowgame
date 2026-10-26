# Flowgame — Endüstriyel Üretim ve Araştırma Ağı

Godot 4.7.2 ile üretim ve araştırma prototipi. Oyuncu sınırlı bir harita üzerinde makine kartlarını bağlar; ürünler otomatik eşit paylaşılır, laboratuvarlar araştırma puanı üretir, makineler malzemeyle üretilip envanterden yerleştirilir. Uygulanan kararlar K-002 – K-045 tasarım vault'unda (`game_design/Yönetim/Karar Defteri.md`), ne çalıştığı ve nasıl test edildiği `game_design/Yönetim/Uygulama Durumu.md` içindedir.

## Başlatma

- **Oyun:** Windows'ta `Baslat.cmd` dosyasına çift tıkla.
- **Üretim Zinciri Editörü (Bağımsız Tasarım Aracı):** `ZincirEditoru.cmd` dosyasına çift tıkla (veya `powershell -File tools/launch.ps1 -ChainEditor`). Ürünlerin birbirleriyle olan girdi/çıktı bağlarını, adetlerini, alternatif reçetelerini, makinelerini, iş yüklerini, yan ürünlerini ve araştırma kilitlerini node editör üzerinde düzenler; **Kaydet (`Ctrl+S`)** ile doğrudan `data/prototype.json` dosyasına aktarır.
- Başlatıcı, projenin üst klasöründeki `Godot_v4.7.2-stable_win64.exe` dosyasını kullanır. Başka konum için `GODOT_PATH` ortam değişkenini ayarla.
- Godot editöründen çalışmak için `project.godot` dosyasını içe aktar ve F5 ile çalıştır. Alternatif: `powershell -File tools/launch.ps1 -Editor`.

## Oyunun başı

- Tuvalde bir `Demir madeni` ve ona bağlı bir `Ergitme fırını` kurulu gelir (K-033). Diğer makineleri **C** ile üretip hızlı erişimden ya da envanterden yerleştirirsin. Kit kömür madenine ve `Laboratuvar 1`'e de yeter (K-023).
- `Laboratuvar 1` sürekli çelik levha ve bağlantı elemanı tüketip Kademe 1 puanı üretir. Puanlar depoda birikir; aktif araştırma fiyatını depodan çeker (K-008).
- Envanterde bir başlangıç kiti vardır: demir levha, demir çubuk, çelik levha, bağlantı elemanı, `Bakır madeni`, `Kuvars ocağı` ve `Depo`.
- Harita 20.000×12.000 px; her kaynaktan 3, toplam 12 dağ var. Maden yalnız kendi türünün boş dağına kurulur, en yakın boş dağa oturur (K-043, K-044). Ormanlar, tepeler ve nehir süstür (K-045).
- `Makine Fabrikası` (AL-01) makineleri kurulum bedelinden üretir; çıktıyı karttan ya da bağlı depodan alırsın (K-024).

## Kontroller

| Ne | Nasıl |
|---|---|
| Envanter ve üretim | **I**, **C** ya da alt çubuktaki sandık. Solda bütün öğeler (elde olanlar adediyle). Bir öğe seç: ortada tarifi, solda girdileri, sağda kullanıldığı yerler görünür; kartlara tıklayarak zincirde gezinirsin. **CRAFT** ile sıraya al (Shift: 5 adet), elindeki makineyi **PLACE** ya da çift tıkla yerleştir. El üretimi süreli bir kuyruktur; × ile iptal edilen işin malzemesi geri döner. |
| Hızlı erişim | Alttaki 10 yuva, **1–9 ve 0** tuşları. Makine yuvası makineyi yerleştirir. Pencereden yuvaya sürükle, sağ tıkla ya da öğenin üstündeyken numara tuşuna bas: öğe o yuvaya sabitlenir. Yuvada sağ tık sabitlemeyi kaldırır. |
| Bağlantı | Bir çıkış portundan aynı ürünün giriş portuna sürükle. Port çemberi turuncuysa bağlı değil, yeşilse akış var, kırmızıysa bağlı ama parça gelmiyor ya da çıkış dolu (K-039). Ürünler çizgi üzerinde taşınır ve hedefe varınca sayılır (K-035); aynı ürünü kabul eden tüketiciler eşit pay alır (K-006). Çizgiler kartların etrafından dolaşır, üst üste binmez (K-036). Bağlantıyı silince yoldaki ürünler kaynağa döner. |
| Reçete | Tel sarım, montaj makineleri ve Modül Tesisi gelen ürüne göre üretir. Haddehane, pres, Tezgâh Atölyesi, dökümhane, Makine Fabrikası ve fırında sağ tık → **Choose recipe** ile reçete ekranı açılır (K-009, K-016). Seçili reçetenin girdileri boş giriş kutularında saydam görünür. |
| Kart menüsü | Kartta sağ tık: reçete, Stop/Run, hız 20 ↔ 40 iş/sn, Take to inventory, Remove (to inventory). Laboratuvarda araştırma hedefi. |
| Ürün alma | Karttaki çıkış kutusuna tıkla: biriken ürün envantere geçer. Depo'da giriş kutusuna tıkla. Üretim envantere kendiliğinden geçmez (K-011). |
| Elle besleme | Hızlı erişimden ya da envanter ve üretim penceresinden bir ürünü makinenin giriş kutusuna sürükle: sığdığı kadar konur, Shift ile 1 adet. Ağa bağlı olmayan makine de böyle çalışır (K-014). |
| Üretici kurma | Bir girişin **+** düğmesi o ürünü yapan makineyi envanterden kurup bağlar. |
| Araştırma | Üst çubuktaki araştırma düğmesi: 9 kolda 63 araştırma, kaydırılabilir ağaç. **Sandbox** bütün kilitleri ve sınırları kaldırır. |
| Zaman | Pause/Resume, 1× ↔ 4× hız. |
| Kayıt | Save / Load (`user://workshop.json`), Reset oyunu maden–fırın başlangıcı ve başlangıç kitiyle yeniden başlatır. |

## Dosyalar

- `sim/production_sim.gd`: simülasyon — reçeteler ve çevrimler, paylaşım, bağlantıda taşıma, laboratuvar puanları, araştırma, kurulum sınırı, envanter, el üretimi, hızlı erişim, kayıt (sürüm 4).
- `data/prototype.json`: 55 ürün (beş modül ve Kurucu Çekirdek dahil), 23 makine türü, 63 reçete, 63 araştırma (etkileriyle), 4 puan kademesi, başlangıç kiti, kurulum bedelleri.
- `app/chain_editor.gd`, `app/chain_editor.tscn`, `ZincirEditoru.cmd`: üretim zinciri ve reçete node editörü; **☰ Tablo** düğmesi reçeteleri süre + girdiler → çıktılar tablosu olarak gösterir.
- `app/main.gd`: tuval, üst çubuk, pencerelerin bağlanması, smoke testi.
- `app/flow_graph.gd`, `app/link_router.gd`: bağlantıların çizimi (bant, dik çizgiler, taşınan ürünler) ve kartların etrafından dolaşan, üst üste binmeyen yolların hesabı; haritanın, dağların, süslerin ve nehrin çizimi.
- `data/map.json`: harita sınırı, 12 dağ (yatak), ağaçlar, çalılar, tepeler, nehrin yolu ve kıyı kayaları. Görseller `app/art/map/`.
- `app/sprite_machine_card.gd`: makine kartı (416 px; 256 px görsel, durum renkli bağlantı çemberleri, göstergeler). Kullanıcı çizimi makineler `app/art/smelter_b/`, `iron_mine_c/`, `copper_mine_a/`.
- `app/craft_screen.gd`: envanter ve üretim penceresi (akış haritası). Görselleri `app/art/ui/`, LibreSprite kaynakları `art_src/ui/envanter_penceresi/`. `app/inventory_bar.gd`, `app/inventory_slot.gd`: hızlı erişim çubuğu ve ortak yuva. `app/fonts/`: Pixelify Sans ve Nunito (OFL).
- `app/machine_menu.gd`, `app/recipe_picker.gd`, `app/research_panel.gd`: kart menüsü, reçete ekranı, araştırma paneli.
- `app/icons.gd`, `app/art/`: ürün simgeleri ve makine görselleri. Kaynakları ve çizim kuralları `art_src/` altında (`art_src/STANDART.md`).
- `tests/`: `test_production.gd`, `test_inventory.gd`, `test_auto_recipe.gd`, `test_chain_editor.gd`, `test_mine_visual.gd`, `test_smelter_visual.gd`.
- `game_design/`: Obsidian tasarım vault'u.

## Doğrulama

```powershell
& '..\Godot_v4.7.2-stable_win64_console.exe' --headless --path . -s tests/test_production.gd
& '..\Godot_v4.7.2-stable_win64_console.exe' --headless --path . -s tests/test_inventory.gd
& '..\Godot_v4.7.2-stable_win64_console.exe' --headless --path . -s tests/test_auto_recipe.gd
& '..\Godot_v4.7.2-stable_win64_console.exe' --headless --path . -s tests/test_chain_editor.gd
& '..\Godot_v4.7.2-stable_win64_console.exe' --path . -- --smoke-test
```

Son komut pencerede açılır, arayüzü fare olaylarıyla dener ve `artifacts/` altına ekran görüntüleri yazar (`craft-screen.png`, `inventory-window.png` …). Smoke testi oyuncu kaydından ayrı bir dosya kullanır. Yeni eklenen `.png` dosyaları için önce `--headless --path . --import` çalıştır. Fiziksel fareyle oynanış testi, denge ve büyük ağ performansı ayrıca değerlendirilmelidir.
