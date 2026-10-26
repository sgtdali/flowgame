# Makine görseli ve kart standardı (aşama 2, 256 px)

Her makine aynı karta oturur. Kart Godot arayüzüdür; görsel sadece makineyi gösterir.
Kararlar: K-038 – K-042 (`game_design/Yönetim/Karar Defteri.md`).

## Kart (416 × 327 px, tek port satırında)

```
╔══════════════════════════════════════════════╗
║ ▓ Ad                     ürün          ⏸   ▓ ║  başlık şeridi çerçevenin içinde
║                                              ║
◉  ▢    ┌──────────────────────────┐     ▢   ◉   girişler solda, çıkışlar sağda
║       │      makine görseli      │           ║  ◉ = 24 px durum çemberi
║       │        256 × 256         │           ║  ▢ = malzeme kutusu (40 px)
║       └──────────────────────────┘           ║
║ ■ ▰▰▰▰▰▰▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱  40/min ║  çevrim çubuğu
╚══════════════════════════════════════════════╝
```

- Yan sütunlar 80 px, görsel 256 px. Port satırları görselin yüksekliğini eşit böler:
  1 port ortada (görselin 128. pikseli), 2 port 64/192 piksel yükseklikte.
- Bağlantı çemberi 24 × 24, kartın kenarına ortalıdır ve kartın üstünde çizilir
  (`app/art/ui/port_states.png`, 72 × 24: turuncu bağlı değil, yeşil akış var, kırmızı
  bağlı ama parça alamıyor). Malzeme kutusu çemberden 2 px boşlukla başlar (kenardan 14 px).
- Çerçeve şimdilik envanter penceresinden ödünçtür (`flow_center_frame.png`, başlık
  `recipe_top.png`); kartın kendi çerçevesi kullanıcı tarafından çizilecek. Şablon
  ölçüleri: başlık 33 px, görsel üstten 39 px, alt şerit 18 px + 14 px boşluk.
- Kartta yazı en aza iner: makine adı ve dakikadaki üretim. Sayılar (tampon 4/12, süre,
  reçete adı) ipucundadır.
- Karttan hiçbir şey dışarı taşmaz; yalnız bağlantı çemberlerinin yarısı kenarın dışındadır.
  Boru, soket, simge gibi parçalar görselde yer almaz.

## Görsel

| Kural | Değer |
|---|---|
| Tuval | 256 × 256, saydam arka plan; çizim oranı korunarak sığdırılır ve ortalanır |
| Çizgi | Çizimin çevresinde 1 px siyah dış çizgi |
| Sprite sheet | 4 sütun, satır sayısı serbest; kare boyutu = sheet genişliği / 4. Fırın 12 kare (1024 × 768), madenler 32 kare (1024 × 2048), 10 FPS |
| Eski görseller | 128 px yer tutucular ve sheet'ler tam 2 kat büyütülerek gösterilir |
| Filtre | Godot'da nearest, mipmap yok |
| Yasak | Yazı, sayı, port/soket, bilgi plakası, kartın dışına uzanan boru |

Kullanıcı çizimleri (Ergitme fırını, Demir madeni, Bakır madeni) eski aşamanın 32 renklik paletine (`araclar/palet.py`)
bağlı değildir; büyük çizimden Lanczos ile küçültülür. Yeni görsel kullanıcı onaylamadan
oyuna konmaz (K-042).

Hareket sadece çalışırken oynar; makine durunca ilk karede kalır. Kasa sabittir, hareket eden
parçalar (matkap, dişli, alev, duman) ayrı katmanda çizilir.

## Dosyalar

- Kullanıcı çizimi makineler: `app/art/smelter_b/`, `app/art/iron_mine_c/`,
  `app/art/copper_mine_a/` (sheet ve tek kare PNG). Kaynak `.ase` dosyaları henüz bu klasörde değil.
- Eski 128 px aşama (palet ve script'le çizim):
- Çizim script'i: `art_src/<makine>/draw_<makine>_128.py`, ortak yardımcılar
  `art_src/araclar/makine128.py`.
- Script çıktıları: `.ase` (katmanlı, LibreSprite'ta açılır), `_onizleme.png`, `.gif`.
- `--oyuna` ile oyun sheet'i `app/art/<makine>/<makine>_sheet.png` olarak yazılır.
- Godot tarafında yeni makine için `app/sprite_machine_card.gd` içindeki `SHEETS`
  sözlüğüne tek satır eklenir. Listede olmayan makineler `app/art/placeholder/<makine>.png`
  yer tutucusunu kullanır (`araclar/yer_tutucu_makineler.py` üretir).
- Ürün simgeleri oyunda 32x32 ve 1:1 görünür (`app/art/ui/product_icons.png`, ürün başına 32
  piksellik hücre). Reçete miktarı 1'den büyükse simgenin köşesinde yazar.
  - Yeni simgeler 32x32 çizilip `urun_32/<ürün>.png` olarak konur; `araclar/urun_ikonlari.py`
    şeridi kurarken bunları olduğu gibi alır. Henüz 32'lik çizimi olmayan ürünler eski 16x16
    çizimin 2x büyütülmüşüyle kalır.
  - Tarz (kullanıcı seçimi, 2026-10-23, dişliyle): iri ve sade silüet, 1 px `ink` dış çizgi,
    sol üstten ışıkla 2 px'lik kenar parlaması/gölgesi, tek bir vurgu ayrıntısı. Mavimsi
    renkler istenmedi. Dişli pirinç renk takımıyla çizildi (`disli_stil/disli_d_32.py`);
    seçenekler ve Codex taslağı `disli_stil/` klasöründe.
