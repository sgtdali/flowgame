# Denge Aracı ↔ Gerçek Oyuncu Turu Karşılaştırması

Hiçbir denge değeri bu turda değiştirilmedi/önerilmedi. Bu, önceki
`balance_audit.md`'nin 2260/986 saniyelik kümülatif sonuçlarını GERÇEK bir
oyuncu turuyla karşılaştırılabilir hâle getirme denemesidir.

## 1. Kapsam — oyuncunun rotası ayrı senaryo olarak kuruldu

Oyuncu PARA MALİYETLİ hiçbir araştırma satın almadı. Bu senaryoya bu
yüzden YALNIZCA ürün-maliyetli (Ar-Ge Sarayı'na teslimatla açılan) dört
araştırma dahil edildi:

| Sıra | Araştırma (görünen ad) | Maliyet türü | Ödül |
|---|---|---|---|
| 1 | Hammer Craft | 24 × Iron Ore (ürün) | Hammer Forge |
| 2 | Shieldcraft | 15 × Iron Plate (ürün) | Shieldwright |
| 3 | Helmcraft | 60 × Iron Shield (ürün) | Helm Forge |
| 4 | Helm Banding | 20 × Iron Helm (ürün) | Helm Bander |

**Bilinçli olarak DIŞARIDA bırakılanlar** (para maliyetli, oyuncu satın
almadı): Rod Drawing (Haddeleme), Rivet Craft (Kesim Hattı), Armor Craft
(Montaj Hattı), Guild Standards (Kalite Kontrol), Salvage Craft (Ar-Ge),
Deep Mining (Derin Sondaj). Bu araştırmaların açtığı istasyonlar (Hadde,
Kesim, Montaj, Kalite, Geri Dönüşüm, Derin Maden) senaryoda HİÇ
kurulmuyor/kullanılmıyor — kodda bu blokları hiçbir strateji fonksiyonu
çağırmıyor (bkz. `tools/balance_lib.gd`, yalnızca Maden/Eritme/Pres/
Kalkan Ustası/Kask Ustası/Dağıtıcı/Ar-Ge Sarayı/Sevkiyat/gıda hattı
kullanılıyor). Bu, oyuncunun bildirdiği kısıtla ÖRTÜŞÜYOR.

**"Açmak" ile "tamamlamak" ayrımı**: bu araç, bir araştırmanın maliyeti
tam karşılanıp `ProgressionState.try_unlock()` başarıyla çağrıldığı anı
ölçer — yani "Keşfet" düğmesi aktif hâle gelip basıldığı an. Ödül
atölyesinin (ör. son araştırmada Helm Bander) FİİLEN KURULUP
ÇALIŞTIRILMASI bu ölçüme DAHİL DEĞİL. Oyuncunun "son araştırmaya
ulaştım" ifadesi kilidi açmak mı yoksa ödülü de kurup kullanmak mı
anlamına geliyor BİLİNMİYOR — kayıt/telemetri olmadığından bu belirsizlik
burada AÇIKÇA bırakılıyor, varsayılmıyor.

**Kayıt/telemetri yok**: aşağıdaki rota, oyuncunun anlattığı KISITLARLA
(tek zincir dönüştürme, sadece ürün-maliyetli araştırma) uyumlu GERÇEKÇİ
BİR MODELDİR — oyuncunun attığı gerçek adımların birebir kaydı DEĞİLDİR.

## 2. Başlangıç durumu — gerçek oyunla aynı kaynak

Bu araç `GameConfig` sabitlerini DOĞRUDAN okur (kopyalamaz):

| Değer | Kaynak | Bu senaryoda |
|---|---|---|
| Başlangıç altını | `GameConfig.START_MONEY` | 1000 |
| Başlangıç işçi | `GameConfig.START_WORKERS` | 5 |
| Başlangıç yiyecek | `GameConfig.START_FOOD` | 30 |
| Tick/saniye | `GameConfig.TICKS_PER_SECOND` | 10 |
| Araştırma miktarları | `ResearchCatalog.*` (canlı `.tres`) | yukarıdaki tablo |

Yani hem gerçek oyun hem bu araç AYNI `.tres`/`GameConfig` dosyalarını
okuyor — ayrı/kopya bir içerik seti YOK.

## 3. Zaman/hız tanımı — ÖNCEKİ araçlarda bulunan bir model hatası düzeltildi

**Bulgu**: `tools/balance_lib.gd`'nin `Sandbox.act()` fonksiyonu, her
kurulum/bağlantı/işçi-atama eylemi için `ACTION_SECONDS` kadar bir süreyi
`seconds_total`'a EKLİYORDU. Bu, gerçek oyunun davranışıyla UYUŞMUYOR:
`GameController._process()` her karede `_advance_sim(delta)` çağırır —
oyuncu bir bağlantıyı sürüklerken/panele tıklarken simülasyon DURMAZ,
seçili hızda tik atmaya DEVAM EDER. Üst bardaki saat (`_clock`) yalnızca
`tick_count`'a bakar. Yani "tıklama süresi" oyunun saatine ekstra
EKLENMEZ — o süre zaten oyunun akan saatinin İÇİNDEDİR.

**Düzeltme**: bu araçta birincil metrik yalnızca `seconds_sim`
(`sim.tick_count / TICKS_PER_SECOND` — oyunun kendi saati). `action_seconds`
(tahmini tıklama/sürükleme payı) AYRI bir dipnot olarak raporlanır, toplama
KATILMAZ. Gerçek dakikaya çevirmek için: `oyun_saniyesi / hız`. Oyuncu 4x
hız bildirdiği için burada 4x varsayılıyor (değiştirilebilir sabit).

## 4. MINIMUM rota — "tek zinciri dönüştürerek" oyuncunun tarif ettiği yol

| Araştırma | Bu aşama (oyun sn) | Kümülatif (oyun sn) | Yatırım | Ek işçi | Para bekleme (sn) | Eylem payı (sn, TOPLAMA DAHİL DEĞİL) |
|---|---|---|---|---|---|---|
| Hammer Craft | 117.7 | 117.7 | 350 altın | 0 | 70.0 | 18.5 |
| Shieldcraft | 283.4 | 401.1 | 900 altın | 1 | 222.4 | 18.0 |
| Helmcraft | 1233.2 | 1634.3 | 2500 altın | 1 | 272.0 | 47.0 |
| Helm Banding | 500.3 | 2134.6 | 1900 altın | 1 | 0.0 | 42.0 |

**Toplam (oyunun kendi saati)**: 2134.6 oyun-saniyesi = 8.9 gerçek dakika (4x hızda).

**Oyuncuyla karşılaştırma**: oyuncu ~5 gerçek dakika bildirdi. Bu modelin
verdiği 8.9 dakika, bildirilen ~5 dakikaya AÇIKÇA FARKLI — aşağıya bkz..

## 4b. "Dönüştür" varyantı — çıktıyı bölmeden %100 laboratuvara

| Araştırma | Bu aşama (oyun sn) | Kümülatif (oyun sn) | Yatırım | Ek işçi | Para bekleme (sn) |
|---|---|---|---|---|---|
| Hammer Craft | 117.7 | 117.7 | 350 altın | 0 | 70.0 |
| Shieldcraft | 283.4 | 401.1 | 900 altın | 1 | 222.4 |
| Helmcraft | 713.1 | 1114.2 | 2150 altın | 1 | 232.0 |
| Helm Banding | 340.3 | 1454.5 | 1550 altın | 1 | 77.5 |

**Toplam (oyunun kendi saati)**: 1454.5 oyun-saniyesi = 6.1 gerçek dakika (4x hızda).

**MINIMUM (bölerek satan) sürüme göre**: 680.1 oyun-sn daha hızlı (%31.9) —
yalnızca çıktıyı bölmeyi bırakmanın etkisi, hiçbir yeni yapı eklenmedi.

**Oyuncuyla karşılaştırma**: oyuncu ~5 gerçek dakika bildirdi. Bu varyant
6.1 dakika veriyor — YAKIN (aynı büyüklük mertebesinde).

## 5. MINIMUM'un denetimi: gereksiz satın alma / yapay bekleme / kullanılmayan kısıt

- **Toplam para bekleme süresi**: 564.4 oyun-sn / 2134.6 toplam (%26.4).
  Bu, MINIMUM'un ZATEN çoğunlukla "bekleyerek" geçtiği bildirimiyle
  UYUŞUYOR — oyuncunun "çoğunlukla bekledim" ifadesi bu modelde de
  doğrudan görünüyor, çelişmiyor.
- **Gereksiz satın alma**: MINIMUM her aşamada yalnızca fiziksel olarak
  ZORUNLU Dağıtıcı(lar)ı satın alıyor (bkz. `tools/balance_lib.gd`
  `_stage_*` fonksiyonları) — Presleme'de 1, Kalkan Zanaati'nde 0 (henüz
  bölme gerekmiyor), Kask Zanaati'nde 2 (kulçe VE kalkan çıkışı için),
  Kask Bantlama'da 2 (levha VE kask çıkışı için). Toplam 5 Dağıtıcı —
  her biri gerçek bir fan-out noktasına karşılık geliyor, fazlalık yok.
- **Kullanılmayan kısıt**: MINIMUM hiçbir noktada 2. Maden/Eritme/Pres
  kurmuyor, hiçbir para-maliyetli araştırmaya ihtiyaç duymuyor — oyuncunun
  "tek zincir" tarifiyle birebir örtüşüyor.
- **Yapay bekleme**: önceki denetimde bulunup düzeltilen sıralama hatası
  (gelir kesilmeden önce satın alma) bu koşumda ZATEN düzeltilmiş hâliyle
  kullanıldı (bkz. `balance_lib.gd` D25/D24 notları).

## 6. HEDEFLİ yatırım — AYNI araştırma hedefleri, AYNI başlangıç durumu

| Araştırma | Bu aşama (oyun sn) | Kümülatif (oyun sn) | Yatırım | Ek işçi | Para bekleme (sn) |
|---|---|---|---|---|---|
| Hammer Craft | 144.2 | 144.2 | 600 altın | 1 | 120.0 |
| Shieldcraft | 142.9 | 287.1 | 900 altın | 1 | 111.9 |
| Helmcraft | 394.1 | 681.2 | 2800 altın | 3 | 152.0 |
| Helm Banding | 149.8 | 831.0 | 2800 altın | 2 | 0.0 |

**Toplam (oyunun kendi saati)**: 831.0 oyun-saniyesi = 3.5 gerçek dakika (4x hızda).

**MINIMUM'a göre mutlak kazanç**: 1303.6 oyun-sn (5.4 gerçek dakika), %61.1.

## 7. Önceki 2260 / 986 saniyelik sonuçlar bu kapsamla eşleşiyor mu?

**Kapsam (hangi araştırmalar, hangi miktarlar) EŞLEŞİYOR** — önceki
`balance_audit.md`'nin kümülatif tablosu da AYNI dört ürün-maliyetli
araştırmayı, AYNI güncel miktarlarla (24/15/60/20) kullandı.

**Zaman TANIMI eşleşMİYOR** — önceki sonuçlar (`seconds_total`)
`seconds_sim + action_seconds` idi (bkz. bölüm 3'teki düzeltme). Bu
yüzden 2260/986 rakamlarını DOĞRUDAN oyuncunun bildirdiği gerçek
dakikayla KARŞILAŞTIRMIYORUZ — yukarıdaki bölüm 4 ve 6'daki DÜZELTİLMİŞ
(`seconds_sim`-yalnız) rakamlar geçerli karşılaştırma noktasıdır.

## 8. Ayrı hat politikası: gıda kapasitesi yatırımıYLA yeniden sınandı

Önceki denetimde "hep ayrı hat" politikası Kask Bantlama'da KİLİTLENDİ
(gıda kıtlığı, doğrulanmıştı). Bu, AYRI HAT stratejisinin KENDİSİNİN
imkansız olduğu anlamına gelmiyordu — SABİT PLANIN (gıda hattını hiç
büyütmeden sürekli işçi eklemek) sonucuydu. Burada aynı politika, işçi
ihtiyacı arttıkça gıda hattını da büyüten bir varyantla yeniden çalıştırıldı.

| Hammer Craft | 74.1 | 74.1 | 250 altın (kümülatif) | 1 (kümülatif) |
| Shieldcraft | 237.5 | 311.6 | 1800 altın (kümülatif) | 4 (kümülatif) |
| Helmcraft | 740.9 | 1052.5 | 7300 altın (kümülatif) | 9 (kümülatif) |
**Gıda genişlemesi** (Kask Bantlama'dan önce): +1 Çiftlik, +1 Değirmen,
+1 Fırın, +1 Ambar = 260 altın, 3 işçi, 193.1 oyun-sn hazırlık.

| Helm Banding | 284.5 | 1530.1 | 10310 altın (kümülatif) | 16 (kümülatif) |

**Sonuç**: gıda hattı önceden büyütüldüğünde "hep ayrı hat" politikası
dört araştırmayı KİLİTLENMEDEN tamamladı. Toplam: 1530.1 oyun-sn (6.4 gerçek
dakika), 10310 altın yatırım, 16 işçi (gıda genişlemesi dahil).

**Sınıflandırma düzeltmesi**: önceki raporda "ayrı hat politikası
kilitleniyor" denmişti — bu YANLIŞ genellemeydi. Doğrusu: "ayrı hat
politikasının gıda hattını BÜYÜTMEYEN SABİT PLANI kilitleniyor"; gıda
yatırımı eklenince aynı politika tamamlanabiliyor, ek maliyeti ölçülebilir
(yukarıdaki 260 altın + 3 işçi + 193.1 sn hazırlık).

## 9. %35 üzeri yatırım avantajı — sorun VARSAYILMADAN, üç boyutuyla raporlanıyor

Kask Bantlama'da HEDEFLİ/AYRI HAT kazancı %35'in belirgin üstünde ölçüldü
(önceki denetimde %73-83). Bu OTOMATİK OLARAK sorun sayılmıyor; üç boyut
birlikte raporlanıyor:

| Boyut | MINIMUM | HEDEFLİ |
|---|---|---|
| Mutlak süre (oyun-sn, bu aşama) | 500.3 | (bkz. bölüm 6 tablosu) |
| Yatırım yükü (bu aşama) | 1900 altın, 1 işçi | (bkz. bölüm 6) |
| Toplam bekleme (para, bu aşama) | 0.0 sn | (bkz. bölüm 6) |

Yüksek yüzde kazancı TEK BAŞINA yorumlanmıyor — mutlak süre kısaysa
(MINIMUM zaten hızlıysa) yüksek yüzde önemsiz olabilir; MINIMUM gerçekten
uzun sürüyorsa (burada olduğu gibi, ~9 dakika) aynı yüzde ANLAMLI bir
mutlak farka karşılık gelir.

## 10. Sonuç: hangi somut yatırım, ne kadar zaman kazandırıyor?

**Oyuncunun rakamıyla asıl uyuşan model "Dönüştür" varyantı** (bölüm 4b):
~6.1 gerçek dakika, oyuncunun bildirdiği ~5 dakikaya bölüm 3'teki
MINIMUM(bölerek-satan)'ın ~8.9 dakikasından çok daha yakın. Bunun anlamı:
iki ayrı bulgu, oyuncunun ~5 dakikalık deneyimini açıklamak için BİRLİKTE
gerekliydi —

1. **Zaman tanımı düzeltmesi** (bölüm 3): eylem süresini toplama EKLEMEMEK
   (2260 sn → 2134.6 sn, küçük ama gerçek bir düzeltme).
2. **Stratejinin kendisi**: "MINIMUM" olarak adlandırdığımız model
   ÇIKTIYI HER ZAMAN bölüp SATIYORDU — oyuncunun "dönüştürerek" tarif
   ettiği, satışı bırakıp %100 araştırmaya yönlendiren yaklaşım DEĞİLDİ.
   Bu ikinci düzeltme (bölüm 4b) asıl büyük farkı kapatan oldu (~8.9 dk
   → ~6.1 dk).

**Somut cevap**: Kalan ~1 dakikalık fark (6.1 vs ~5) için elimde güçlü bir
açıklama YOK — olası nedenler: oyuncunun "~5 dakika" ifadesi yuvarlak bir
tahmin olabilir; kurulum sırasını benim modelimden farklı optimize etmiş
olabilir; ya da bu modelde hâlâ fazladan bir bekleme/adım gizli olabilir.
**Kayıt/telemetri olmadan bu kalan farkı kapatma iddiasında BULUNMUYORUM.**

HEDEFLİ yatırımın (bölüm 6) MINIMUM(bölerek-satan)'a göre sağladığı mutlak
kazanç bölüm 6'da ayrıca raporlandı — ama oyuncunun GERÇEKTE hangi rotayı
izlediği (bölme mi, dönüştürme mi) belirsiz olduğundan, HEDEFLİ'nin
oyuncunun KENDİ deneyimine göre ne kadar kazandıracağı da aynı belirsizliği
taşır — "Dönüştür" temel alınırsa kazanç oranı MINIMUM(bölerek-satan)
temel alınandan FARKLI çıkar; bu araç ikisini de ayrı ayrı gösterdi,
TEK bir "doğru" kazanç yüzdesi İDDİA ETMİYOR.

**Bu bir denge ÖNERİSİ DEĞİLDİR** — kullanıcı isteği üzerine hiçbir
`.tres` değeri değiştirilmedi. Yukarıdaki kanıt bir sonraki denge turunda
başlangıç noktası olarak kullanılabilir; ama "Dönüştür" ile MINIMUM
arasındaki fark başlı başına gösteriyor ki denge aracının STRATEJİ
TANIMLARI (yalnız miktarlar değil) gerçek oyuncu davranışına göre önce
gözden geçirilmeden yeni değer önerisi güvenilir olmaz.