# Faz 5 — kalan işler

> Faz 1-4 bitti, MVP oynanabilir. Bu dosya **duraklattığımız yerin notu.**
> Bağlam için: [DESIGN.md](DESIGN.md) (19+2 maddelik karar günlüğü dahil).
>
> Son durum: `oyun-uygulama` dalı, commit `ac2a22f`.
> Ölçülen tur süresi 63.3 dk (hedef 60). 8 sim testi + tempo koşumu geçiyor.

---

## Oynanıştan gelenler

**1. tur (yapıldı) — metrikler eksikti.** Node'larda üretim hızı, üst barda
gelir hızı yoktu; oyuncu "hangi istasyon yavaş" ve "ne kazanıyorum"
sorularını sayıyla göremiyordu. Eklendi:

- Node: `Hız  32.0/dk  %75` — gerçekleşen hız ve teorik tavana göre verim.
  **%100 = darboğaz** (daha fazlası gerekiyor), düşük yüzde = bekliyor,
  suç başka yerde.
- Üst bar: `+320 ₺/dk`
- Alt çubuk: `sevkiyat 32.0/dk`
- Durum rozeti yumuşatıldı: %75 verimle çalışan istasyon ÇALIŞIYOR ile AÇ
  arasında titriyordu. Son bir saniye içinde çalıştıysa ÇALIŞIYOR gösterilir.
- Alt çubuktaki tıkalı/aç sayımı da node'larda gösterilen duruma bağlandı;
  iki ayrı kaynaktan okuyup çelişiyorlardı.

**2. tur (yapıldı) — durum yazısı gereksizdi.** Node'daki "Durum: ÇALIŞIYOR"
satırı hem yer kaplıyordu hem de renk zaten okunuyordu. Yazı kaldırıldı,
durum **çerçeve rengine** taşındı:

- **Yeşil** — çalışıyor
- **Turuncu** — boşta (ya malzeme bekliyor ya çıktısını boşaltamıyor;
  ikisi de "duruyor" demek, oyuncu için ayrımı hız/kuyruk sayıları veriyor)
- **Kırmızı** — bir portu boşta, akışa katılamıyor

Kırmızı yeni bir şey söylüyor: akış durumu değil **kurulum hatası**. Bu
sayede aşağıdaki 2. madde (bağlanmamış Ret portu uyarısı) da kapandı.
Rengin ne anlama geldiği düğümün üstüne gelince ipucunda yazıyor.

**3. tur (yapıldı) — hız göstergesi dalgalanıyordu.** Node'daki `Hız` ve
`%verim` düzenli üretimde bile sürekli değişiyordu, ilerleme çubuğu dolarken
göz rahatsız edici şekilde titriyordu. Kök sebep iki yanlış tasarımdan geçti:

