# Denge Arama Raporu

Uretici: `tools/balance_search.gd`. Bu rapor EKONOMIK TESVIKLERI olcer
(hangi strateji ne kadar surede/paraya tamamlaniyor, kaynak nerede
bekletiyor). Oyuncunun bunu eglenceli bulup bulmayacagini KANITLAMAZ —
onu yalniz elle oynanan playtest gosterir.

Hedef bant: hedefli/ayri hat yatirimi, MINIMUM stratejiye gore hazirlik
dahil toplam surede **%20-%35** kazanc saglamali (degistirilebilir,
evrensel dogru degil — `BalanceLib.TARGET_SAVINGS_MIN/MAX`).

Ayrintili, sayisal denetim icin (tum stratejilerin tek tabloda
karsilastirilmasi, kumulatif sure, kilit nedeni analizi) bkz.
`tools/balance_audit.gd` ve onun uretttigi `tools/balance_audit.md`.

## Bu koşumda taranan adaylar

| Asama | Mevcut | Taranan aday | Bantta mi? | Hedefli kazanc | Ayri hat kazanc |
|---|---|---|---|---|---|
| presleme (Hammer Craft / Iron Ore → Hammer Forge) | 24 | 24 | evet | %-27.9 | %36.0 |
| kalkan_zanaati (Shieldcraft / Iron Plate → Shieldwright) | 15 | 15 | hayir | %-15.2 | %-58.8 |
| kask_zanaati (Helmcraft / Iron Shield → Helm Forge) | 60 | 35 | evet | %27.4 | %10.3 |
| kask_bantlama (Helm Banding / Iron Helm → Helm Bander) | 20 | 20 | hayir | %73.6 | %83.2 |

## Varsayimlar

- Eylem suresi modeli (saniye/eylem): { "build": 6.0, "wire": 3.0, "unwire": 2.0, "staff": 2.5, "research_click": 1.5 }
- Iki baslangic senaryosu test edildi: normal (1000 altin) ve az sermaye
  (efektif 700 altin). Farkli hat kapasiteleri taranmadi — bilinen sinir.
- Bu arac EKONOMIK TESVIKLERI dogrular; oyuncu KEYFINI degil.
- Bu dosyadaki 'taranan aday' bir ONERI degil — hedef banda giren EN
  KUCUK/uygun deger. 'En iyi deger' iddiasi degildir; detay icin
  balance_audit.md'ye bakin.