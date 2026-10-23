# Flowgame — Endüstriyel Üretim ve Araştırma Ağı

Godot 4.7.2 ile üretim ve araştırma prototipi. Oyuncu sonsuz bir tuval üzerinde makine kartlarını bağlar; ürünler otomatik eşit paylaşılır, laboratuvarlar araştırma puanı üretir, makineler malzemeyle üretilip envanterden yerleştirilir. Uygulanan kararlar K-002 – K-012 tasarım vault'unda (`game_design/Yönetim/Karar Defteri.md`), ne çalıştığı ve nasıl test edildiği `game_design/Yönetim/Uygulama Durumu.md` içindedir.

## Başlatma

- **Oyun:** Windows'ta `Baslat.cmd` dosyasına çift tıkla.
- **Üretim Zinciri Editörü (Bağımsız Tasarım Aracı):** `ZincirEditoru.cmd` dosyasına çift tıkla (veya `powershell -File tools/launch.ps1 -ChainEditor`). Ürünlerin birbirleriyle olan girdi/çıktı bağlarını, adetlerini, alternatif reçetelerini, makinelerini, iş yüklerini, yan ürünlerini ve araştırma kilitlerini node editör üzerinde düzenler; **Kaydet (`Ctrl+S`)** ile doğrudan `data/prototype.json` dosyasına aktarır.
- Başlatıcı, projenin üst klasöründeki `Godot_v4.7.2-stable_win64.exe` dosyasını kullanır. Başka konum için `GODOT_PATH` ortam değişkenini ayarla.
- Godot editöründen çalışmak için `project.godot` dosyasını içe aktar ve F5 ile çalıştır. Alternatif: `powershell -File tools/launch.ps1 -Editor`.

## Oyunun başı

- Tuval boştur (K-013). İlk makineleri **C** ile üretip hızlı erişimden ya da envanterden yerleştirirsin. Kit; demir ve kömür madeni, ergitme ve çelik fırınına yeter, fırının külçesinden el ile levha, çubuk ve bağlantı elemanı yapıp `Laboratuvar 1`'e ulaşılır.
- `Laboratuvar 1` sürekli çelik levha ve bağlantı elemanı tüketip Kademe 1 puanı üretir. Puanlar depoda birikir; aktif araştırma fiyatını depodan çeker (K-008).
- Envanterde bir başlangıç kiti vardır: çelik levha, bağlantı elemanı, çelik külçe, `Bakır madeni`, `Kuvars ocağı` ve `Depo`.
- Madenler oyun başında birer adet kurulabilir (K-010).

## Kontroller

| Ne | Nasıl |
|---|---|
| Üretim ekranı | **C** ya da alt çubuktaki çekiç. Bir öğe seç, **ÜRET** ile sıraya al (Shift: 5 adet). El üretimi süreli bir kuyruktur; × ile iptal edilen işin malzemesi geri döner. |
| Envanter penceresi | **I** ya da alt çubuktaki sandık. Makineye tıklamak onu yerleştirir. |
| Hızlı erişim | Alttaki 10 yuva, **1–9 ve 0** tuşları. Makine yuvası makineyi yerleştirir. Envanterden yuvaya sürükle, sağ tıkla ya da öğenin üstündeyken numara tuşuna bas: öğe o yuvaya sabitlenir. Yuvada sağ tık sabitlemeyi kaldırır. |
| Bağlantı | Bir çıkış portundan aynı ürünün giriş portuna sürükle. Aynı ürünü kabul eden tüketiciler eşit pay alır (K-006). |
| Reçete | Pres, tel sarım ve montaj gelen ürüne göre üretir. Haddehane, CNC, dökümhane ve fırınlarda sağ tık → **Ne üretilsin?** ile reçete ekranı açılır (K-009, K-016). Seçili reçetenin girdileri boş giriş kutularında saydam görünür. |
| Kart menüsü | Kartta sağ tık: reçete, Durdur/Çalıştır, hız 20 ↔ 40 iş/sn, Envantere al, Kaldır (envantere). Laboratuvarda araştırma hedefi. |
| Ürün alma | Karttaki çıkış kutusuna tıkla: biriken ürün envantere geçer. Depo'da giriş kutusuna tıkla. Üretim envantere kendiliğinden geçmez (K-011). |
| Elle besleme | Hızlı erişimden ya da envanter penceresinden bir ürünü makinenin giriş kutusuna sürükle: sığdığı kadar konur, Shift ile 1 adet. Ağa bağlı olmayan makine de böyle çalışır (K-014). |
| Üretici kurma | Bir girişin **+** düğmesi o ürünü yapan makineyi envanterden kurup bağlar. |
| Araştırma | Üst çubuktaki araştırma düğmesi; **Serbest mod** bütün kilitleri ve sınırları kaldırır. |
| Zaman | Duraklat/Devam, 1× ↔ 4× hız. |
| Kayıt | Kaydet / Yükle (`user://workshop.json`), Sıfırla oyunu boş tuval ve başlangıç kitiyle yeniden başlatır. |

## Dosyalar

- `sim/production_sim.gd`: simülasyon — reçeteler ve çevrimler, paylaşım, laboratuvar puanları, araştırma, kurulum sınırı, envanter, el üretimi, hızlı erişim, kayıt (sürüm 4).
- `data/prototype.json`: 55 ürün (beş modül ve Kurucu Çekirdek dahil), 19 makine türü, 62 reçete, 9 araştırma, başlangıç kiti, kurulum bedelleri.
- `app/chain_editor.gd`, `app/chain_editor.tscn`, `ZincirEditoru.cmd`: üretim zinciri ve reçete node editörü.
- `app/main.gd`: tuval, üst çubuk, pencerelerin bağlanması, smoke testi.
- `app/sprite_machine_card.gd`: makine kartı (görsel, göstergeler, portlar).
- `app/craft_screen.gd`: üretim ekranı. `app/inventory_window.gd`, `app/inventory_bar.gd`, `app/inventory_slot.gd`: envanter penceresi, hızlı erişim çubuğu ve ortak yuva.
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
