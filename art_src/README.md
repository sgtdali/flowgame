# art_src – çizim çalışma alanı

Görsel ve kart kuralları: [STANDART.md](STANDART.md). Yeni makineler `araclar/makine128.py` ile 128x128 çizilir.

Oyunun kullandığı son sheet'ler `app/art/<makine>/` altında durur. Bu klasör onların
kaynağıdır: script'ler, `.ase` dosyaları, referans görseller, önizlemeler.

`.gdignore` sayesinde Godot bu klasörü görmez; buradaki `.png`/`.ase` dosyaları import
edilmez. GIF önizlemeler, `_x4` ve `_kareler` görselleri git'e girmez (`.gitignore`),
script'ler onları yeniden üretir.

| Klasör | İçerik |
|---|---|
| `araclar/` | `pixel_donustur.py`: yapay zekâ görselini piksel art'a çevirir (`--renk 16`, `--blok 2`, klasör de alır). `pixelize_reference.py`: eski, fırın referansına özel sürüm. |
| `ergitme_firini_A/` | Güncel fırın (v3): `draw_furnace_a_v3.py`, referans görsel ve piksel hali, `.ase`, oyun sheet'i. `eski/` = v1 ve v2. |
| `komur_makinesi/` | Ham görsel, piksel halleri, 16 renkli animasyon, `animate_komur_makinesi.py`. `eski_33renk/` = ilk 33 renkli animasyon (elle düzeltilmiş `.ase` burada). |
| `demir_madeni_B/` | Demir madeni çizim/animasyon script'leri ve çıktıları. Fırın script'leri buradaki `draw_mine_node_b.py`'deki yardımcıları kullanır. |
| `disli/`, `robot_kol/`, `diger/` | Dişli, robot kol ve küçük tek görseller. |
| `_yedek_godot/` | Eski kopyalar: oyuna girmeden önceki kart script'leri, mine B entegrasyon script'i ve tek kopyası burada olan `main.gd` yedeği. Asıl kartlar `app/` altında. |

## Çalıştırma

```
python art_src/demir_madeni_B/draw_iron_mine_128.py --oyuna     # 128px maden + oyun sheet'i
python art_src/ergitme_firini_A/draw_smelter_128.py --oyuna     # 128px fırın + oyun sheet'i
python art_src/ergitme_firini_A/draw_furnace_a_v3.py           # eski 288px fırın (artık oyuna yazmayın)
python art_src/komur_makinesi/animate_komur_makinesi.py
python art_src/araclar/pixel_donustur.py gorsel.png --renk 16
```

Script'ler çıktı `.ase` dosyasının üzerine yazar. Elle düzelteceğin `.ase`'yi önce farklı adla kaydet.
