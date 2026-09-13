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

## Faz 5 kapsamı

### 1. Montaj ipucu  ·  *tasarımda söz verildi, yapılmadı*

DESIGN.md §6'daki risk: "Montaj öğrenme eşiği — kavranmazsa oyun orada biter.
Azaltma: Montaj açılınca örnek düzen ipucu göster."

Montaj araştırması alındığında bir kerelik ipucu: Pres çıkışının hem Hadde'ye
hem Montaj'a gitmesi gerektiğini anlatan küçük bir şema.

### 2. Bağlanmamış Ret portu uyarısı  ·  *kilitlenme düzeltildi ama sessiz*

Faz 4'te ölümcül bir kilitlenme bulunup düzeltildi (karar D21): hurda kutusu
dolunca istasyon artık kilitlenmiyor, parçayı sağlam geçiriyor.

Ama oyuncu hâlâ **sessizce** fire kaybediyor — Ret portunu bağlamadığını
fark etmesinin bir yolu yok. Kalite Kontrol'ün Ret portu boştayken görsel bir
uyarı gerekiyor (port kırmızı yanıp sönsün, ya da bildirim çıksın).

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