1. **İlk sürüm** (sabit 15 sn'lik pencere): üretim periyodu pencereye tam
   bölünmezse (14 tick'te 1 gibi), pencere kenarı her üretim anını
   geçtiğinde sayaç 40↔44 arası sert sıçrıyordu. Ölçüldü.
2. **İkinci deneme** (üstel yumuşatılmış türev): kenar sıçraması gitti ama
   üretim ayrık olduğu için (çoğu tick'te değişim sıfır, üretim anında ani
   sıçrama) yumuşatılmış değer HER KAREDE sürekli sürünmeye başladı —
   "zıplama" yerine "durmadan kayma" oldu, ki asıl şikayet buydu.

**Doğru model:** üretim bir olay dizisi. Hız, konumun türevinden değil,
**ardışık olaylar arasındaki sürenin ortalamasından** hesaplanır — tıpkı bir
hız göstergesinin tekerlek dönüşleri arasındaki süreden hız kestirmesi gibi.
Düzenli üretimde iki olay arası süre hep aynı olduğundan gösterilen değer
olaylar arasında TAMAMEN SABİT kalır. Doğrulandı: 3 saniye gerçek oyun
koşumunda `30.0/dk %70` metni bir kez yazıldı, hiç değişmedi (eskiden her
karede değişiyordu). İstasyon durunca da hız donup kalmıyor, kademeli sıfıra
sönüyor (60→10→5.5→2.9→1.9/dk), donuk/yanlış bir sayı göstermiyor.

**4. tur (yapıldı) — gelir hızı testere dişi gibiydi.** 3. turdaki düzeltme
tek üretimli node'larda işe yaradı ama üst bardaki gelir hızı (birden fazla
istasyonun, farklı fiyatlı ürünlerin toplamı) hâlâ bozuktu: bir satışta
sıçrıyor, sıradaki satışa kadar sürekli düşüyor, sonra tekrar sıçrıyordu.

Kök sebep, 3. turdaki düzeltmenin İÇİNDE gizli bir birim uyuşmazlığıydı.
Algoritma "olaylar arası ortalama süreyi" **birim başına** tutuyordu (ör.
"1₺ üretmek kaç tick sürer"). Bir satışta 10₺ birden gelince bu değer 2.0
tick'e düşüyordu — çünkü 10₺, 20 tick'lik aralığa değil, teknik olarak "tek
bir ₺" ölçeğine bölünüyordu. Bunu son olaydan bu yana geçen HAM tick
sayısıyla (0-20 arası) karşılaştırınca sistem satıştan birkaç tick sonra
"normalden çok beklendi" sanıp sönmeye başlıyordu; asıl olaylar arası süre
tam 20 tick olduğu hâlde.

**Doğru düzeltme:** olaylar arası HAM süreyi ve olay başına düşen MİKTARI
AYRI AYRI ortalamak, ikisini ancak son anda bölmek. Böylece "ne kadar
beklendiği" ile "normalde ne kadar beklenmesi gerektiği" aynı birimde (ham
tick) kıyaslanıyor. Doğrulandı: aynı senaryoda yön değişimi 551'den 0'a
düştü, üst bar 3 saniye boyunca "+300 ₺/dk" yazıp hiç kıpırdamadı.

Bu, RateMeter'ın üçüncü ve son tasarımı. Dosyanın başındaki yorum üç
denemeyi de (neden başarısız olduklarıyla) kayıtlı tutuyor — aynı hataya
düşmemek için oraya bakılabilir.

**5. tur (yapıldı) — üç ayrı konu.**

**(a) Araştırma paneli açıkken bakiye canlanmıyordu.** Panel yalnızca
Ar-Ge Lab'a akıtılan ürün değişince yenileniyordu, bakiye değişince değil —
para maliyetli bir araştırma erişilebilir hâle gelse bile "Araştır" düğmesi
etkinleşmiyordu, paneli kapatıp açmak gerekiyordu. Artık bakiye değişimi de
yenilemeyi tetikliyor.

**(b) Gelir hızı yüksek meblağlarda hâlâ oynaktı (1600-3000 gibi).** 4. turda
düzeltilen model TEK bir olay akışı varsayıyordu; gerçekte külçe (10₺) ve
gövde (220₺) gibi 22 kat farklı büyüklükte satışlar AYNI ölçere karışınca,
nadir gelen büyük satış ortalamayı bir anda fırlatıyordu. Ölçüldü: karışık
ekonomide gösterge 481-3330 TL/dk arası geziniyordu. Çözüm: her ÜRÜN TÜRÜ
için ayrı bir hız ölçer tutup (`SalesRateTracker`), sonucu toplamak — aynı
ürün içinde miktar sabit olduğundan her biri kusursuz durağan kalıyor,
sabitlerin toplamı da durağan kalıyor.

