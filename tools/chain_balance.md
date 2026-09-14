# Hat dengesi: Maden → Eritme → Sevkiyat → Tahsilat

`tools/chain_balance.gd` çıktısı (bkz. DESIGN.md D29). Gerçek `FactorySim` +
`ProgressionState` üzerinde koşulmuştur — teorik hesap değil.

Başlangıç: 1000 TL | Maden yapım=250, Eritme yapım=400, Sevkiyat yapım=0
(kalan bakiye: 350 TL) | Sonraki aşama (Ar-Ge Sarayı) = 450 TL

Maden geliştirme: taban 150 TL, büyüme ×2.0/seviye, +15.0 cevher/dk/seviye
(katlanmayan, sabit artış), maksimum seviye 4.

Sevkiyat geliştirme: taban 900 TL, büyüme ×2.0/seviye, her seviye temel
satış değerine toplamsal +%100 (×1 → ×2 → ×3 → ×4), maksimum seviye 4.

## Sonraki aşamaya ulaşma süresi (strateji × tahsilat aralığı)

| Strateji | 15 sn aralık | 30 sn aralık |
|---|---|---|
| Hiç geliştirme alma (biriktir) | 10.0 dk (2.5 dk @4x) | 10.0 dk (2.5 dk @4x) |
| Sadece üretim hızı (Maden) | 1.5 dk (23 sn @4x) | 3.0 dk (45 sn @4x) |
| Sadece satış değeri (Sevkiyat) | 2.8 dk (41 sn @4x) | 3.0 dk (45 sn @4x) |
| Önce hız, sonra değer | 1.5 dk (23 sn @4x) | 3.0 dk (45 sn @4x) |
| Önce değer, sonra hız | 1.5 dk (23 sn @4x)* | 3.0 dk (45 sn @4x) |
| İki geliştirme al, sonra biriktir | 1.5 dk (23 sn @4x) | 2.0 dk (30 sn @4x) |

\* "Önce değer" öncelik sırası dener ama ilk tahsilat anında (15 sn) 900 TL
henüz karşılanamadığından gerçekte Maden'e kayar — bu YAPAY değil, gerçek bir
oyuncunun da yapacağı şey: elindeki parayla alabildiğini alır.

**Neden "hiç geliştirme alma" hep 10 dakika sürüyor?** Bu tasarım gereği
(bkz. D27): araştırma erişimi en az 1 geliştirme satın alınmasına bağlı;
hiç almayan bir oyuncu için 10 dakikalık zamanlayıcı yalnızca GÜVENLİK AĞI.
Para 1-2 dakikada zaten yeter, ama kapı geç açılıyor — bu, "en az bir
yükseltme al" davranışını doğal olarak ödüllendiriyor.

## Uzun vadeli karşılaştırma (15 dk, erken kesmeden, 15 sn tahsilat)

NONE = hiç geliştirme almadan biriktirilen toplam kazanç. Diğer sütunlar
NONE'a göre FARK (+) ve o ana kadar yükseltmeye harcanan toplamı gösterir.

| t | NONE | RATE_MAX (+fark, harcanan) | VALUE_MAX (+fark, harcanan) | BOTH_MAX (+fark, harcanan) |
|---|---|---|---|---|
| 60s | 290 | 370 (+80, 450) | 290 (+0, 0) | 370 (+80, 450) |
| 180s | 890 | 1230 (+340, 1050) | 1190 (+300, 900) | 1230 (+340, 1050) |
| 300s | 1490 | 2080 (+590, 1050) | 2390 (+900, 2700) | 2510 (+1020, 1950) |
| 600s | 2990 | 4230 (+1240, 1050) | 7190 (+4200, 6300) | 8850 (+5860, 7350) |
| 900s | 4490 | 6370 (+1880, 1050) | 13190 (+8700, 6300) | 17410 (+12920, 7350) |

**Okuma:** RATE_MAX (Maden'i 3 kez geliştirip durmak) 1050 TL harcar, ~9 dk
civarında kendini öder (600s'de +1240 > 1050 harcanan), sonra sabit bir
ek gelir vermeye devam eder — düşük risk, mütevazı getiri.

VALUE_MAX (Sevkiyat'ı 3 kez geliştirip durmak) 6300 TL harcar; 300s'de HÂLÂ
zararda (+900 kazanç, 2700 harcanan), 600s'de bile henüz tam ödemedi (+4200
kazanç, 6300 harcanan) — ama 900s'de fazlasıyla döndü (+8700, 6300 harcanan)
ve büyümesi hızlanarak sürüyor. Yüksek risk (geç öder), ama tavana kadar
gidildiğinde çok daha büyük getiri.

Bu asimetri BEKLENEN bir sonuç, tesadüf değil: satış değeri geliştirmesi
TÜM geliri çarpıyor (kullanıcı isteği gereği, +%100/seviye — bu formül
değiştirilemez), üretim hızı geliştirmesi ise sabit bir miktar EKLİYOR.
Çarpımsal bir yükseltme, yeterince büyük bir tabana uygulandığında her
zaman toplamsal bir yükseltmeden daha güçlü olur — bunu dengelemek için
tek gerçek kolum onun FİYATIYDI (taban 400 TL'den 900 TL'ye çıkarıldı,
büyüme aynı ×2.0 kaldı çünkü kullanıcı isteği sabit).

## Gerçek START_FOOD doğrulaması

START_FOOD=300, işçi=5, 16 dakika boyunca gıda hiç tükenmedi
(`food_shortage` hep `false`). Eskiden 30 idi — 5 işçi × 1 gıda/dk ile
6 dakikada tükenip istasyonları AÇ (HUNGRY) durdururdu; "hiç geliştirme
alma" stratejisinin kendisi 10 dakika sürdüğü için bu GÖRÜNMEYEN bir
darboğaz olurdu. 300, bu deneyin süresini rahatça kapsayan (~60 dk tampon)
ama kalıcı olarak sınırsız olmayan bir değer.
