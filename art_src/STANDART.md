# Makine görseli ve kart standardı (aşama 1)

Her makine aynı karta oturur. Kart Godot arayüzüdür; görsel sadece makineyi gösterir.

## Kart (256 px genişlik)

```
┌──────────────────────────────────────┐
│ Ad                               ⏸   │  başlık: tek yazı, durdur/çalıştır
├─────────┬──────────────────┬─────────┤
│ ● ▰▰▱   │                  │   ▰▱▱ ● │  girişler solda, çıkışlar sağda
│         │  makine görseli  │         │  (ürün simgesi + tampon çubuğu)
│ ● ▰▱▱   │     128 × 128    │         │
├─────────┴──────────────────┴─────────┤
│ ▰▰▰▰▰▰▰▰▰▱▱▱▱▱▱▱               40/dk  │  çevrim çubuğu, renk = durum
└──────────────────────────────────────┘
```

- Yan sütunlar 64 px, görsel 128 px. Port satırları görselin yüksekliğini eşit böler:
  1 port ortada, 2 port 32/96, 3 port yaklaşık 21/64/107 piksel yükseklikte.
- Kartta yazı en aza iner: makine adı ve dakikadaki üretim. Sayılar (tampon 4/12, süre,
  reçete adı) ipucunda ve sağ paneldedir.
- Durum rengi: yeşil çalışıyor, sarı bekliyor/çıkış dolu, gri durdu veya oyun duraklatıldı.
- Reçete seçimi kartta değil, sağ paneldedir.
- Karttan hiçbir şey dışarı taşmaz. Boru, soket, simge gibi parçalar görselde yer almaz;
  bağlantı noktaları kartın kendi portlarıdır.

## Görsel

| Kural | Değer |
|---|---|
| Tuval | 128 × 128, saydam arka plan |
| Gövde | En fazla 112 × 112, tuvalde ortalı, zemin çizgisi y = 120 |
| Sprite sheet | 12 kare, 4 sütun × 3 satır = 512 × 384, 10 FPS, 1.2 sn döngü |
| Palet | `araclar/palet.py` içindeki ortak 32 renk, başka renk yok |
| Çizgi | 1 px koyu (`ink`) dış çizgi, ışık sol üstten |
| Filtre | Godot'da nearest, mipmap yok |
| Yasak | Yazı, sayı, port/soket, bilgi plakası, kartın dışına uzanan boru |

Hareket sadece çalışırken oynar; makine durunca ilk karede kalır. Kasa sabittir, hareket eden
parçalar (matkap, dişli, alev, duman) ayrı katmanda çizilir.

## Dosyalar

- Çizim script'i: `art_src/<makine>/draw_<makine>_128.py`, ortak yardımcılar
  `art_src/araclar/makine128.py`.
- Script çıktıları: `.ase` (katmanlı, LibreSprite'ta açılır), `_onizleme.png`, `.gif`.
- `--oyuna` ile oyun sheet'i `app/art/<makine>/<makine>_sheet.png` olarak yazılır.
- Godot tarafında yeni makine için `app/sprite_machine_card.gd` içindeki `SHEETS`
  sözlüğüne tek satır eklenir. Listede olmayan makineler `app/art/placeholder/<makine>.png`
  yer tutucusunu kullanır (`araclar/yer_tutucu_makineler.py` üretir).
- Ürün simgeleri `araclar/urun_ikonlari.py` ile 16x16 çizilir; kart portlarında 2x görünür ve
  reçete miktarı 1'den büyükse simgenin köşesinde yazar.
