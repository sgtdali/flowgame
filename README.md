# Flowgame — Endüstriyel Üretim ve Araştırma Ağı

Godot 4.7.2 ile üretim ve araştırma prototipi. Onaylanan **K-001** (doğrudan ürün tüketen araştırma), **K-005** (iş/hız üretim çevrimi), **K-006** (otomatik eşit paylaşım) ve **K-007** (5 katmanlı 24 ürün kataloğu, makine türleri ve 9 araştırmalık teknoloji ağacı ilk taslağı) birlikte çalışır.

## Başlatma

Windows'ta `Baslat.cmd` dosyasına çift tıkla. Başlatıcı, bu bilgisayarda projenin üst klasöründeki `Godot_v4.7.2-stable_win64.exe` dosyasını kullanır. Başka konum için `GODOT_PATH` ortam değişkenini ayarla.

Godot editöründen çalışmak için bu klasördeki `project.godot` dosyasını içe aktar ve F6 yerine projeyi F5 ile çalıştır. Alternatif: `powershell -File tools/launch.ps1 -Editor`.

## Başlangıç Ağı ve Araştırma Döngüsü

Başlangıç ağı Kademe 0 makineleriyle kurulur:
`Demir Madeni` + `Kömür Madeni` → `Ergitme Fırını (Pik Demir)` → `Çelik Fırını (Çelik Külçe)` → iki `Haddehane (Çelik Levha ve Çelik Çubuk)` → `Pres (Bağlantı Elemanı)` → `Araştırma Laboratuvarı (A-01: Talaşlı İmalat)`.

- `Kömür`, `Çelik Külçe` ve `Çelik Çubuk` çıkışları bağlı tüketiciler arasında **K-006** gereğince otomatik eşit paylaşılır.
- `Araştırma Laboratuvarı`, seçili araştırmanın gerektirdiği ürünleri doğrudan tüketerek deney ilerlemesi sağlar (**K-001**).
- **A-01: Talaşlı İmalat** tamamlandığında sol kütüphanede `Torna` ve `CNC Tezgâhı` açılır (`Mil`, `Dişli`, `Rulman` ve yan ürün olarak `Metal Talaşı`).
- Üst çubuktaki **Araştırma Ağacı** düğmesinden 9 araştırmalık (`A-01` – `A-09`) teknoloji ağacını açıp aktif araştırmayı değiştirebilir veya **Serbest Mod** düğmesiyle 24 ürünün tüm makine ve reçetelerini hemen açabilirsin.

## Kontroller

- Soldaki **Makine Kütüphanesi** içinde ara ve açık bir makineye tıklayarak canvas'a ekle.
- Canvas üzerinde bir karta tıkla: sağdaki **Seçili Makine** panelinde **uygun reçeteleri seçebilir**, gereken iş, işleme hızı, çevrim süresi, kapasite ve canlı tamponları görebilirsin.
- Çok girdili ve çok çıktılı reçetelerde (ör. `CNC` ve `Torna`'dan çıkan `Metal Talaşı` yan ürünü) her ürün kendi renkli port satırına sahiptir.
- **Çıkış Tamponunu Boşalt** düğmesiyle makine çıkışında biriken ürünleri (ör. henüz geri kazanım hattına bağlanmamış `Metal Talaşı`) temizleyebilir veya `Talaş Bertaraf Ünitesi` / `Çelik Fırını (Talaştan Çelik Geri Kazanımı)` bağlayabilirsin.
- Kaydet/Yükle yerel `user://workshop.json` yuvasını kullanır; ağ, seçili reçeteler, stoklar, yarım kalan işler, paylaşım sırası ve araştırma ilerlemesi korunur.

## Dosyalar

- `sim/production_sim.gd`: 24 ürün, çok girdili/çıktılı reçeteler, K-005 işleme, K-006 paylaşım, K-007 9 araştırmalık teknoloji ağacı ve kayıt durumu.
- `data/prototype.json`: 24 ürün, 16 makine türü, 37 reçete ve 9 araştırma (`A-01` – `A-09`) tanımı.
- `app/main.gd`: Çok portlu GraphEdit arayüzü ve simülasyon bağlantısı.
- `app/machine_library.gd`: Arama, kilit durumu ve kart ekleme menüsü.
- `app/machine_inspector.gd`: Seçili makinenin reçete seçimi, canlı ayrıntı ve envanter paneli.
- `app/research_panel.gd`: 3 kademeli 9 araştırmalık teknoloji ağacı paneli.
- `tests/test_production.gd`: 24 ürün erişilebilirliği (deadlock kontrolü), süre, stok, paylaşım, yan ürün geri kazanımı, araştırma geçişi ve kayıt devamlılığı testleri (63 kontrol).
- `game_design/`: Obsidian tasarım vault'u; güncel ürün kararları.

## Doğrulama

```powershell
& '..\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/test_production.gd
& '..\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --quit-after 20 -- --smoke-test
& '..\Godot_v4.7.2-stable_win64_console.exe' --path . --rendering-method gl_compatibility -- --smoke-test
```

Son komut OpenGL penceresinde çalışır, arayüz işlemlerini kontrol eder ve `artifacts/production-workshop.png` görüntüsünü üretir. Test; arama, boş arama/sonuç bulunamaması, kütüphaneden ekleme, seçime bağlı panel, stok çubukları, hız değişimine tepki, durdur/çalıştır, silme ve kayıt yüklemesini kapsar. Kütüphane ve kart seçimi, viewport'a gönderilen fare giriş olaylarıyla da doğrulanır. Smoke testi normal oyuncu kaydından ayrı dosya kullanır. Fiziksel fareyle kullanıcı testi ve büyük ağ performansı ayrıca değerlendirilmelidir.