**(c) Yeni node: Dağıtıcı (Splitter).** Bir istasyonun çıkışı yetişemeyen
ikinci bir istasyona yönlendirilebilsin istendi (ör. Pres 1sn'de 1 veriyor,
Hadde 1.5sn'de tüketiyor). Bunun yanında **kural değişikliği**: artık her
çıkış portu TEK tele sınırlı — birden fazla hatta dağıtmanın tek yolu
Dağıtıcı (2 ayrı çıkış portu olan tek istasyon türü). Bu, önceki "aynı
porttan birden fazla tel" örtük mekaniğinin yerini aldı; oyuncu artık
dallanmayı görmeden/anlamadan kuramaz.

Uygulama sırasında BULUNAN VE DÜZELTİLEN bir hata: Dağıtıcı'nın iki çıkış
portu sabit sırayla (0, sonra 1) denenince, tek bir parça birikmişken port 0
HER SEFERİNDE kazanıyor, port 1 HİÇ beslenmiyordu — ölçüldü, 3000 tick'te
ikinci Hadde 0 üretti. Düzeltme: hangi portun önce deneneceği, bir gönderim
başarılı olduğunda bir sonraki porta kaydırılıyor. Doğrulandı: 74/74 üretim,
%0 fark.

Not: bu turda tempo YENİDEN ÖLÇÜLMEDİ (kullanıcı talebiyle ertelendi).
`tools/sim_test.gd`'nin 8 kontrolü ve `tools/progression_test.gd`'nin
bağlantı/satın alma adımları hatasız tamamlanıyor; tempo sayısı bir dahaki
turda değerlendirilecek.

---

## Sıradaki tur: yine oyna

Kod yazmadan önce **10-15 dakika gerçekten oynanmalı.** Ölçüm tempoyu
doğruluyor ama şunları ölçemiyor:

- Tıkanmayı çözmek tatmin edici mi, yoksa sinir bozucu mu?
- Montaj (iki hattı birleştirme) kavranıyor mu? MVP'nin zirvesi orası;
  kavranmazsa oyun 33. dakikada biter.
- Boş sahayla başlamak kafa karıştırıcı mı? Şu an tek yönlendirme alt
  çubuktaki "Maden Ocağı → Eritme Fırını → Sevkiyat kurarak başla" bildirimi.

Aşağıdaki maddelerin önceliği bu geri bildirime göre değişebilir.

---

## Test disiplini — SÜREÇ KURALI

Bir önceki turda `progression_test.gd`'yi düzeltmek 10 dakika sürdü ve bu
zaman kaybı oyunu geliştirmekten çaldı. İki kalıcı önlem alındı:

### 1. İki katmanlı test — hangi durumda hangisi çalışır

| Test | Ne zaman | Süre | Neden |
|---|---|---|---|
| `sim_test.gd` | **Her kod değişikliğinden sonra, varsayılan** | ~saniyeler | Simülasyonun kendisinin doğru çalıştığını kanıtlar — determinizm, kaydet/yükle, tıkanma. Gerçek hata yakalar (fire kilitlenmesi, Dağıtıcı port adaletsizliği). |
| `progression_test.gd` | **Yalnızca tempo/denge sorulduğunda** | dakikalar | 60 dakikalık bir turu oynayarak ölçer. Mimari değişikliklerde OTOMATİK çalıştırılıp düzeltilmez — kırılırsa TODO'ya not düşülür, tempo turunda toplu ele alınır. |

Bir mimari kural değiştiğinde (ör. "çıkış tek tele sınırlı") her iki test de
etkilenebilir. `sim_test.gd` küçük olduğu için düzeltmesi ucuz, hep yapılır.
`progression_test.gd` gerçek bir oyun turunu elle kablolar, düzeltmesi
pahalıdır — bu yüzden BEKLER, tempo ölçümü istenene kadar bozuk kalabilir.

### 2. `progression_test.gd` artık gerçekten HIZLI BAŞARISIZ oluyor

Bulunan ikinci sorun: script'in `_fail()`'i hatayı yazdırıp **koşuma devam
ediyordu** — `quit()` GDScript'te çalışan kodu anında durdurmuyor, yalnızca
ana döngüye "bir sonraki karede çık" diyor; `--script` modunda hepsi tek
karede çalıştığından `_play()` TAMAMEN BİTENE KADAR sürüyor. Sonuç: kırık
bir bağlantıyla sahte bir ekonomi üstünden onlarca oyun-içi dakika daha
koşup BİR SONRAKİ aşamada da hataya düşüyordu — kök nedeni görmek için
scripti üç kez art arda çalıştırıp her seferinde zincirin bir halkasını
çözmek gerekti.

Düzeltme: `halted` bayrağı — `_fail()` çağrılınca tüm yardımcı fonksiyonlar
(`_build`, `_wire`, `_run_until`, `_afford_and_research`, `_mark`) no-op'a
döner. Artık İLK hata anında duruyor, tek koşumda kök neden görünüyor.
Doğrulandı: kasıtlı bozuk bir bağlantıyla test edildi, tek satır hata verip
durdu (eskiden tüm senaryoyu sahte verilerle tamamlayıp yanıltıcı bir özet
basıyordu).

---

## Faz 5 kapsamı

### 1. Montaj ipucu  ·  *tasarımda söz verildi, yapılmadı*

DESIGN.md §6'daki risk: "Montaj öğrenme eşiği — kavranmazsa oyun orada biter.
Azaltma: Montaj açılınca örnek düzen ipucu göster."

Montaj araştırması alındığında bir kerelik ipucu: Pres çıkışının hem Hadde'ye
hem Montaj'a gitmesi gerektiğini anlatan küçük bir şema.

### ~~2. Bağlanmamış Ret portu uyarısı~~  ·  **YAPILDI**

Boşta portu olan istasyonun çerçevesi kırmızı yanıyor, alt çubuk da
"N istasyonun portu boşta" diyor. Kalite Kontrol'ün Ret portu dahil.

### 3. Çıkış oranı kontrolü  ·  *ertelenmiş karar, Faz 2'den*

Bir çıkış birden fazla yere bağlıysa yük **round-robin 50/50** bölünüyor ve
oyuncunun oranı ayarlama imkânı yok.

Bu gerçek bir sorun: Pres çıkışı Hadde ile Montaj arasında yarı yarıya
bölünüyor, ama Montaj gövde başına 2 levha istiyor ve vida kolu fazlasıyla
besleniyor. Oyuncunun tek çözümü "daha çok istasyon kurmak".

**Karar bekliyor:** MVP için bu yeterli mi, yoksa Factorio'daki gibi öncelikli
ayırıcı mı gerekiyor? Gerçek oynanışı görmeden karar verme — erken eklemek
YAGNI olur.

### 4. Denge ince ayarı  ·  *oyun geri bildirimine bağlı*

63.3 dk ölçüldü. Oyuncu "sıkıldım" ya da "çok hızlı bitti" derse ayar yeri belli:

- `common/game_config.gd` — tick hızı, başlangıç parası, slot
- `tools/gen_content.gd` — fiyatlar, süreler, araştırma maliyetleri

Değiştirdikten sonra **mutlaka** üreticiyi ve tempo koşumunu tekrar çalıştır:

```bash
godot --headless --path . --script res://tools/gen_content.gd
godot --headless --path . --script res://tools/progression_test.gd
```

### 5. Kablolarda akan noktalar  ·  *Faz 3'te bilerek ertelendi*

Bağlantı üzerinde akan ürünleri gösteren animasyon. Tamamen kozmetik ama
hattın canlı hissini çok artırır. GraphEdit'in çizgilerinin üstüne ayrı bir
overlay `Control` ile `_draw` yapmak en pratik yol.

---

## Test disiplini — SÜREÇ KURALI

Bir önceki turda `progression_test.gd`'yi düzeltmek 10 dakika sürdü ve bu
zaman kaybı oyunu geliştirmekten çaldı. İki kalıcı önlem alındı:

### 1. İki katmanlı test — hangi durumda hangisi çalışır

| Test | Ne zaman | Süre | Neden |
|---|---|---|---|
| `sim_test.gd` | **Her kod değişikliğinden sonra, varsayılan** | ~saniyeler | Simülasyonun kendisinin doğru çalıştığını kanıtlar — determinizm, kaydet/yükle, tıkanma. Gerçek hata yakalar (fire kilitlenmesi, Dağıtıcı port adaletsizliği). |
| `progression_test.gd` | **Yalnızca tempo/denge sorulduğunda** | dakikalar | 60 dakikalık bir turu oynayarak ölçer. Mimari değişikliklerde OTOMATİK çalıştırılıp düzeltilmez — kırılırsa TODO'ya not düşülür, tempo turunda toplu ele alınır. |

Bir mimari kural değiştiğinde (ör. "çıkış tek tele sınırlı") her iki test de
etkilenebilir. `sim_test.gd` küçük olduğu için düzeltmesi ucuz, hep yapılır.
`progression_test.gd` gerçek bir oyun turunu elle kablolar, düzeltmesi
pahalıdır — bu yüzden BEKLER, tempo ölçümü istenene kadar bozuk kalabilir.

### 2. `progression_test.gd` artık gerçekten HIZLI BAŞARISIZ oluyor

Bulunan ikinci sorun: script'in `_fail()`'i hatayı yazdırıp **koşuma devam
ediyordu** — `quit()` GDScript'te çalışan kodu anında durdurmuyor, yalnızca
ana döngüye "bir sonraki karede çık" diyor; `--script` modunda hepsi tek
karede çalıştığından `_play()` TAMAMEN BİTENE KADAR sürüyor. Sonuç: kırık
bir bağlantıyla sahte bir ekonomi üstünden onlarca oyun-içi dakika daha
koşup BİR SONRAKİ aşamada da hataya düşüyordu — kök nedeni görmek için
scripti üç kez art arda çalıştırıp her seferinde zincirin bir halkasını
çözmek gerekti.

Düzeltme: `halted` bayrağı — `_fail()` çağrılınca tüm yardımcı fonksiyonlar
(`_build`, `_wire`, `_run_until`, `_afford_and_research`, `_mark`) no-op'a
döner. Artık İLK hata anında duruyor, tek koşumda kök neden görünüyor.
Doğrulandı: kasıtlı bozuk bir bağlantıyla test edildi, tek satır hata verip
durdu (eskiden tüm senaryoyu sahte verilerle tamamlayıp yanıltıcı bir özet
basıyordu).

---

## Faz 5 kapsamında DEĞİL (bilinçli olarak dışarıda)

Bunlar MVP non-goal'ü olarak kararlaştırıldı, DESIGN.md §1'e bakın:

offline kazanç · dinamik pazar · sözleşme sistemi · enerji şebekesi ·
çoklu reçete seçici · birden fazla fabrika · ses · çoklu dil

İki tanesi için yol zaten açık, istenirse ucuz:

- **Offline kazanç** — simülasyon deterministik ve tamsayı tick sayıyor.
  Kapanış zamanını kaydedip açılışta fark kadar `tick()` çağırmak yeterli.
- **Bitiş koşulu** (karar D18, "sonraya bırakıldı") — Derin Maden Sondajı
  zaten doğal bir final. Üstüne bir kazanma ekranı koymak küçük iş.

---

## Devam ederken hatırlanacaklar

- **`tools/gen_content.gd` üzerine yazar.** Inspector'da elle yapılan ayarlar
  silinir. İçerik değişikliğini ya hep oradan yap, ya hep Inspector'dan.
- **Kabuk (Git Bash) Türkçe kesme işaretinde takılıyor.** `Laboratuvarı'na`
  gibi metinler heredoc içinde komutu bozuyor. Bu dosyaları Write aracıyla
  yaz, `bash -c` içine gömme.
- **Yeni global sınıf ekledikten sonra** `--script` çalıştırmadan önce bir kez
  `godot --headless --path . --editor --quit` ile projeyi taratmak gerekiyor,
  yoksa sınıf önbelleği bayat kalıyor.
