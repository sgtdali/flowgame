# Erken Oyun Deneyi — Zamanlama Raporu

Üretici: `tools/intro_timing.gd`. Hiçbir denge değeri değiştirmez —
yalnızca mevcut `.tres`/`GameConfig` değerleriyle ölçer.

**Tahsilat modeli**: oyuncu her `X` GERÇEK saniyede bir "Tahsil Et"e
bastığı varsayılıyor (4x hızda) — anında/sürekli tahsil eden kusursuz
bir oyuncu DEĞİL. Birden fazla aralık tarandı, aralığın etkisi ayrı
gösteriliyor.

**İlk geliştirme** = oyuncunun karşılayabildiği İLK geliştirmeyi satın
aldığı an (en ucuzundan başlanır). **Araştırmaya erişim** = Ar-Ge Sarayı
kurulabilir hâle GELDİĞİ an (`requires_first_upgrade` kapısı açıldığında)
— bina fiilen SATIN ALINDIĞI an da ayrıca raporlanıyor, ikisi aynı şey
değil.

| Tahsilat aralığı | İlk geliştirme | Ar-Ge Sarayı erişilebilir | Ar-Ge Sarayı kuruldu |
|---|---|---|---|
| 10 sn | 0 sn (0.0 dk) | 0 sn (0.0 dk) | 160 sn (0.7 dk) |
| 20 sn | 0 sn (0.0 dk) | 0 sn (0.0 dk) | 160 sn (0.7 dk) |
| 45 sn | 0 sn (0.0 dk) | 0 sn (0.0 dk) | 180 sn (0.8 dk) |

Sütun değerleri "oyun-sn (gerçek dk @ 4x)" biçiminde.

## Bu deneyde seçilen sabitler

| Parametre | Değer | Nerede |
|---|---|---|
| Maden/Çiftlik sınırı | 1 | `BlockType.max_instances` |
| Maden geliştirme (taban/kat/max) | 150 altın / ×1.6 / L3 |
| Çiftlik geliştirme (taban/kat/max) | 60 altın / ×1.6 / L3 |
| Eritme geliştirme (taban/kat/max) | 250 altın / ×1.6 / L3 |
| Değirmen/Fırın geliştirme (taban) | 60 / 70 altın |
| Her seviye hız kazancı | ×0.85 süre (%15 daha hızlı) |
| Araştırma erişim eşiği | 1 geliştirme VEYA 10.0 min | `GameConfig.MIN_UPGRADES_FOR_RESEARCH` / `RESEARCH_FALLBACK_TICKS` |

## Bilinen sınır

`tools/balance_lib.gd`'nin HEDEFLİ/AYRI HAT stratejileri, Maden/Çiftlik'i
2./3. kez İNŞA EDEREK darboğazı çözüyordu — bu artık `max_instances=1`
ile YASAK. Bu araç onları bu turda GÜNCELLEMEDİ (kapsam: yalnızca erken
oyun deneyinin kendi zamanlamasını ölç). Presleme-ve-sonrası zincir için
o araçlar hâlâ geçerli, ama 'Maden Ocağı inşa et' adımları artık
simülasyonda GERÇEKTEN reddedilir — bir sonraki denge turunda ele
alınmalı.